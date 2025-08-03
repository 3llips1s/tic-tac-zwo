import 'dart:developer' as developer;
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

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
      if (_nounsBox.isEmpty) {
        try {
          unawaited(syncWithRemote());

          await Future.any([
            Future.delayed(Duration(seconds: 3)),
            _waitForMinimalData(),
          ]);

          if (_nounsBox.length < 100) {
            await _loadFromAssets();
            await _markFallbackData();
          }
        } catch (e) {
          await _loadFromAssets();
          await _markFallbackData();
        }
      } else {
        _scheduleRemoteSync();
      }

      developer.log('data init complete. ${_nounsBox.length} nouns available',
          name: 'data_init_service');

      if (!_dataReadyCompleter.isCompleted) {
        _dataReadyCompleter.complete();
      }
    } catch (e) {
      developer.log('error initializing data: $e', name: 'data_init_service');
      if (!_dataReadyCompleter.isCompleted) {
        _dataReadyCompleter.completeError(e);
      }
    }

    _isInitializing = false;
    return ready;
  }

  Future<void> _waitForMinimalData() async {
    int attempts = 0;
    while (_nounsBox.length < 100 && _isSyncing && attempts < 30) {
      await Future.delayed(Duration(milliseconds: 100));
      attempts++;
    }
  }

  Future<void> _loadFromAssets() async {
    try {
      final String jsonString = await rootBundle.loadString(_assetPath);

      _syncController.add(SyncStatus(status: 'parsing noun data...'));
      final List<GermanNoun> nouns = await _parseNounsInBackground(jsonString);

      _syncController
          .add(SyncStatus(status: 'loading ${nouns.length} nouns...'));

      await _nounsBox.clear();

      const batchSize = 100;

      for (int i = 0; i < nouns.length; i += batchSize) {
        final batch = nouns.skip(i).take(batchSize);

        for (var noun in batch) {
          final hiveNoun = GermanNounHive(
            id: 'fb_${noun.article}_${noun.noun}',
            noun: noun.noun,
            article: noun.article,
            plural: noun.plural,
            english: noun.english,
            difficulty: 1,
            updatedAt: DateTime.now(),
            version: 0,
          );
          await _nounsBox.put(noun.id, hiveNoun);
        }

        await Future.delayed(Duration.zero);

        _syncController.add(SyncStatus(
          status: 'loaded ${i + batch.length}/${nouns.length} nouns',
          count: i + batch.length,
        ));
      }

      _syncController.add(SyncStatus(
        status: 'loaded from assets',
        count: nouns.length,
        isSuccess: true,
      ));
    } catch (e) {
      developer.log('Error loading nouns from assets: $e',
          name: 'data_init_service');
      _syncController.add(SyncStatus(
        status: 'Error loading from assets',
        error: e.toString(),
      ));
      rethrow;
    }
  }

  Future<List<GermanNoun>> _parseNounsInBackground(String jsonString) async {
    return await Isolate.run(() {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => GermanNoun.fromJson(json)).toList();
    });
  }

  Future<void> syncWithRemote() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      developer.log('starting noun sync with remote',
          name: 'data_init_service');
      _syncController.add(SyncStatus(status: 'syncing...'));

      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        developer.log('sync aborted. no internet connection',
            name: 'data_init_service');
        _syncController.add(SyncStatus(status: 'no internet connection'));
        return;
      }

      // last sync info
      final lastSync = _syncInfoBox.get('lastSyncTime') as DateTime?;
      final lastVersion = _syncInfoBox.get('lastVersion') as int? ?? 0;

      List<Map<String, dynamic>> nounsData;

      if (lastSync == null || _nounsBox.length < 100) {
        developer.log('performing full db sync', name: 'data_init_service');
        nounsData = await _syncService.fetchNouns();
      } else {
        developer.log('performing incremental sync since $lastSync',
            name: 'data_init_service');
        nounsData = await _syncService.fetchNouns(
          since: lastSync,
          lastVersions: lastVersion,
        );
      }

      final latestVersion = await _syncService.getLatestVersion();

      // update local db with new nouns
      int updateCount = 0;
      const batchSize = 100;

      _syncController
          .add(SyncStatus(status: 'processing ${nounsData.length} nouns...'));

      for (int i = 0; i < nounsData.length; i += batchSize) {
        final batch = nounsData.skip(i).take(batchSize);

        for (final nounData in batch) {
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

          await _nounsBox.put(hiveNoun.id, hiveNoun);
          updateCount++;
        }

        await Future.delayed(Duration.zero);

        _syncController.add(SyncStatus(
          status: 'processed $updateCount/${nounsData.length} nouns',
          count: updateCount,
        ));
      }

      developer.log('total fetched: $updateCount nouns',
          name: 'data_init_service');

      // update sync info
      await _syncInfoBox.put('lastSyncTime', DateTime.now());
      await _syncInfoBox.put('lastVersion', latestVersion);

      _syncController.add(SyncStatus(
        status: 'sync completed',
        count: updateCount,
        isSuccess: true,
      ));

      if (updateCount > 0 && _syncInfoBox.get('hasFallbackData') == true) {
        await _cleanUpFallbackDataInBatches();
        await _syncInfoBox.delete('hasFallbackData');
        await _syncInfoBox.delete('fallbackLoadTime');
      }
    } catch (e) {
      developer.log('Error syncing with remote: $e', name: 'data_init_service');
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
      Duration(days: 7),
      (timer) async {
        final connectivityResult = await Connectivity().checkConnectivity();
        if (!connectivityResult.contains(ConnectivityResult.none)) {
          syncWithRemote();
        }
      },
    );

    syncWithRemote();
  }

  Future<void> _markFallbackData() async {
    await _syncInfoBox.put('hasFallbackData', true);
    await _syncInfoBox.put('fallbackLoadTime', DateTime.now());
  }

  Future<void> _cleanUpFallbackDataInBatches() async {
    final fallbackKeys = <dynamic>[];

    const batchSize = 100;
    int processed = 0;

    for (final key in _nounsBox.keys) {
      final noun = _nounsBox.get(key);
      if (noun?.version == 0) {
        fallbackKeys.add(key);
      }

      processed++;
      if (processed % batchSize == 0) {
        await Future.delayed(Duration.zero);
      }
    }

    for (int i = 0; i < fallbackKeys.length; i += batchSize) {
      final batch = fallbackKeys.skip(i).take(batchSize);
      for (final key in batch) {
        await _nounsBox.delete(key);
      }
      await Future.delayed(Duration.zero);
    }
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

class DataInitializationNotifier
    extends AsyncNotifier<DataInitializationService> {
  @override
  Future<DataInitializationService> build() async {
    final nounsBox = ref.watch(nounsBoxProvider);
    final syncInfoBox = ref.watch(syncInfoProvider);
    final syncService = ref.watch(nounSyncServiceProvider);

    final service = DataInitializationService(
      nounsBox: nounsBox,
      syncInfoBox: syncInfoBox,
      syncService: syncService,
    );

    await service.initialize();

    ref.onDispose(
      () {
        service.dispose();
      },
    );

    return service;
  }
}

final dataInitializationServiceProvider = AsyncNotifierProvider<
    DataInitializationNotifier, DataInitializationService>(() {
  return DataInitializationNotifier();
});

final dataReadyProvider = FutureProvider<bool>((ref) async {
  await ref.watch(dataInitializationServiceProvider.future);
  return true;
});

final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  return ref.watch(dataInitializationServiceProvider).when(
        data: (service) => service.syncStatus,
        loading: () => Stream.value(SyncStatus(status: 'initializing...')),
        error: (error, _) => Stream.value(SyncStatus(
          status: 'initialization failed',
          error: error.toString(),
        )),
      );
});

void unawaited(Future<void> future) {
  future.catchError((error) {
    developer.log('background operation failed:$error',
        name: 'data_init_service');
  });
}
