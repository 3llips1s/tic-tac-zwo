import 'package:flutter/material.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';

class WdlBarTest extends StatelessWidget {
  final int gamesWon;
  final int gamesDrawn;
  final int gamesLost;

  const WdlBarTest({
    super.key,
    this.gamesWon = 12,
    this.gamesDrawn = 5,
    this.gamesLost = 8,
  });

  @override
  Widget build(BuildContext context) {
    final totalGames = gamesWon + gamesDrawn + gamesLost;

    if (totalGames == 0) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'Noch keine Spieldaten verfügbar.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorGrey600,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
          ),
        ),
      );
    }

    Widget buildBarSegment(int flex, Color color, String label) {
      if (flex == 0) return const SizedBox.shrink();
      return Expanded(
        flex: flex,
        child: Container(
          height: 40,
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27.0),
        child: Row(
          children: [
            buildBarSegment(gamesWon, winColor.withOpacity(0.75), '$gamesWon'),
            buildBarSegment(
                gamesDrawn, drawColor.withOpacity(0.5), '$gamesDrawn'),
            buildBarSegment(
                gamesLost, lossColor.withOpacity(0.75), '$gamesLost')
          ],
        ),
      ),
    );
  }
}
