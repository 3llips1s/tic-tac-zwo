import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/features/game/wordle/data/models/guess_model.dart';
import 'package:tic_tac_zwo/features/game/wordle/logic/wordle_providers.dart';

import '../../../../../config/constants.dart';
import '../../data/models/wordle_game_state.dart';
import '../widgets/wordle_keyboard.dart';

class WordleGameScreen extends ConsumerStatefulWidget {
  const WordleGameScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WordleGameScreen> createState() => _WordleGameScreenState();
}

class _WordleGameScreenState extends ConsumerState<WordleGameScreen> {
  final TextEditingController _guessController = TextEditingController();
  String _currentGuess = '';

  @override
  void dispose() {
    _guessController.dispose();
    super.dispose();
  }

  void _handleGuess() async {
    final guess = _currentGuess.trim();
    if (guess.length != 5) {
      _showSnackBar('Das Wort muss 5 Buchstaben haben.');
      return;
    }

    final gameState = ref.read(wordleGameStateProvider);
    if (gameState == null) return;

    // check if word is valid
    final repository = ref.read(wordRepoProvider);
    final isValid = await repository.isValidWord(guess);

    if (!isValid) {
      _showSnackBar('Dieses Wort ist nicht in meiner Liste.');
      return;
    }

    // make the guess
    await ref.read(wordleGameStateProvider.notifier).makeGuess(guess);
    setState(() {
      _currentGuess = '';
    });

    // check if game is over after guess
    final newState = ref.read(wordleGameStateProvider);
    if (newState == null) return;

    if (newState.status == GameStatus.won) {
      _showWinSnackBar(newState);
    } else if (newState.status == GameStatus.lost) {
      _showLoseSnackBar(newState);
    }
  }

