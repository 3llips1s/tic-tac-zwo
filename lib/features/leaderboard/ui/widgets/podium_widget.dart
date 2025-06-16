import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
import 'package:tic_tac_zwo/features/auth/ui/widgets/flag.dart';
import 'package:tic_tac_zwo/features/leaderboard/data/leaderboard_entry.dart';

class PodiumWidget extends StatelessWidget {
  final List<LeaderboardEntry> top3Players;

  const PodiumWidget({super.key, required this.top3Players});

  @override
  Widget build(BuildContext context) {
    final List<LeaderboardEntry?> podiumPlayers = List.filled(3, null);
    for (final player in top3Players) {
      if (player.rank >= 1 && player.rank <= 3) {
        podiumPlayers[player.rank - 1] = player;
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd
          _buildPodiumPlace(
            player: podiumPlayers[1],
            rank: 2,
            height: 100,
            color: const Color(0xFFC0C0C0),
          )
              .animate()
              .slideY(begin: 0.5, delay: 300.ms, duration: 600.ms)
              .fadeIn(),

          // 1st
          _buildPodiumPlace(
            player: podiumPlayers[0],
            rank: 1,
            height: 150,
            color: const Color(0xFFFFD700),
          ).animate().slideY(begin: 0.5, duration: 600.ms).fadeIn(),

          // 3rd
          _buildPodiumPlace(
            player: podiumPlayers[2],
            rank: 3,
            height: 75,
            color: const Color(0xFFCD7F32),
          )
              .animate()
              .slideY(begin: 0.5, delay: 600.ms, duration: 600.ms)
              .fadeIn()
        ],
      ),
    );
  }

  Widget _buildPodiumPlace({
    LeaderboardEntry? player,
    required int rank,
    required double height,
    required Color color,
  }) {
    if (player == null) {
      return SizedBox(width: 90);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PlayerInfoCard(player: player),
        const SizedBox(height: 8),
        Container(
          width: 90,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.7),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Center(
            child: Text(
              '$rank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorWhite.withOpacity(0.8),
              ),
            ),
          ),
        )
      ],
    );
  }
}

class _PlayerInfoCard extends StatelessWidget {
  final LeaderboardEntry player;

  const _PlayerInfoCard({required this.player});

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = player.isCurrentUser;
    return Container(
      width: 110,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.blue.withOpacity(0.1) : colorWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser ? Colors.blue : colorGrey300,
          width: isCurrentUser ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorBlack.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flag(countryCode: player.countryCode, height: 16, width: 24),
              const SizedBox(width: 6),
              Text(
                player.username,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                overflow: TextOverflow.ellipsis,
              )
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${player.points} Pkt',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '🏆 ${player.gamesWon} | 🎯 ${player.accuracy.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 10,
              color: colorGrey600,
              fontWeight: FontWeight.w500,
            ),
          )
        ],
      ),
    );
  }
}
