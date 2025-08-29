import 'package:tic_tac_zwo/config/game_config/config.dart';

import 'player.dart';

class GameConfig {
  final List<Player> players;
  final Player startingPlayer;
  final GameMode gameMode;
  final String? gameSessionId;
  final AIDifficulty? difficulty;

  const GameConfig({
    required this.players,
    required this.startingPlayer,
    required this.gameMode,
    this.gameSessionId,
    this.difficulty,
  });
}
