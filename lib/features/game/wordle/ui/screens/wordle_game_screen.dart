import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tic_tac_zwo/features/game/core/ui/widgets/dual_progress_indicator.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/glassmorphic_dialog.dart';
import 'package:tic_tac_zwo/features/game/wordle/data/models/guess_model.dart';
import 'package:tic_tac_zwo/features/game/wordle/data/services/wordle_coins_service.dart';
import 'package:tic_tac_zwo/features/game/wordle/logic/wordle_logic.dart';
import 'package:tic_tac_zwo/features/game/wordle/ui/widgets/game_result_dialog.dart';
import 'package:tic_tac_zwo/features/game/wordle/ui/widgets/hint_confirmation_dialog.dart';
import 'package:tic_tac_zwo/features/game/wordle/ui/widgets/wordle_game_grid.dart';

import '../../../../../config/game_config/constants.dart';
import '../../../../navigation/routes/route_names.dart';
import '../../data/models/wordle_game_state.dart';
import '../../data/repositories/wordle_word_repo.dart';
import '../widgets/coin_display.dart';
import '../widgets/hint_button.dart';
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
      child: PopScope(
        canPop: false,
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
      ),
    );
  }

  void _showHintConfirmationDialog() async {
    final gameState = ref.read(wordleGameStateProvider);
    if (gameState == null) return;

    final coinsService = ref.read(wordleCoinsServiceProvider);
    final currentCoins = coinsService.getCoinsData().totalCoins;

    final nextHintNumber = gameState.hintsUsed + 1;

    if (nextHintNumber > gameState.maxHints || !gameState.canGuess) {
      _showSnackBar('Keine weiteren Hinweise verfügbar 🚫');
      return;
    }

    final hintCost = nextHintNumber == 1 ? 30 : 50;

    if (currentCoins < hintCost) {
      _showInsufficientCoinsSnackbar();
      return;
    }

    if (!mounted) return;

    showCustomDialog(
      context: context,
      barrierDismissible: true,
      width: 200,
      height: 250,
      child: HintConfirmationDialog(
        hintNumber: nextHintNumber,
        hintCost: hintCost,
        currentCoins: currentCoins,
        onConfirm: () {
          Navigator.of(context).pop();
          _useHint(nextHintNumber);
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _handleGuess() async {
    final gameState = ref.read(wordleGameStateProvider);
    if (gameState == null) return;

    // build complete word including revealed letters
    String completeGuess = '';
    final currentGuessLetters = _currentGuess.split('');
    int typedLetterIndex = 0;

    for (int i = 0; i < 5; i++) {
      if (gameState.revealedPositions.contains(i)) {
        // use revealed letter
        completeGuess += gameState.targetWord[i];
      } else if (typedLetterIndex < currentGuessLetters.length) {
        // use next typed letter
        completeGuess += currentGuessLetters[typedLetterIndex];
        typedLetterIndex++;
      } else {
        // position not filled
        completeGuess += ' ';
      }
    }

    final guess = completeGuess.trim();
    if (guess.length != 5) {
      _showSnackBar('Muss 5 Buchstaben haben. 🫤');
      return;
    }

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
      _showSnackBar('Bravo! 🥳');
      _showGameResultDialog(newState);
    } else if (newState.status == GameStatus.lost) {
      _showSnackBar('Beim nächsten Mal! 🙃');
      _showGameResultDialog(newState);
    }
  }

  void _handleKeyPress(String letter) {
    final gameState = ref.read(wordleGameStateProvider);
    if (gameState == null) return;

    if (letter == '←') {
      if (_currentGuess.isNotEmpty) {
        setState(() {
          _currentGuess = _currentGuess.substring(0, _currentGuess.length - 1);
        });
      }
    } else if (letter == '✓') {
      _handleGuess();
    } else {
      // calculate non-revealed positions to fill
      final maxTypeableLength = 5 - gameState.revealedPositions.length;

      if (_currentGuess.length < maxTypeableLength) {
        setState(() {
          _currentGuess += letter;
        });
      }
    }
    HapticFeedback.lightImpact();
  }

  void _useHint(int hintNumber) async {
    final success =
        await ref.read(wordleGameStateProvider.notifier).useHint(hintNumber);

    if (!success) {
      _showSnackBar('Fehler beim Verwenden des Hinweises 😕');
    }
  }

  void _showInsufficientCoinsSnackbar() {
    _showSnackBar('Nicht genug Münzen 💰');
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

    // add revealed letters
    for (final position in gameState.revealedPositions) {
      final revealedLetter = gameState.targetWord[position];
      letterStates[revealedLetter] = Colors.green;
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
          )
              .animate(
                delay: 300.ms,
              )
              .scale(
                begin: Offset(0.5, 0.5),
                duration: 1200.ms,
                curve: Curves.easeInOut,
              )
              .fadeIn(
                begin: 0.5,
                duration: 1200.ms,
                curve: Curves.easeInOut,
              ),

          // controls
          Padding(
            padding: const EdgeInsets.only(left: 55, right: 60, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // home
                IconButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    RouteNames.home,
                    (route) => false,
                  ),
                  icon: Icon(
                    Icons.home_rounded,
                    color: colorGrey500,
                    size: 36,
                  ),
                ),

                // coins + hint
                Row(
                  children: [
                    Consumer(
                      builder: (context, ref, child) {
                        final coinsService =
                            ref.watch(wordleCoinsServiceProvider);
                        final currentCoins =
                            coinsService.getCoinsData().totalCoins;

                        return CoinDisplay(
                          coinCount: currentCoins,
                          useContainer: false,
                          svgAssetPath: 'assets/images/coins.svg',
                        );
                      },
                    ),
                    const SizedBox(width: 24),
                    Consumer(
                      builder: (context, ref, child) {
                        final gameState = ref.watch(wordleGameStateProvider);
                        if (gameState == null) return const SizedBox.shrink();

                        final gameLogic = ref.read(wordleLogicProvider);
                        final nextHintNumber = gameState.hintsUsed + 1;

                        // all hint conditions
                        final hasRemainingHints =
                            nextHintNumber <= gameState.maxHints;
                        final canUseHint = gameState.canGuess;
                        final canAfford = hasRemainingHints
                            ? gameLogic.canAffordHint(nextHintNumber)
                            : false;

                        final isActive =
                            hasRemainingHints && canAfford && canUseHint;

                        VoidCallback? inactiveCallback;
                        if (!hasRemainingHints) {
                          inactiveCallback = () => _showSnackBar(
                              'Keine weiteren Hinweise verfügbar 🚫');
                        } else if (!canUseHint) {
                          inactiveCallback =
                              () => _showSnackBar('Spiel ist vorbei 🏁');
                        } else if (!canAfford) {
                          inactiveCallback = _showInsufficientCoinsSnackbar;
                        }

                        return HintButton(
                          isActive: isActive,
                          useContainer: true,
                          onPressed:
                              isActive ? _showHintConfirmationDialog : null,
                          onInsufficientCoins: inactiveCallback,
                        );
                      },
                    ),
                  ],
                )
              ],
            ),
          ),

          SizedBox(height: 30),

          // keyboard
          WordleKeyboard(
            onKeyTap: gameState.canGuess ? _handleKeyPress : null,
            letterStates: _getKeyboardLetterStates(gameState),
          )
              .animate(delay: 1200.ms)
              .slideY(
                begin: 0.3,
                end: 0.0,
                duration: 900.ms,
                curve: Curves.easeInOut,
              )
              .fadeIn(
                duration: 900.ms,
                curve: Curves.easeInOut,
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
