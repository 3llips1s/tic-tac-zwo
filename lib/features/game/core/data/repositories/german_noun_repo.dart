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
  final DataInitializationService _dataService;

  final _nounsReadyCompleter = Completer<void>();
  Future<void> get ready => _nounsReadyCompleter.future;

  // main pool of available nouns
  List<GermanNoun> _availableNouns = [];

  // nouns used in current session
  final Set<String> _globallyUsedNouns = {};

  // nouns used in the current game
  final Set<String> _currentGameUsedNouns = {};

  GermanNounRepo({
    required Box<GermanNounHive> nounsBox,
    required DataInitializationService dataService,
  })  : _nounsBox = nounsBox,
        _dataService = dataService;

  // initialize the repo - loads from local db or fallback nouns
  Future<void> initialize() async {
    try {
      await _dataService.ready;

      _refreshAvailableNouns();

      if (!_nounsReadyCompleter.isCompleted) {
        _nounsReadyCompleter.complete();
      }
    } catch (e) {
      print('error initializing german noun repo:$e');
      if (!_nounsReadyCompleter.isCompleted) {
        _nounsReadyCompleter.completeError(e);
      }
    }
  }

  // refresh available nouns from local db
  void _refreshAvailableNouns() {
    final allNouns = _nounsBox.values
        .map((hiveNoun) => _hiveNounToGermanNoun(hiveNoun))
        .toList();
    _availableNouns = List<GermanNoun>.from(allNouns)..shuffle();
    print(
        'German noun repo: refreshed ${_availableNouns.length} available nouns');
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

  // fetch a batch of nouns for a new game
  Future<List<GermanNoun>> getGameBatch({int batchSize = 18}) async {
    await ready;

    // refresh pool if running low on nouns
    if (_availableNouns.isEmpty ||
        _availableNouns.length < batchSize + _globallyUsedNouns.length) {
      _refreshAvailableNouns();
      _globallyUsedNouns.clear();
    }

    // filter out globally used nouns
    final unusedNouns = _availableNouns
        .where((noun) => !_globallyUsedNouns.contains(noun.noun))
        .toList();

    // if we still have enough unique nouns
    if (unusedNouns.length >= batchSize) {
      unusedNouns.shuffle();
      return unusedNouns.take(batchSize).toList();
    } else {
      // reset tracking and use any available if running low
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
      _globallyUsedNouns.clear();
    }

    // get an unused noun
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
      print('error fetching noun by id: $e');
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
    final dataService = ref.watch(dataInitializationServiceProvider);

    final repo = GermanNounRepo(
      nounsBox: nounsBox,
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
