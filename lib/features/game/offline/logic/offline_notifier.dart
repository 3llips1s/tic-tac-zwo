import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/config/game_config/config.dart';
import 'package:tic_tac_zwo/features/game/core/data/models/game_config.dart';
import 'package:tic_tac_zwo/features/game/core/data/models/player.dart';
import 'package:tic_tac_zwo/features/game/core/logic/game_notifier.dart';
import 'package:tic_tac_zwo/features/game/core/logic/game_state.dart';

class OfflineNotifier extends GameNotifier {
  final Random _random = Random();
  Timer? _aiThinkingTimer;
  final AIDifficulty difficulty;

  OfflineNotifier(
    super.ref,
    super.players,
    super.startingPlayer,
    this.difficulty,
  ) {
    if (state.currentPlayer.isAI) {
      _scheduleAIMove();
    }
  }

  @override
  void selectCell(int index) {
    bool isAIMove = StackTrace.current.toString().contains('_scheduleAIMove');

    if (state.currentPlayer.isAI && !isAIMove) return;

    super.selectCell(index);
  }

  @override
  void makeMove(String selectedArticle) {
    super.makeMove(selectedArticle);

    if (!state.isGameOver && state.currentPlayer.isAI) {
      _scheduleAIMove();
    }
  }

  @override
  void rematch() {
    final swappedPlayers = state.players
        .map((player) => Player(
            username: player.username,
            symbol: player.symbol == PlayerSymbol.X
                ? PlayerSymbol.O
                : PlayerSymbol.X,
            isAI: player.isAI))
        .toList();

    final newStartingPlayer = swappedPlayers.firstWhere(
      (player) => player.symbol == PlayerSymbol.X,
    );

    state = GameState.initial(swappedPlayers, newStartingPlayer).copyWith(
      player1Score: player1Score,
      player2Score: player2Score,
      gamesDrawn: gamesDrawn,
      winningCells: null,
    );

    if (state.currentPlayer.isAI) {
      _scheduleAIMove();
    }
  }

  Future<void> _scheduleAIMove() async {
    if (state.lastPlayedPlayer == null && state.currentPlayer.isAI) {
      await Future.delayed(const Duration(seconds: 4));
    }

    // cancel existing timer
    _aiThinkingTimer?.cancel();

    final cellThinkingTime = 1 + _random.nextInt(4);

    _aiThinkingTimer = Timer(
      Duration(seconds: cellThinkingTime),
      () {
        if (state.isGameOver) return;

        // select cell
        final selectedCell = _selectBestMove();

        if (selectedCell != null) {
          selectCell(selectedCell);

          // select article selection
          final articleThinkingTime = 1 + _random.nextInt(2);
          _aiThinkingTimer = Timer(
            Duration(seconds: articleThinkingTime),
            () {
              if (state.isGameOver || !state.isTimerActive) return;

              final selectedArticle = _shouldMakeRandomMove()
                  ? _selectRandomArticle()
                  : _selectCorrectArticle();

              makeMove(selectedArticle);
            },
          );
        }
      },
    );
  }

  // forfeit turn
  @override
  void forfeitTurn() {
    super.forfeitTurn();
    if (!state.isGameOver && state.currentPlayer.isAI) {
      _scheduleAIMove();
    }
  }

  // random move
  bool _shouldMakeRandomMove() {
    switch (difficulty) {
      case AIDifficulty.easy:
        return _random.nextDouble() < 0.3;
      case AIDifficulty.medium:
        return _random.nextDouble() < 0.15;
      case AIDifficulty.hard:
        return _random.nextDouble() < 0.05;
    }
  }

  // best move
  int? _selectBestMove() {
    final availableCells = List.generate(9, (i) => i)
        .where((i) => state.board[i] == null)
        .toList();

    if (availableCells.isEmpty) return null;

    final opponentSymbol =
        state.currentPlayer.symbol == PlayerSymbol.X ? 'Ö' : 'X';
    final currentSymbol = state.currentPlayer.symbolString;

    // 1. check if ai can win in one move
    for (final cell in availableCells) {
      final boardCopy = List<String?>.from(state.board);
      boardCopy[cell] = currentSymbol;
      if (_isWinningMove(boardCopy, currentSymbol)) {
        return cell;
      }
    }

    // 2. block opponent's winning move
    if (_shouldBlock()) {
      for (final cell in availableCells) {
        final boardCopy = List<String?>.from(state.board);
        boardCopy[cell] = opponentSymbol;
        if (_isWinningMove(boardCopy, opponentSymbol)) {
          return cell;
        }
      }
    }

    // 3. difficulty dependent strategic thinking
    if (_shouldUseStrategy()) {
      if (availableCells.length <= 7) {
        int? bestMove = _getBestStrategicMove(
            availableCells, currentSymbol, opponentSymbol);
        if (bestMove != null) return bestMove;
      }
    }

    // 4. basic positional play
    return _getPositionalMove(availableCells);
  }

