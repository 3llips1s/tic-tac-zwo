import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tic_tac_zwo/config/constants.dart';

class AppTitle extends StatefulWidget {
  const AppTitle({super.key});

  @override
  State<AppTitle> createState() => _AppTitleState();
}

class _AppTitleState extends State<AppTitle> {
  static bool _hasAnimatedOnce = false;

  final List<bool> _isTitleTileVisible =
      List.generate(appTitleString.length, (index) => false);
  final List<int> _remainingTileIndices =
      List.generate(appTitleString.length, (index) => index);

  @override
  void initState() {
    super.initState();
    if (!_hasAnimatedOnce) {
      _startTitleAnimation();
      _hasAnimatedOnce = true;
    } else {
      // show all immediately if already animated once
      setState(() {
        for (int i = 0; i < _isTitleTileVisible.length; i++) {
          _isTitleTileVisible[i] = true;
        }
        _remainingTileIndices.clear();
      });
    }
  }

  void _startTitleAnimation() async {
    final random = Random();

    await Future.delayed(const Duration(milliseconds: 300));

    while (_remainingTileIndices.isNotEmpty) {
      if (!mounted) return;

      setState(() {
        // pick a random position from remaining array
        final randomIndex = random.nextInt(_remainingTileIndices.length);

        // pick the index at picked position
        final indexToShow = _remainingTileIndices[randomIndex];

        // show the tile at the index
        _isTitleTileVisible[indexToShow] = true;

        // remove index from remaining indices
        _remainingTileIndices.removeAt(randomIndex);
      });

      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Center(
      heightFactor: screenHeight <= 700 ? 1.6 : 2.4,
      child: SizedBox(
        height: 200,
        width: 200,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: appTitleString.length,
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            Color titleTileColor;
            Color titleTextColor;

            if (index < 3) {
              titleTileColor = colorBlack;
              titleTextColor = colorWhite;
            } else if (index > 2 && index < 6) {
              titleTileColor = colorRed;
              titleTextColor = colorWhite;
            } else {
              titleTileColor = colorYellow;
              titleTextColor = colorBlack;
            }

            // elevated title tile
            return AnimatedOpacity(
              opacity: _isTitleTileVisible[index] ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCirc,
              child: Container(
                decoration: BoxDecoration(
                  color: titleTileColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colorGrey500,
                      spreadRadius: 0.5,
                      blurRadius: 15,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    appTitleString[index],
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 30,
                          color: titleTextColor,
                        ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// app title
final appTitleString = <String>['T', 'I', 'C', 'T', 'A', 'C', 'Z', 'W', 'Ö'];
