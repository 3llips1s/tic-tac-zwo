enum GameMode { pass, offline, pair, online }

enum PlayerSymbol { X, O }

extension GameModeExtension on GameMode {
  String get string {
    switch (this) {
      case GameMode.pass:
        return 'pass + play';
      case GameMode.offline:
        return 'offline';
      case GameMode.pair:
        return 'pair + play';
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
