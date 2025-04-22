import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tic_tac_zwo/features/game/core/data/models/game_config.dart';
import 'package:tic_tac_zwo/features/game/core/logic/game_notifier.dart';
import 'package:tic_tac_zwo/features/game/offline/logic/offline_notifier.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/article_buttons.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/game_board.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/game_over_dialog.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/player_info.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/timer_display.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/turn_noun_display.dart';

import '../../../../../config/game_config/config.dart';
import '../../../../../config/game_config/constants.dart';
import '../../../../navigation/routes/route_names.dart';

class GameScreen extends ConsumerWidget {
  final GameConfig gameConfig;

  const GameScreen({
    super.key,
    required this.gameConfig,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameConfig.gameMode == GameMode.offline
        ? offlineStateProvider(gameConfig)
        : gameStateProvider(gameConfig));

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
          final notifier = gameConfig.gameMode == GameMode.offline
              ? ref.read(offlineStateProvider(gameConfig).notifier)
              : ref.read(gameStateProvider(gameConfig).notifier);

          notifier.rematch();
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
                child: TimerDisplay(gameConfig: gameConfig)),

            halfSpace,

            // players
            PlayerInfo(gameConfig: gameConfig),

            quarterSpace,

            // word display
            TurnNounDisplay(gameConfig: gameConfig),

            quarterSpace,

            // game board
            Center(
              child: GameBoard(
                gameConfig: gameConfig,
              ),
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
                padding: const EdgeInsets.only(right: 50),
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
                                colorBlack,
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