  // difficulty-based decision making
  bool _shouldBlock() {
    switch (difficulty) {
      case AIDifficulty.easy:
        return _random.nextDouble() < 0.7;
      case AIDifficulty.medium:
        return _random.nextDouble() < 0.9;
      case AIDifficulty.hard:
        return true;
    }
  }

  // difficulty-based decision making
  bool _shouldUseStrategy() {
    switch (difficulty) {
      case AIDifficulty.easy:
        return _random.nextDouble() < 0.5;
      case AIDifficulty.medium:
        return _random.nextDouble() < 0.75;
      case AIDifficulty.hard:
        return _random.nextDouble() < 0.95;
    }
  }

  int? _getBestStrategicMove(
      List<int> availableCells, String currentSymbol, String opponentSymbol) {
    int? bestMove = -1;
    int bestScore = -1000;

    for (final cell in availableCells) {
      final boardCopy = List<String?>.from(state.board);
      boardCopy[cell] = currentSymbol;

      int score = _miniMax(boardCopy, 0, false, currentSymbol, opponentSymbol);

      score += _getPositionalBonus(cell);

      if (score > bestScore) {
        bestScore = score;
        bestMove = cell;
      }
    }

    return bestMove != -1 ? bestMove : null;
  }

  int _getPositionalBonus(int position) {
    if (position == 4) return 3;
    if ([0, 2, 6, 8].contains(position)) return 2;
    return 1;
  }

  int _getPositionalMove(List<int> availableCells) {
    final moves = <int>[];
// prefer centre
    if (availableCells.contains(4)) {
      moves.add(4);
    }

    // then corners
    final corners = [0, 2, 6, 8].where(availableCells.contains).toList();
    moves.addAll(corners);

    // then edges
    final edges = [1, 3, 5, 7].where(availableCells.contains).toList();
    moves.addAll(edges);

    final finalMoves = moves.isEmpty ? moves : availableCells;
    return finalMoves[_random.nextInt(finalMoves.length)];
  }

  int _miniMax(List<String?> board, int depth, bool isMaximizing,
      String aiSymbol, String opponentSymbol) {
    // check internal states
    if (_isWinningMove(board, aiSymbol)) return 10 - depth;
    if (_isWinningMove(board, opponentSymbol)) return depth - 10;
    if (!board.contains(null)) return 0;

    int bestScore = isMaximizing ? -1000 : 1000;

    final moves =
        List.generate(9, (i) => i).where((i) => board[i] == null).toList();

    for (final move in moves) {
      board[move] = isMaximizing ? aiSymbol : opponentSymbol;
      int score =
          _miniMax(board, depth + 1, !isMaximizing, aiSymbol, opponentSymbol);
      board[move] = null;

      bestScore = isMaximizing ? max(bestScore, score) : min(bestScore, score);
    }
    return bestScore;
  }

  // check winning move
  bool _isWinningMove(List<String?> board, String symbol) {
    final winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // columns
      [0, 4, 8], [2, 4, 6], // diagonals
    ];

    for (final pattern in winPatterns) {
      // check immediate win
      if (board[pattern[0]] == symbol &&
          board[pattern[1]] == symbol &&
          board[pattern[2]] == symbol) {
        return true;
      }
    }
    return false;
  }

  // choose correct/random article
  String _selectCorrectArticle() {
    if (_random.nextDouble() < difficulty.articleErrorRate) {
      return _selectRandomArticle();
    }

    return state.currentNoun?.article ?? _selectRandomArticle();
  }

  String _selectRandomArticle() {
    const articles = ['der', 'die', 'das'];
    return articles[_random.nextInt(articles.length)];
  }

  @override
  void dispose() {
    _aiThinkingTimer?.cancel();
    super.dispose();
  }
}

final offlineStateProvider =
    StateNotifierProvider.family<OfflineNotifier, GameState, GameConfig>(
        (ref, config) => OfflineNotifier(
              ref,
              config.players,
              config.startingPlayer,
              config.difficulty ?? AIDifficulty.medium,
            ));
