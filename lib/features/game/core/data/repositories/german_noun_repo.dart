import 'dart:developer' as developer;

import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tic_tac_zwo/features/game/core/data/services/data_initialization_service.dart';

import '../../../online/data/models/german_noun_hive.dart';
import '../models/german_noun.dart';

class GermanNounRepo {
  final Box<GermanNounHive> _nounsBox;
  final Box<String> _seenNounsBox;
  final DataInitializationService _dataService;

  final _nounsReadyCompleter = Completer<void>();
  Future<void> get ready => _nounsReadyCompleter.future;

  // main pool of available nouns
  List<GermanNoun> _availableNouns = [];

  // nouns used in current session
  final Set<String> _globallyUsedNouns = {};

  // track seen noun IDs
  Set<String> _seenNounIds = {};

  // nouns used in the current game
  final Set<String> _currentGameUsedNouns = {};

  GermanNounRepo({
    required Box<GermanNounHive> nounsBox,
    required Box<String> seenNounsBox,
    required DataInitializationService dataService,
  })  : _nounsBox = nounsBox,
        _seenNounsBox = seenNounsBox,
        _dataService = dataService;

  // initialize the repo - loads from local db or fallback nouns
  Future<void> initialize() async {
    try {
      await _dataService.ready;

      await _loadSeenNounIds();

      developer.log(
          'German noun repo initialized: ${_availableNouns.length} total nouns, ${_seenNounIds.length} seen nouns',
          name: 'german_noun_repo');

      _refreshAvailableNouns();

      if (!_nounsReadyCompleter.isCompleted) {
        _nounsReadyCompleter.complete();
      }
    } catch (e) {
      developer.log('error initializing german noun repo:$e',
          name: 'german_noun_repo');
      if (!_nounsReadyCompleter.isCompleted) {
        _nounsReadyCompleter.completeError(e);
      }
    }
  }

  // load seen noun id into memory for fast lookup
  Future<void> _loadSeenNounIds() async {
    try {
      _seenNounIds = _seenNounsBox.values.toSet();
      developer.log('Loaded ${_seenNounIds.length} seen noun IDs from storage',
          name: 'german_noun_repo');
    } catch (e) {
      developer.log('Error loading seen noun IDs: $e',
          name: 'german_noun_repo');
      _seenNounIds = <String>{};
    }
  }

  // refresh available nouns from local db
  void _refreshAvailableNouns() {
    final allNouns = _nounsBox.values
        .map((hiveNoun) => _hiveNounToGermanNoun(hiveNoun))
        .toList();
    _availableNouns = List<GermanNoun>.from(allNouns)..shuffle();
    developer.log(
        'German noun repo: refreshed ${_availableNouns.length} available nouns',
        name: 'german_noun_repo');
  }

  // convert hive noun to german noun
  GermanNoun _hiveNounToGermanNoun(GermanNounHive hiveNoun) {
    return GermanNoun(
      id: hiveNoun.id,
      article: hiveNoun.article,
      noun: hiveNoun.noun,
      english: hiveNoun.english,
      plural: hiveNoun.plural,
    );
  }

  // mark noun as seen (permanently)
  Future<void> markNounAsSeen(String nounId) async {
    if (_seenNounIds.contains(nounId)) return;

    _seenNounIds.add(nounId);

    try {
      await _seenNounsBox.add(nounId);
      developer.log('marked noun as seen: $nounId', name: 'german_noun_repo');

      await _checkAndResetIfAllNounsSeen();
    } catch (e) {
      developer.log('error marking noun as seen: $e', name: 'german_noun_repo');
      _seenNounIds.remove(nounId);
    }
  }

  // check if all nouns = seen + reset
  Future<void> _checkAndResetIfAllNounsSeen() async {
    final totalNouns = _availableNouns.length;
    final seenNouns = _seenNounIds.length;

    if (seenNouns >= totalNouns && totalNouns > 0) {
      developer
          .log('all $totalNouns nouns see. resetting seen nouns tracking.');

      await _resetSeenNouns();
    }
  }

  // reset all seen nouns tracking
  Future<void> _resetSeenNouns() async {
    try {
      _seenNounIds.clear();
      await _seenNounsBox.clear();
      developer.log('successfully reset all seen nouns');
    } catch (e) {
      developer.log('error resetting seen nouns:$e');
    }
  }

  // fetch unseen nouns only
  List<GermanNoun> _getUnseenNouns() {
    return _availableNouns
        .where((noun) => !_seenNounIds.contains(noun.id))
        .toList();
  }

