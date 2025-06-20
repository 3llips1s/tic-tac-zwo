import 'package:flutter/material.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
import 'package:tic_tac_zwo/features/profile/data/models/user_profile.dart';

class WdlBar extends StatelessWidget {
  final UserProfile userProfile;

  const WdlBar({super.key, required this.userProfile});

  static const Color winColor = colorYellow;
  static const Color drawColor = colorGrey600;
  static const Color lossColor = colorRed;

  @override
  Widget build(BuildContext context) {
    final totalGames = userProfile.gamesPlayed;
    if (totalGames == 0) {
      return Center(
        child: Text(
          'Noch keine Spieldaten verfügbar.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorGrey600,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
        ),
      );
    }

    Widget _buildBarSegment(int flex, Color color, String label) {
      if (flex == 0) return const SizedBox.shrink();
      return Expanded(
        flex: flex,
        child: Container(
          height: 32,
          color: color,
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorBlack,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(9.0),
      child: Row(
        children: [
          _buildBarSegment(
              userProfile.gamesWon, winColor, '${userProfile.gamesWon}S'),
          _buildBarSegment(
              userProfile.gamesDrawn, drawColor, '${userProfile.gamesDrawn}U'),
          _buildBarSegment(
              userProfile.gamesLost, lossColor, '${userProfile.gamesLost}N')
        ],
      ),
    );
  }
}
