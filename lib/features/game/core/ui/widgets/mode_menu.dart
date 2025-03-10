import 'package:flutter/material.dart';

import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';

import '../../../../../config/config.dart';
import '../../../../../config/constants.dart';
import '../../../../../routes/route_names.dart';
import 'neu_button.dart';

class ModeMenu extends StatefulWidget {
  const ModeMenu({super.key});

  @override
  State<ModeMenu> createState() => _ModeMenuState();
}

class _ModeMenuState extends State<ModeMenu> {
  bool _isMenuVisible = false;
  final NearbyService _nearbyService = NearbyService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startMenuAnimation();
    });
  }

  void _startMenuAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _isMenuVisible = true;
    });
  }

  // navigate to turn selection
  int? _pressedNeuButtonIndex;

  void _handleMenuButtonTap(int index) async {
    if (_pressedNeuButtonIndex != index) {
      setState(() {
        _pressedNeuButtonIndex = index;
      });

      await Future.delayed(const Duration(milliseconds: 200));

      if (mounted) {
        if (gameModeIcons[index]['gameMode'] == GameMode.pair) {
          /*  // check BT before navigating
          final bluetoothState = await  ;
          if (bluetoothState == off) {
            _showSnackBar('Bluetooth aus. Bitte einschalten.');
            setState(() => _pressedNeuButtonIndex = null);
            return;
          } */
          await Navigator.pushNamed(context, RouteNames.deviceScan);
        } else {
          await Navigator.pushNamed(
            context,
            RouteNames.turnSelection,

            // pass selected game mode
            arguments: {'gameMode': gameModeIcons[index]['gameMode']},
          );
        }

        if (mounted) {
          setState(() {
            _pressedNeuButtonIndex = null;
          });
        }
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        margin: EdgeInsets.only(
          bottom: kToolbarHeight * 2,
          left: 40,
          right: 40,
        ),
        content: Container(
            padding: EdgeInsets.all(12),
            height: kToolbarHeight,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.all(Radius.circular(9)),
              boxShadow: [
                BoxShadow(
                  color: colorGrey300,
                  blurRadius: 7,
                  offset: Offset(7, 7),
                ),
              ],
            ),
            child: Center(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorWhite,
                    ),
              ),
            )
            // message

            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      width: 250,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: gameModeIcons.length,
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 45,
          crossAxisSpacing: 45,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          return AnimatedOpacity(
            opacity: _isMenuVisible ? 1 : 0,
            duration: Duration(milliseconds: 900),
            curve: Curves.easeIn,
            child: NeuButton(
              iconPath: gameModeIcons[index]['imagePath'],
              gameMode: gameModeIcons[index]['gameMode'],
              isNeuButtonPressed: _pressedNeuButtonIndex == index,
              onTap: () => _handleMenuButtonTap(index),
            ),
          );
        },
      ),
    );
  }
}

// list of game modes
final gameModeIcons = <Map<String, dynamic>>[
  {
    'imagePath': 'assets/images/pass.svg',
    'gameMode': GameMode.pass,
  },
  {
    'imagePath': 'assets/images/offline.svg',
    'gameMode': GameMode.offline,
  },
  {
    'imagePath': 'assets/images/pair.svg',
    'gameMode': GameMode.pair,
  },
  {
    'imagePath': 'assets/images/online.svg',
    'gameMode': GameMode.online,
  }
];
