import 'package:flutter/material.dart';

import 'features/game/core/ui/screens/home_screen.dart';
import 'features/navigation/ui/hidden_drawer.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool _isDrawerOpen = false;

  void toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          HiddenDrawer(),
          HomeScreen(),
        ],
      ),
    );
  }
}
