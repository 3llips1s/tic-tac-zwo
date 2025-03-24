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
            userName: player.userName,
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
        gamesPlayed: gamesPlayed,
        winningCells: null);

    if (state.currentPlayer.isAI) {
      _scheduleAIMove();
    } else {}
  }

  void _scheduleAIMove() {
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
    return _random.nextDouble() < 0.3;
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

    // block opponent's winning move
    final winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // columns
      [0, 4, 8], [2, 4, 6], // diagonals
    ];

    for (final pattern in winPatterns) {
      // get symbols in the pattern
      final patternSymbols = pattern.map((e) => state.board[e]).toList();

      // count opponent symbols and empty spaces
      final opponentSymbolCount =
          patternSymbols.where((symbol) => symbol == opponentSymbol).length;
      final emptyCount =
          patternSymbols.where((symbol) => symbol == null).length;

      // standard block (2 in a row, empty space on one end)
      if (opponentSymbolCount == 2 && emptyCount == 1) {
        return pattern[patternSymbols.indexWhere((symbol) => symbol == null)];
      }

      // check for separated threats
      if (emptyCount == 1) {
        final firstIndex = 0;
        final middleIndex = 1;
        final lastIndex = 2;

        if (patternSymbols[firstIndex] == opponentSymbol &&
            patternSymbols[lastIndex] == opponentSymbol &&
            patternSymbols[middleIndex] == null) {
          return pattern[middleIndex];
        }
      }

      // check for diagonal threats
      if (pattern.length == 3 && pattern.contains(4)) {
        final corners = [pattern[0], pattern[2]];
        if (corners.every((i) =>
            state.board[i] == opponentSymbol && state.board[4] == null)) {
          return 4;
        }
      }
    }

    // check if AI can win
    for (final cell in availableCells) {
      final boardCopy = List<String?>.from(state.board);
      boardCopy[cell] = currentSymbol;
      if (_isWinningMove(boardCopy, currentSymbol)) {
        return cell;
      }
    }

    // take center if available
    if (state.board[4] == null) return 4;

    // take corners
    final corners = [0, 2, 6, 8].where((i) => state.board[i] == null).toList();
    if (corners.isNotEmpty) {
      return corners[_random.nextInt(corners.length)];
    }

    // take edges
    final edges = [1, 3, 5, 7].where((i) => state.board[i] == null).toList();
    if (edges.isNotEmpty) {
      return edges[_random.nextInt(edges.length)];
    }

    // fall back to minimax if no better move was found
    int? bestMove = -1;
    int bestScore = -1000;

    // evaluate each available move
    for (final cell in availableCells) {
      final boardCopy = List<String?>.from(state.board);
      boardCopy[cell] = currentSymbol;

      final score =
          _miniMax(boardCopy, 0, false, currentSymbol, opponentSymbol);

      if (score > bestScore) {
        bestScore = score;
        bestMove = cell;
      }
    }

    return bestMove;
  }

  int _miniMax(List<String?> board, int depth, bool isMaximizing,
      String aiSymbol, String opponentSymbol) {
    // check internal states
    if (_isWinningMove(board, aiSymbol)) return 10 - depth;
    if (_isWinningMove(board, opponentSymbol)) return depth - 10;
    if (!board.contains(null)) return 0;

    int bestScore = isMaximizing ? -1000 : 1000;

    final availableMoves =
        List.generate(9, (i) => i).where((i) => board[i] == null).toList();

    for (final move in availableMoves) {
      board[move] = isMaximizing ? aiSymbol : opponentSymbol;
      int score =
          _miniMax(board, depth + 1, isMaximizing, aiSymbol, opponentSymbol);
      board[move] = null;

      bestScore = isMaximizing ? max(bestScore, score) : min(bestScore, score);
    }
    return bestScore;
  }

  // check winning move
  bool _isWinningMove(
    List<String?> board,
    String symbol,
  ) {
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
