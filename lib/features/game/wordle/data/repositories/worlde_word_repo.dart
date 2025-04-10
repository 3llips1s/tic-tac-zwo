import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

class WordRepo {
  List<Map<String, String>> _words = [];
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // load json from assets
      final jsonString =
          await rootBundle.loadString('assets/words/fallback_nouns.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      // convert json to word format
      _words = jsonList.map((word) {
        return {
          'word': word['noun'] as String,
          'article': word['article'] as String,
          'english': word['english'] as String,
          'plural': word['plural'] as String,
        };
      }).toList();

      _isInitialized = true;
    } catch (e) {
      print('error loading words: $e');
      _words = _getFallbackWords();
      _isInitialized = true;
    }
  }

  List<Map<String, String>> get fiveLetterWords {
    return _words.where((word) => word['word']!.length == 5).toList();
  }

  // get a random word
  Future<Map<String, String>> getRandomWord() async {
    await initialize();

    var filteredWords = fiveLetterWords;

    if (filteredWords.isEmpty) {
      final fallbackWords = _getFallbackWords();
      filteredWords = fallbackWords;
    }

    if (filteredWords.isEmpty) {
      return {'word': 'BINGO', 'article': 'das', 'english': 'bingo'};
    }

    final random = Random();
    final index = random.nextInt(filteredWords.length);
    return filteredWords[index];
  }

  // check if word is in dictionary
  Future<bool> isValidWord(String word) async {
    await initialize();

    final uppercaseWord = word.toUpperCase();
    return _words.any((entry) => entry['word']!.toUpperCase() == uppercaseWord);
  }

  Future<String?> getWordArticle(String word) async {
    await initialize();

    final uppercaseWord = word.toUpperCase();
    final entry = _words.firstWhere(
      (entry) => entry['word']!.toUpperCase() == uppercaseWord,
    );
    return entry['article'];
  }

  Future<String?> getEnglishTranslation(String word) async {
    await initialize();

    final uppercaseWord = word.toUpperCase();
    final entry = _words.firstWhere(
      (entry) => entry['word']!.toUpperCase() == uppercaseWord,
    );
    return entry['english'];
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
