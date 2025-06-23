import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
import 'package:tic_tac_zwo/features/auth/ui/widgets/flag.dart';
import 'package:tic_tac_zwo/features/leaderboard/data/leaderboard_entry.dart';

import '../../../navigation/routes/route_names.dart';

class LeaderboardList extends StatefulWidget {
  final List<LeaderboardEntry> players;

  const LeaderboardList({super.key, required this.players});

  @override
  State<LeaderboardList> createState() => _LeaderboardListState();
}

class _LeaderboardListState extends State<LeaderboardList> {
  int? _expandedIndex;

  void _handleExpansion(int index) {
    setState(() {
      if (_expandedIndex == index) {
        _expandedIndex = null;
      } else {
        _expandedIndex = index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: widget.players.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            child: _buildHeader(context).animate().fadeIn(
                  duration: 2400.ms,
                  curve: Curves.easeInOut,
                ),
          );
        }

        final playerIndex = index - 1;
        final player = widget.players[playerIndex];
        final isExpanded = _expandedIndex == playerIndex;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildExpandableRow(
            context,
            player,
            isExpanded,
            onExpandTap: () => _handleExpansion(playerIndex),
            onProfileTap: () {
              Navigator.of(context).pushNamed(RouteNames.profile,
                  arguments: {'userId': player.id});
            },
          ),
        )
            .animate(delay: (2000 + (playerIndex * 50)).ms)
            .fadeIn(duration: 900.ms)
            .slideX(begin: -0.3, duration: 900.ms, curve: Curves.easeInOut);
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final headerTheme = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorGrey600,
        );

    return Row(
      children: [
        SizedBox(
          width: 75,
          child: Text(
            '#',
            textAlign: TextAlign.center,
            style: headerTheme,
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            'Spieler*in',
            textAlign: TextAlign.start,
            style: headerTheme,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Punkte',
            textAlign: TextAlign.center,
            style: headerTheme,
          ),
        ),
        const SizedBox(width: 32),
      ],
    );
  }

  Widget _statCapsule({
    required String value,
    required String label,
    Color valueColor = colorBlack,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: colorGrey600,
          ),
        )
      ],
    );
  }

  Widget _buildExpandableRow(
      BuildContext context, LeaderboardEntry player, bool isExpanded,
      {required VoidCallback onExpandTap, required VoidCallback onProfileTap}) {
    final losses = player.gamesPlayed - player.gamesWon - player.gamesDrawn;
    final isCurrentUser = player.isCurrentUser;

    Color getAccuracyColor(double accuracy) {
      if (accuracy >= 80) return Colors.green.shade700;
      if (accuracy >= 50) return Colors.orange.shade700;
      return Colors.red.shade700;
    }

    return InkWell(
      onTap: onProfileTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isCurrentUser ? Colors.blue.withOpacity(0.1) : colorWhite,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isCurrentUser ? Colors.blue : colorGrey300,
            width: isCurrentUser ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            // collapsed view
            Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    player.rank.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Flag(
                  countryCode: player.countryCode,
                  height: 12,
                  width: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  player.username,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        overflow: TextOverflow.ellipsis,
                      ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    player.points.toString(),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  icon: Icon(isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded),
                  color: colorGrey400,
                  onPressed: onExpandTap,
                )
              ],
            ),
            // Expanded view with AnimatedOpacity and AnimatedSize
            AnimatedOpacity(
              opacity: isExpanded ? 1.0 : 0.0,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: AnimatedSize(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Visibility(
                  visible: isExpanded,
                  maintainState: true,
                  maintainSize: true,
                  maintainAnimation: true,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: const Divider(
                          color: colorGrey200,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statCapsule(
                            value: '${player.gamesPlayed}',
                            label: 'Spiele',
                          ),
                          _statCapsule(
                            value:
                                '${player.gamesWon}-${player.gamesDrawn}-$losses',
                            label: 'S-U-N',
                          ),
                          _statCapsule(
                            value: '${player.accuracy.toStringAsFixed(0)}%',
                            label: 'Acc',
                            valueColor: getAccuracyColor(player.accuracy),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
