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

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: colorGrey300,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isNeuButtonPressed ? colorGrey100 : colorGrey300,
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
              colorFilter: ColorFilter.mode(
                  isNeuButtonPressed ? colorGrey500 : colorBlack,
                  BlendMode.srcIn),
            ),
            SizedBox(height: 10),
            Text(
              gameMode.string,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: isNeuButtonPressed ? colorGrey500 : Colors.black87,
                  ),
            )
          ],
        ),
      ),
    );
  }
}
