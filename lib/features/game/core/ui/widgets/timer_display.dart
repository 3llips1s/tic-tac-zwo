import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
import 'package:tic_tac_zwo/features/game/core/logic/game_notifier.dart';

import '../../../../../config/game_config/config.dart';
import '../../data/models/game_config.dart';
import '../../../offline/logic/offline_notifier.dart';

class TimerDisplay extends ConsumerWidget {
  final GameConfig gameConfig;

  const TimerDisplay({super.key, required this.gameConfig});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameConfig.gameMode == GameMode.offline
        ? offlineStateProvider(gameConfig)
        : gameStateProvider(gameConfig));

    // if (!gameState.isTimerActive) return SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: gameState.isTimerActive ? Colors.black87 : colorGrey400,
        shape: BoxShape.circle,
        boxShadow: gameState.isTimerActive
            ? [
                // darker shadow bottom right
                BoxShadow(
                  color: colorGrey500,
                  offset: Offset(3, 3),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Text(
        gameState.isTimerActive ? '0${gameState.remainingSeconds}' : '09',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 18,
              fontFamily: 'monospace',
              color: colorWhite,
            ),
      ),
    );
  }
}
