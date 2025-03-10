import 'package:tic_tac_zwo/config/config.dart';

import '../../../pair/logic/pair_service.dart';
import 'player.dart';

class GameConfig {
  final List<Player> players;
  final Player startingPlayer;
  final GameMode gameMode;
  final PairService? pairService;

  const GameConfig({
    required this.players,
    required this.startingPlayer,
    required this.gameMode,
    this.pairService,
  }) : assert(gameMode != GameMode.pair || pairService != null,
            'PairService must be provided for pair mode');
}
