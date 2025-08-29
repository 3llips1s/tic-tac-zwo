import 'dart:ui';

import 'package:tic_tac_zwo/config/game_config/constants.dart';

import '../../../../config/game_config/config.dart';
import '../data/models/german_noun.dart';
import '../data/models/player.dart';

class GameState {
  final List<String?> board;
  final List<bool> _cellPressed;
  final List<Player> players;
  final Player startingPlayer;
  final Player? lastPlayedPlayer;
  final GermanNoun? currentNoun;
  final bool isTimerActive;
  final int remainingSeconds;
  final int? selectedCellIndex;
  final String? wrongSelectedArticle;

  // after game ends
  final bool isGameOver;
  final Player? winningPlayer;
  final int player1Score;
  final int player2Score;
  final int gamesDrawn;
  final List<int>? winningCells;
  final bool showArticleFeedback;
  final int? pointsEarnedPerGame;

  final bool isOpponentReady;

  // online mode
  final String? currentPlayerId;
  final String? revealedArticle;
  final bool? revealedArticleIsCorrect;
  final DateTime? articleRevealedAt;
  final OnlineGamePhase? onlineGamePhase;
  final String? lastStarterId;
  final OnlineRematchStatus onlineRematchStatus;
  final bool localPlayerWantsRematch;
  final bool remotePlayerWantsRematch;
  final GameStatus gameStatus;
  final LocalConnectionStatus localConnectionStatus;
  final OpponentConnectionStatus opponentConnectionStatus;

  static const int turnDurationSeconds = 9;

  GameState({
    required this.board,
    required cellPressed,
    required this.players,
    required this.startingPlayer,
    this.lastPlayedPlayer,
    this.currentNoun,
    required this.isTimerActive,
    required this.remainingSeconds,
    this.selectedCellIndex,
    this.wrongSelectedArticle,

    // after game ends
    required this.isGameOver,
    this.winningPlayer,
    required this.player1Score,
    required this.player2Score,
    required this.gamesDrawn,
    this.winningCells,
    this.showArticleFeedback = false,
    this.pointsEarnedPerGame,

    // online mode
    this.currentPlayerId,
    this.isOpponentReady = false,
    this.revealedArticle,
    this.revealedArticleIsCorrect,
    this.articleRevealedAt,
    required this.onlineGamePhase,
    this.lastStarterId,
    this.onlineRematchStatus = OnlineRematchStatus.none,
    this.localPlayerWantsRematch = false,
    this.remotePlayerWantsRematch = false,
    this.gameStatus = GameStatus.inProgress,
    this.localConnectionStatus = LocalConnectionStatus.connected,
    this.opponentConnectionStatus = OpponentConnectionStatus.connected,
  }) : _cellPressed = cellPressed;

