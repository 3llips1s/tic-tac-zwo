import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
import 'package:tic_tac_zwo/features/game/core/data/services/data_initialization_service.dart';

import 'features/game/core/ui/screens/home_screen.dart';
import 'features/navigation/ui/hidden_drawer.dart';

class DataInitializationWrapper extends ConsumerWidget {
  final Widget child;

  const DataInitializationWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataStatus = ref.watch(dataReadyProvider);

    return dataStatus.when(
      loading: () => Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: colorBlack,
            strokeWidth: 1,
          ),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 50,
                color: colorRed,
              ),
              const SizedBox(height: kToolbarHeight),
              const Text('Spieldaten konnten nicht geladen werden.'),
              const SizedBox(height: kToolbarHeight),
              OutlinedButton(
                onPressed: () {
                  ref.refresh(dataInitializationServiceProvider).initialize();
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  overlayColor: colorBlack,
                  side: BorderSide(color: Colors.white70),
                ),
                child: const Text('erneut versuchen'),
              ),
            ],
          ),
        ),
      ),
      data: (_) => child,
    );
  }
}

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            HiddenDrawer(),
            HomeScreen(),
          ],
        ),
      ),
    );
  }
}