  // fetch a batch of nouns for a new game
  Future<List<GermanNoun>> getGameBatch({int batchSize = 18}) async {
    await ready;

    // refresh pool if running low on nouns
    if (_availableNouns.isEmpty) {
      _refreshAvailableNouns();
    }

    final unseenNouns = _getUnseenNouns();

    // filter out globally used nouns from unseen nouns
    final availableUnseenNouns = unseenNouns
        .where((noun) => !_globallyUsedNouns.contains(noun.noun))
        .toList();

    if (availableUnseenNouns.length >= batchSize) {
      availableUnseenNouns.shuffle();
      return availableUnseenNouns.take(batchSize).toList();
    }

    // fall back to seen nouns if not enough unseen
    final allUnusedNouns = _availableNouns
        .where((noun) => !_globallyUsedNouns.contains(noun.noun))
        .toList();

    if (allUnusedNouns.length >= batchSize) {
      allUnusedNouns.shuffle();
      return allUnusedNouns.take(batchSize).toList();
    } else {
      // reset tracking and use any available
      _globallyUsedNouns.clear();
      _availableNouns.shuffle();
      return _availableNouns.take(batchSize).toList();
    }
  }

  // mark noun as used in current game
  void markNounAsUsedInCurrentGame(GermanNoun noun) {
    _currentGameUsedNouns.add(noun.noun);
  }

  // mark noun as globally used == remove from available pool
  void markNounAsGloballyUsed(GermanNoun noun) {
    _globallyUsedNouns.add(noun.noun);
  }

  // handle noun transition for new game
  void resetNounsForNewGame() {
    for (final noun in _currentGameUsedNouns) {
      _globallyUsedNouns.add(noun);
    }
    _currentGameUsedNouns.clear();
  }

  Future<GermanNoun> loadRandomNoun() async {
    await ready;

    if (_availableNouns.isEmpty) {
      _refreshAvailableNouns();
    }

    // first attempt to fetch unseen noun
    final unseenNouns = _getUnseenNouns();
    final availableUnseenNouns = unseenNouns
        .where((noun) => !_globallyUsedNouns.contains(noun.noun))
        .toList();

    if (availableUnseenNouns.isNotEmpty) {
      return availableUnseenNouns[
          Random().nextInt(availableUnseenNouns.length)];
    }

    // fall back to any unused noun
    final unusedNouns = _availableNouns
        .where((noun) => !_globallyUsedNouns.contains(noun.noun))
        .toList();

    if (unusedNouns.isNotEmpty) {
      return unusedNouns[Random().nextInt(unusedNouns.length)];
    } else if (_availableNouns.isNotEmpty) {
      // if all are used, pick a random one
      return _availableNouns[Random().nextInt(_availableNouns.length)];
    } else {
      return GermanNoun(
        id: '',
        article: 'das',
        noun: 'Fehler',
        english: 'Error',
        plural: 'Fehler',
      );
    }
  }

  Future<GermanNoun?> getNounById(String id) async {
    try {
      final Box<GermanNounHive> nounsBox =
          Hive.box<GermanNounHive>('german_nouns');

      GermanNounHive? hiveNoun = nounsBox.get(id);

      if (hiveNoun != null) {
        return hiveNoun.toGermanNoun();
      }

      // fetch from sb if not found locally
      final supabase = Supabase.instance.client;
      final response =
          await supabase.from('german_nouns').select().eq('id', id).single();

      if (response.isEmpty) return null;

      final fetchedNoun = GermanNounHive(
        id: response['id'],
        noun: response['noun'],
        article: response['article'],
        plural: response['plural'] ?? '',
        english: response['english'] ?? '',
        difficulty: response['difficulty'] ?? 1,
        updatedAt: DateTime.parse(response['updated_at']),
        version: response['version'],
      );

      await nounsBox.put(fetchedNoun.id, fetchedNoun);

      return fetchedNoun.toGermanNoun();
    } catch (e) {
      developer.log('error fetching noun by id: $e', name: 'german_noun_repo');
      return null;
    }
  }

  void resetAllNounTracking() {
    _globallyUsedNouns.clear();
    _currentGameUsedNouns.clear();
  }

  // reset available nouns pool
  void resetNouns() {
    _refreshAvailableNouns();
    resetAllNounTracking();
  }

  // manual sync
  Future<void> triggerRefresh() async {
    return _dataService.syncWithRemote();
  }

  Future<void> resetSeenNounsManually() async {
    await _resetSeenNouns();
  }

  int get seenNounsCount => _seenNounIds.length;
  int get totalNounsCount => _availableNouns.length;
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

final germanNounRepoProvider = Provider<GermanNounRepo>(
  (ref) {
    final nounsBox = ref.watch(nounsBoxProvider);
    final seenNounsBox = ref.watch(seenNounsBoxProvider);
    final dataServiceAsync = ref.watch(dataInitializationServiceProvider);
    final dataService = dataServiceAsync.requireValue;

    final repo = GermanNounRepo(
      nounsBox: nounsBox,
      seenNounsBox: seenNounsBox,
      dataService: dataService,
    );

    repo.initialize();

    return repo;
  },
);

final nounReadyProvider = FutureProvider<bool>(
  (ref) async {
    final repo = ref.read(germanNounRepoProvider);
    await repo.ready;
    return true;
  },
);
