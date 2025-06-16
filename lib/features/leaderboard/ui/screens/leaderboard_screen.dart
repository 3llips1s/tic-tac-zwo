import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/dual_progress_indicator.dart';
import 'package:tic_tac_zwo/features/leaderboard/logic/leaderboard_notifier.dart';

import '../../../navigation/routes/route_names.dart';
import '../widgets/leaderboard_list.dart';
import '../widgets/podium_widget.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  final String userId;

  const LeaderboardScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        ref.read(leaderboardProvider.notifier).loadLeaderboard(widget.userId);
      },
    );
  }

  Future<void> _refresh() {
    return ref
        .read(leaderboardProvider.notifier)
        .refreshLeaderboard(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardState = ref.watch(leaderboardProvider);

    return Scaffold(
      backgroundColor: colorGrey300,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            RefreshIndicator(
              backgroundColor: colorBlack,
              color: colorYellowAccent,
              strokeWidth: 1.5,
              elevation: 3.0,
              onRefresh: _refresh,
              child: _buildBody(leaderboardState),
            ),

            // refresh button
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                onPressed: _refresh,
                icon: Icon(
                  Icons.refresh_rounded,
                  color: Colors.black54,
                ),
              ),
            ),

            // home buttons
            Positioned(
              bottom: 24,
              right: 16,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    RouteNames.home,
                    (route) => false,
                  );
                },
                backgroundColor: colorBlack,
                child: const Icon(
                  Icons.home_rounded,
                  color: colorWhite,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(LeaderboardState state) {
    if (state.isLoading && !state.hasData) {
      return const Center(
        child: DualProgressIndicator(size: 60),
      );
    }

    if (state.error != null && !state.hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: colorGrey500, size: 64),
            const SizedBox(height: 32),
            Text(
              'Fehler beim Laden des Leaderboards',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            OutlinedButton(
              onPressed: () => ref
                  .read(leaderboardProvider.notifier)
                  .loadLeaderboard(widget.userId),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9)),
                overlayColor: colorBlack.withOpacity(0.3),
                side: const BorderSide(color: Colors.black87),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                child: Text(
                  'Erneut versuchen',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorBlack,
                        fontSize: 18,
                      ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state.isEmpty) {
      return const Center(
        child: Text('Noch keine Spieler im Leaderboard'),
      );
    }

    return CustomScrollView(
      slivers: [
        // top 3
        if (state.top3.isNotEmpty)
          SliverToBoxAdapter(
            child: PodiumWidget(top3Players: state.top3),
          ).animate().fadeIn(delay: 300.ms, duration: 600.ms),

        // remaining
        if (state.remaining.isNotEmpty)
          LeaderboardList(
            players: state.remaining,
          )
              .animate()
              .slideY(begin: 0.1, delay: 600.ms, duration: 600.ms)
              .fadeIn(),

        SliverToBoxAdapter(
          child: SizedBox(height: kToolbarHeight),
        )
      ],
    );
  }
}
