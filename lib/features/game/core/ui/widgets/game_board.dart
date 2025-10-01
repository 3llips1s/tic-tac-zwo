import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/config/game_config/game_providers.dart';
import 'package:tic_tac_zwo/features/game/core/data/models/game_config.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/game_board_cell.dart';
import 'package:tic_tac_zwo/features/game/online/logic/online_game_notifier.dart';

import '../../../../../config/game_config/config.dart';
import '../../../../../config/game_config/constants.dart';
import '../../../../settings/logic/audio_manager.dart';

class GameBoard extends ConsumerWidget {
  final GameConfig gameConfig;

  const GameBoard({super.key, required this.gameConfig});

  void onCellTapped(WidgetRef ref, int index) {
    final gameState = ref.read(GameProviders.getStateProvider(ref, gameConfig));

    // play sound when cell is selected
    if (gameState.board[index] == null && !gameState.isGameOver) {
      AudioManager.instance.playClickSound();
    }

    final gameNotifier =
        ref.read(GameProviders.getStateProvider(ref, gameConfig).notifier);

    if (gameConfig.gameMode == GameMode.online) {
      final notifier =
          ref.read(onlineGameStateNotifierProvider(gameConfig).notifier);

      if (notifier.canLocalPlayerMakeMove) {
        notifier.selectCellOnline(index);
      }
    } else {
      gameNotifier.selectCell(index);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState =
        ref.watch(GameProviders.getStateProvider(ref, gameConfig));

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
            onTap: () => onCellTapped(ref, index),
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