  GameState copyWith({
    List<String?>? board,
    List<bool>? cellPressed,
    List<Player>? players,
    Player? startingPlayer,
    Player? lastPlayedPlayer,
    bool allowNullLastPlayedPlayer = false,
    GermanNoun? currentNoun,
    bool allowNullCurrentNoun = false,
    int? remainingSeconds,
    bool? isTimerActive,
    int? selectedCellIndex,
    bool allowNullSelectedCellIndex = false,
    String? wrongSelectedArticle,

    // after game ends
    bool? isGameOver,
    Player? winningPlayer,
    bool allowNullWinningPlayer = false,
    int? player1Score,
    int? player2Score,
    int? gamesDrawn,
    List<int>? winningCells,
    bool? showArticleFeedback,
    int? pointsEarnedPerGame,
    bool allowNullPointsEarnedPerGame = false,

    // online mode
    String? currentPlayerId,
    bool? isOpponentReady,
    String? revealedArticle,
    bool? revealedArticleIsCorrect,
    DateTime? articleRevealedAt,
    OnlineGamePhase? onlineGamePhase,
    String? lastStarterId,
    OnlineRematchStatus? onlineRematchStatus,
    bool? localPlayerWantsRematch,
    bool? remotePlayerWantsRematch,
    GameStatus? gameStatus,
    LocalConnectionStatus? localConnectionStatus,
    OpponentConnectionStatus? opponentConnectionStatus,

    // catch null values
    bool allowNullRevealedArticle = false,
    bool allowNullRevealedArticleIsCorrect = false,
    bool allowNullArticleRevealedAt = false,
  }) {
    return GameState(
      board: board ?? this.board,
      cellPressed: cellPressed ?? this.cellPressed,
      players: players ?? this.players,
      startingPlayer: startingPlayer ?? this.startingPlayer,
      lastPlayedPlayer: allowNullLastPlayedPlayer
          ? lastPlayedPlayer
          : (lastPlayedPlayer ?? this.lastPlayedPlayer),
      currentNoun: allowNullCurrentNoun
          ? currentNoun
          : (currentNoun ?? this.currentNoun),
      isTimerActive: isTimerActive ?? this.isTimerActive,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      selectedCellIndex: allowNullSelectedCellIndex
          ? selectedCellIndex
          : (selectedCellIndex ?? this.selectedCellIndex),
      wrongSelectedArticle: wrongSelectedArticle ?? this.wrongSelectedArticle,

      // after game ends
      isGameOver: isGameOver ?? this.isGameOver,
      winningPlayer: allowNullWinningPlayer
          ? winningPlayer
          : (winningPlayer ?? this.winningPlayer),
      player1Score: player1Score ?? this.player1Score,
      player2Score: player2Score ?? this.player2Score,
      gamesDrawn: gamesDrawn ?? this.gamesDrawn,
      winningCells: winningCells ?? this.winningCells,
      showArticleFeedback: showArticleFeedback ?? this.showArticleFeedback,
      isOpponentReady: isOpponentReady ?? this.isOpponentReady,
      pointsEarnedPerGame: allowNullPointsEarnedPerGame
          ? pointsEarnedPerGame
          : (pointsEarnedPerGame ?? this.pointsEarnedPerGame),

      // online game mode
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
      revealedArticle: allowNullRevealedArticle
          ? revealedArticle
          : (revealedArticle ?? this.revealedArticle),
      revealedArticleIsCorrect: allowNullRevealedArticleIsCorrect
          ? revealedArticleIsCorrect
          : (revealedArticleIsCorrect ?? this.revealedArticleIsCorrect),
      articleRevealedAt: allowNullArticleRevealedAt
          ? articleRevealedAt
          : (articleRevealedAt ?? this.articleRevealedAt),
      onlineGamePhase: onlineGamePhase ?? this.onlineGamePhase,
      lastStarterId: lastStarterId ?? this.lastStarterId,
      onlineRematchStatus: onlineRematchStatus ?? this.onlineRematchStatus,
      localPlayerWantsRematch:
          localPlayerWantsRematch ?? this.localPlayerWantsRematch,
      remotePlayerWantsRematch:
          remotePlayerWantsRematch ?? this.remotePlayerWantsRematch,
      gameStatus: gameStatus ?? this.gameStatus,
      localConnectionStatus:
          localConnectionStatus ?? this.localConnectionStatus,
      opponentConnectionStatus:
          opponentConnectionStatus ?? this.opponentConnectionStatus,
    );
  }

  static GameState initial(
    List<Player> players,
    Player startingPlayer, {
    OnlineGamePhase? onlineGamePhase,
    String? currentPlayerId,
    String? initialLastStarterId,
  }) {
    return GameState(
      board: List.filled(9, null),
      cellPressed: List.filled(9, false),
      players: players,
      startingPlayer: startingPlayer,
      lastPlayedPlayer: null,
      isTimerActive: false,
      remainingSeconds: turnDurationSeconds,
      isGameOver: false,
      player1Score: 0,
      player2Score: 0,
      gamesDrawn: 0,
      showArticleFeedback: false,
      onlineGamePhase: onlineGamePhase,
      currentPlayerId: currentPlayerId ?? startingPlayer.userId,
      lastStarterId: initialLastStarterId ?? startingPlayer.userId,
      onlineRematchStatus: OnlineRematchStatus.none,
      localPlayerWantsRematch: false,
      remotePlayerWantsRematch: false,
      gameStatus: GameStatus.inProgress,
      localConnectionStatus: LocalConnectionStatus.connected,
    );
  }

