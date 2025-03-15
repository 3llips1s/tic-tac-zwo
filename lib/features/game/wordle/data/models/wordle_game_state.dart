import 'package:tic_tac_zwo/features/game/wordle/data/models/guess_model.dart';

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
