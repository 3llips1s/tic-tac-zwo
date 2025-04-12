import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/config/game_config/config.dart';
import 'package:tic_tac_zwo/features/game/core/logic/game_state.dart';

import '../data/models/game_config.dart';
import '../data/models/german_noun.dart';
import '../data/models/player.dart';
import '../data/repositories/german_noun_repo.dart';

class GameNotifier extends StateNotifier<GameState> {
  final Ref ref;
  Timer? _timer;
  List<GermanNoun>? _nounsList;

  // track scores
  int player1Score = 0;
  int player2Score = 0;
  int gamesPlayed = 0;

  GameNotifier(this.ref, List<Player> players, Player startingPlayer)
      : super(GameState.initial(players, startingPlayer));

  Future<void> _ensureNounsLoaded() async {
    if (_nounsList == null) {
      try {
        final nounsRepository = ref.read(nounRepositoryProvider);
        _nounsList = await nounsRepository.loadNouns();
      } catch (e) {
        _nounsList = [];
      }
    }
  }

  final Set<String> _usedNouns = {};

  void loadTurnNoun() async {
    try {
      // ensure nouns are loaded
      await _ensureNounsLoaded();

      // check if nouns are available
      if (_nounsList != null && _nounsList!.isNotEmpty) {
        // filter used nouns
        final availableNouns = _nounsList!
            .where(
              (noun) => !_usedNouns.contains(noun.noun),
            )
            .toList();

        if (availableNouns.isEmpty) {
          // reset used nouns if exhausted
          _usedNouns.clear();
          // reshuffle original list
          _nounsList!.shuffle();
        }

        final randomNoun = availableNouns.isNotEmpty
            ? availableNouns[Random().nextInt(availableNouns.length)]
            : _nounsList![Random().nextInt(_nounsList!.length)];

        // track used noun
        _usedNouns.add(randomNoun.noun);

        state = state.copyWith(
          currentNoun: randomNoun,
        );
      }
    } catch (e) {
      print('error loading turn noun: $e');
    }
  }

  void selectCell(int index) {
    if (state.isGameOver || state.board[index] != null || state.isTimerActive) {
      return;
    }

    loadTurnNoun();

    var newCellPressed = List<bool>.from(state.cellPressed);
    newCellPressed[index] = true;

    state = state.copyWith(
      cellPressed: newCellPressed,
      selectedCellIndex: index,
      isTimerActive: true,
      remainingSeconds: GameState.turnDurationSeconds,
    );

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(seconds: 1),
      (timer) {
        if (state.remainingSeconds > 0) {
          state = state.copyWith(
            remainingSeconds: state.remainingSeconds - 1,
          );
        } else {
          forfeitTurn();
        }
      },
    );
  }

  void forfeitTurn() {
    _timer?.cancel();

    var newCellPressed = List<bool>.from(state.cellPressed);
    if (state.selectedCellIndex != null) {
      newCellPressed[state.selectedCellIndex!] = false;
    }

    state = state.copyWith(
      cellPressed: newCellPressed,
      selectedCellIndex: null,
      isTimerActive: false,
      remainingSeconds: GameState.turnDurationSeconds,
      currentNoun: null,
      lastPlayedPlayer: state.currentPlayer,
    );
  }

  void makeMove(String selectedArticle) async {
    if (state.selectedCellIndex == null || !state.isTimerActive) return;

    _timer?.cancel();
    bool isCorrect = state.currentNoun?.article == selectedArticle;

    final germanNounsRepository = ref.read(germanNounRepoProvider);
    if (state.currentNoun != null) {
      germanNounsRepository.removeUsedNoun(state.currentNoun!);
    }

    if (isCorrect) {
      var newBoard = List<String?>.from(state.board);
      newBoard[state.selectedCellIndex!] = state.currentPlayer.symbolString;

      // first update board and show pressed state
      state = state.copyWith(
        board: newBoard,
        cellPressed: List<bool>.from(state.cellPressed)
          ..[state.selectedCellIndex!] = true,
        isTimerActive: false,
        lastPlayedPlayer: state.currentPlayer,
        showArticleFeedback: false,
        wrongSelectedArticle: null,
      );

      final (gameResult, winningPattern) = state.checkWinner();

      // handle turn change and reset states
      if (gameResult != null) {
        if (gameResult != 'Draw' && winningPattern != null) {
          var finalCellPressed = List.generate(9, (_) => true);
          for (var winIndex in winningPattern) {
            finalCellPressed[winIndex] = false;
          }

          // always reset the cell press state, even if game is ending
          state = state.copyWith(
            cellPressed: finalCellPressed,
            winningCells: winningPattern,
            selectedCellIndex: null,
            currentNoun: null,
          );
        }
        // game ends + show result
        handleWinOrDraw();
      } else {
        // regular turn change
        state = state.copyWith(
          cellPressed: List<bool>.from(state.cellPressed)
            ..[state.selectedCellIndex!] = false,
          selectedCellIndex: null,
          isTimerActive: false,
          remainingSeconds: GameState.turnDurationSeconds,
          currentNoun: null,
        );
      }
    } else {
      // for incorrect moves, first show article
      state = state.copyWith(
        isTimerActive: false,
        showArticleFeedback: true,
        wrongSelectedArticle: selectedArticle,
      );

      forfeitTurn();
    }
  }

  void handleWinOrDraw() {
    if (state.isGameOver) return;

    final (winResult, winPattern) = state.checkWinner();
    if (winResult != null) {
      _timer?.cancel();

      // update scores
      if (winResult != 'Draw') {
        final winningPlayer =
            state.players.firstWhere((p) => p.symbolString == winResult);
        if (winningPlayer == state.players[0]) {
          player1Score++;
        } else {
          player2Score++;
        }
      }
      gamesPlayed++;

      // update game state
      state = state.copyWith(
        isGameOver: true,
        winningPlayer: winResult == 'Draw'
            ? null
            : state.players.firstWhere((p) => p.symbolString == winResult),
        player1Score: player1Score,
        player2Score: player2Score,
        gamesPlayed: gamesPlayed,
      );
    }
  }

  void rematch() {
    _timer?.cancel();
    _usedNouns.clear();

    // swap symbols between players
    final newPlayers = [
      Player(
          userName: state.players[0].userName,
          symbol: state.players[0].symbol == PlayerSymbol.X
              ? PlayerSymbol.O
              : PlayerSymbol.X),
      Player(
          userName: state.players[1].userName,
          symbol: state.players[1].symbol == PlayerSymbol.X
              ? PlayerSymbol.O
              : PlayerSymbol.X)
    ];

    final newStartingPlayer =
        newPlayers.firstWhere((player) => player.symbol == PlayerSymbol.X);

    state = GameState.initial(newPlayers, newStartingPlayer).copyWith(
        player1Score: player1Score,
        player2Score: player2Score,
        gamesPlayed: gamesPlayed,
        winningCells: null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final gameStateProvider =
    StateNotifierProvider.family<GameNotifier, GameState, GameConfig>(
  (ref, config) => GameNotifier(ref, config.players, config.startingPlayer),
);
