import 'package:flutter/material.dart';

import '../../../../../config/game_config/constants.dart';
import '../widgets/app_title.dart';
import '../widgets/mode_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomePageState();
}

class _HomePageState extends State<HomeScreen> {
  double _xOffset = 0;
  double _yOffset = 0;
  double _scaleFactor = 1;
  bool _isDrawerOpen = false;

  // toggle drawer
  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
      _xOffset = _isDrawerOpen ? 225 : 0;
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
                    offset: const Offset(-10, 10),
                    blurRadius: 15,
                  )
                ]
              : []),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 0, top: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // app title
            AppTitle(),

            // mode menu
            ModeMenu(),

            // menu icon
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 10, bottom: 10, top: 10),
                child: IconButton(
                  onPressed: _toggleDrawer,
                  icon: _isDrawerOpen
                      ? const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.black45,
                          size: 28,
                        )
                      : const Icon(
                          Icons.filter_none_rounded,
                          color: Colors.black45,
                          size: 24,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
