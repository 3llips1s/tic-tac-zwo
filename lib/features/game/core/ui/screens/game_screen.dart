import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tic_tac_zwo/features/game/core/data/models/game_config.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/article_buttons.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/game_board.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/game_over_dialog.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/player_info.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/timer_display.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/turn_noun_display.dart';

import '../../../../../config/game_config/constants.dart';
import '../../../../../config/game_config/game_providers.dart';
import '../../../../navigation/routes/route_names.dart';

class GameScreen extends ConsumerWidget {
  final GameConfig gameConfig;

  const GameScreen({
    super.key,
    required this.gameConfig,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState =
        ref.watch(GameProviders.getStateProvider(ref, gameConfig));

    final space = SizedBox(height: kToolbarHeight);
    final halfSpace = SizedBox(height: kToolbarHeight / 2);
    final quarterSpace = SizedBox(height: kToolbarHeight / 4);

    final bool activateSaveButton =
        gameState.selectedCellIndex != null && gameState.isTimerActive;

    if (gameState.isGameOver) {
      showGameOverDialog(
        context,
        gameConfig,
        gameState,
        () {
          final gameNotifier = ref
              .read(GameProviders.getStateProvider(ref, gameConfig).notifier);

          gameNotifier.rematch();
        },
      );
    }

    return Scaffold(
      backgroundColor: colorGrey300,
      body: Container(
        color: colorGrey300,
        padding: EdgeInsets.only(bottom: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            space,

            Align(
              alignment: Alignment.center,
              child: TimerDisplay(gameConfig: gameConfig),
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
                                Colors.black87,
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
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        RouteNames.home,
                        (route) => false,
                      ),
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
}
