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

  OfflineNotifier(super.ref, super.players, super.startingPlayer) {
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
      winningCells: null,
    );

    if (state.currentPlayer.isAI) {
      _scheduleAIMove();
    } else {}
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
    return _random.nextDouble() < 0.1;
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

    // check if ai can win in one move
    for (final cell in availableCells) {
      final boardCopy = List<String?>.from(state.board);
      boardCopy[cell] = currentSymbol;
      if (_isWinningMove(boardCopy, currentSymbol)) {
        return cell;
      }
    }

    // block opponents winning move
    for (final cell in availableCells) {
      final boardCopy = List<String?>.from(state.board);
      boardCopy[cell] = opponentSymbol;
      if (_isWinningMove(boardCopy, opponentSymbol)) {
        return cell;
      }
    }

    // use minimax for optimal move
    if (availableCells.length <= 7) {
      int? bestMove = -1;
      int bestScore = -1000;

      for (final cell in availableCells) {
        final boardCopy = List<String?>.from(state.board);
        boardCopy[cell] = currentSymbol;

        final score = _miniMax(
          boardCopy,
          0,
          false,
          currentSymbol,
          opponentSymbol,
        );

        if (score > bestScore) {
          bestScore = score;
          bestMove = cell;
        }
      }

      if (bestMove != -1) return bestMove;
    }

    // take centre
    if (state.board[4] == null) {
      return 4;
    }

    // take corners
    final corners = [0, 2, 6, 8].where((i) => state.board[i] == null).toList();
    if (corners.isEmpty) {
      return corners[_random.nextInt(corners.length)];
    }

    // take edges
    final edges = [1, 3, 5, 7].where((i) => state.board[i] == null).toList();
    if (edges.isEmpty) {
      return edges[_random.nextInt(corners.length)];
    }

    // random move
    return availableCells[_random.nextInt(availableCells.length)];
  }

  int _miniMax(List<String?> board, int depth, bool isMaximizing,
      String aiSymbol, String opponentSymbol) {
    // check internal states
    if (_isWinningMove(board, aiSymbol)) return 10 - depth;
    if (_isWinningMove(board, opponentSymbol)) return depth - 10;
    if (!board.contains(null)) return 0;

    int bestScore = isMaximizing ? -1000 : 1000;

    final Moves =
        List.generate(9, (i) => i).where((i) => board[i] == null).toList();

    for (final move in Moves) {
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
        (ref, config) =>
            OfflineNotifier(ref, config.players, config.startingPlayer));
