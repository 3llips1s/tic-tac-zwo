import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/features/game/offline/logic/offline_notifier.dart';

import '../../../../../config/game_config/config.dart';
import '../../../../../config/game_config/constants.dart';
import '../../data/models/game_config.dart';
import '../../logic/game_notifier.dart';

class ArticleButtons extends ConsumerStatefulWidget {
  final GameConfig gameConfig;
  final Color overlayColor;

  const ArticleButtons(
      {super.key, required this.gameConfig, required this.overlayColor});

  @override
  ConsumerState<ArticleButtons> createState() => _ArticleButtonsState();
}

class _ArticleButtonsState extends ConsumerState<ArticleButtons> {
  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(widget.gameConfig.gameMode == GameMode.offline
        ? offlineStateProvider(widget.gameConfig)
        : gameStateProvider(widget.gameConfig));

    final gameNotifier = ref.read(widget.gameConfig.gameMode == GameMode.offline
        ? offlineStateProvider(widget.gameConfig).notifier
        : gameStateProvider(widget.gameConfig).notifier);

    // button should only be enabled when a cell is selected and timer is active
    final bool buttonEnabled =
        gameState.selectedCellIndex != null && gameState.isTimerActive;

    return SizedBox(
      width: 300,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: ['der', 'die', 'das']
            .map(
              (article) => OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  overlayColor: gameState.currentNoun?.article == article
                      ? widget.overlayColor
                      : colorBlack,
                  minimumSize: Size(85, 50),
                ),
                onPressed: buttonEnabled
                    ? () {
                        HapticFeedback.mediumImpact();
                        gameNotifier.makeMove(article);
                      }
                    : null,
                child: Text(
                  article,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 20,
                        color: buttonEnabled ? colorBlack : Colors.grey,
                      ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
