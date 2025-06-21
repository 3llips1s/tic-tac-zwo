import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../widgets/app_title.dart';
import '../widgets/mode_menu.dart';

class HomeScreen extends StatefulWidget {
  final bool isDrawerOpen;
  final VoidCallback onToggleDrawer;

  const HomeScreen({
    super.key,
    this.isDrawerOpen = false,
    this.onToggleDrawer = _defaultToggle,
  });

  static void _defaultToggle() {}

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/background.webp'), context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
            padding: const EdgeInsets.only(right: 8, bottom: 16),
            child: IconButton(
              onPressed: widget.onToggleDrawer,
              icon: widget.isDrawerOpen
                  ? SvgPicture.asset(
                      'assets/images/close_menu.svg',
                      colorFilter: const ColorFilter.mode(
                          Colors.black87, BlendMode.srcIn),
                      height: 40,
                      width: 40,
                    )
                  : SvgPicture.asset(
                      'assets/images/open_menu.svg',
                      colorFilter: const ColorFilter.mode(
                          Colors.black54, BlendMode.srcIn),
                      height: 40,
                      width: 40,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
