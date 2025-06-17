import 'package:flutter/material.dart';

import '../../../../../config/game_config/constants.dart';
import '../widgets/app_title.dart';
import '../widgets/mode_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _xOffset = 0;
  double _yOffset = 0;
  double _scaleFactor = 1;
  bool _isDrawerOpen = false;

  // toggle drawer
  void toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
      _xOffset = _isDrawerOpen ? -225 : 0;
      _yOffset = _isDrawerOpen ? 86.5 : 0;
      _scaleFactor = _isDrawerOpen ? 0.8 : 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 900),
      curve: Curves.decelerate,
      transform: Matrix4.translationValues(_xOffset, _yOffset, 0)
        ..scale(_scaleFactor),
      decoration: BoxDecoration(
          color: colorGrey300,
          borderRadius: BorderRadius.circular(
            _isDrawerOpen ? 30 : 0,
          ),
          boxShadow: _isDrawerOpen
              ? [
                  BoxShadow(
                    color: Colors.grey.shade100.withAlpha((255 / 0.4).toInt()),
                    offset: const Offset(10, 10),
                    blurRadius: 15,
                  )
                ]
              : []),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // app title
          AppTitle(),

          // mode menu
          ModeMenu(),

          // menu icon
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20, bottom: 20),
              child: IconButton(
                onPressed: toggleDrawer,
                icon: _isDrawerOpen
                    ? const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.black45,
                        size: 28,
                      )
                    : const Icon(
                        Icons.more_vert_rounded,
                        color: Colors.black45,
                        size: 24,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
