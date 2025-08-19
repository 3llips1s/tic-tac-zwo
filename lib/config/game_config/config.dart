import 'dart:developer' as developer;

enum GameMode { pass, offline, wordle, online }

enum PlayerSymbol { X, O }

enum OnlineGamePhase {
  waiting,
  cellSelected,
  articleRevealed,
  turnComplete,
}

enum OnlineRematchStatus {
  none,
  localOffered,
  remoteOffered,
  bothAccepted,
  localCancelled,
  localDeclined,
  remoteDeclined,
  timeout,
}

enum TimerDisplayState {
  static,
  inactivity,
  countdown,
}

enum LocalConnectionStatus {
  connected,
  reconnecting,
  disconnected,
}

enum OpponentConnectionStatus {
  connected,
  reconnecting,
  forfeited,
}

enum GameStatus {
  inProgress,
  completed,
  forfeited,
  abandoned,
}

extension GameModeExtension on GameMode {
  String get string {
    switch (this) {
      case GameMode.pass:
        return 'pass + play';
      case GameMode.offline:
        return 'solo';
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
        developer.log(
            '[OnlineGameNotifier] Unknown or null online_game_phase string: "$phaseString", defaulting to waiting.',
            name: 'config');
        return OnlineGamePhase.waiting;
    }
  }
}

extension GameStatusExtension on GameStatus {
  String get string {
    switch (this) {
      case GameStatus.inProgress:
        return 'in_progress';
      case GameStatus.completed:
        return 'completed';
      case GameStatus.forfeited:
        return 'forfeited';
      case GameStatus.abandoned:
        return 'abandoned';
    }
  }

  static GameStatus fromString(String value) {
    switch (value) {
      case 'in_progress':
        return GameStatus.inProgress;
      case 'completed':
        return GameStatus.completed;
      case 'forfeited':
        return GameStatus.forfeited;
      case 'abandoned':
        return GameStatus.abandoned;

      default:
        return GameStatus.inProgress;
    }
  }
}
