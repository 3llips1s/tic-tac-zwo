import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tic_tac_zwo/features/game/core/data/models/game_config.dart';
import 'package:tic_tac_zwo/features/game/core/logic/game_state.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/article_buttons.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/dual_progress_indicator.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/game_board.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/game_over_dialog.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/player_info.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/timer_display.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/turn_noun_display.dart';
import 'package:tic_tac_zwo/features/game/online/logic/online_game_notifier.dart';
import 'package:tic_tac_zwo/features/navigation/navigation_provider.dart';

import '../../../../../config/game_config/config.dart';
import '../../../../../config/game_config/constants.dart';
import '../../../../../config/game_config/game_providers.dart';
import '../../../../navigation/routes/route_names.dart';
import '../../../online/ui/widgets/online_game_over_dialog.dart';

class GameScreen extends ConsumerWidget {
  final GameConfig gameConfig;

  const GameScreen({
    super.key,
    required this.gameConfig,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // navigation listener
    ref.listen<NavigationTarget?>(navigationTargetProvider, (previous, next) {
      if (next != null) {
        String routeName;
        switch (next) {
          case NavigationTarget.home:
            routeName = RouteNames.home;
            break;
          case NavigationTarget.matchmaking:
            routeName = RouteNames.matchmaking;
            break;
        }

        Navigator.pushNamedAndRemoveUntil(context, routeName, (route) => false);
        ref.read(navigationTargetProvider.notifier).state = null;
      }
    });

    // dialog trigger listener
    ref.listen<GameState>(GameProviders.getStateProvider(ref, gameConfig),
        (previous, next) {
      final wasGameOver = previous?.isGameOver ?? false;
      final gameNotifier =
          ref.read(GameProviders.getStateProvider(ref, gameConfig).notifier);

      if (next.isGameOver && !wasGameOver) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) {
            if (context.mounted) {
              if (gameConfig.gameMode == GameMode.online) {
                showOnlineGameOverDialog(context, ref, gameConfig);
              } else {
                showGameOverDialog(
                  context,
                  gameConfig,
                  next,
                  () => gameNotifier.rematch(),
                );
              }
            }
          },
        );
      }
    });

    final gameState =
        ref.watch(GameProviders.getStateProvider(ref, gameConfig));
    final isOnlineMode = gameConfig.gameMode == GameMode.online;
    final onlineNotifier = isOnlineMode
        ? ref.read(onlineGameStateNotifierProvider(gameConfig).notifier)
        : null;

    final bool activateSaveButton =
        gameState.selectedCellIndex != null && gameState.isTimerActive;
    final bool activateHomeButton = gameState.isGameOver;

    final space = SizedBox(height: kToolbarHeight);
    final halfSpace = SizedBox(height: kToolbarHeight / 2);
    final quarterSpace = SizedBox(height: kToolbarHeight / 4);

    if (gameState.isGameOver) {}

    return Scaffold(
      backgroundColor: colorGrey300,
      body: Container(
        color: colorGrey300,
        padding: EdgeInsets.only(bottom: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            space,

            // timer
            Align(
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 600),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                child: _buildTimerWidget(context, ref, gameConfig, gameState,
                    isOnlineMode, onlineNotifier),
              ),
            ).animate().fadeIn(
                  delay: 3300.ms,
                  duration: 600.ms,
                  curve: Curves.easeInOut,
                ),

            halfSpace,

            // players
            PlayerInfo(gameConfig: gameConfig)
                .animate(delay: 1800.ms)
                .slideY(
                  begin: -0.5,
                  end: 0.0,
                  duration: 1500.ms,
                  curve: Curves.easeInOut,
                )
                .fadeIn(
                  duration: 1500.ms,
                  curve: Curves.easeInOut,
                ),

            quarterSpace,

            // word display
            TurnNounDisplay(gameConfig: gameConfig).animate().fadeIn(
                  delay: 3300.ms,
                  duration: 600.ms,
                  curve: Curves.easeInOut,
                ),

            quarterSpace,

            // game board
            Center(
              child: GameBoard(
                gameConfig: gameConfig,
              ),
            )
                .animate(
                  delay: 300.ms,
                )
                .scale(
                  duration: 1500.ms,
                  curve: Curves.easeInOut,
                )
                .fadeIn(
                  begin: 0.0,
                  duration: 1500.ms,
                  curve: Curves.easeInOut,
                ),

            space,

            // article buttons
            ArticleButtons(
              gameConfig: gameConfig,
              overlayColor:
                  gameState.getArticleOverlayColor(gameState.currentPlayer),
            ),

            halfSpace,

            // save word
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 35),
                child: GestureDetector(
                  onTap: activateSaveButton ? () {} : () {},
                  child: Container(
                    height: 40,
                    width: 40,
                    color: Colors.transparent,
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/images/bookmark.svg',
                        colorFilter: activateSaveButton
                            ? ColorFilter.mode(
                                colorBlack,
                                BlendMode.srcIn,
                              )
                            : ColorFilter.mode(
                                Colors.black26,
                                BlendMode.srcIn,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // back home
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 10),
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: IconButton(
                      onPressed: activateHomeButton
                          ? () => Navigator.pushNamedAndRemoveUntil(
                                context,
                                RouteNames.home,
                                (route) => false,
                              )
                          : () => {},
                      icon: Icon(
                        Icons.home_rounded,
                        color: colorWhite,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerWidget(
    BuildContext context,
    WidgetRef ref,
    GameConfig gameConfig,
    GameState gameState,
    bool isOnlineMode,
    OnlineGameNotifier? onlineNotifier,
  ) {
    if (!isOnlineMode) {
      final key = gameState.isTimerActive ? 'active' : 'inactive';
      return TimerDisplay(
        gameConfig: gameConfig,
        key: ValueKey(key),
      );
    }

    final timerState =
        onlineNotifier?.timerDisplayState ?? TimerDisplayState.static;

    switch (timerState) {
      case TimerDisplayState.inactivity:
        return DualProgressIndicator(
          key: ValueKey('inactivity'),
          size: 25,
          outerStrokeWidth: 1,
          innerStrokeWidth: 1,
          circleGap: 0.75,
        );
      case TimerDisplayState.countdown:
        return TimerDisplay(
          gameConfig: gameConfig,
          key: ValueKey('countdown'),
        );
      case TimerDisplayState.static:
        return TimerDisplay(
          gameConfig: gameConfig,
          key: ValueKey('static'),
        );
    }
  }
}
