import 'package:tic_tac_zwo/features/game/wordle/data/models/guess_model.dart';
import 'package:tic_tac_zwo/features/game/wordle/data/models/wordle_game_state.dart';
import 'package:tic_tac_zwo/features/game/wordle/data/repositories/word_repo.dart';

class WordleLogic {
  final WordRepo repository;

  WordleLogic({required this.repository});

  // initial game state
  Future<WordleGameState> createNewGame() async {
    final targetWordData = await repository.getRandomWord();
    return WordleGameState(
      targetWord: targetWordData['word']!.toUpperCase(),
      guesses: [],
      status: GameStatus.playing,
      startTime: DateTime.now(),
    );
  }

  // process guess + return update game sync
  Future<WordleGameState> makeGuess(WordleGameState state, String guess) async {
    if (state.isGameOver || !state.canGuess) {
      return state;
    }

    final uppercaseGuess = guess.toUpperCase();

    // validate length
    if (uppercaseGuess.length != state.targetWord.length) {
      return state;
    }

    // valid word in dict.
    final isValid = await repository.isValidWord(uppercaseGuess);
    if (!isValid) {
      return state;
    }

    // check guess against target word
    final matches = checkWord(state.targetWord, uppercaseGuess);
    final newGuess = WordGuess(word: uppercaseGuess, matches: matches);

    // add new guess to list of guesses
    final newGuesses = List<WordGuess>.from(state.guesses)..add(newGuess);

    // win or lose
    GameStatus newStatus = state.status;
    DateTime? newEndTime = state.endTime;

    if (uppercaseGuess == state.targetWord) {
      newStatus = GameStatus.won;
      newEndTime = DateTime.now();
    } else if (newGuesses.length >= state.maxAttempts) {
      newStatus = GameStatus.lost;
      newEndTime = DateTime.now();
    }

    return state.copyWith(
      guesses: newGuesses,
      status: newStatus,
      endTime: newEndTime,
    );
  }

  // ensure word implementation remains the same
  List<LetterMatch> checkWord(String target, String guess) {
    if (target.length != guess.length) {
      throw ArgumentError('target and guess must be the same length');
    }

    final targetChars = target.toUpperCase().split('');
    final guessChars = guess.toUpperCase().split('');
    final results = List<LetterMatch>.filled(guess.length, LetterMatch.absent);

    // count available letters in target word
    final availableLetters = <String, int>{};
    for (final char in targetChars) {
      availableLetters[char] = (availableLetters[char] ?? 0) + 1;
    }

    // first pass: mark correct positions and update available letters
    for (var i = 0; i < guess.length; i++) {
      if (guessChars[i] == targetChars[i]) {
        results[i] = LetterMatch.correct;
        availableLetters[guessChars[i]] = availableLetters[guessChars[i]]! - 1;
      }
    }

    // second pass: mark present letters based on remaining available letter
    for (var i = 0; i < guess.length; i++) {
      // skip correct positions
      if (results[i] == LetterMatch.correct) continue;

      final letter = guessChars[i];
      if (availableLetters.containsKey(letter) &&
          availableLetters[letter]! > 0) {
        results[i] = LetterMatch.present;
        availableLetters[letter] = availableLetters[letter]! - 1;
      }
    }

    return results;
  }

  // solution feedback
  String winFeedback(WordleGameState state) {
    final attempts = state.guesses.length;

    if (attempts == 1) {
      return 'Du bist ein Wortgenie! 🤓';
    } else if (attempts == 2) {
      return 'Das war der Hammer! 😎';
    } else if (attempts == 3) {
      return 'Sehr gut gemacht! 👏';
    } else if (attempts == 4) {
      return 'Gut gemacht! 👏';
    } else {
      return 'Das war knapp! 😮‍💨';
    }
  }

  // check article
  Future<bool> checkArticle(
      WordleGameState state, String selectedArticle) async {
    final correctArticle = await repository.getWordArticle(state.targetWord);
    return selectedArticle == correctArticle;
  }
}
