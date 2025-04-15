import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:tic_tac_zwo/features/game/core/data/services/data_initialization_service.dart';

import '../../../online/data/models/german_noun_hive.dart';

class WorldeWordRepo {
  final Box<GermanNounHive> _nounsBox;
  final DataInitializationService _dataService;
  List<Map<String, String>> _cachedWords = [];
  bool _isInitialized = false;

  final _wordleWordsReadyCompleter = Completer<void>();
  Future<void> get ready => _wordleWordsReadyCompleter.future;

  WorldeWordRepo({
    required Box<GermanNounHive> nounsBox,
    required DataInitializationService dataService,
  })  : _nounsBox = nounsBox,
        _dataService = dataService;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _dataService.ready;

      await _loadFromLocalDb();
      _isInitialized = true;

      if (!_wordleWordsReadyCompleter.isCompleted) {
        _wordleWordsReadyCompleter.complete();
      }
    } catch (e) {
      print('error loading words: $e');
      _cachedWords = _getFallbackWords();
      _isInitialized = true;

      if (!_wordleWordsReadyCompleter.isCompleted) {
        _wordleWordsReadyCompleter.completeError(e);
      }
    }
  }

  Future<void> _loadFromLocalDb() async {
    // clear cached words
    _cachedWords = [];

    int totalNouns = 0;
    int fiveLetterNouns = 0;

    // convert hive object to wordle word repo
    _nounsBox.values.forEach(
      (hiveNoun) {
        totalNouns++;
        if (hiveNoun.noun.length == 5) {
          fiveLetterNouns++;
          _cachedWords.add({
            'word': hiveNoun.noun,
            'article': hiveNoun.article,
            'english': hiveNoun.english,
            'plural': hiveNoun.plural
          });
        }
      },
    );

    print('Total nouns in box: $totalNouns');
    print('Five letter nouns detected: $fiveLetterNouns');
    print('cached words: ${_cachedWords.length} nouns');

    if (_cachedWords.isEmpty) {
      throw Exception('No words found in local DB');
    }
  }

  Future<void> refreshWords() async {
    _isInitialized = false;
    return initialize();
  }

  // get a random word
  Future<Map<String, String>> getRandomWord() async {
    await initialize();

    if (_cachedWords.isEmpty) {
      _cachedWords = _getFallbackWords();
    }

    final random = Random();
    final index = random.nextInt(_cachedWords.length);
    return _cachedWords[index];
  }

  // check if word is in dictionary
  Future<bool> isValidWord(String word) async {
    await initialize();

    final uppercaseWord = word.toUpperCase();
    return _cachedWords
        .any((entry) => entry['word']!.toUpperCase() == uppercaseWord);
  }

  Future<String?> getWordArticle(String word) async {
    await initialize();

    final uppercaseWord = word.toUpperCase();
    final matchingEntry = _cachedWords.firstWhere(
      (entry) => entry['word']!.toUpperCase() == uppercaseWord,
    );

    if (matchingEntry.isEmpty) {
      return null;
    }

    return matchingEntry['article'];
  }

  Future<String?> getEnglishTranslation(String word) async {
    await initialize();

    final uppercaseWord = word.toUpperCase();
    final matchingEntry = _cachedWords.firstWhere(
      (entry) => entry['word']!.toUpperCase() == uppercaseWord,
    );

    if (matchingEntry.isEmpty) {
      return null;
    }

    return matchingEntry['english'];
  }

  List<Map<String, String>> _getFallbackWords() {
    return [
      {
        'word': 'TASSE',
        'article': 'die',
        'english': 'cup',
        'plural': 'Tassen',
      },
      {
        'word': 'TISCH',
        'article': 'der',
        'english': 'table',
        'plural': 'Tische'
      },
      {
        'word': 'BLATT',
        'article': 'das',
        'english': 'leaf',
        'plural': 'Blätter'
      },
      {
        'word': 'LAMPE',
        'article': 'die',
        'english': 'lamp',
        'plural': 'Lampen'
      },
      {
        'word': 'STUHL',
        'article': 'der',
        'english': 'chair',
        'plural': 'Stühle'
      },
    ];
  }
}

final worldeWordRepoProvider = Provider<WorldeWordRepo>((ref) {
  final nounsBox = ref.watch(nounsBoxProvider);
  final dataService = ref.watch(dataInitializationServiceProvider);

  final repo = WorldeWordRepo(
    nounsBox: nounsBox,
    dataService: dataService,
  );

  repo.initialize();

  return repo;
});

final wordleRepoReadyProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(worldeWordRepoProvider);
  await repo.ready;
  return true;
});
