import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../../../online/data/models/german_noun_hive.dart';
import '../../../online/data/services/noun_sync_service.dart';
import '../models/german_noun.dart';

class DataInitializationService {
  static const String _assetPath = 'assets/words/fallback_nouns.json';
  final Box<GermanNounHive> _nounsBox;
  final Box<dynamic> _syncInfoBox;
  final NounSyncService _syncService;

  final _dataReadyCompleter = Completer<void>();
  Future<void> get ready => _dataReadyCompleter.future;

  bool _isInitializing = false;
  bool _isSyncing = false;
  Timer? _syncTimer;

  // stream controller for sync status updates
  final _syncController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatus => _syncController.stream;

  StreamSubscription? _connectivitySubscription;

  DataInitializationService({
    required Box<GermanNounHive> nounsBox,
    required Box<dynamic> syncInfoBox,
    required NounSyncService syncService,
  })  : _nounsBox = nounsBox,
        _syncInfoBox = syncInfoBox,
        _syncService = syncService;

  Future<void> initialize() async {
    if (_isInitializing) {
      return ready;
    }

    _isInitializing = true;

    try {
      print('starting shared data initialization');

      if (_nounsBox.isEmpty) {
        await _loadFromAssets();
      }

      _scheduleRemoteSync();

      print('data init complete. ${_nounsBox.length} nouns available');

      if (!_dataReadyCompleter.isCompleted) {
        _dataReadyCompleter.complete();
      }
    } catch (e) {
      print('error initializing data: $e');
      if (!_dataReadyCompleter.isCompleted) {
        _dataReadyCompleter.completeError(e);
      }
    }

    _isInitializing = false;
    return ready;
  }

  Future<void> _loadFromAssets() async {
    try {
      final String jsonString = await rootBundle.loadString(_assetPath);
      final List<dynamic> jsonList = json.decode(jsonString);
      final List<GermanNoun> nouns =
          jsonList.map((json) => GermanNoun.fromJson(json)).toList();

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

      _syncController
          .add(SyncStatus(status: 'loaded from assets', count: nouns.length));
    } catch (e) {
      print('Error loading nouns from assets: $e');
      _syncController.add(SyncStatus(
        status: 'Error loading from assets',
        error: e.toString(),
      ));
      rethrow;
    }
  }

  Future<void> syncWithRemote() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      print('starting noun sync with remote');
      _syncController.add(SyncStatus(status: 'syncing...'));

      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        print('sync aborted. no internet connection');
        _syncController.add(SyncStatus(status: 'no internet connection'));
        return;
      }

      // last sync info
      final lastSync = _syncInfoBox.get('lastSyncTime') as DateTime?;
      final lastVersion = _syncInfoBox.get('lastVersion') as int? ?? 0;

      List<Map<String, dynamic>> nounsData;

      if (lastSync == null || _nounsBox.length < 100) {
        print('performing full db sync');
        nounsData = await _syncService.fetchNouns();
      } else {
        print('performing incremental sync since $lastSync');
        nounsData = await _syncService.fetchNouns(
          since: lastSync,
          lastVersions: lastVersion,
        );
      }

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

      _syncController.add(SyncStatus(
        status: 'sync completed',
        count: updateCount,
        isSuccess: true,
      ));
    } catch (e) {
      print('Error syncing with remote: $e');
      _syncController.add(SyncStatus(
        status: 'Sync failed',
        error: e.toString(),
      ));
    } finally {
      _isSyncing = false;
    }
  }

  void _scheduleRemoteSync() {
    _syncTimer = Timer.periodic(
      Duration(days: 1),
      (timer) async {
        final connectivityResult = await Connectivity().checkConnectivity();
        if (!connectivityResult.contains(ConnectivityResult.none)) {
          syncWithRemote();
        }
      },
    );

    syncWithRemote();
  }

  void dispose() {
    _syncTimer?.cancel();
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

final syncInfoProvider = Provider<Box>((ref) {
  return Hive.box('sync_info');
});

final dataInitializationServiceProvider =
    Provider<DataInitializationService>((ref) {
  final nounsBox = ref.watch(nounsBoxProvider);
  final syncInfoBox = ref.watch(syncInfoProvider);
  final syncService = ref.watch(nounSyncServiceProvider);

  final service = DataInitializationService(
    nounsBox: nounsBox,
    syncInfoBox: syncInfoBox,
    syncService: syncService,
  );

  service.initialize();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

final dataReadyProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(dataInitializationServiceProvider);
  await service.ready;
  return true;
});

final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  return ref.watch(dataInitializationServiceProvider).syncStatus;
});
