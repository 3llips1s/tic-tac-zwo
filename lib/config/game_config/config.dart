enum GameMode { pass, offline, wordle, online }

enum PlayerSymbol { X, O }

enum OnlineGamePhase {
  waiting,
  cellSelected,
  articleRevealed,
  turnComplete,
}

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
        return 'cell_selected';
      case OnlineGamePhase.articleRevealed:
        return 'article_revealed';
      case OnlineGamePhase.turnComplete:
        return 'turn_complete';
    }
  }

  static OnlineGamePhase fromString(String? phaseString) {
    switch (phaseString?.toLowerCase()) {
      case 'waiting':
        return OnlineGamePhase.waiting;
      case 'cell_selected':
        return OnlineGamePhase.cellSelected;
      case 'article_revealed':
        return OnlineGamePhase.articleRevealed;
      case 'turn_complete':
        return OnlineGamePhase.turnComplete;
      default:
        print(
            '[OnlineGameNotifier] Unknown or null online_game_phase string: "$phaseString", defaulting to waiting.');
        return OnlineGamePhase.waiting;
    }
  }
}