  static GameState initialOnline({
    required List<Player> players,
    required Player startingPlayer,
  }) {
    return GameState(
      board: List.filled(9, null),
      cellPressed: List.filled(9, false),
      players: players,
      startingPlayer: startingPlayer,
      lastPlayedPlayer: null,
      isTimerActive: false,
      remainingSeconds: turnDurationSeconds,
      isGameOver: false,
      player1Score: 0,
      player2Score: 0,
      gamesDrawn: 0,
      showArticleFeedback: false,
      isOpponentReady: false,
      onlineGamePhase: OnlineGamePhase.waiting,
      currentPlayerId: startingPlayer.userId,
      lastStarterId: startingPlayer.userId,
      onlineRematchStatus: OnlineRematchStatus.none,
      localPlayerWantsRematch: false,
      remotePlayerWantsRematch: false,
      gameStatus: GameStatus.inProgress,
      localConnectionStatus: LocalConnectionStatus.connected,
    );
  }

  List<bool> get cellPressed {
    if (onlineGamePhase != null && onlineGamePhase != OnlineGamePhase.waiting) {
      var pressed = List<bool>.filled(9, false);

      if (selectedCellIndex != null &&
          onlineGamePhase == OnlineGamePhase.cellSelected) {
        pressed[selectedCellIndex!] = true;
      }

      return pressed;
    }

    return _cellPressed;
  }

  // method to determine whose turn it is
  bool isPlayerTurn(Player player) {
    if (isGameOver) return false;

    if (currentPlayerId != null) {
      return player.userId == currentPlayerId;
    }

    if (lastPlayedPlayer == null) {
      // first turn to starting player
      return player.symbol == startingPlayer.symbol;
    }

    // switch to other player after a turn or forfeit
    return player.symbol != lastPlayedPlayer!.symbol;
  }

  Player get currentPlayer {
    if (currentPlayerId != null) {
      return players.firstWhere(
        (player) => player.userId == currentPlayerId,
        orElse: () => startingPlayer,
      );
    }

    if (lastPlayedPlayer == null) {
      return startingPlayer;
    }
    return players.firstWhere(
        (player) => player.symbol != lastPlayedPlayer!.symbol,
        orElse: () => players.first);
  }

  // symbol display
  static const String symbolX = 'X';
  static const String symbolO = 'Ö';
  static const Color colorX = colorRed;
  static const Color colorO = colorYellow;
  static const Color colorDefault = colorGrey300;

  Color getCellColor(int index) {
    if (board[index] == null) return colorDefault;
    return board[index] == symbolX ? colorX : colorO;
  }

  Color getArticleOverlayColor(Player player) {
    return player.symbolString == symbolX ? colorX : colorO;
  }

  String get currentSymbol =>
      currentPlayer.symbol == PlayerSymbol.X ? symbolX : symbolO;

  (String?, List<int>?) checkWinner({List<String?>? board}) {
    final boardToCheck = board ?? this.board;
    final winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // columns
      [0, 4, 8], [2, 4, 6], // diagonals
    ];

    for (final pattern in winPatterns) {
      final p1 = boardToCheck[pattern[0]];
      final p2 = boardToCheck[pattern[1]];
      final p3 = boardToCheck[pattern[2]];
      if (p1 != null && p1 == p2 && p1 == p3) {
        return (p1, pattern);
      }
    }

    if (!boardToCheck.contains(null)) {
      return ('Draw', null);
    }

    return (null, null);
  }
}
