import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:tic_tac_zwo/features/game/online/data/services/noun_sync_service.dart';

import '../../../online/data/models/german_noun_hive.dart';
import '../models/german_noun.dart';

class GermanNounRepo {
  static const String _assetPath = 'assets/words/fallback_nouns.json';
  final Box<GermanNounHive> _nounsBox;
  final Box<dynamic> _syncInfoBox;
  final NounSyncService _syncService;

  final _nounsReadyCompleter = Completer<void>();
  Future<void> get ready => _nounsReadyCompleter.future;

  List<GermanNoun> _availableNouns = [];

  // stream controller for sync status updates
  final _syncController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatus => _syncController.stream;

  StreamSubscription? _connectivitySubscription;

  GermanNounRepo({
    required Box<GermanNounHive> nounsBox,
    required Box<dynamic> syncInfoBox,
    required NounSyncService syncService,
  })  : _nounsBox = nounsBox,
        _syncInfoBox = syncInfoBox,
        _syncService = syncService;

  // initialize the repo - loads from local db or fallback nouns
  Future<void> initialize() async {
    try {
      if (_nounsBox.isEmpty) {
        await _loadFromAssets();
      } else {
        // refresh from available nouns
        _refreshAvailableNouns();
      }

      // schedule sync with remote after initial load
      _scheduleRemoteSync();

      _monitorConnectivity();

      if (!_nounsReadyCompleter.isCompleted) {
        _nounsReadyCompleter.complete();
      }
    } catch (e) {
      if (!_nounsReadyCompleter.isCompleted) {
        _nounsReadyCompleter.completeError(e);
      }
    }
  }

