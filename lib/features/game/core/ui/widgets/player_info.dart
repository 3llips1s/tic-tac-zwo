import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/config/game_config/config.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
import 'package:tic_tac_zwo/features/game/core/data/models/game_config.dart';

import '../../../../../config/game_config/game_providers.dart';

class PlayerInfo extends ConsumerWidget {
  final GameConfig gameConfig;

  const PlayerInfo({super.key, required this.gameConfig});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState =
        ref.watch(GameProviders.getStateProvider(ref, gameConfig));

    final space = SizedBox(width: 15);

    final player1 = gameState.players[0];
    final player2 = gameState.players[1];

    final xPlayer = player1.symbol == PlayerSymbol.X ? player1 : player2;
    final oPlayer = player1.symbol == PlayerSymbol.O ? player1 : player2;

    final xPlayerScore =
        xPlayer == player1 ? gameState.player1Score : gameState.player2Score;
    final oPlayerScore =
        oPlayer == player1 ? gameState.player1Score : gameState.player2Score;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // p1 name + symbol | left
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                xPlayer.userName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      fontStyle:
                          xPlayer.isAI ? FontStyle.italic : FontStyle.normal,
                      color: xPlayer.isAI ? Colors.black54 : colorBlack,
                    ),
              ),
              space,
              Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: colorRed,
                ),
                child: Center(
                  child: Text(
                    xPlayer.symbolString,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 18,
                          color: colorWhite,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // scores
        Center(
          child: playerScores(context, xPlayerScore, oPlayerScore),
        ),

        // p2 name + symbol | right
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: colorYellow,
                ),
                child: Center(
                  child: Text(
                    oPlayer.symbolString,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 18,
                          color: colorBlack,
                        ),
                  ),
                ),
              ),
              space,
              Text(
                oPlayer.userName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      fontStyle:
                          oPlayer.isAI ? FontStyle.italic : FontStyle.normal,
                      color: oPlayer.isAI ? Colors.black54 : colorBlack,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Widget playerScores(BuildContext context, int xPlayerScore, int oPlayerScore) {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 20),
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.black87,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: colorGrey300),
    ),
    child: Text(
      '$xPlayerScore - $oPlayerScore',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 16,
            color: colorWhite,
          ),
    ),
  );
}
