import 'package:flutter/material.dart';
import 'package:tic_tac_zwo/features/game/wordle/data/models/guess_model.dart';
import 'package:tic_tac_zwo/features/game/wordle/ui/widgets/letter_tile.dart';

import '../../data/models/wordle_game_state.dart';

class WordleGameGrid extends StatelessWidget {
  final WordleGameState gameState;
  final String currentGuess;

  const WordleGameGrid({
    super.key,
    required this.gameState,
    this.currentGuess = '',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // previous guesses
          ...List.generate(
            gameState.guesses.length,
            (index) {
              final guess = gameState.guesses[index];
              return _buildGuessRow(guess.word, guess.matches);
            },
          ),

          // current guess
          if (gameState.canGuess) _buildCurrentGuessRow(),

          // empty rows for remaining attempts
          ...List.generate(
            gameState.remainingAttempts - (gameState.canGuess ? 1 : 0),
            (_) => _buildEmptyRow(),
          ),
        ],
      ),
    );
  }

  Widget _buildGuessRow(String word, List<LetterMatch> matches) {
    final letters = word.split('');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (index) => LetterTile(
          letter: letters[index],
          match: matches[index],
          animationDelay: Duration(milliseconds: 200 * index),
        ),
      ),
    );
  }

  Widget _buildCurrentGuessRow() {
    final currentGuessLetters = currentGuess.split('');
    int typedLetterIndex = 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final isRevealed = gameState.revealedPositions.contains(index);
        String displayLetter = '';

        // Debug logging (remove after testing)
        if (isRevealed) {
          print('Target word: "${gameState.targetWord}"');
          print('Target word length: ${gameState.targetWord.length}');
          print('Revealing position $index');
          print(
              'Character at position $index: "${gameState.targetWord[index]}"');
          print('Character code: ${gameState.targetWord.codeUnitAt(index)}');

          displayLetter = gameState.targetWord[index];
        } else {
          // use next available typed letter
          if (typedLetterIndex < currentGuessLetters.length) {
            displayLetter = currentGuessLetters[typedLetterIndex];
            typedLetterIndex++;
          } else {
            displayLetter = ' ';
          }
        }

        return LetterTile(
          letter: displayLetter,
          isCurrentGuess: !isRevealed,
          isEmpty: displayLetter == ' ' && !isRevealed,
          isRevealed: isRevealed,
        );
      }),
    );
  }

  Widget _buildEmptyRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (_) => const LetterTile(
          isEmpty: true,
        ),
      ),
    );
  }
}
