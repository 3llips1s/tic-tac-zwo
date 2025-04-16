import 'package:flutter/material.dart';
// import 'package:hive/hive.dart';
import '../../../../../config/game_config/constants.dart';
import '../../../core/ui/widgets/glassmorphic_dialog.dart';

class WordleInstructionsDialog extends StatelessWidget {
  final VoidCallback onClose;

  const WordleInstructionsDialog({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
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
          const SizedBox(height: 45),

          // Close button
          GlassMorphicButton(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 17.5),
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
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colorBlack,
                ),
          ),
        ),
      ],
    );
  }
}

class WordleInstructionsManager {
  static const String _preferencesBoxName = 'user_preferences';
  static const String _hasSeenInstructionsKey = 'has_seen_wordle_instructions';

  static bool _hasSeenInstructionsTest = false;

  // check if use has seen instructions
  static Future<bool> hasSeenInstructions() async {
    return _hasSeenInstructionsTest;

    /* 
    final box = await Hive.openBox(_preferencesBoxName);
    return box.get(_hasSeenInstructionsKey, defaultValue: false);
     */
  }

  static Future<void> markInstructionsAsSeen() async {
    _hasSeenInstructionsTest = true;

    /* 
    final box = await Hive.openBox(_preferencesBoxName);
    await box.put(_hasSeenInstructionsKey, true);
     */
  }

  // show dialog
  static Future<void> showInstructionsDialog(BuildContext context) async {
    if (await hasSeenInstructions()) return;

    if (context.mounted) {
      await showCustomDialog(
        context: context,
        barrierDismissible: false,
        width: 300,
        height: 500,
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
