import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
import 'package:tic_tac_zwo/features/game/core/data/models/game_config.dart';
import 'package:tic_tac_zwo/features/game/core/logic/game_notifier.dart';
import 'package:tic_tac_zwo/features/game/offline/logic/offline_notifier.dart';

import '../../../../../config/game_config/config.dart';
import '../../data/models/nouns.dart';
import '../../data/models/player.dart';

class TurnNounDisplay extends ConsumerStatefulWidget {
  final GameConfig gameConfig;

  const TurnNounDisplay({super.key, required this.gameConfig});

  @override
  ConsumerState<TurnNounDisplay> createState() => _TurnNounDisplayState();
}

class _TurnNounDisplayState extends ConsumerState<TurnNounDisplay>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;
  late AnimationController _articleController;
  late Animation<Offset> _articleSlideAnimation;

  // article feedback animation
  late AnimationController _feedbackController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _underlineOpacity;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // hover turn noun
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _hoverAnimation = Tween<double>(
      begin: 3,
      end: 9,
    ).animate(
      CurvedAnimation(
        parent: _hoverController,
        curve: Curves.easeInOut,
      ),
    );

    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // slide in / reveal article
    _articleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      reverseDuration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _articleSlideAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _articleController,
        curve: Curves.easeOut,
      ),
    );

    // article feedback animations
    // subtle bounce
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 1.1)
              .chain(CurveTween(curve: Curves.easeOutCirc)),
          weight: 25.0),
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.1, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOutCirc)),
          weight: 75.0)
    ]).animate(_feedbackController);

    // underline opacity animation
    _underlineOpacity = TweenSequence<double>(
      [
        TweenSequenceItem(
            tween: Tween<double>(begin: 0.0, end: 1.0), weight: 20.0),
        TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 1.0), weight: 60.0),
        TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 0.0), weight: 20.0),
      ],
    ).animate(_feedbackController);

    _hoverController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _articleController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TurnNounDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final gameState = ref.read(widget.gameConfig.gameMode == GameMode.offline
        ? offlineStateProvider(widget.gameConfig)
        : gameStateProvider(widget.gameConfig));

    // reset and player article animation when a move is made
    if (gameState.lastPlayedPlayer != null && !gameState.isTimerActive) {
      _articleController.forward(from: 0);
    }

    if (gameState.showArticleFeedback) {
      _feedbackController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(widget.gameConfig.gameMode == GameMode.offline
        ? offlineStateProvider(widget.gameConfig)
        : gameStateProvider(widget.gameConfig));

    final currentPlayer = gameState.currentPlayer;
    final currentNoun = gameState.currentNoun;
    final isTimerActive = gameState.isTimerActive;
    final selectedCellIndex = gameState.selectedCellIndex;
    final lastPlayerPlayer = gameState.lastPlayedPlayer;
    final showArticleFeedback = gameState.showArticleFeedback;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 300,
            height: kToolbarHeight * 1.1,
            child: AnimatedCrossFade(
              firstChild: AnimatedBuilder(
                animation: _hoverAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _hoverAnimation.value),
                    child: _showCurrentPlayer(context, currentPlayer),
                  );
                },
              ),
              secondChild: currentNoun != null
                  ? _showCurrentNoun(
                      context,
                      currentNoun,
                      lastPlayerPlayer != null && !isTimerActive,
                      _articleSlideAnimation,
                      showArticleFeedback)
                  : const Row(children: [SizedBox()]),
              crossFadeState: (selectedCellIndex != null && isTimerActive)
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 600),
              reverseDuration: Duration(milliseconds: 3000),
              secondCurve: Curves.easeInOutCirc,
              firstCurve: Curves.easeOutCirc,
              sizeCurve: Curves.easeIn,
            ),
          )
        ],
      ),
    );
  }

  Widget _showCurrentNoun(
    BuildContext context,
    GermanNoun currentNoun,
    bool showArticle,
    Animation<Offset> slideAnimation,
    bool shouldArticleAnimate,
  ) {
    final gameState = ref.read(widget.gameConfig.gameMode == GameMode.offline
        ? offlineStateProvider(widget.gameConfig)
        : gameStateProvider(widget.gameConfig));

    final wrongArticle = gameState.wrongSelectedArticle;
    final hasWrongArticle = wrongArticle != null && shouldArticleAnimate;

    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showArticle) ...[
            SlideTransition(
              position: slideAnimation,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // wrong article with strikethrough
                  if (hasWrongArticle) ...[
                    Text(
                      wrongArticle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 28,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: colorBlack,
                            decorationThickness: 1.54,
                            color: colorRed,
                          ),
                    ),
                    SizedBox(width: 15),
                  ],

                  // correct article with animation
                  AnimatedBuilder(
                    animation: shouldArticleAnimate
                        ? _feedbackController
                        : const AlwaysStoppedAnimation(0.0),
                    builder: (context, child) {
                      return Transform.scale(
                        scale:
                            shouldArticleAnimate ? _bounceAnimation.value : 1.0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentNoun.article,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontSize: hasWrongArticle ? 30 : 33,
                                    color: shouldArticleAnimate
                                        ? colorDarkGreen
                                        : colorBlack,
                                  ),
                            ),

                            // animated underline
                            AnimatedBuilder(
                              animation: shouldArticleAnimate
                                  ? _underlineOpacity
                                  : const AlwaysStoppedAnimation(0.0),
                              builder: (context, child) {
                                return Container(
                                  height: 3,
                                  width: currentNoun.article.length * 15.0,
                                  color: colorBlack.withAlpha((255 *
                                          (shouldArticleAnimate
                                              ? _underlineOpacity.value
                                              : 0))
                                      .toInt()),
                                );
                              },
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(width: 10),
          ],
          Text(
            currentNoun.noun,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 33,
                ),
          ),
          SizedBox(width: 10),
          Text(
            ' (${currentNoun.english})',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 18,
                  // fontStyle: FontStyle.italic,
                  color: Colors.black54,
                ),
          ),
        ],
      ),
    );
  }
}

Widget _showCurrentPlayer(BuildContext context, Player currentPlayer) {
  final space = SizedBox(width: 10);

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          currentPlayer.symbolString,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 20,
                fontStyle: FontStyle.italic,
                color: colorBlack,
              ),
        ),
        space,
        Text(
          'spielt...',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontSize: 20, fontStyle: FontStyle.italic),
        ),
      ],
    ),
  );
}
