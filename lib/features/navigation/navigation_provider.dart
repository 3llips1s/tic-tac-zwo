import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NavigationTarget {
  home,
  matchmaking,
}

final navigationTargetProvider =
    StateProvider<NavigationTarget?>((ref) => null);
