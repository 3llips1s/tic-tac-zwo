import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/dual_progress_indicator.dart';
import 'package:tic_tac_zwo/features/navigation/routes/route_names.dart';
import 'package:tic_tac_zwo/features/profile/data/models/game_history_entry.dart';
import 'package:tic_tac_zwo/features/profile/logic/user_profile_providers.dart';
import 'package:tic_tac_zwo/features/profile/ui/widgets/avatar_flag.dart';

import '../../../../config/game_config/constants.dart';

class GamesHistoryList extends ConsumerWidget {
  final String userId;

  const GamesHistoryList({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesHistoryAsync = ref.watch(gamesHistoryProvider(userId));
    return gamesHistoryAsync.when(
      loading: () => const Center(child: DualProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text(
          'Spielverlauf konnte nicht geladen werden.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorGrey600,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
        ),
      ),
      data: (history) {
        if (history.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Du hast noch keine online Spiele gespielt.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorGrey600,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
              ),
            ),
          );
        }
        return ListView.separated(
          itemCount: history.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (context, index) => const SizedBox(height: 8.0),
          itemBuilder: (context, index) {
            return _GameHistoryTile(entry: history[index])
                .animate(delay: (2700 + (index * 100)).ms)
                .slideX(
                  begin: -0.3,
                  curve: Curves.easeInOut,
                  duration: 600.ms,
                )
                .fadeIn(
                  duration: 600.ms,
                  curve: Curves.easeInOut,
                );
          },
        );
      },
    );
  }
}

class _GameHistoryTile extends StatelessWidget {
  final GameHistoryEntry entry;

  const _GameHistoryTile({required this.entry});

  (Color, String) _getResultStyle() {
    switch (entry.result) {
      case 'Win':
        return (winColor, 'S');
      case 'Draw':
        return (drawColor, 'U');
      case 'Loss':
        return (lossColor, 'N');
      default:
        return (drawColor, 'N');
    }
  }

  @override
  Widget build(BuildContext context) {
    final (resultColor, resultText) = _getResultStyle();

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () {
        Navigator.of(context).pushNamed(RouteNames.profile,
            arguments: {'userId': entry.opponentId});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        decoration: BoxDecoration(
          color: colorWhite,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: colorGrey300,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              'Du',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorGrey500,
                  ),
            ),
            const SizedBox(width: 16),
            Text(
              ' vs. ',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorGrey400,
                  ),
            ),
            const SizedBox(width: 16),

            // opponent avatar
            AvatarFlag(
                radius: 14,
                avatarUrl: entry.opponentAvatarUrl,
                countryCode: entry.opponentCountryCode),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                entry.opponentUsername,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: resultColor,
                borderRadius: BorderRadius.circular(3.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
