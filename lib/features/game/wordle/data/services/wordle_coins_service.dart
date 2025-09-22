import 'dart:math' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../models/wordle_coins_model.dart';

class WordleCoinsService {
  static const String _boxName = 'wordle_coins';
  static const String _coinsKey = 'coins_data';

  late final Box _coinsBox;

  Future<void> initialize() async {
    _coinsBox = await Hive.openBox(_boxName);
  }

  WordleCoinsData getCoinsData() {
    try {
      final jsonData = _coinsBox.get(_coinsKey);
      if (jsonData != null) {
        return WordleCoinsData.fromJson(Map<String, dynamic>.from(jsonData));
      }

      return WordleCoinsData(
        totalCoins: 50,
        totalCoinsEarned: 0,
        totalCoinsSpent: 0,
      );
    } catch (e) {
      return WordleCoinsData(
        totalCoins: 50,
        totalCoinsEarned: 0,
        totalCoinsSpent: 0,
      );
    }
  }

  Future<bool> spendCoins(int amount) async {
    try {
      final currentData = getCoinsData();
      if (currentData.totalCoins < amount) {
        return false;
      }

      final newData = currentData.copyWith(
        totalCoins: currentData.totalCoins - amount,
        totalCoinsSpent: currentData.totalCoinsSpent + amount,
      );

      await _coinsBox.put(_coinsKey, newData.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> earnCoins(int amount) async {
    try {
      final currentData = getCoinsData();
      final newData = currentData.copyWith(
        totalCoins: currentData.totalCoins + amount,
        totalCoinsEarned: currentData.totalCoinsEarned + amount,
      );

      await _coinsBox.put(_coinsKey, newData.toJson());
    } catch (e) {
      developer.log(400);
    }
  }

  bool canAfford(int amount) {
    return getCoinsData().totalCoins >= amount;
  }
}

final wordleCoinsServiceProvider = Provider<WordleCoinsService>(
  (ref) {
    final service = WordleCoinsService();
    service.initialize();
    return service;
  },
);
