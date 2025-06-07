import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/config/game_config/config.dart';
import 'package:tic_tac_zwo/config/game_config/game_providers.dart';
import 'package:tic_tac_zwo/features/game/core/data/models/game_config.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/glassmorphic_dialog.dart';
import 'package:tic_tac_zwo/features/game/online/data/services/matchmaking_service.dart';

import '../../../../../config/game_config/constants.dart';
import '../../../core/data/models/player.dart';

class _OnlineGameOverDialogContent extends ConsumerWidget {
  final GameConfig gameConfig;

  const _OnlineGameOverDialogContent({required this.gameConfig});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState =
        ref.watch(GameProviders.getStateProvider(ref, gameConfig));
    final status = gameState.onlineRematchStatus;

    // determine whether to show rematch ui
    final showRematchUI = status != OnlineRematchStatus.none &&
        status != OnlineRematchStatus.bothAccepted;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: showRematchUI
          ? _OnlineRematchStatusView(
              key: const ValueKey('rematch_view'), gameConfig: gameConfig)
          : _InitialGameOverView(
              key: const ValueKey('initial_view'), gameConfig: gameConfig),
    );
  }
}

class _InitialGameOverView extends ConsumerWidget {
  final GameConfig gameConfig;

  const _InitialGameOverView({super.key, required this.gameConfig});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState =
        ref.watch(GameProviders.getStateProvider(ref, gameConfig));
    final notifier =
        ref.read(GameProviders.getStateProvider(ref, gameConfig).notifier);
    final localPlayerId = ref.watch(supabaseProvider).auth.currentUser?.id;

    String title;
    if (gameState.winningPlayer != null) {
      title = gameState.winningPlayer!.userId == localPlayerId
          ? 'Du gewinnst!'
          : '${gameState.winningPlayer!.userName} gewinnt!';
    } else {
      title = 'Unentschieden!';
    }

    final Player localPlayer = gameState.players.firstWhere(
        (player) => player.userId == localPlayerId,
        orElse: () => gameState.players[0]);
    final Player remotePlayer = gameState.players.firstWhere(
        (player) => player.userId != localPlayerId,
        orElse: () => gameState.players[1]);
    final int localPlayerSessionScore =
        (gameState.players[0].userId == localPlayer.userId)
            ? gameState.player1Score
            : gameState.player2Score;
    final int remotePlayerSessionScore =
        (gameState.players[0].userId == remotePlayer.userId)
            ? gameState.player1Score
            : gameState.player2Score;

    final pointsEarned = gameState.pointsEarnedPerGame;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          // game outcome
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
          ),

          // scores
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((255 * 0.3).toInt()),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              '$localPlayerSessionScore - $remotePlayerSessionScore',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorBlack,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          // points
          Text(
            '+ $pointsEarned',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  color: colorDarkGreen,
                ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(context,
                  icon: Icons.home_rounded,
                  tooltip: 'Startseite',
                  onPressed: () => notifier.go)
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context,
      {required IconData icon,
      required String tooltip,
      required VoidCallback onPressed,
      bool isPrimary = false}) {
    return Tooltip(
      message: tooltip,
      child: GlassMorphicButton(onPressed: onPressed, child: Icon(icon)),
    );
  }
}

class _OnlineRematchStatusView extends ConsumerWidget {
  final GameConfig gameConfig;

  const _OnlineRematchStatusView({super.key, required this.gameConfig});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack();
  }
}

void showOnlineGameOverDialog(
  BuildContext context,
  WidgetRef ref,
  GameConfig gameConfig,
) async {
  await Future.delayed(const Duration(milliseconds: 600));

  if (context.mounted) {
    await showCustomDialog(
        context: context,
        height: 300,
        width: 300,
        child: _OnlineGameOverDialogContent(gameConfig: gameConfig));
  }
}
