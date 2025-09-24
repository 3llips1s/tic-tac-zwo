import 'package:flutter/material.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/glassmorphic_dialog.dart';

class HintConfirmationDialog extends StatelessWidget {
  final int hintNumber;
  final int hintCost;
  final int currentCoins;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const HintConfirmationDialog({
    super.key,
    required this.hintNumber,
    required this.hintCost,
    required this.currentCoins,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // title
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            'Hinweis $hintNumber  •  $hintCost 🪙',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorBlack,
                ),
          ),
        ),

        const SizedBox(height: 32),

        // current balance
        Text(
          'Verfügbar: $currentCoins',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                color: colorBlack.withOpacity(0.5),
              ),
        ),

        const SizedBox(height: 40),

        // actions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // cancel
            GlassMorphicButton(
              onPressed: onCancel,
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.close_rounded,
                color: colorRed,
                size: 30,
              ),
            ),
            // confirm
            GlassMorphicButton(
              onPressed: onConfirm,
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.check_rounded,
                color: colorDarkGreen,
                size: 30,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}
