import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/features/game/wordle/data/models/guess_model.dart';

import '../../logic/wordle_logic.dart';

enum GameStatus {
  playing,
  won,
  lost,
}

class WordleGameState {
  final String targetWord;
  final List<WordGuess> guesses;
  final GameStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final int maxAttempts;

  WordleGameState({
    required this.targetWord,
    required this.guesses,
    required this.status,
    required this.startTime,
    this.endTime,
    this.maxAttempts = 6,
  });

  WordleGameState copyWith({
    String? targetWord,
    List<WordGuess>? guesses,
    GameStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    int? maxAttempts,
  }) {
    return WordleGameState(
      targetWord: targetWord ?? this.targetWord,
      guesses: guesses ?? this.guesses,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      maxAttempts: maxAttempts ?? this.maxAttempts,
    );
  }

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  bool get isGameOver => status == GameStatus.won || status == GameStatus.lost;
  bool get canGuess => !isGameOver && guesses.length < maxAttempts;
  int get remainingAttempts => maxAttempts - guesses.length;
}

// loading game state
final wordleLoadingProvider = FutureProvider<WordleGameState>((ref) async {
  final gameLogic = ref.watch(wordleLogicProvider);
  return await gameLogic.createNewGame();
});

// state notifier for game state
class WordleGameNotifier extends StateNotifier<WordleGameState?> {
  final WordleLogic _gameLogic;

  WordleGameNotifier(this._gameLogic) : super(null) {
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    state = await _gameLogic.createNewGame();
  }

  Future<void> newGame() async {
    state = await _gameLogic.createNewGame();
  }

  Future<void> makeGuess(String guess) async {
    if (state == null) return;
    state = await _gameLogic.makeGuess(state!, guess);
  }

  Future<bool> checkArticle(String article) async {
    if (state == null) return false;
    return await _gameLogic.checkArticle(state!, article);
  }

  String getWinFeedback() {
    if (state == null) return 'Sehr gut!';
    return _gameLogic.winFeedback(state!);
  }
}

final wordleGameStateProvider =
    StateNotifierProvider<WordleGameNotifier, WordleGameState?>(
  (ref) {
    final gameLogic = ref.watch(wordleLogicProvider);
    return WordleGameNotifier(gameLogic);
  },
);
