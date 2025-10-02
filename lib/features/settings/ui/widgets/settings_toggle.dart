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
    const double toggleWidth = 72;
    const double toggleHeight = 32;
    const double thumbSize = 20;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: toggleWidth,
        height: toggleHeight,
        decoration: BoxDecoration(
          color: value ? activeColor : colorGrey500,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [
            // circle that moves (thumb)
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: thumbSize,
                height: thumbSize,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: value
                      ? (activeColor == colorYellow ? colorBlack : colorGrey300)
                      : colorGrey600,
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // labels
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: value ? 12 : null,
              right: value ? null : 12,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
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
              ),
            )
          ],
        ),
      ),
    );
  }
}
