import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    final gameState =
        ref.watch(GameProviders.getStateProvider(ref, gameConfig));
    final status = gameState.onlineRematchStatus;

    ref.listen(
      GameProviders.getStateProvider(ref, gameConfig)
          .select((state) => state.onlineRematchStatus),
      (previous, next) {
        if (next == OnlineRematchStatus.bothAccepted) {
          final notifier =
              ref.read(GameProviders.getStateProvider(ref, gameConfig).notifier)
                  as OnlineGameNotifier;
          notifier.initiateNewGameAfterRematch();
        }
      },
    );

    // determine whether to show rematch ui
    final showRematchUI = status == OnlineRematchStatus.localOffered ||
        status == OnlineRematchStatus.remoteOffered;

    Widget currentView;

    if (status == OnlineRematchStatus.bothAccepted) {
      currentView = Container(
        height: 280,
        key: const ValueKey('starting_new_game'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Starte neues Spiel...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 18,
                    color: Colors.green,
                  ),
            ),
          ],
        ),
      );
    } else if (showRematchUI) {
      currentView = _OnlineRematchStatusView(
          key: const ValueKey('rematch_view'), gameConfig: gameConfig);
    } else {
      currentView = _InitialGameOverView(
          key: const ValueKey('initial_view'), gameConfig: gameConfig);
    }

    return AnimatedSwitcher(
      duration: 600.ms,
      reverseDuration: 600.ms,
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: currentView,
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

    final Player p1 = gameState.players[0];
    final Player p2 = gameState.players[1];

    final localPlayer = p1.userId == localPlayerId ? p1 : p2;
    final opponent = p1.userId == localPlayerId ? p2 : p1;

    final localScore = localPlayer.userId == p1.userId
        ? gameState.player1Score
        : gameState.player2Score;
    final opponentScore = opponent.userId == p1.userId
        ? gameState.player1Score
        : gameState.player2Score;

    final pointsEarned = gameState.pointsEarnedPerGame;

    return Stack(
      children: [
        Container(
          height: 280,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              SizedBox(height: 28),
              // game outcome
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorBlack,
                      fontSize: 20,
                    ),
              ),

              // scores and points earned
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 40),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '$localScore - $opponentScore',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  if (pointsEarned != null)
                    Text('+ $pointsEarned',
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.lightGreenAccent,
                            )).animate(delay: 600.ms).fadeIn(
                          duration: 900.ms,
                          curve: Curves.easeInOut,
                        )
                  else
                    const SizedBox(width: 40),
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GlassMorphicButton(
                    onPressed: () => notifier.findNewOpponent(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 6.0),
                      child: const Icon(
                        Icons.search_rounded,
                        color: Colors.black87,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  GlassMorphicButton(
                    onPressed: () => notifier.requestRematch(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 6.0),
                      child: const Icon(
                        Icons.refresh_rounded,
                        color: colorYellowAccent,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: IconButton(
            icon: Icon(
              Icons.home_rounded,
              color: colorRed.withOpacity(0.7),
              size: 30,
            ),
            onPressed: () => notifier.goHomeAndCleanupSession(),
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

    final opponent =
        gameState.players.firstWhere((player) => player.userId != localUserId);
    final opponentName = opponent.userName;

    String message = '';
    List<Widget> actionButtons = [];

    switch (gameState.onlineRematchStatus) {
      case OnlineRematchStatus.localOffered:
        message = 'Warte auf $opponentName...';
        actionButtons = [
          GlassMorphicButton(
            onPressed: () => notifier.cancelRematchRequest(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Text(
              'Abbrechen',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                    fontSize: 18,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Icon(
              Icons.close_rounded,
              color: colorBlack,
              size: 30,
            ),
          ),
          const SizedBox(width: 40),
          GlassMorphicButton(
            onPressed: () => notifier.acceptRematch(),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Icon(
              Icons.check_rounded,
              color: colorYellowAccent,
              size: 30,
            ),
          ),
        ];
        break;
      default:
        message = 'Status wird geladen...';
        break;
    }

    return Stack(
      children: [
        Container(
          height: 280,
          padding: const EdgeInsets.fromLTRB(16, 112, 16, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              // rematch status
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorBlack,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: actionButtons,
              ),
            ],
          ),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => notifier.goHomeAndCleanupSession(),
                icon: Icon(
                  Icons.home_rounded,
                  color: colorRed.withOpacity(0.5),
                  size: 30,
                ),
              ),
              SizedBox(height: 8),
              IconButton(
                onPressed: () => notifier.findNewOpponent(),
                icon: Icon(
                  Icons.search_rounded,
                  color: colorBlack.withOpacity(0.5),
                  size: 30,
                ),
              ),
            ],
          ),
        ),
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
        height: 320,
        width: 320,
        child: _OnlineGameOverDialogContent(gameConfig: gameConfig));
  }
}
