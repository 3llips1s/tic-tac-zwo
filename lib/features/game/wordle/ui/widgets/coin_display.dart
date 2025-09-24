import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../../config/game_config/constants.dart';

class CoinDisplay extends StatelessWidget {
  final int coinCount;
  final bool useContainer;
  final String? svgAssetPath;

  const CoinDisplay({
    super.key,
    required this.coinCount,
    this.useContainer = false,
    this.svgAssetPath = 'assets/images/coins_dark.svg',
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (svgAssetPath != null)
          SvgPicture.asset(
            svgAssetPath!,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              useContainer ? colorBlack : colorGrey400,
              BlendMode.srcIn,
            ),
          )
        else
          Icon(
            Icons.monetization_on_rounded,
            size: 24,
            color: useContainer ? colorBlack : colorWhite,
          ),
        const SizedBox(width: 4),
        Text(
          '$coinCount',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: useContainer ? colorBlack : colorGrey400,
              ),
        )
      ],
    );

    if (useContainer) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorWhite,
          borderRadius: BorderRadius.circular(9),
        ),
        child: content,
      );
    }

    return content;
  }
}
