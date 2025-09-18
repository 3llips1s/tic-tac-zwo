import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/dual_progress_indicator.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/glassmorphic_dialog.dart';
import 'package:tic_tac_zwo/features/game/wordle/data/models/guess_model.dart';
import 'package:tic_tac_zwo/features/game/wordle/ui/widgets/game_result_dialog.dart';
import 'package:tic_tac_zwo/features/game/wordle/ui/widgets/wordle_game_grid.dart';

import '../../../../../config/game_config/constants.dart';
import '../../../../navigation/routes/route_names.dart';
import '../../data/models/wordle_game_state.dart';
import '../../data/repositories/wordle_word_repo.dart';
import '../widgets/wordle_instructions_dialog.dart';
import '../widgets/wordle_keyboard.dart';

class WordleGameScreen extends ConsumerStatefulWidget {
  const WordleGameScreen({super.key});

  @override
  ConsumerState<WordleGameScreen> createState() => _WordleGameScreenState();
}

class _WordleGameScreenState extends ConsumerState<WordleGameScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _guessController = TextEditingController();
  String _currentGuess = '';

  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;

  @override
  void initState() {
    super.initState();
    _initHoverAnimation();

    _checkAndShowInstructions();
  }

  Future<void> _checkAndShowInstructions() async {
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      WordleInstructionsManager.showInstructionsDialog(context);
    }
  }

  void _showGameResultDialog(WordleGameState state) async {
    await Future.delayed(const Duration(milliseconds: 2200));

    if (!mounted) return;

    showCustomDialog(
      context: context,
      barrierDismissible: false,
      width: 300,
      height: 330,
      child: GameResultDialog(
        gameState: state,
        hoverAnimation: _hoverAnimation,
        onHomePressed: () {
          Navigator.pushNamedAndRemoveUntil(
            context,
            RouteNames.home,
            (route) => false,
          );
          ref.read(wordleGameStateProvider.notifier).newGame();
        },
        onPlayAgainPressed: () {
          Navigator.of(context).pop();
          ref.read(wordleGameStateProvider.notifier).newGame();
        },
      ),
    );
  }

  void _handleGuess() async {
    final guess = _currentGuess.trim();
    if (guess.length != 5) {
      _showSnackBar('Muss 5 Buchstaben haben. 🫤');
      return;
    }

    final gameState = ref.read(wordleGameStateProvider);
    if (gameState == null) return;

    // check if word is valid
    final repository = ref.read(wordleWordRepoProvider);
    final isValid = await repository.isValidWord(guess);

    if (!isValid) {
      _showSnackBar('Nicht in meiner Liste. 😔');
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
      _showSnackBar('Geschafft! 🎉');
      _showGameResultDialog(newState);
    } else if (newState.status == GameStatus.lost) {
      _showSnackBar('Schade! ❤️‍🩹');
      _showGameResultDialog(newState);
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
    HapticFeedback.lightImpact();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: EdgeInsets.only(
          bottom: kToolbarHeight * 3.5,
          left: 30,
          right: 30,
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorBlack,
                  ),
            ),
          ),
        ),
      ),
    );
  }

  void _initHoverAnimation() {
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _hoverAnimation = Tween<double>(
      begin: 0,
      end: 5,
    ).animate(
      CurvedAnimation(
        parent: _hoverController,
        curve: Curves.easeInOut,
      ),
    );

    _hoverController.repeat(reverse: true);
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
          child: DualProgressIndicator(),
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
              height: 120,
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

          // grid
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  WordleGameGrid(
                    gameState: gameState,
                    currentGuess: _currentGuess,
                  ),
                ],
              ),
            ),
          ),

          // back home
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 55),
              child: IconButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  RouteNames.home,
                  (route) => false,
                ),
                icon: Icon(
                  Icons.home_rounded,
                  color: colorGrey600,
                  size: 40,
                ),
              ),
            ),
          ),

          SizedBox(height: 30),

          // keyboard
          WordleKeyboard(
            onKeyTap: gameState.canGuess ? _handleKeyPress : null,
            letterStates: _getKeyboardLetterStates(gameState),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _guessController.dispose();
    _hoverController.dispose();
    super.dispose();
  }
}
