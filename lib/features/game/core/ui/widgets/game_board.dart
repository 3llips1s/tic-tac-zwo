import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/features/game/core/data/models/game_config.dart';
import 'package:tic_tac_zwo/features/game/offline/logic/offline_notifier.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/game_board_cell.dart';

import '../../../../../config/config.dart';
import '../../../../../config/constants.dart';
import '../../logic/game_notifier.dart';

class GameBoard extends ConsumerWidget {
  final GameConfig gameConfig;

  const GameBoard({super.key, required this.gameConfig});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = gameConfig.gameMode == GameMode.offline
        ? ref.watch(offlineStateProvider(gameConfig))
        : ref.watch(gameStateProvider(gameConfig));

    final gameNotifier = gameConfig.gameMode == GameMode.offline
        ? ref.read(offlineStateProvider(gameConfig).notifier)
        : ref.read(gameStateProvider(gameConfig).notifier);

    return Center(
      child: SizedBox(
        height: 300,
        width: 300,
        child: GridView.builder(
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
          ),
          itemCount: 9,
          itemBuilder: (context, index) => GestureDetector(
            onTap: () => gameNotifier.selectCell(index),
            child: GameBoardCell(
              isPressed: gameState.cellPressed[index],
              cellColor: gameState.getCellColor(index),
              isWinningCell: gameState.winningCells?.contains(index) ?? false,
              isGameOver: gameState.isGameOver,
              child: Text(
                gameState.board[index] ?? '',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 30,
                      color: gameState.board[index] == 'X'
                          ? colorWhite
                          : colorBlack,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
