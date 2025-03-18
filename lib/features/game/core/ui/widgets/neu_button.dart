import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tic_tac_zwo/config/config.dart';

import '../../../../../config/constants.dart';

class NeuButton extends StatelessWidget {
  final String iconPath;
  final GameMode gameMode;
  final bool isNeuButtonPressed;
  final VoidCallback onTap;

  const NeuButton({
    super.key,
    required this.iconPath,
    required this.gameMode,
    required this.isNeuButtonPressed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Offset shadowOffset = Offset(10, 10);
    const double shadowBlurRadius = 10;
    const double shadowSpreadRadius = 1;

    final bool isWordleMode = gameMode == GameMode.wordle;

    final Color wordlePressedColor = Colors.grey[500]!;

    final Color neuButtonColor = isWordleMode
        ? (isNeuButtonPressed ? wordlePressedColor : Colors.black87)
        : colorGrey300;

    final Color textColor = isWordleMode
        ? colorWhite
        : (isNeuButtonPressed ? colorGrey500 : Colors.black87);

    final Color iconColor = isWordleMode
        ? colorWhite
        : (isNeuButtonPressed ? colorGrey500 : colorBlack);

    final Color borderColor = isWordleMode
        ? (isNeuButtonPressed ? colorGrey400 : Colors.black54)
        : (isNeuButtonPressed ? colorGrey100 : colorGrey300);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: neuButtonColor,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: borderColor,
          ),
          boxShadow: isNeuButtonPressed
              ? []
              : [
                  // bottom right shadow
                  BoxShadow(
                    color: colorGrey500,
                    offset: shadowOffset,
                    blurRadius: shadowBlurRadius,
                    spreadRadius: shadowSpreadRadius / 10,
                  ),

                  // top left shadow
                  BoxShadow(
                      color: colorGrey200,
                      offset: -shadowOffset,
                      blurRadius: shadowBlurRadius,
                      spreadRadius: shadowSpreadRadius),
                ],
        ),

        // game mode icons + name
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              height: 40,
              width: 40,
              iconPath,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),
            SizedBox(height: 10),
            Text(
              gameMode.string,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    color: textColor,
                  ),
            )
          ],
        ),
      ),
    );
  }
}