  void _handleKeyPress(String letter) {
    if (letter == '←') {
      if (_currentGuess.isNotEmpty) {
        setState(() {
          _currentGuess = _currentGuess.substring(0, _currentGuess.length - 1);
        });
      }
    } else if (letter == '↵') {
      _handleGuess();
    } else if (_currentGuess.length < 5) {
      setState(() {
        _currentGuess += letter;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: EdgeInsets.only(
          bottom: kToolbarHeight * 2,
          left: 40,
          right: 40,
        ),
        content: Container(
          padding: EdgeInsets.all(12),
          height: kToolbarHeight,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.all(Radius.circular(9)),
            boxShadow: [
              BoxShadow(
                color: colorGrey300,
                blurRadius: 7,
                offset: Offset(7, 7),
              ),
            ],
          ),
          child: Center(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorWhite,
                  ),
            ),
          ),
        ),
      ),
    );
  }

  void _showWinSnackBar(WordleGameState state) {
    final feedback =
        ref.read(wordleGameStateProvider.notifier).getWinFeedback();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(feedback),
            const SizedBox(height: 8),
            Text('Richtige Artikel für ${state.targetWord}?'),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _checkArticle('der'),
                  child: const Text('der'),
                ),
                ElevatedButton(
                  onPressed: () => _checkArticle('die'),
                  child: const Text('die'),
                ),
                ElevatedButton(
                  onPressed: () => _checkArticle('das'),
                  child: const Text('das'),
                ),
              ],
            )
          ],
        ),
        duration: const Duration(seconds: 9),
      ),
    );
  }

  void _showLoseSnackBar(WordleGameState state) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Schade! Das Wort war: ${state.targetWord}'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _checkArticle(String article) async {
    final isCorrect =
        ref.read(wordleGameStateProvider.notifier).checkArticle(article);
    final gameState = ref.read(wordleGameStateProvider);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            await isCorrect ? 'Richtig!' : 'Falsch! Versuche es noch einmal.'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(wordleGameStateProvider);

    if (gameState == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorBlack,
      body: Column(
        children: [
          // game mode title
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: SizedBox(
              height: kToolbarHeight * 2,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'wördle',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
          ),

          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildGameGrid(gameState),
                  const SizedBox(height: 16),
                  _buildGameInfo(gameState),
                ],
              ),
            ),
          ),
          WordleKeyboard(
            onKeyTap: gameState.canGuess ? _handleKeyPress : null,
            letterStates: _getKeyboardLetterStates(gameState),
          ),
        ],
      ),
    );
  }

  Widget _buildGameGrid(WordleGameState gameState) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // previous guesses
          ...gameState.guesses
              .map((guess) => _buildGuessRow(guess.word, guess.matches)),

          // display current guess
          if (gameState.canGuess) _buildCurrentGuessRow(),

          // empty rows for remaining attempts
          ...List.generate(
            gameState.remainingAttempts - (gameState.canGuess ? 1 : 0),
            (_) => _buildEmptyRow(),
          )
        ],
      ),
    );
  }

  Widget _buildCurrentGuessRow() {
    final letters = _currentGuess.padRight(5, ' ').split('');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (index) => Container(
          width: 50,
          height: 50,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              letters[index],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (_) => Container(
          width: 50,
          height: 50,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildGuessRow(String word, List<LetterMatch> matches) {
    final letters = word.split('');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (index) => TweenAnimationBuilder(
          duration: Duration(milliseconds: 500),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, double value, child) {
            // rotate 0 - 90 for first half of animation
            // rotate from 270 - 360 for the second half
            final rotation =
                value < 0.5 ? value * pi : pi + (value - 0.05) * pi;

            return Transform(
              transform: Matrix4.rotationX(rotation),
              alignment: Alignment.center,
              child: Container(
                width: 50,
                height: 50,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  // show grey until halfway, then show actual color
                  color: value < 0.5
                      ? Colors.grey
                      : _getColorForMatch(matches[index]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Transform(
                    // flip text so it's not mirror shaped
                    transform: Matrix4.rotationX(value < 0.5 ? 0 : pi),
                    alignment: Alignment.center,
                    child: Text(
                      letters[index],
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: value < 0.5 ? colorBlack : colorWhite,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getColorForMatch(LetterMatch match) {
    switch (match) {
      case LetterMatch.correct:
        return Colors.green;
      case LetterMatch.present:
        return colorYellow;
      case LetterMatch.absent:
        return Colors.grey;
    }
  }

  Widget _buildGameInfo(WordleGameState gameState) {
    final status = gameState.status;
    final attempts = gameState.guesses.length;
    final remaining = gameState.remainingAttempts;

    return Column(
      children: [
        Text(
          status == GameStatus.playing
              ? 'Versuch übrig: $remaining'
              : status == GameStatus.won
                  ? 'Gewonnen in $attempts Versuchen!'
                  : 'Verloren. Das Wort war: ${gameState.targetWord}',
          style: const TextStyle(fontSize: 18),
        )
      ],
    );
  }

  Map<String, Color> _getKeyboardLetterStates(WordleGameState gameState) {
    final letterStates = <String, Color>{};

    // process all guesses to determine keyboard colors
    for (final guess in gameState.guesses) {
      final word = guess.word;
      final matches = guess.matches;

      for (int i = 0; i < word.length; i++) {
        final letter = word[i];
        final match = matches[i];

        // only update if new state is better than current one
        if (!letterStates.containsKey(letter) ||
            (_getMatchPriority(match) >
                _getColorPriority(letterStates[letter]!))) {
          letterStates[letter] = _getColorForMatch(match);
        }
      }
    }

    return letterStates;
  }

  int _getMatchPriority(LetterMatch match) {
    switch (match) {
      case LetterMatch.correct:
        return 2;
      case LetterMatch.present:
        return 1;
      case LetterMatch.absent:
        return 0;
    }
  }

  int _getColorPriority(Color color) {
    if (color == Colors.green) return 2;
    if (color == colorYellow) return 1;
    return 0;
  }
}
