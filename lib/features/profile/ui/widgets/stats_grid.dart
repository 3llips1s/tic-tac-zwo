import 'package:flutter/material.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
import 'package:tic_tac_zwo/features/profile/data/models/user_profile.dart';

class StatsGrid extends StatelessWidget {
  final UserProfile userProfile;

  const StatsGrid({super.key, required this.userProfile});

  String _formatPercentage(double value, [int decimals = 1]) {
    return '${(value * 100).toStringAsFixed(decimals)}%';
  }

  Color _getColorForPercentage(double value) {
    if (value > 0.8) return Colors.green.shade700;
    if (value > 0.4) return Colors.yellow.shade900;
    return Colors.red.shade700;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 300,
        width: 300,
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1,
          children: [
            _StatCard(
              label: 'Punkte',
              value: userProfile.points.toString(),
            ),
            _StatCard(
              label: 'Siegquote',
              value: _formatPercentage(userProfile.winRate),
              valueColor: _getColorForPercentage(userProfile.winRate),
            ),
            _StatCard(
              label: 'Artikel Acc.',
              value: _formatPercentage(userProfile.articleAccuracy),
              valueColor: _getColorForPercentage(userProfile.articleAccuracy),
            ),
            _StatCard(
              label: 'Spiele',
              value: userProfile.gamesPlayed.toString(),
              valueColor: Colors.brown,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatCard(
      {required this.label, required this.value, this.valueColor = colorBlack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
          color: colorGrey300,
          borderRadius: BorderRadius.circular(9.0),
          border: Border.all(
            color: colorGrey300,
          ),
          boxShadow: [
            BoxShadow(
              color: colorGrey500,
              offset: Offset(3, 3),
              blurRadius: 3,
              spreadRadius: 0.3,
            ),
            BoxShadow(
                color: colorGrey200,
                offset: -Offset(3, 3),
                blurRadius: 3,
                spreadRadius: 0.3),
          ]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorGrey600,
                ),
          )
        ],
      ),
    );
  }
}
