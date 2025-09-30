import 'package:flutter/material.dart';

import '../../../../config/game_config/constants.dart';

class SettingsToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const SettingsToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 360),
        width: 72,
        height: 36,
        decoration: BoxDecoration(
          color: value ? activeColor : colorGrey500,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [
            // circle that moves (thumb)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: value ? 44 : 0,
              top: 0,
              child: Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(4),
                child: Container(
                  decoration: BoxDecoration(
                    color: value ? colorBlack : colorGrey600,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),

            // labels
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: value ? 8 : null,
              right: value ? null : 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: Text(
                  value ? 'ein' : 'aus',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: value
                          ? (activeColor == colorYellow
                              ? colorBlack
                              : colorWhite)
                          : colorWhite),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
