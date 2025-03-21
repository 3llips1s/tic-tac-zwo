import 'package:flutter/material.dart';

import 'features/game/core/ui/screens/home_screen.dart';
import 'features/navigation/ui/hidden_drawer.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          HiddenDrawer(),
          HomeScreen(),
        ],
      ),
    );
  }
}
