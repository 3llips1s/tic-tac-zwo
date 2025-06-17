import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tic_tac_zwo/features/auth/data/services/auth_service.dart';
import 'package:tic_tac_zwo/features/auth/ui/widgets/flag.dart';

import '../../../config/game_config/constants.dart';
import '../routes/route_names.dart';

class HiddenDrawer extends StatefulWidget {
  const HiddenDrawer({super.key});

  @override
  State<HiddenDrawer> createState() => _HiddenDrawerState();
}

class _HiddenDrawerState extends State<HiddenDrawer> {
  final authService = AuthService();

  final String _defaultDisplayName = 'User${Random().nextInt(100000)}';
  final String _defaultCountryCode = '';

  late String displayName;
  late String countryCode;
  late StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();

    displayName = _defaultDisplayName;
    countryCode = _defaultCountryCode;

    _loadUserProfile();

    // listen to auth changes
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        if (data.event == AuthChangeEvent.signedIn) {
          _loadUserProfile();
        } else if (data.event == AuthChangeEvent.signedOut) {
          setState(() {
            displayName = _defaultDisplayName;
            countryCode = _defaultCountryCode;
          });
        }
      },
    );
  }

  void _logout() async {
    if (mounted) {
      Navigator.pushNamed(context, RouteNames.home);
      _showSnackBar('Du wurdest ausgeloggt.');
    }
    if (authService.isAuthenticated) {
      await authService.signOut();
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.pushNamed(context, RouteNames.home);
      Future.delayed(Duration(milliseconds: 300));
      Navigator.pushNamed(context, RouteNames.login);
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
          left: 40,
          right: 40,
        ),
        content: Container(
          padding: EdgeInsets.all(12),
          height: kToolbarHeight,
          decoration: BoxDecoration(
            color: colorBlack,
            borderRadius: BorderRadius.all(Radius.circular(9)),
          ),
          child: Center(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorWhite,
                  ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadUserProfile() async {
    final Map<String, dynamic>? userProfile =
        await AuthService().getUserProfile();

    if (userProfile != null && userProfile.containsKey('username')) {
      setState(() {
        displayName = userProfile['username'] as String;
        countryCode = userProfile['country_code'] as String;
      });
    } else {
      setState(() {
        displayName = _defaultDisplayName;
        countryCode = _defaultCountryCode;
      });
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.only(
          top: 25,
          bottom: 30,
          right: 40,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // user profile
            Padding(
              padding: EdgeInsets.only(top: kToolbarHeight / 1.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                      padding: EdgeInsets.all(9),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: colorYellowAccent),
                      child: Icon(
                        Icons.face_5_rounded,
                        size: 25,
                      )),
                  const SizedBox(width: 15),
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorYellowAccent,
                          fontSize: 20.0,
                        ),
                  ),
                  const SizedBox(width: 10),
                  Flag(
                    countryCode: countryCode,
                    height: 16,
                    width: 24,
                  )
                ],
              ),
            ),

            // menu
            Column(
              children: drawerItems
                  .map(
                    (drawerItem) => InkWell(
                      onTap: () {
                        final routeName = drawerItem['route'] as String;

                        if (routeName == RouteNames.leaderboard) {
                          final userId = authService.currentUserId;
                          if (userId != null) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              routeName,
                              (route) => false,
                              arguments: {'userId': userId},
                            );
                          }
                        } else {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            routeName,
                            (route) => false,
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              drawerItem['title'],
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: colorWhite, fontSize: 16),
                            ),
                            const SizedBox(
                              width: 15,
                            ),
                            Icon(
                              drawerItem['icon'],
                              color: colorYellowAccent,
                              size: 30,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),

            GestureDetector(
              onTap: authService.isAuthenticated ? _logout : _navigateToLogin,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // logout
                  Icon(
                    Icons.logout_rounded,
                    color: colorRed,
                    size: 26,
                  ),

                  const SizedBox(width: 10),
                  Text(
                    authService.isAuthenticated ? 'ausloggen' : 'einloggen',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colorWhite, fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final drawerItems = <Map<String, dynamic>>[
  {
    'icon': Icons.leaderboard_rounded,
    'title': 'l e a d e r b o a r d',
    'route': RouteNames.leaderboard,
  },
  {
    'icon': Icons.favorite_rounded,
    'title': 'w o r t s c h a t z',
    'route': RouteNames.wortschatz,
  },
  {
    'icon': Icons.info_outline_rounded,
    'title': 'i n f o',
    'route': RouteNames.info,
  }
];
