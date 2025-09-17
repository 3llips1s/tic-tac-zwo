import 'package:flutter/material.dart';

import '../../../../../config/game_config/constants.dart';

class GameBoardCell extends StatelessWidget {
  final Widget child;
  final bool isPressed;
  final Color cellColor;
  final bool isWinningCell;
  final bool isGameOver;

  const GameBoardCell({
    super.key,
    required this.child,
    this.isPressed = false,
    required this.cellColor,
    this.isWinningCell = false,
    this.isGameOver = false,
  });

  Color _getAdjustedColor() {
    if (!isGameOver) return cellColor;

    return isWinningCell
        ? cellColor
        : HSLColor.fromColor(cellColor).withSaturation(0.2).toColor();
  }

  @override
  Widget build(BuildContext context) {
    const Offset shadowOffset = Offset(7, 7);
    const double shadowBlurRadius = 8.5;
    const double shadowSpreadRadius = 1;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: _getAdjustedColor(),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
            color: isGameOver
                ? (isWinningCell ? cellColor : Colors.black12)
                : (isPressed ? colorGrey400 : cellColor),
            width: isWinningCell ? 2 : 1),
        boxShadow:
            (!isPressed && (!isGameOver || (isGameOver && isWinningCell)))
                ? [
                    // bottom right shadow
                    BoxShadow(
                      color: colorGrey500,
                      offset: shadowOffset,
                      blurRadius: shadowBlurRadius,
                      spreadRadius: shadowSpreadRadius,
                    ),

                    // top left shadow
                    BoxShadow(
                      color: colorGrey200,
                      offset: -shadowOffset,
                      blurRadius: 12,
                      spreadRadius: shadowSpreadRadius,
                    ),
                  ]
                : [],
      ),

      // game mode icons + name
      child: Center(child: child),
    );
  }
}
