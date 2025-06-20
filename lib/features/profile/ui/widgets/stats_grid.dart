import 'package:flutter/material.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
import 'package:tic_tac_zwo/features/profile/data/models/user_profile.dart';

class StatsGrid extends StatelessWidget {
  final UserProfile userProfile;

  const StatsGrid({super.key, required this.userProfile});

  String _formatPercentage(double value, [int decimals = 1]) {
    return '${(value * 100).toStringAsFixed(decimals)}%';
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: [
        _StatCard(
          label: 'Spiele',
          value: userProfile.gamesPlayed.toString(),
        ),
        _StatCard(
          label: 'Punkte',
          value: userProfile.points.toString(),
        ),
        _StatCard(
          label: 'Artikelgenauigkeit',
          value: _formatPercentage(userProfile.articleAccuracy),
        ),
        _StatCard(
          label: 'Siegquote',
          value: _formatPercentage(userProfile.winRate),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

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
              offset: Offset(5, 5),
              blurRadius: 5,
              spreadRadius: 0.1,
            ),
            BoxShadow(
                color: colorGrey200,
                offset: -Offset(5, 5),
                blurRadius: 5,
                spreadRadius: 0.1),
          ]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: colorBlack),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  color: colorGrey600,
                ),
          )
        ],
      ),
    );
  }
}
