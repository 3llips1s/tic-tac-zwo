import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
import 'package:tic_tac_zwo/features/game/core/data/models/game_config.dart';
import 'package:tic_tac_zwo/features/game/core/data/repositories/german_noun_repo.dart';
import 'package:tic_tac_zwo/features/game/online/data/services/matchmaking_service.dart';

import '../../../../../config/game_config/config.dart';
import '../../../../../config/game_config/game_providers.dart';
import '../../data/models/german_noun.dart';
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
  late Animation<double> _underlineOpacity;

  // track previous state for animation triggers
  String? _previousRevealedArticle;
  bool? _previousRevealedArticleIsCorrect;

  bool _isOnlineMode = false;

  // dynamic font scaling
  double _calculateDynamicFontSize(String noun) {
    const baseFontSize = 30.0;
    const minFontSize = 20.0;

    if (noun.length <= 12) return baseFontSize;
    if (noun.length <= 14) return 28.0;
    if (noun.length <= 16) return 26.0;
    if (noun.length <= 18) return 24.0;
    if (noun.length <= 20) return 22.0;

    return minFontSize;
  }

  bool _showNoun() {
    final gameState =
        ref.watch(GameProviders.getStateProvider(ref, widget.gameConfig));

    if (_isOnlineMode) {
      final phase = _getCurrentGamePhase();

      return phase == OnlineGamePhase.cellSelected ||
          phase == OnlineGamePhase.articleRevealed;
    } else {
      return gameState.selectedCellIndex != null && gameState.isTimerActive;
    }
  }

  bool _showArticle() {
    final gameState =
        ref.watch(GameProviders.getStateProvider(ref, widget.gameConfig));
    if (_isOnlineMode) {
      final phase = _getCurrentGamePhase();
      final articleIsPresent = gameState.revealedArticle != null;

      return phase == OnlineGamePhase.articleRevealed && articleIsPresent;
    } else {
      return gameState.lastPlayedPlayer != null && !gameState.isTimerActive;
    }
  }

  bool _showArticleFeedback() {
    final gameState =
        ref.watch(GameProviders.getStateProvider(ref, widget.gameConfig));
    if (_isOnlineMode) {
      final phase = _getCurrentGamePhase();

      return phase == OnlineGamePhase.articleRevealed &&
          gameState.revealedArticleIsCorrect == false;
    } else {
      return gameState.showArticleFeedback;
    }
  }

  String? _getWrongArticle() {
    final gameState =
        ref.watch(GameProviders.getStateProvider(ref, widget.gameConfig));

    if (_isOnlineMode) {
      if (gameState.revealedArticle != null &&
          gameState.revealedArticleIsCorrect == false &&
          gameState.currentNoun != null) {
        return gameState.revealedArticle != gameState.currentNoun!.article
            ? gameState.revealedArticle
            : null;
      }
      return null;
    } else {
      return gameState.wrongSelectedArticle;
    }
  }

  @override
  void initState() {
    super.initState();
    _isOnlineMode = widget.gameConfig.gameMode == GameMode.online;
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // hover turn noun
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _hoverAnimation = Tween<double>(
      begin: 15,
      end: 20,
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

    _isOnlineMode = widget.gameConfig.gameMode == GameMode.online;

    if (_isOnlineMode) {
      _handleOnlineModeAnimations();
    } else {
      _handleOfflineModeAnimations();
    }
  }

  OnlineGamePhase _getCurrentGamePhase() {
    final gameState =
        ref.watch(GameProviders.getStateProvider(ref, widget.gameConfig));

    if (_isOnlineMode && gameState.onlineGamePhase != null) {
      return gameState.onlineGamePhase!;
    }

    if (gameState.isGameOver) {
      return OnlineGamePhase.turnComplete;
    }

    if (gameState.revealedArticle != null &&
        gameState.revealedArticleIsCorrect != null) {
      return OnlineGamePhase.articleRevealed;
    }

    if (gameState.selectedCellIndex != null && gameState.currentNoun != null) {
      return OnlineGamePhase.cellSelected;
    }

    return gameState.onlineGamePhase ?? OnlineGamePhase.waiting;
  }

  void _handleOnlineModeAnimations() {
    final gameState =
        ref.watch(GameProviders.getStateProvider(ref, widget.gameConfig));
    final currentPhase = _getCurrentGamePhase();
    final currentRevealedArticle = gameState.revealedArticle;
    final currentRevealedIsCorrect = gameState.revealedArticleIsCorrect;

    // article animation
    if (currentPhase == OnlineGamePhase.articleRevealed &&
        currentRevealedArticle != null &&
        _articleController.status == AnimationStatus.dismissed) {
      _articleController.forward(from: 0);
    } else if (currentPhase != OnlineGamePhase.articleRevealed &&
            _articleController.isAnimating ||
        _articleController.isCompleted) {
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted && gameState.revealedArticle == null) {
          _articleController.reset();
        }
      });
    }

    // feedback? animation
    if (currentPhase == OnlineGamePhase.articleRevealed &&
        currentRevealedIsCorrect != null &&
        (_feedbackController.status == AnimationStatus.dismissed ||
            currentRevealedIsCorrect != _previousRevealedArticleIsCorrect ||
            currentRevealedArticle != _previousRevealedArticle)) {
      _feedbackController.forward(from: 0);
    } else if (currentPhase != OnlineGamePhase.articleRevealed &&
            _feedbackController.isAnimating ||
        _feedbackController.isCompleted) {
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted && gameState.revealedArticle == null) {
          _feedbackController.reset();
        }
      });
    }

    _previousRevealedArticle = currentRevealedArticle;
    _previousRevealedArticleIsCorrect = currentRevealedIsCorrect;
  }

  void _handleOfflineModeAnimations() {
    final gameState =
        ref.watch(GameProviders.getStateProvider(ref, widget.gameConfig));

    if (gameState.lastPlayedPlayer != null && !gameState.isTimerActive) {
      _articleController.forward(from: 0);
      _feedbackController.reset();
    }

    if (gameState.showArticleFeedback &&
        gameState.wrongSelectedArticle != null) {
      _feedbackController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState =
        ref.watch(GameProviders.getStateProvider(ref, widget.gameConfig));
    final nounRepoReady = ref.watch(nounReadyProvider);

    final currentPlayer = gameState.currentPlayer;
    final currentNoun = gameState.currentNoun;

    final String? localPlayerId =
        ref.watch(supabaseProvider).auth.currentUser?.id;

    final showNoun = _showNoun();

    return nounRepoReady.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: colorBlack,
          strokeWidth: 1,
        ),
      ),
      error: (error, stackTrace) => Center(
        child: Text('Fehler. Bitte lade das Spiel noch einmal.'),
      ),
      data: (data) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: kToolbarHeight * 1.25,
              child: AnimatedCrossFade(
                firstChild: AnimatedBuilder(
                  animation: _hoverAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _hoverAnimation.value),
                      child: _showCurrentPlayer(
                        context,
                        currentPlayer,
                        gameMode: widget.gameConfig.gameMode,
                        localPlayerId: localPlayerId,
                        currentPlayerId: gameState.currentPlayerId,
                      ),
                    );
                  },
                ),
                secondChild: currentNoun != null
                    ? _showCurrentNoun(
                        context,
                        currentNoun,
                        _showArticle(),
                        _articleSlideAnimation,
                        _showArticleFeedback(),
                      )
                    : const Row(children: [SizedBox()]),
                crossFadeState: showNoun
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 600),
                reverseDuration: Duration(milliseconds: 1800),
                secondCurve: Curves.easeInOutCirc,
                firstCurve: Curves.easeOutCirc,
                sizeCurve: Curves.easeIn,
              ),
            )
          ],
        ),
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
    final wrongArticle = _getWrongArticle();
    final hasWrongArticle = wrongArticle != null && shouldArticleAnimate;

    final dynamicFontSize = _calculateDynamicFontSize(currentNoun.noun);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // articles + noun
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showArticle) ...[
              SlideTransition(
                position: slideAnimation,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    if (hasWrongArticle) ...[
                      Text(
                        wrongArticle,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: dynamicFontSize * 0.8,
                              fontStyle: FontStyle.italic,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: colorBlack,
                              decorationThickness: 1.5,
                              color: colorRed,
                            ),
                      ),
                      SizedBox(width: 15),
                    ],

                    // correct article with animation
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentNoun.article,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: hasWrongArticle
                                        ? dynamicFontSize * 0.9
                                        : dynamicFontSize,
                                    color: colorDarkGreen,
                                  ),
                        ),

                        // animated underline
                        AnimatedBuilder(
                          animation: shouldArticleAnimate
                              ? _underlineOpacity
                              : const AlwaysStoppedAnimation(0),
                          builder: (context, child) {
                            return Padding(
                              padding: shouldArticleAnimate
                                  ? const EdgeInsets.only(bottom: 7.0)
                                  : EdgeInsets.zero,
                              child: Container(
                                height: 2,
                                width: currentNoun.article.length * 12.5,
                                color: colorBlack.withAlpha(
                                  (255 *
                                          (shouldArticleAnimate
                                              ? _underlineOpacity.value
                                              : 0))
                                      .toInt(),
                                ),
                              ),
                            );
                          },
                        )
                      ],
                    ),
                    SizedBox(width: hasWrongArticle ? 15 : 12.5),
                  ],
                ),
              ),
            ],

            // noun with dynamic font sizing
            Text(
              currentNoun.noun,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: dynamicFontSize,
                  ),
            ),
          ],
        ),

        // translation
        Text(
          '- ${currentNoun.english}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: shouldArticleAnimate ? 15 : 16,
                color: Colors.black45,
              ),
        ),
      ],
    );
  }
}

Widget _showCurrentPlayer(
  BuildContext context,
  Player currentPlayer, {
  required GameMode gameMode,
  String? localPlayerId,
  String? currentPlayerId,
}) {
  const space = SizedBox(width: 5);

  String displayName;
  String verbText;

  switch (gameMode) {
    case GameMode.online:
      final isLocalPlayerTurn = (currentPlayerId == localPlayerId);
      displayName = isLocalPlayerTurn ? 'Du' : currentPlayer.username;
      verbText = isLocalPlayerTurn ? 'bist dran...' : 'spielt...';
      break;
    case GameMode.pass:
      displayName = currentPlayer.username;
      verbText = 'ist dran...';
    case GameMode.offline:
      if (currentPlayer.isAI) {
        displayName = currentPlayer.username;
        verbText = 'spielt...';
      } else {
        displayName = 'Du';
        verbText = 'bist dran...';
      }
    default:
      displayName = currentPlayer.username;
      verbText = 'spielt...';
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          displayName,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: Colors.black26,
              ),
        ),
        space,
        Text(
          verbText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: Colors.black26,
              ),
        ),
      ],
    ),
  );
}
