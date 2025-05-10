import 'package:flutter/material.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
import 'package:tic_tac_zwo/features/game/core/data/models/game_config.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/glassmorphic_dialog.dart';

import '../../../../navigation/routes/route_names.dart';
import '../../logic/game_state.dart';

class GameOverDialog extends StatelessWidget {
  final GameConfig gameConfig;
  final GameState gameState;
  final VoidCallback onRematch;

  const GameOverDialog({
    super.key,
    required this.gameConfig,
    required this.gameState,
    required this.onRematch,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // game outcome
        if (gameState.winningPlayer != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // todo: add a flag to username in online mode
              Text(
                gameState.winningPlayer!.userName == 'Du'
                    ? '${gameState.winningPlayer!.userName} gewinnst!'
                    : '${gameState.winningPlayer!.userName} gewinnt!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorBlack,
                    ),
              ),
            ],
          ),
        ] else ...[
          Text(
            'Unentschieden!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorBlack,
                ),
          ),
        ],
        const SizedBox(height: kToolbarHeight / 1.25),

        // scores
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((255 * 0.3).toInt()),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            '${gameState.player1Score} - ${gameState.player2Score}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorBlack,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: kToolbarHeight / 2),
      ],
    );
  }
}

void showGameOverDialog(
  BuildContext context,
  GameConfig gameConfig,
  GameState gameState,
  VoidCallback onRematch,
) async {
  await Future.delayed(Duration(milliseconds: 900));

  if (context.mounted) {
    await showCustomDialog(
      context: context,
      height: 250,
      width: 250,
      child: GameOverDialog(
        gameConfig: gameConfig,
        gameState: gameState,
        onRematch: onRematch,
      ),
      actions: [
        // home
        GlassMorphicButton(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            RouteNames.home,
            (route) => false,
          ),
          child: Icon(
            Icons.home_rounded,
            color: colorRed,
            size: 30,
          ),
        ),

        // rematch
        GlassMorphicButton(
          onPressed: () {
            Navigator.of(context).pop();
            onRematch();

            // fetch other player
            final nextStartingPlayer = gameState.players.firstWhere(
              (player) => player != gameState.startingPlayer,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                margin: EdgeInsets.only(
                  bottom: kToolbarHeight,
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
                  child:
                      // message
                      Center(
                          child: Text(
                    nextStartingPlayer.userName == 'Du'
                        ? '${nextStartingPlayer.userName} beginnst.'
                        : '${nextStartingPlayer.userName} beginnt.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorWhite,
                        ),
                  )),
                ),
              ),
            );
          },
          child: Icon(
            Icons.refresh_rounded,
            color: colorYellowAccent,
            size: 30,
          ),
        ),
      ],
    );
  }
}
