import 'dart:async';
import 'dart:math';

import 'package:device_scan_animation/device_scan_animation.dart';
import 'package:flutter/material.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../config/game_config/config.dart';

class DeviceScanScreen extends ConsumerStatefulWidget {
  const DeviceScanScreen({super.key});

  @override
  ConsumerState<DeviceScanScreen> createState() => _DeviceScanScreenState();
}

class _DeviceScanScreenState extends ConsumerState<DeviceScanScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanning = true;
  Timer? _scanTimer;

  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;

  @override
  void initState() {
    super.initState();
    _initHoverAnimation();
  }

  void _initHoverAnimation() {
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _hoverAnimation = Tween<double>(
      begin: 3,
      end: 9,
    ).animate(
      CurvedAnimation(
        parent: _hoverController,
        curve: Curves.easeInOut,
      ),
    );

    _hoverController.repeat(reverse: true);
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
    final textTheme = Theme.of(context).textTheme;

    // devices is temp var before full implementation
    final devices = [];

    return Scaffold(
      backgroundColor: colorGrey300,
      body: Padding(
        padding: const EdgeInsets.only(top: 10.0, bottom: kToolbarHeight / 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // game mode title
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: SizedBox(
                height: kToolbarHeight * 2,
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    // might need to change this down the line
                    GameMode.online.string,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
            ),

            SizedBox(height: kToolbarHeight * 2),

            // device scan animation
            if (_isScanning)
              DeviceScanWidget(
                gap: 50,
                layers: 3,
                nodeType: NodeType.all,
                duration: const Duration(seconds: 3),
                newNodesDuration: const Duration(seconds: 3),
                ringThickness: 1,
                ringColor: colorGrey400,
                centerNodeColor: Colors.black45,
                nodeColor: colorRed,
                scanColor: colorYellowAccent,
              ),

            SizedBox(height: kToolbarHeight * 2),

            Expanded(
              child: Random().nextBool() // change this boolean
                  ? Padding(
                      padding: _isScanning
                          ? EdgeInsets.zero
                          : EdgeInsets.only(bottom: kToolbarHeight * 4),
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _hoverAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _hoverAnimation.value),
                              child: Center(
                                child: Text(
                                  _isScanning
                                      ? 'Suche nach Gerät...'
                                      : 'Kein Gerät gefunden!',
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        return ListTile(
                          title: Text(
                              device.deviceName.isNotEmpty
                                  ? device.deviceName
                                  : 'Unbekanntes Gerät',
                              style: textTheme.bodyMedium),
                          onTap: () async {
                            _showSnackBar('Verbindung wird hergestellt...');

                            print('waiting for connection confirmation');
                          },
                        );
                      },
                    ),
            ),

            if (!_isScanning && devices.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: OutlinedButton(
                  onPressed:
                      _initHoverAnimation, // change this on pressed function
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                    overlayColor: colorBlack,
                    side: BorderSide(
                      color: Colors.black87,
                    ),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
                    child: Text(
                      'erneut scannen',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorBlack,
                            fontSize: 20,
                          ),
                    ),
                  ),
                ),
              ),

            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 20, top: 20),
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: colorWhite,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _scanTimer?.cancel();
    super.dispose();
  }
}
