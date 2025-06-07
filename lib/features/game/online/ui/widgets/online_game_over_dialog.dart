import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/config/game_config/config.dart';
import 'package:tic_tac_zwo/config/game_config/game_providers.dart';
import 'package:tic_tac_zwo/features/game/core/data/models/game_config.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/glassmorphic_dialog.dart';
import 'package:tic_tac_zwo/features/game/online/data/services/matchmaking_service.dart';
import 'package:tic_tac_zwo/features/game/online/logic/online_game_notifier.dart';

import '../../../../../config/game_config/constants.dart';
import '../../../core/data/models/player.dart';

class _OnlineGameOverDialogContent extends ConsumerWidget {
  final GameConfig gameConfig;

  const _OnlineGameOverDialogContent({required this.gameConfig});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(GameProviders.getStateProvider(ref, gameConfig)
        .select((state) => state.onlineRematchStatus));

    // determine whether to show rematch ui
    final showRematchUI = status == OnlineRematchStatus.localOffered ||
        status == OnlineRematchStatus.remoteOffered;

    if (status == OnlineRematchStatus.bothAccepted) {
      return Center(
        child: Text(
          'Starte neues Spiel...',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 18,
                color: colorBlack,
              ),
        ),
      );
    }

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
        ref.read(GameProviders.getStateProvider(ref, gameConfig).notifier)
            as OnlineGameNotifier;
    final localPlayerId = ref.watch(supabaseProvider).auth.currentUser?.id;

    String title;
    if (gameState.winningPlayer != null) {
      title = gameState.winningPlayer!.userId == localPlayerId
          ? 'Du gewinnst!'
          : '${gameState.winningPlayer!.userName} gewinnt!';
    } else {
      title = 'Unentschieden!';
    }

    final Player xPlayer = gameState.players[0];
    final localScore = xPlayer.userId == localPlayerId
        ? gameState.player1Score
        : gameState.player2Score;
    final opponentScore = xPlayer.userId == localPlayerId
        ? gameState.player2Score
        : gameState.player1Score;

    final pointsEarned = gameState.pointsEarnedPerGame;

    return Stack(
      children: [
        Padding(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((255 * 0.3).toInt()),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '$localScore - $opponentScore',
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Tooltip(
                    message: 'Neuer Gegner',
                    child: GlassMorphicButton(
                      onPressed: () => notifier.findNewOpponent(),
                      child: const Icon(
                        Icons.search_rounded,
                        color: colorBlack,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Tooltip(
                    message: 'Revanche',
                    child: GlassMorphicButton(
                      onPressed: () => notifier.requestRematch(),
                      child: const Icon(
                        Icons.refresh_rounded,
                        color: colorYellowAccent,
                        size: 30,
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          right: 4,
          child: Tooltip(
            message: 'Home',
            child: IconButton(
              icon:
                  Icon(Icons.home_rounded, color: colorBlack.withOpacity(0.5)),
              onPressed: () => notifier.goHomeAndCleanupSession(),
            ),
          ),
        ),
      ],
    );
  }
}

class _OnlineRematchStatusView extends ConsumerWidget {
  final GameConfig gameConfig;

  const _OnlineRematchStatusView({super.key, required this.gameConfig});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState =
        ref.watch(GameProviders.getStateProvider(ref, gameConfig));
    final notifier =
        ref.watch(GameProviders.getStateProvider(ref, gameConfig).notifier)
            as OnlineGameNotifier;
    final localUserId = ref.watch(supabaseProvider).auth.currentUser?.id;

    String message = '';
    List<Widget> actionButtons = [];
    final opponent =
        gameState.players.firstWhere((player) => player.userId != localUserId);
    final opponentName = opponent.userName;

    switch (gameState.onlineRematchStatus) {
      case OnlineRematchStatus.localOffered:
        message = 'Warte auf $opponentName...';
        actionButtons = [
          GlassMorphicButton(
            onPressed: () => notifier.cancelRematchRequest(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Text(
              'Abbrechen',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorBlack,
                    fontSize: 16,
                  ),
            ),
          ),
        ];
        break;
      case OnlineRematchStatus.remoteOffered:
        message = '$opponentName möchte eine Revanche!';
        actionButtons = [
          GlassMorphicButton(
            onPressed: () => notifier.declineRematch(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Text(
              'Ablehnen',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorBlack,
                    fontSize: 16,
                  ),
            ),
          ),
          const SizedBox(width: 16),
          GlassMorphicButton(
            onPressed: () => notifier.acceptRematch(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Text(
              'Akzeptieren',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorBlack,
                    fontSize: 16,
                  ),
            ),
          ),
        ];
        break;
      default:
        message = 'Warte auf $opponentName...';
        break;
    }

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 56.0, 20.0, 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Center(
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorBlack,
                          fontSize: 20,
                        ),
                  ),
                ),
              ),
              if (actionButtons.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: actionButtons,
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          right: 4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: 'Startseite',
                child: IconButton(
                  onPressed: () => notifier.goHomeAndCleanupSession(),
                  icon: Icon(
                    Icons.home_rounded,
                    color: colorBlack.withOpacity(0.5),
                  ),
                ),
              ),
              SizedBox(height: 4),
              Tooltip(
                message: 'Neuer Gegner',
                child: IconButton(
                  onPressed: () => notifier.findNewOpponent(),
                  icon: Icon(
                    Icons.search_rounded,
                    color: colorBlack.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
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
