import 'dart:ui';

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
      padding: const EdgeInsets.only(
        top: 90,
        bottom: 18,
        left: 8,
        right: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd
          _buildPodiumPlace(
            player: podiumPlayers[1],
            rank: 2,
            height: 120,
            color: const Color(0xFFC0C0C0),
          )
              .animate()
              .slideY(
                begin: -0.3,
                delay: 600.ms,
                duration: 900.ms,
                curve: Curves.easeInOut,
              )
              .fadeIn(
                curve: Curves.easeInOut,
                duration: 900.ms,
              ),

          // 1st
          _buildPodiumPlace(
            player: podiumPlayers[0],
            rank: 1,
            height: 150,
            color: const Color(0xFFD4AF37),
          )
              .animate()
              .slideY(
                begin: -0.3,
                delay: 300.ms,
                duration: 900.ms,
                curve: Curves.easeInOut,
              )
              .fadeIn(
                curve: Curves.easeInOut,
                duration: 900.ms,
              ),

          // 3rd
          _buildPodiumPlace(
            player: podiumPlayers[2],
            rank: 3,
            height: 90,
            color: const Color(0xFFCD7F32),
          )
              .animate()
              .slideY(
                begin: -0.3,
                delay: 900.ms,
                duration: 900.ms,
                curve: Curves.easeInOut,
              )
              .fadeIn(
                curve: Curves.easeInOut,
                duration: 900.ms,
              )
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
        const SizedBox(height: 20),
        Container(
          width: 100,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  '🏆 ${player.gamesWon}    🎯 ${player.accuracy.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
              )
            ],
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

    return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: [
            Container(
              width: 100,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: isCurrentUser ? Colors.blue : colorWhite,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCurrentUser
                      ? Colors.blue.withOpacity(0.4)
                      : colorWhite.withOpacity(0.1),
                  width: isCurrentUser ? 2 : 1,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withAlpha((255 * 0.7).toInt()),
                    Colors.white.withAlpha((255 * 0.1).toInt()),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Flag(
                          countryCode: player.countryCode,
                          height: 10,
                          width: 15),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          player.username,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${player.points} Pkt',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ));
  }
}