  void _monitorConnectivity() {
    _connectivitySubscription?.cancel();

    syncWithRemote();

    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      if (!result.contains(ConnectivityResult.none)) {
        syncWithRemote();
      }
    });

    Connectivity().checkConnectivity().then(
      (result) {
        if (!result.contains(ConnectivityResult.none)) {
          syncWithRemote();
        }
      },
    );
  }

  // load nouns from assets and store in hive
  Future<void> _loadFromAssets() async {
    try {
      final String jsonString = await rootBundle.loadString(_assetPath);
      final List<dynamic> jsonList = json.decode(jsonString);
      final List<GermanNoun> nouns =
          jsonList.map((json) => GermanNoun.fromJson(json)).toList();

      // store in hive
      await _nounsBox.clear();
      for (var i = 0; i < nouns.length; i++) {
        final noun = nouns[i];
        final hiveNoun = GermanNounHive(
          id: 'local_$i',
          noun: noun.noun,
          article: noun.article,
          plural: noun.plural,
          english: noun.english,
          difficulty: 1,
          updatedAt: DateTime.now(),
          version: 1,
        );
        await _nounsBox.put(noun.noun, hiveNoun);
      }
      _refreshAvailableNouns();
      _syncController
          .add(SyncStatus(status: 'Loaded from assets', count: nouns.length));
    } catch (e) {
      print('error loading nouns from assets: $e');
      _syncController.add(SyncStatus(
        status: 'Error loading from assets',
        error: e.toString(),
      ));
    }
  }

  // refresh available nouns from local db
  void _refreshAvailableNouns() {
    final allNouns = _nounsBox.values
        .map((hiveNoun) => _hiveNounToGermanNoun(hiveNoun))
        .toList();
    _availableNouns = List<GermanNoun>.from(allNouns)..shuffle();
  }

  // convert hive noun to german noun
  GermanNoun _hiveNounToGermanNoun(GermanNounHive hiveNoun) {
    return GermanNoun(
      article: hiveNoun.article,
      noun: hiveNoun.noun,
      english: hiveNoun.english,
      plural: hiveNoun.plural,
    );
  }

  //fetch 9 nouns for a game
  Future<List<GermanNoun>> loadNouns() async {
    final int nounBatchSize = 18;

    if (_availableNouns.isEmpty || _availableNouns.length < nounBatchSize) {
      _refreshAvailableNouns();
    }

    final fetchedNouns = _availableNouns.take(nounBatchSize).toList();

    return fetchedNouns;
  }

  // mark used nouns
  void markNounAsUsed(GermanNoun noun) {
    _availableNouns.removeWhere((n) => n.noun == noun.noun);
  }

  Future<GermanNoun> loadRandomNoun() async {
    if (_availableNouns.isEmpty) {
      _refreshAvailableNouns();
    }

    if (_availableNouns.isNotEmpty) {
      return _availableNouns[Random().nextInt(_availableNouns.length)];
    } else {
      return GermanNoun(
        article: 'das',
        noun: 'Fehler',
        english: 'Error',
        plural: 'Fehler',
      );
    }
  }

  Future<void> syncWithRemote() async {
    try {
      print('Starting noun sync with remote');
      _syncController.add(SyncStatus(status: 'Syncing...'));

      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        print('Sync aborted: No internet connection');
        _syncController.add(SyncStatus(status: 'no internet connection'));
        return;
      }

      // get last sync info
      final lastSync = _syncInfoBox.get('lastSyncTime') as DateTime?;
      final lastVersion = _syncInfoBox.get('lastVersion') as int? ?? 0;
      print(
          'Last sync: ${lastSync?.toIso8601String() ?? 'never'}, version: $lastVersion');

      // fetch updates from supabase
      print('Fetching nouns from Supabase...');
      final nounsData = await _syncService.fetchNouns(
        since: lastSync,
        lastVersions: lastVersion,
      );

      // get the latest version number
      final latestVersion = await _syncService.getLatestVersion();

      // update local db with new nouns
      int updateCount = 0;
      for (final nounData in nounsData) {
        final hiveNoun = GermanNounHive(
          id: nounData['id'],
          noun: nounData['noun'],
          article: nounData['article'],
          plural: nounData['plural'] ?? '',
          english: nounData['english'] ?? '',
          difficulty: nounData['difficulty'] ?? 1,
          updatedAt: DateTime.parse(nounData['updated_at']),
          version: nounData['version'],
        );

        await _nounsBox.put(hiveNoun.noun, hiveNoun);
        updateCount++;
      }

      // update sync info
      await _syncInfoBox.put('lastSyncTime', DateTime.now());
      await _syncInfoBox.put('lastVersion', latestVersion);

      // refresh available nouns if necessary
      if (updateCount > 0) {
        _refreshAvailableNouns();
      }

      _syncController.add(SyncStatus(
        status: 'sync completed',
        count: updateCount,
        isSuccess: true,
      ));
      print('Sync completed successfully');
    } catch (e) {
      print('error syncing with remote: $e');
      _syncController.add(
        SyncStatus(
          status: 'sync failed',
          error: e.toString(),
        ),
      );
    }
  }

  // schedule periodic sync
  void _scheduleRemoteSync() {
    syncWithRemote();

    Timer.periodic(
      const Duration(days: 30),
      (_) {
        syncWithRemote();
      },
    );
  }

  // manual sync
  Future<void> triggerSync() async {
    await syncWithRemote();
  }

  // reset available nouns pool
  void resetNouns() {
    _refreshAvailableNouns();
  }

  // remove a specific noun from available pool
  void removeUsedNoun(GermanNoun noun) {
    _availableNouns.removeWhere((n) => n.noun == noun.noun);
  }

  // clean up
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncController.close();
  }
}

class SyncStatus {
  final String status;
  final int? count;
  final String? error;
  final bool isSuccess;

  SyncStatus({
    required this.status,
    this.count,
    this.error,
    this.isSuccess = false,
  });
}

// providers
final nounsBoxProvider = Provider<Box<GermanNounHive>>((ref) {
  return Hive.box<GermanNounHive>('german_nouns');
});

final syncInfoBoxProvider = Provider<Box>((ref) {
  return Hive.box('sync_info');
});

final germanNounRepoProvider = Provider<GermanNounRepo>(
  (ref) {
    final nounsBox = ref.watch(nounsBoxProvider);
    final syncInfoBox = ref.watch(syncInfoBoxProvider);
    final syncService = ref.watch(nounSyncServiceProvider);

    final repo = GermanNounRepo(
      nounsBox: nounsBox,
      syncInfoBox: syncInfoBox,
      syncService: syncService,
    );

    repo.initialize();

    ref.onDispose(
      () {
        repo.dispose();
      },
    );

    return repo;
  },
);

final syncStatusProvider = StreamProvider<SyncStatus>(
  (ref) {
    return ref.read(germanNounRepoProvider).syncStatus;
  },
);

final nounReadyProvider = FutureProvider<bool>(
  (ref) async {
    final repo = ref.read(germanNounRepoProvider);
    await repo.ready;
    return true;
  },
);
