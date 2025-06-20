import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
import 'package:tic_tac_zwo/features/game/core/data/services/data_initialization_service.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/dual_progress_indicator.dart';

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
          child: DualProgressIndicator(),
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
  double _xOffset = 0;
  double _yOffset = 0;
  double _scaleFactor = 1;
  bool _isDrawerOpen = false;

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
      _xOffset = _isDrawerOpen ? -225 : 0;
      _yOffset = _isDrawerOpen ? 86.5 : 0;
      _scaleFactor = _isDrawerOpen ? 0.8 : 1;
    });
  }

  void _closeDrawer() {
    if (_isDrawerOpen) {
      setState(() {
        _isDrawerOpen = false;
        _xOffset = 0;
        _yOffset = 0;
        _scaleFactor = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            HiddenDrawer(onCloseDrawer: _closeDrawer),
            _buildHomeScreenWithDrawer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeScreenWithDrawer() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 900),
      curve: Curves.decelerate,
      transform: Matrix4.translationValues(_xOffset, _yOffset, 0)
        ..scale(_scaleFactor),
      child: Container(
        decoration: BoxDecoration(
          color: colorGrey300,
          borderRadius: BorderRadius.circular(_isDrawerOpen ? 30 : 0),
          boxShadow: _isDrawerOpen
              ? [
                  BoxShadow(
                    color: Colors.grey.shade100.withOpacity(0.3),
                    offset: const Offset(10, 10),
                    blurRadius: 15,
                  )
                ]
              : [],
        ),
        child: HomeScreen(
          isDrawerOpen: _isDrawerOpen,
          onToggleDrawer: _toggleDrawer,
        ),
      ),
    );
  }
}
