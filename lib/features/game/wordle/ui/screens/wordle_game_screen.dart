import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/glassmorphic_dialog.dart';
import 'package:tic_tac_zwo/features/game/wordle/data/models/guess_model.dart';
import 'package:tic_tac_zwo/features/game/wordle/logic/wordle_providers.dart';
import 'package:tic_tac_zwo/features/game/wordle/ui/widgets/wordle_game_grid.dart';

import '../../../../../config/constants.dart';
import '../../../../../routes/route_names.dart';
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
      _showSnackBar('Das Wort muss 5 Buchstaben haben. 🫤');
      return;
    }

    final gameState = ref.read(wordleGameStateProvider);
    if (gameState == null) return;

    // check if word is valid
    final repository = ref.read(wordRepoProvider);
    final isValid = await repository.isValidWord(guess);

    if (!isValid) {
      _showSnackBar('Dieses Wort ist nicht in meiner Liste. 😔');
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
      _showWinDialog(newState);
    } else if (newState.status == GameStatus.lost) {
      _showLoseDialog(newState);
    }
  }

  void _handleKeyPress(String letter) {
    if (letter == '←') {
      if (_currentGuess.isNotEmpty) {
        setState(() {
          _currentGuess = _currentGuess.substring(0, _currentGuess.length - 1);
        });
      }
    } else if (letter == '✓') {
      _handleGuess();
    } else if (_currentGuess.length < 5) {
      setState(() {
        _currentGuess += letter;
      });
    }
    HapticFeedback.mediumImpact();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        margin: EdgeInsets.only(
          bottom: kToolbarHeight * 3.5,
          left: 10,
          right: 10,
        ),
        content: Container(
          padding: EdgeInsets.all(12),
          height: kToolbarHeight,
          decoration: BoxDecoration(
            color: colorWhite,
            borderRadius: BorderRadius.all(Radius.circular(9)),
          ),
          child: Center(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorBlack,
                  ),
            ),
          ),
        ),
      ),
    );
  }

  void _showWinDialog(WordleGameState state) {
    final feedback =
        ref.read(wordleGameStateProvider.notifier).getWinFeedback();

    showCustomDialog(
      context: context,
      barrierDismissible: false,
      width: MediaQuery.of(context).size.width * 0.8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            feedback,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorBlack,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Artikel für ${state.targetWord}?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorBlack,
                ),
            textAlign: TextAlign.center,
          )
        ],
      ),
      actions: [
        GlassMorphicButton(
          onPressed: () => _checkArticleAndStartNewGame('der'),
          child: Text(
            'der',
            style: TextStyle(color: colorBlack),
          ),
        ),
        GlassMorphicButton(
          onPressed: () => _checkArticleAndStartNewGame('die'),
          child: Text(
            'die',
            style: TextStyle(color: colorBlack),
          ),
        ),
        GlassMorphicButton(
          onPressed: () => _checkArticleAndStartNewGame('das'),
          child: Text(
            'das',
            style: TextStyle(color: colorBlack),
          ),
        ),
      ],
    );
  }

  void _showLoseDialog(WordleGameState state) {
    showCustomDialog(
        context: context,
        barrierDismissible: false,
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Das Wort war: ${state.targetWord}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 22,
                    color: colorBlack,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              ' Artikel für ${state.targetWord}?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorBlack,
                  ),
              textAlign: TextAlign.center,
            )
          ],
        ),
        actions: [
          GlassMorphicButton(
            onPressed: () => _checkArticleAndStartNewGame('der'),
            child: Text(
              'der',
              style: TextStyle(color: colorBlack),
            ),
          ),
          GlassMorphicButton(
            onPressed: () => _checkArticleAndStartNewGame('die'),
            child: Text(
              'die',
              style: TextStyle(color: colorBlack),
            ),
          ),
          GlassMorphicButton(
            onPressed: () => _checkArticleAndStartNewGame('das'),
            child: Text(
              'das',
              style: TextStyle(color: colorBlack),
            ),
          ),
        ]);
  }

  void _checkArticleAndStartNewGame(String article) async {
    final isCorrect =
        ref.read(wordleGameStateProvider.notifier).checkArticle(article);
    final gameState = ref.read(wordleGameStateProvider);

    // close current dialog
    Navigator.of(context).pop();

    // result dialog
    showCustomDialog(
      context: context,
      barrierDismissible: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            await isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: await isCorrect ? Colors.green : Colors.red,
            size: 50,
          ),
          const SizedBox(height: 16),
          Text(
            await isCorrect
                ? '$article ${gameState?.targetWord} 🥳'
                : 'fetch correct article',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 18,
                  color: colorBlack,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        GlassMorphicButton(
          onPressed: () {
            Navigator.of(context).pop();
            ref.read(wordleGameStateProvider.notifier).newGame();
          },
          child: Icon(
            Icons.refresh_rounded,
            color: Colors.green,
          ),
        ),
        GlassMorphicButton(
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              RouteNames.home,
              (route) => false,
            );
          },
          child: Icon(
            Icons.home_rounded,
            color: colorBlack,
          ),
        ),
      ],
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
            padding: const EdgeInsets.only(top: 20),
            child: SizedBox(
              height: kToolbarHeight * 2,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'wördle',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorWhite),
                ),
              ),
            ),
          ),

          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  WordleGameGrid(
                    gameState: gameState,
                    currentGuess: _currentGuess,
                  ),
                  const SizedBox(height: kToolbarHeight * 2),
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
}
