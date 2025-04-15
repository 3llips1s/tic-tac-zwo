import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:tic_tac_zwo/features/game/core/data/services/data_initialization_service.dart';

import '../../../online/data/models/german_noun_hive.dart';
import '../models/german_noun.dart';

class GermanNounRepo {
  final Box<GermanNounHive> _nounsBox;
  final DataInitializationService _dataService;

  final _nounsReadyCompleter = Completer<void>();
  Future<void> get ready => _nounsReadyCompleter.future;

  List<GermanNoun> _availableNouns = [];

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
      article: hiveNoun.article,
      noun: hiveNoun.noun,
      english: hiveNoun.english,
      plural: hiveNoun.plural,
    );
  }

  //fetch 9 nouns for a game
  Future<List<GermanNoun>> loadNouns() async {
    await ready;

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
    await ready;

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

  // manual sync
  Future<void> triggerRefresh() async {
    return _dataService.syncWithRemote();
  }

  // reset available nouns pool
  void resetNouns() {
    _refreshAvailableNouns();
  }

  // remove a specific noun from available pool
  void removeUsedNoun(GermanNoun noun) {
    _availableNouns.removeWhere((n) => n.noun == noun.noun);
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
