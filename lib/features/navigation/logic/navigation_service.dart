import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/features/auth/data/services/auth_service.dart';
import 'package:tic_tac_zwo/features/auth/logic/auth_providers.dart';

import '../routes/route_names.dart';

class NavigationService {
  final AuthService _authService;

  NavigationService(this._authService);

  static const Set<String> _routesWithAuth = {
    RouteNames.leaderboard,
    RouteNames.profile,
  };

  void navigateFromDrawer({
    required BuildContext context,
    required String routeName,
  }) {
    if (_routesWithAuth.contains(routeName)) {
      _navigateAuthenticatedRoute(context, routeName);
    } else {
      _navigatePublicRoute(context, routeName);
    }
  }

  void _navigateAuthenticatedRoute(BuildContext context, String routeName) {
    final userId = _authService.currentUserId;

    if (userId != null) {
      _navigate(
          context: context,
          routeName: routeName,
          arguments: {'userId': userId});
    } else {
      _navigate(
        context: context,
        routeName: RouteNames.login,
      );
    }
  }

  void _navigatePublicRoute(BuildContext context, String routeName) {
    _navigate(
      context: context,
      routeName: routeName,
    );
  }

  void _navigate({
    required BuildContext context,
    required String routeName,
    Map<String, dynamic>? arguments,
  }) {
    try {
      Navigator.pushNamed(
        context,
        routeName,
        arguments: arguments,
      );
    } catch (e) {
      developer.log('Navigation failed for route: $routeName, Error: $e',
          name: 'navigation_service');
      Navigator.pushReplacementNamed(context, RouteNames.home);
    }
  }
}

// create navigation service instance
// inject auth service automatically
final navigationSErviceProvider = Provider<NavigationService>(
  (ref) {
    final authService = ref.watch(authServiceProvider);
    return NavigationService(authService);
  },
);
