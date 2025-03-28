import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('assets/images/background.jpg'),
                  fit: BoxFit.cover),
            ),
          ),
          Container(color: colorBlack.withAlpha((255 * 0.7).toInt())),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 400,
                  width: 300,
                  decoration: BoxDecoration(
                    color: colorWhite.withAlpha((255 * 0.1).toInt()),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorWhite.withAlpha((255 * 0.1).toInt()),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicatorWeight: 1,
                        indicator: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [colorGrey100, colorGrey600],
                          ),
                        ),
                        dividerColor: Colors.transparent,
                        tabs: [Tab(text: 'einloggen'), Tab(text: 'anmelden')],
                        labelColor: colorBlack,
                        labelStyle:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                        unselectedLabelColor: colorGrey500,
                        unselectedLabelStyle:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 16,
                                ),
                      ),
                      Expanded(
                        child: TabBarView(
                            controller: _tabController,
                            children: [_buildSignupTab(), _buildLoginTab()]),
                      )
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  _buildLoginTab() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // _buildGoogleIcon(),
              SizedBox(width: 10),
              if (Platform.isIOS)
                // _buildAppleIcon(),
                SizedBox(width: 10),
            ],
          )
        ],
      ),
    );
  }

  _buildSignupTab() {
    return Padding(padding: EdgeInsets.all(20));
  }
}
