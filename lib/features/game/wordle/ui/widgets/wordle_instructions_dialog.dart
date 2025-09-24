import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import '../../../../../config/game_config/constants.dart';
import '../../../core/ui/widgets/glassmorphic_dialog.dart';

class WordleInstructionsDialog extends StatelessWidget {
  final VoidCallback onClose;

  const WordleInstructionsDialog({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 560,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                'Wördle',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorBlack,
                    ),
              ),
              const SizedBox(height: 20),

              // Instructions
              Text(
                'Errate das 5-Buchstaben Wort:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorBlack,
                    ),
              ),
              const SizedBox(height: 10),

              // Noun requirement rule with hint icon
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 20,
                    color: colorYellowAccent,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Alle Wörter sind NOMEN',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: colorYellowAccent,
                        ),
                  ),
                ],
              ),

              const SizedBox(height: 35),

              // Example tiles - in a Column (stacked vertically)
              Column(
                children: [
                  // Correct position example
                  _buildExampleRow(
                    context: context,
                    letter: 'Z',
                    color: Colors.green,
                    explanation: 'Richtiger Buchstabe an richtiger Stelle',
                  ),
                  const SizedBox(height: 25),

                  // Wrong position example
                  _buildExampleRow(
                    context: context,
                    letter: 'W',
                    color: colorYellow,
                    explanation: 'Buchstabe im Wort aber falsche Stelle',
                  ),
                  const SizedBox(height: 25),

                  // Not in word example
                  _buildExampleRow(
                    context: context,
                    letter: 'Ö',
                    color: Colors.grey,
                    explanation: 'Buchstabe nicht im Wort',
                  ),
                ],
              ),

              const SizedBox(height: 42),

              Text(
                '🪙  Münzen System:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorBlack,
                    ),
              ),

              const SizedBox(height: 30),

              _buildCoinExplanationRow(
                  context: context,
                  icon: Icons.emoji_events_rounded,
                  iconColor: Colors.grey,
                  explanation:
                      'Verdiene 50 bis 5 Münzen - je nach deinen Versuchen'),
              const SizedBox(height: 20),

              _buildCoinExplanationRow(
                  context: context,
                  icon: Icons.star_rounded,
                  iconColor: colorYellowAccent,
                  explanation: '+5 Bonus ohne Hinweise!'),
              const SizedBox(height: 20),

              _buildCoinExplanationRow(
                context: context,
                icon: Icons.lightbulb_rounded,
                iconColor: Colors.green,
                explanation: 'Hinweise: 1. kostet 30 🪙 und 2. kostet 50 🪙',
              ),

              const SizedBox(height: 45),

              // Close button
              GlassMorphicButton(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 18),
                onPressed: onClose,
                child: Text(
                  'Los geht\'s!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorYellowAccent,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Returns a Row with the tile and explanation side by side
  Widget _buildExampleRow({
    required BuildContext context,
    required String letter,
    required Color color,
    required String explanation,
  }) {
    return Row(
      children: [
        // Letter tile
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              letter,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorWhite,
                  ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Explanation text
        Expanded(
          child: Text(
            explanation,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorBlack,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoinExplanationRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String explanation,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(21),
          ),
          child: Icon(
            icon,
            size: 18,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            explanation,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorBlack,
                ),
          ),
        )
      ],
    );
  }
}

class WordleInstructionsManager {
  static const String _preferencesBoxName = 'user_preferences';
  static const String _hasSeenInstructionsKey = 'has_seen_wordle_instructions';

  // check if use has seen instructions
  static Future<bool> hasSeenInstructions() async {
    final box = await Hive.openBox(_preferencesBoxName);
    return box.get(_hasSeenInstructionsKey, defaultValue: false);
  }

  static Future<void> markInstructionsAsSeen() async {
    final box = await Hive.openBox(_preferencesBoxName);
    await box.put(_hasSeenInstructionsKey, true);
  }

  // show dialog
  static Future<void> showInstructionsDialog(BuildContext context) async {
    if (await hasSeenInstructions()) return;

    if (context.mounted) {
      await showCustomDialog(
        context: context,
        barrierDismissible: true,
        width: 300,
        height: 600,
        child: WordleInstructionsDialog(
          onClose: () {
            Navigator.of(context).pop();
            markInstructionsAsSeen();
          },
        ),
      );
    }
  }
}
