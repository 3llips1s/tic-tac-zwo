import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GermanNoun {
  final String article;
  final String noun;
  final String english;
  final String plural;

  const GermanNoun({
    required this.article,
    required this.noun,
    required this.english,
    required this.plural,
  });

  factory GermanNoun.fromJson(Map<String, dynamic> json) => GermanNoun(
        article: json['article'] as String,
        noun: json['noun'] as String,
        english: json['english'] as String,
        plural: json['plural'] as String,
      );
}

class NounRepository {
  static const String _assetPath = 'assets/words/testnouns.json';
  List<GermanNoun> _allNouns = [];
  List<GermanNoun> _availableNouns = [];

  Future<List<GermanNoun>> loadNouns() async {
    try {
      // load all nouns just once
      if (_allNouns.isEmpty) {
        final String jsonString = await rootBundle.loadString(_assetPath);
        final List<dynamic> jsonList = json.decode(jsonString);
        _allNouns = jsonList.map((json) => GermanNoun.fromJson(json)).toList();
      }

      // reset available nouns if they're depleted
      if (_availableNouns.isEmpty) {
        _availableNouns = List<GermanNoun>.from(_allNouns)..shuffle();
      }

      // take 9 nouns from available nouns
      final selectedNouns = _availableNouns.take(9).toList();

      // remove from available nouns
      _availableNouns.removeWhere(
        (noun) => selectedNouns.contains(noun),
      );

      return selectedNouns;
    } catch (e) {
      print('Error loading noun: $e');
      return [
        GermanNoun(
          article: 'das',
          noun: 'Fehler',
          english: 'Error',
          plural: 'Fehler',
        )
      ];
    }
  }

  void removeUsedNoun(GermanNoun noun) {
    _availableNouns.removeWhere((n) => n.noun == noun.noun);
  }

  Future<GermanNoun> loadRandomNoun() async {
    final nouns = await loadNouns();
    return nouns[Random().nextInt(nouns.length)];
  }

  void resetNouns() {
    _availableNouns = List<GermanNoun>.from(_allNouns)..shuffle();
  }
}

final nounRepositoryProvider = Provider((ref) => NounRepository());
final nounsProvider = FutureProvider<List<GermanNoun>>((ref) {
  return ref.read(nounRepositoryProvider).loadNouns();
});
final randomNounProvider = FutureProvider<GermanNoun>((ref) {
  return ref.read(nounRepositoryProvider).loadRandomNoun();
});
