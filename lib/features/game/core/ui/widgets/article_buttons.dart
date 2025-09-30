import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../config/game_config/constants.dart';
import '../../../../../config/game_config/game_providers.dart';
import '../../../../settings/logic/haptics_manager.dart';
import '../../data/models/game_config.dart';

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
    final gameState =
        ref.watch(GameProviders.getStateProvider(ref, widget.gameConfig));
    final gameNotifier = ref
        .read(GameProviders.getStateProvider(ref, widget.gameConfig).notifier);

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
                        HapticsManager.medium();
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
