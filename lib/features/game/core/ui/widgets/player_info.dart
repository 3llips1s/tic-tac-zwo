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

    return Padding(
      padding: const EdgeInsets.only(
        top: 8.0,
        bottom: 8.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // p1 name + symbol | left
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  gameState.players[0].userName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        fontStyle: gameState.players[0].isAI
                            ? FontStyle.italic
                            : FontStyle.normal,
                        color: gameState.players[0].isAI
                            ? Colors.black54
                            : colorBlack,
                      ),
                ),
                space,
                Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: gameState.players[0].symbol == PlayerSymbol.X
                        ? colorRed
                        : colorYellow,
                  ),
                  child: Center(
                    child: Text(
                      gameState.players[0].symbolString,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 18,
                            color: gameState.players[0].symbol == PlayerSymbol.X
                                ? colorWhite
                                : colorBlack,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // scores
          Center(
              child: playerScores(
                  context, gameState.player1Score, gameState.player2Score)),

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
                    color: gameState.players[1].symbol == PlayerSymbol.X
                        ? colorRed
                        : colorYellow,
                  ),
                  child: Center(
                    child: Text(
                      gameState.players[1].symbolString,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 18,
                            color: gameState.players[1].symbol == PlayerSymbol.X
                                ? colorWhite
                                : colorBlack,
                          ),
                    ),
                  ),
                ),
                space,
                Text(
                  gameState.players[1].userName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        fontStyle: gameState.players[1].isAI
                            ? FontStyle.italic
                            : FontStyle.normal,
                        color: gameState.players[1].isAI
                            ? Colors.black54
                            : colorBlack,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget playerScores(BuildContext context, int player1Score, int player2Score) {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 20),
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.black87,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: colorGrey300),
    ),
    child: Text(
      '$player1Score - $player2Score',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 16,
            color: colorWhite,
          ),
    ),
  );
}
