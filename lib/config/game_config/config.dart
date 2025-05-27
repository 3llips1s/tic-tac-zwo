import 'package:tic_tac_zwo/features/game/core/logic/game_state.dart';

enum GameMode { pass, offline, wordle, online }

enum PlayerSymbol { X, O }

extension GameModeExtension on GameMode {
  String get string {
    switch (this) {
      case GameMode.pass:
        return 'pass + play';
      case GameMode.offline:
        return 'offline';
      case GameMode.wordle:
        return 'wördle';
      case GameMode.online:
        return 'online';
    }
  }
}

extension SymbolExtension on PlayerSymbol {
  String get string {
    switch (this) {
      case PlayerSymbol.X:
        return 'X';
      case PlayerSymbol.O:
        return 'Ö';
    }
  }
}

extension OnlineGamePhaseExtension on OnlineGamePhase {
  String get string {
    switch (this) {
      case OnlineGamePhase.waiting:
        return 'waiting';
      case OnlineGamePhase.cellSelected:
        return 'cellSelected';
      case OnlineGamePhase.articleRevealed:
        return 'articleRevealed';
      case OnlineGamePhase.turnComplete:
        return 'turnComplete';
    }
  }
}
