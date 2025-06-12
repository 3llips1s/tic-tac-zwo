import 'package:flutter/material.dart';
import 'package:tic_tac_zwo/config/game_config/config.dart';
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
    final player1 = gameState.players[0];
    final player2 = gameState.players[1];

    final xPlayer = player1.symbol == PlayerSymbol.X ? player1 : player2;
    final oPlayer = player1.symbol == PlayerSymbol.O ? player1 : player2;

    final xPlayerScore =
        xPlayer == player1 ? gameState.player1Score : gameState.player2Score;
    final oPlayerScore =
        oPlayer == player1 ? gameState.player1Score : gameState.player2Score;

    return Column(
      children: [
        SizedBox(height: 16),
        // game outcome
        if (gameState.winningPlayer != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                gameState.winningPlayer!.username == 'Du'
                    ? '${gameState.winningPlayer!.username} gewinnst!'
                    : '${gameState.winningPlayer!.username} gewinnt!',
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
        const SizedBox(height: 30),

        // scores
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((255 * 0.3).toInt()),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            '$xPlayerScore - $oPlayerScore',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorBlack,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 16),
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
  await Future.delayed(Duration(milliseconds: 600));

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
          padding: EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 12,
          ),
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
          padding: EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 12,
          ),
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
                    nextStartingPlayer.username == 'Du'
                        ? '${nextStartingPlayer.username} beginnst.'
                        : '${nextStartingPlayer.username} beginnt.',
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
