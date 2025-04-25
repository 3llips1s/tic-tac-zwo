import 'package:flutter/material.dart';
import 'package:tic_tac_zwo/features/auth/ui/screens/login_screen.dart';
import 'package:tic_tac_zwo/features/game/core/data/models/game_config.dart';
import 'package:tic_tac_zwo/features/game/online/ui/screens/matchmaking_screen.dart';
import 'package:tic_tac_zwo/features/game/online/ui/screens/online_turn_selection_screen.dart';
import 'package:tic_tac_zwo/features/game/wordle/ui/screens/wordle_game_screen.dart';

import '../../../config/game_config/config.dart';
import '../../game/core/ui/screens/game_screen.dart';
import '../../game/core/ui/screens/home_screen.dart';
import '../../game/core/ui/screens/turn_selection_screen.dart';
import 'route_names.dart';

class AppRouter {
  // private constructor to prevent instantiation
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // home
      case RouteNames.home:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );

      // turn selection
      case RouteNames.turnSelection:
        final arguments = settings.arguments as Map<String, dynamic>?;
        final gameMode = arguments?['gameMode'] as GameMode?;

        // check
        if (gameMode == null) {
          return PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomeScreen(),
            transitionDuration: const Duration(milliseconds: 600),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          );
        }

        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              TurnSelectionScreen(gameMode: gameMode),
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
        );

      // match making
      case RouteNames.matchmaking:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              MatchmakingScreen(),
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity:
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              child: child,
            );
          },
        );

      // online turn selection
      case RouteNames.onlineTurnSelection:
        final arguments = settings.arguments as Map<String, dynamic>?;
        final gameSessionId = arguments?['gameSessionId'] as String?;

        // check
        if (gameSessionId == null) {
          return PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomeScreen(),
            transitionDuration: const Duration(milliseconds: 600),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          );
        }

        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              OnlineTurnSelectionScreen(
            gameSessionId: gameSessionId,
          ),
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
        );

      // game board
      case RouteNames.gameBoard:
        final gameConfig = settings.arguments as GameConfig;

        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              GameScreen(gameConfig: gameConfig),
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
        );

      // wordle
      case RouteNames.wordle:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              WordleGameScreen(),
          transitionDuration: Duration(milliseconds: 900),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
        );

      // login screen
      case RouteNames.login:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              LoginScreen(),
          transitionDuration: Duration(milliseconds: 900),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              ),
              child: child,
            );
          },
        );

      default:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
    }
  }
}
