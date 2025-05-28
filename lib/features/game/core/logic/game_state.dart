import 'dart:ui';

import 'package:tic_tac_zwo/config/game_config/constants.dart';

import '../../../../config/game_config/config.dart';
import '../data/models/german_noun.dart';
import '../data/models/player.dart';

enum OnlineGamePhase {
  waiting,
  cellSelected,
  articleRevealed,
  turnComplete,
}

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
  final int gamesPlayed;
  final List<int>? winningCells;
  final bool showArticleFeedback;

  final bool isOpponentReady;

  static const int turnDurationSeconds = 9;

  // online mode
  final String? currentPlayerId;
  final String? revealedArticle;
  final bool? revealedArticleIsCorrect;
  final DateTime? articleRevealedAt;
  final OnlineGamePhase? onlineGamePhase;

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
    required this.gamesPlayed,
    this.winningCells,
    this.showArticleFeedback = false,

    // online mode
    this.currentPlayerId,
    this.isOpponentReady = false,
    this.revealedArticle,
    this.revealedArticleIsCorrect,
    this.articleRevealedAt,
    required this.onlineGamePhase,
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
    int? gamesPlayed,
    List<int>? winningCells,
    bool? showArticleFeedback,

    // online mode
    String? currentPlayerId,
    bool? isOpponentReady,
    String? revealedArticle,
    bool? revealedArticleIsCorrect,
    DateTime? articleRevealedAt,
    OnlineGamePhase? onlineGamePhase,

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
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      winningCells: winningCells ?? this.winningCells,
      showArticleFeedback: showArticleFeedback ?? this.showArticleFeedback,
      isOpponentReady: isOpponentReady ?? this.isOpponentReady,

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
    );
  }

  static GameState initial(
    List<Player> players,
    Player startingPlayer, {
    OnlineGamePhase onlineGamePhase = OnlineGamePhase.waiting,
    String? currentPlayerId,
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
      gamesPlayed: 0,
      showArticleFeedback: false,
      onlineGamePhase: onlineGamePhase,
      currentPlayerId: currentPlayerId ?? startingPlayer.userId,
    );
  }

  static GameState initialOnline({
    required List<Player> players,
    required Player startingPlayer,
    required String gameSessionId,
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
      gamesPlayed: 0,
      showArticleFeedback: false,
      isOpponentReady: false,
      onlineGamePhase: OnlineGamePhase.waiting,
      currentPlayerId: startingPlayer.userId,
    );
  }

  List<bool> get cellPressed {
    if (onlineGamePhase != null) {
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

  Map<String, dynamic> toJson() {
    return {
      'board': board,
      'cellPressed': cellPressed,
      'players': players.map((player) => player.toJson()).toList(),
      'startingPlayer': startingPlayer.toJson(),
      'lastPlayedPlayer': lastPlayedPlayer?.toJson(),
      'currentPlayerId': currentPlayerId,
      'currentNoun': currentNoun != null
          ? {
              'article': currentNoun!.article,
              'noun': currentNoun!.noun,
              'english': currentNoun!.english,
              'plural': currentNoun!.plural,
            }
          : null,
      'isTimerActive': isTimerActive,
      'remainingSeconds': remainingSeconds,
      'selectedCellIndex': selectedCellIndex,
      'isGameOver': isGameOver,
      'winningPlayer': winningPlayer?.toJson(),
      'player1Score': player1Score,
      'player2Score': player2Score,
      'gamesPlayed': gamesPlayed,
      'winningCells': winningCells,
      'showArticleFeedback': showArticleFeedback,
      'isOpponentReady': isOpponentReady,
      'revealedArticle': revealedArticle,
      'revealedArticleIsCorrect': revealedArticleIsCorrect,
      'articleRevealedAt': articleRevealedAt,
    };
  }

  static GameState fromJson(Map<String, dynamic> json) {
    return GameState(
        board: List<String?>.from(json['board']),
        cellPressed: List<bool>.from(json['cellPressed']),
        players:
            (json['players'] as List).map((p) => Player.fromJson(p)).toList(),
        startingPlayer: Player.fromJson(json['startingPlayer']),
        lastPlayedPlayer: json['lastPlayedPlayer'] != null
            ? Player.fromJson(json['lastPlayedPlayer'])
            : null,
        currentNoun: json['currentNoun'] != null
            ? GermanNoun(
                id: json['currentNoun']['id'],
                article: json['currentNoun']['article'],
                noun: json['currentNoun']['noun'],
                english: json['currentNoun']['english'],
                plural: json['currentNoun']['plural'],
              )
            : null,
        isTimerActive: json['isTimerActive'],
        remainingSeconds: json['remainingSeconds'],
        selectedCellIndex: json['selectedCellIndex'],
        isGameOver: json['isGameOver'],
        winningPlayer: json['winningPlayer'] != null
            ? Player.fromJson(json['winningPlayer'])
            : null,
        player1Score: json['player1Score'],
        player2Score: json['player2Score'],
        gamesPlayed: json['gamesPlayed'],
        winningCells: json['winningCells'] != null
            ? List<int>.from(json['winningCells'])
            : null,
        showArticleFeedback: json['showArticleFeedback'] ?? false,
        isOpponentReady: json['isOpponentReady'] ?? false,
        revealedArticle: json['revealedArticle'],
        revealedArticleIsCorrect: json['revealedArticleIsCorrect'] ?? false,
        articleRevealedAt: json['articleRevealedAt'],
        currentPlayerId: json['currentPlayerId'],
        onlineGamePhase: json['onlineGamePhase']);
  }

  (String?, List<int>?) checkWinner() {
    final winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // columns
      [0, 4, 8], [2, 4, 6], // diagonals
    ];

    for (final pattern in winPatterns) {
      if (board[pattern[0]] != null &&
          board[pattern[0]] == board[pattern[1]] &&
          board[pattern[0]] == board[pattern[2]]) {
        return (board[pattern[0]], pattern);
      }
    }

    if (!board.contains(null)) {
      return ('Draw', null);
    }

    return (null, null);
  }
}
