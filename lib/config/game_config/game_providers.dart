import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/features/game/core/data/models/game_config.dart';
import 'package:tic_tac_zwo/features/game/core/logic/game_notifier.dart';
import 'package:tic_tac_zwo/features/game/offline/logic/offline_notifier.dart';
import 'package:tic_tac_zwo/features/game/online/logic/online_game_notifier.dart';

import '../../features/game/core/logic/game_state.dart';
import 'config.dart';

class GameProviders {
  static StateNotifierProvider<dynamic, GameState> getStateProvider(
      WidgetRef ref, GameConfig config) {
    switch (config.gameMode) {
      case GameMode.offline:
        return offlineStateProvider(config);
      case GameMode.online:
        return onlineGameStateNotifierProvider(config);
      default:
        return gameStateProvider(config);
    }
  }
}
