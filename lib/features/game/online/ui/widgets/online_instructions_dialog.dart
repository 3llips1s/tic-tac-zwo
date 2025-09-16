import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/glassmorphic_dialog.dart';

class OnlineInstructionsDialog extends StatelessWidget {
  final VoidCallback onClose;

  const OnlineInstructionsDialog({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),

          // Title
          Text(
            'Online Hausregeln',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorBlack,
                ),
          ),
          const SizedBox(height: 24),

          // points
          _buildSectionTitle(context, 'Punkesystem:'),
          const SizedBox(height: 16),
          _buildRuleItem(
            context: context,
            icon: Icons.check_circle_rounded,
            iconColor: Colors.green,
            text: '1 Punkt für jeden richtigen Artikel',
          ),
          const SizedBox(height: 12),
          _buildRuleItem(
            context: context,
            icon: Icons.emoji_events_rounded,
            iconColor: colorYellowAccent,
            text: '3 Bonuspunkte für einen Sieg',
          ),
          const SizedBox(height: 12),
          _buildRuleItem(
            context: context,
            icon: Icons.handshake_outlined,
            iconColor: colorGrey600,
            text: '1 Bonuspunkt für ein Unentschieden',
          ),
          const SizedBox(height: 36),

          // time limits
          _buildSectionTitle(context, 'Zeitlimits:'),
          const SizedBox(height: 16),
          _buildRuleItem(
            context: context,
            icon: Icons.hourglass_top_rounded,
            iconColor: Colors.amberAccent,
            text: '9 Sekunden um ein Feld zu wählen',
          ),
          const SizedBox(height: 12),
          _buildRuleItem(
            context: context,
            icon: Icons.timer_rounded,
            iconColor: colorRed,
            text: '9 Sekunden um den Artikel zu wählen',
          ),
          const SizedBox(height: 40),

          // close
          GlassMorphicButton(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 17.5),
            onPressed: onClose,
            child: Text(
              'Verstanden!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorYellowAccent,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorBlack,
            ),
      ),
    );
  }

  Widget _buildRuleItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 22,
          color: iconColor,
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                color: colorBlack,
              ),
        ))
      ],
    );
  }
}

class OnlineInstructionsManager {
  static const String _preferencesBox = 'user_preferences';
  static const String _hasSeenOnlineInstructionsKey =
      'has_seen_online_instructions';

  static Future<bool> hasSeenInstructions() async {
    final box = await Hive.openBox(_preferencesBox);
    return box.get(_hasSeenOnlineInstructionsKey, defaultValue: false);
  }

  static Future<void> markInstructionsAsSeen() async {
    final box = await Hive.openBox(_preferencesBox);
    await box.put(_hasSeenOnlineInstructionsKey, true);
  }

  static Future<void> showInstructionsDialog(BuildContext context) async {
    if (await hasSeenInstructions()) return;

    if (context.mounted) {
      await showCustomDialog(
        context: context,
        barrierDismissible: false,
        width: 320,
        height: 500,
        child: OnlineInstructionsDialog(
          onClose: () {
            Navigator.of(context).pop();
            markInstructionsAsSeen();
          },
        ),
      );
    }
  }
}
