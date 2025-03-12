import 'package:tic_tac_zwo/config/config.dart';

import 'player.dart';

class GameConfig {
  final List<Player> players;
  final Player startingPlayer;
  final GameMode gameMode;

  const GameConfig({
    required this.players,
    required this.startingPlayer,
    required this.gameMode,
  });
}
