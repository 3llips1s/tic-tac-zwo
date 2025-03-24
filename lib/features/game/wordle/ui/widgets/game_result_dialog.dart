import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/features/game/wordle/logic/wordle_providers.dart';

import '../../../../../config/game_config/constants.dart';
import '../../../../../routes/route_names.dart';
import '../../../core/ui/widgets/glassmorphic_dialog.dart';
import '../../data/models/wordle_game_state.dart';

class GameResultDialog extends ConsumerStatefulWidget {
  final WordleGameState gameState;
  final Animation<double> hoverAnimation;

  final VoidCallback onHomePressed;
  final VoidCallback onPlayAgainPressed;

  const GameResultDialog({
    super.key,
    required this.gameState,
    required this.hoverAnimation,
    required this.onHomePressed,
    required this.onPlayAgainPressed,
  });

  @override
  ConsumerState<GameResultDialog> createState() => _GameResultDialogState();
}

class _GameResultDialogState extends ConsumerState<GameResultDialog> {
  bool _showingArticleResult = false;
  bool _isLoading = true;
  String _selectedArticle = '';
  bool _isCorrect = false;
  String _correctArticle = '';
  String _englishTranslation = '';

  void _onArticleSelected(String article) async {
    setState(() {
      _selectedArticle = article;
      _isLoading = true;
      _showingArticleResult = true;
    });

    // fetch necessary futures
    final isCorrectFuture =
        ref.read(wordleGameStateProvider.notifier).checkArticle(article);
    final correctArticleFuture =
        ref.read(wordRepoProvider).getWordArticle(widget.gameState.targetWord);
    final englishTranslationFuture = ref
        .read(wordRepoProvider)
        .getEnglishTranslation(widget.gameState.targetWord);

    final results = await Future.wait([
      isCorrectFuture,
      correctArticleFuture,
      englishTranslationFuture,
    ]);

    if (mounted) {
      setState(() {
        _isCorrect = results[0] as bool;
        _correctArticle = results[1] as String;
        _englishTranslation = results[2] as String;
        _isLoading = false;
      });
    }
  }

  Widget _buildInitialContent() {
    final isWon = widget.gameState.status == GameStatus.won;
    final targetWord = widget.gameState.targetWord;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // game result message
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: AnimatedBuilder(
            animation: widget.hoverAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, widget.hoverAnimation.value),
                child: isWon
                    ? Text(
                        ref
                            .read(wordleGameStateProvider.notifier)
                            .getWinFeedback(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: colorBlack,
                            ),
                        textAlign: TextAlign.center,
                      )
                    : RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 16,
                                    color: colorBlack,
                                  ),
                          children: [
                            TextSpan(text: 'Das Wort war: '),
                            TextSpan(
                              text: '$targetWord  😔',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontSize: 24,
                                    color: colorBlack,
                                  ),
                            ),
                          ],
                        ),
                      ),
              );
            },
          ),
        ),

        const SizedBox(height: kToolbarHeight * 1.5),

        // target word display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                'Artikel für?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorBlack,
                      fontSize: 18,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            Row(
              children: List.generate(
                targetWord.length,
                (index) => Container(
                  height: 28,
                  width: 28,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Center(
                    child: Text(
                      targetWord[index],
                      style: const TextStyle(
                        color: colorWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),

        const SizedBox(height: kToolbarHeight / 1.5),

        // article selection buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GlassMorphicButton(
              onPressed: () => _onArticleSelected('der'),
              child: const Text(
                'der',
                style: TextStyle(
                  fontSize: 20,
                  color: colorBlack,
                ),
              ),
            ),
            GlassMorphicButton(
              onPressed: () => _onArticleSelected('die'),
              child: const Text(
                'die',
                style: TextStyle(
                  fontSize: 20,
                  color: colorBlack,
                ),
              ),
            ),
            GlassMorphicButton(
              onPressed: () => _onArticleSelected('das'),
              child: const Text(
                'das',
                style: TextStyle(
                  fontSize: 20,
                  color: colorBlack,
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildArticleResultContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // result emoji
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: AnimatedBuilder(
            animation: widget.hoverAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, widget.hoverAnimation.value),
                child: Icon(
                  _isCorrect ? Icons.check_circle_sharp : Icons.cancel_sharp,
                  size: 70,
                  color: _isCorrect ? Colors.green : colorRed,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: kToolbarHeight * 0.75),

        // word with article + translation
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isCorrect)
              Text(
                '$_selectedArticle ${widget.gameState.targetWord} ',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 28,
                      color: colorBlack,
                    ),
                textAlign: TextAlign.center,
              ),
            if (!_isCorrect)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // incorrect article
                  Text(
                    _selectedArticle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 28,
                          color: colorRed,
                          decoration: TextDecoration.lineThrough,
                          decorationThickness: 2,
                        ),
                  ),
                  const SizedBox(width: 10),
                  // correct article
                  Text(
                    _correctArticle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 28,
                          color: colorBlack,
                          decoration: TextDecoration.underline,
                        ),
                  ),
                  const SizedBox(width: 2),

                  // word itself
                  Text(
                    ' ${widget.gameState.targetWord}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 28,
                          color: colorBlack,
                        ),
                  ),

                  const SizedBox(width: 5),
                ],
              ),
            // translation
            Text(
              '- $_englishTranslation',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 20,
                    color: colorBlack,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),

        const SizedBox(height: kToolbarHeight * 0.75),

        // action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GlassMorphicButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  RouteNames.home,
                  (route) => false,
                );
                ref.read(wordleGameStateProvider.notifier).newGame();
              },
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Icon(
                Icons.home_rounded,
                color: colorBlack,
                size: 30,
              ),
            ),
            SizedBox(),
            GlassMorphicButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(wordleGameStateProvider.notifier).newGame();
              },
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Icon(
                Icons.refresh_rounded,
                color: colorYellow,
                size: 30,
              ),
            ),
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 600),
      firstChild: _buildInitialContent(),
      secondChild: _buildArticleResultContent(),
      crossFadeState: _showingArticleResult
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      firstCurve: Curves.easeOutCubic,
      secondCurve: Curves.easeInCubic,
      sizeCurve: Curves.easeInOutCubic,

      // account for size differences
      layoutBuilder: (topChild, topChildKey, bottomChild, bottomChildKey) {
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned(
              key: bottomChildKey,
              child: bottomChild,
            ),
            Positioned(
              key: topChildKey,
              child: topChild,
            )
          ],
        );
      },
    );
  }
}
