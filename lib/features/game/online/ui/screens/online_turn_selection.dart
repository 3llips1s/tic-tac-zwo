import 'package:flutter/material.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';

class OnlineTurnSelection extends StatefulWidget {
  const OnlineTurnSelection({super.key});

  @override
  State<OnlineTurnSelection> createState() => _OnlineTurnSelectionState();
}

class _OnlineTurnSelectionState extends State<OnlineTurnSelection> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorGrey300,
      appBar: AppBar(),
    );
  }
}
