import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tic_tac_zwo/features/game/core/data/models/game_config.dart';
import 'package:tic_tac_zwo/features/game/core/data/repositories/german_noun_repo.dart';
import 'package:tic_tac_zwo/features/game/core/logic/game_notifier.dart';
import 'package:tic_tac_zwo/features/game/core/logic/game_state.dart';
import 'package:tic_tac_zwo/features/game/online/data/services/matchmaking_service.dart';
import 'package:tic_tac_zwo/features/game/online/data/services/online_game_service.dart';

class OnlineGameNotifier extends GameNotifier {
  final SupabaseClient supabase;
  final String gameSessionId;
  String? currentUserId;
  Map<String, dynamic>? gameSessionData;
  Map<String, dynamic>? _lastProcessedUpdate;

  StreamSubscription? _gameStateSubscription;
  bool _processingRemoteUpdate = false;
  bool _isLocalPlayerTurn = false;

  OnlineGameNotifier(Ref ref, GameConfig gameConfig, this.supabase)
      : gameSessionId = gameConfig.gameSessionId ?? '',
        currentUserId = supabase.auth.currentUser?.id,
        super(ref, gameConfig.players, gameConfig.startingPlayer) {
    if (gameSessionId.isNotEmpty) {
      _initOnlineGame();
    }
  }

  void _initOnlineGame() async {
    final gameService = ref.read(onlineGameServiceProvider);

    // get initial game session data
    try {
      gameSessionData = await gameService.getGameSession(gameSessionId);

      final currentPlayerId = gameSessionData?['current_player_id'];
      _isLocalPlayerTurn = currentPlayerId == currentUserId;

      // initialize player ready status
      await gameService.setPlayerReady(gameSessionId);

      // sub to game state updates
      _gameStateSubscription = gameService
          .getGameStateStream(gameSessionId)
          .listen(_handleGameStateUpdate);
    } catch (e) {
      print('error initializing online game: $e');
    }

    _gameStateSubscription = gameService
        .getGameStateStream(gameSessionId)
        .listen(_handleGameStateUpdate);

    // initialize player ready status
    gameService.setPlayerReady(gameSessionId);
  }

  @override
  void loadTurnNoun() async {
    if (!_isLocalPlayerTurn) return;

    super.loadTurnNoun();

    // update loaded noun to server
    if (state.currentNoun != null && gameSessionId.isNotEmpty) {
      final gameService = ref.read(onlineGameServiceProvider);

      final currentNounId = state.currentNoun!.id;

      await gameService.updateGameState(
        gameSessionId,
        currentNounId: currentNounId,
      );
    }
  }

  @override
  void selectCell(int index) {
    if (!_isLocalPlayerTurn || _processingRemoteUpdate) return;

    super.selectCell(index);

    // update selected cell
    if (gameSessionId.isNotEmpty && state.selectedCellIndex != null) {
      final gameService = ref.read(onlineGameServiceProvider);

      // update game state
      gameService.updateGameState(
        gameSessionId,
        selectedCellIndex: state.selectedCellIndex,
        currentNounId: state.currentNoun?.id,
      );
    }
  }

  @override
  void makeMove(String selectedArticle) async {
    if (!_isLocalPlayerTurn || _processingRemoteUpdate) return;
    if (state.selectedCellIndex == null ||
        !state.isTimerActive ||
        gameSessionId.isEmpty) {
      return;
    }

    _processingRemoteUpdate = true;

    bool isCorrect = state.currentNoun?.article == selectedArticle;

    final int cellIndex = state.selectedCellIndex!;
    final boardCopy = List<String?>.from(state.board);

    if (isCorrect) {
      boardCopy[cellIndex] = state.currentPlayer.symbolString;
    }

    super.makeMove(selectedArticle);

    final gameService = ref.read(onlineGameServiceProvider);

    try {
      // record the round in game rounds table
      await gameService.recordGameRound(
        gameSessionId,
        playerId: currentUserId ?? '',
        nounId: state.currentNoun?.id ?? '',
        selectedArticle: selectedArticle,
        isCorrect: isCorrect,
        cellIndex: state.selectedCellIndex!,
      );
    } catch (e) {
      print('Error recording game round: $e');
    }

    final String? player1Id = gameSessionData?['player1_id'];
    final String? player2Id = gameSessionData?['player1_id'];

    // determine next player's id
    final nextPlayerUserId =
        (currentUserId == player1Id) ? player2Id : player1Id;

    try {
      // update the game state over the server with full info
      await gameService.updateGameState(
        gameSessionId,
        board: state.board,
        selectedCellIndex: null,
        currentPlayerId: nextPlayerUserId,
        isGameOver: state.isGameOver,
        winnerId: state.winningPlayer?.userId,
      );

      _isLocalPlayerTurn = false;
    } catch (e) {
      print('Error updating game state: $e');
      // On error, restore local interaction ability
      _processingRemoteUpdate = false;
    }
  }

  void _handleGameStateUpdate(Map<String, dynamic> gameSessionData) {
    if (gameSessionData.isEmpty) return;

    if (_isIdenticalToLastUpdate(gameSessionData)) {
      return;
    }

    _processingRemoteUpdate = true;
    this.gameSessionData = gameSessionData;

    try {
      bool stateChanged = false;

      // update turn information
      final currentPlayerId = gameSessionData['current_player_id'];
      final previousIsLocalPlayerTurn = _isLocalPlayerTurn;
      _isLocalPlayerTurn = currentPlayerId == currentUserId;

      if (previousIsLocalPlayerTurn != _isLocalPlayerTurn) {
        stateChanged = true;
      }

      // check if board is different from local state + update
      final remoteBoard =
          List<String?>.from(gameSessionData['board'] ?? List.filled(9, null));

      bool boardChanged = false;
      for (int i = 0; i < 9; i++) {
        if (state.board[i] != remoteBoard[i]) {
          boardChanged = true;
          break;
        }
      }

      if (boardChanged) {
        state = state.copyWith(board: remoteBoard);
        stateChanged = true;
      }

      // handle opponent cell selection
      final remoteSelectedCell = gameSessionData['selected_cell_index'];
      if (remoteSelectedCell != null &&
          remoteSelectedCell != state.selectedCellIndex &&
          !_isLocalPlayerTurn) {
        var newCellPressed = List<bool>.from(state.cellPressed);
        newCellPressed[remoteSelectedCell] = true;

        state = state.copyWith(
          selectedCellIndex: remoteSelectedCell,
          cellPressed: newCellPressed,
        );
        stateChanged = true;
      }

      // handle current noun from opponent
      final remoteNounId = gameSessionData['current_noun_id'];
      if (remoteNounId != null &&
          (state.currentNoun == null ||
              state.currentNoun!.id != remoteNounId)) {
        _loadNounFromId(remoteNounId);
        stateChanged = true;
      }

      // change turn from remote player to local player
      if (!previousIsLocalPlayerTurn &&
          _isLocalPlayerTurn &&
          !state.isGameOver) {
        // reset game state for local player
        state = state.copyWith(
          selectedCellIndex: null,
          isTimerActive: false,
          currentNoun: null,
        );

        // load new noun for local player
        if (_isLocalPlayerTurn) {
          Future.delayed(
            Duration(milliseconds: 300),
            () {
              if (_isLocalPlayerTurn && !state.isGameOver) {
                loadTurnNoun();
              }
            },
          );
        }
        stateChanged = true;
      }

      // check game over state
      final isGameOver = gameSessionData['is_game_over'] ?? false;
      if (isGameOver && !state.isGameOver) {
        final winnerId = gameSessionData['winner_id'];
        final winningPlayer = winnerId != null
            ? state.players.firstWhere((player) => player.userId == winnerId,
                orElse: () => state.players[0])
            : null;

        state = state.copyWith(
          isGameOver: true,
          winningPlayer: winningPlayer,
        );
        stateChanged = true;
      }

      if (stateChanged) {
        // rebuild if something has changes
      }
    } finally {
      Future.delayed(
        Duration(milliseconds: 150),
        () {
          _processingRemoteUpdate = false;
        },
      );
    }
  }

  bool _isIdenticalToLastUpdate(Map<String, dynamic> newData) {
    if (_lastProcessedUpdate == null) {
      _lastProcessedUpdate = Map<String, dynamic>.from(newData);
      return false;
    }

    final criticalFields = [
      'board',
      'current_player_id',
      'selected_cell_index',
      'current_noun_id',
      'is_game_over',
      'winner_id'
    ];

    bool identical = true;
    for (var field in criticalFields) {
      // deep equality for lists
      if (field == 'board') {
        List? oldBoard = _lastProcessedUpdate![field];
        List? newBoard = newData[field];

        if (oldBoard == null && newBoard == null) continue;
        if (oldBoard == null || newBoard == null) {
          identical = false;
          break;
        }

        if (oldBoard.length != newBoard.length) {
          identical = false;
          break;
        }

        for (int i = 0; i < oldBoard.length; i++) {
          if (oldBoard[i] != newBoard[i]) {
            identical = false;
            break;
          }
        }
        if (!identical) break;
      } else if (_lastProcessedUpdate![field] != newData[field]) {
        identical = false;
        break;
      }
    }

    if (!identical) {
      _lastProcessedUpdate = Map<String, dynamic>.from(newData);
    }

    return identical;
  }

  Future<void> _loadNounFromId(String nounId, {int retryCount = 3}) async {
    for (int attempt = 0; attempt < retryCount; attempt++) {
      try {
        final germanNounsRepository = ref.read(germanNounRepoProvider);
        final noun = await germanNounsRepository.getNounById(nounId);

        if (noun != null) {
          state = state.copyWith(currentNoun: noun);
          return;
        }

        await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
      } catch (e) {
        print('error loading noun by id (attempt ${attempt + 1}): $e');
        if (attempt == retryCount - 1) {
          // On last attempt, notify the user
          print('Failed to load noun after $retryCount attempts');
        } else {
          // Wait before retry with exponential backoff
          await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
        }
      }
    }
  }

  @override
  void forfeitTurn() {
    if (!_isLocalPlayerTurn || _processingRemoteUpdate) return;

    _processingRemoteUpdate = true;

    super.forfeitTurn();

    final gameService = ref.read(onlineGameServiceProvider);

    final String? player1Id = gameSessionData?['player1_id'];
    final String? player2Id = gameSessionData?['player2_id'];

    final nextPlayerUserId =
        (currentUserId == player1Id) ? player2Id : player1Id;

    gameService
        .updateGameState(
      gameSessionId,
      selectedCellIndex: null,
      currentPlayerId: nextPlayerUserId,
      currentNounId: null,
    )
        .then((_) {
      _isLocalPlayerTurn = false;
    }).catchError((e) {
      print('Error updating game state for forfeit: $e');
    }).whenComplete(
      () {
        _processingRemoteUpdate = false;
      },
    );
  }

  @override
  void rematch() {
    super.rematch();

    if (gameSessionId.isNotEmpty) {
      final gameService = ref.read(onlineGameServiceProvider);

      // reset game session on server
      gameService.updateGameState(
        gameSessionId,
        board: List.filled(9, null),
        selectedCellIndex: null,
        isGameOver: null,
        winnerId: null,
      );
    }
  }

  @override
  void dispose() {
    _gameStateSubscription?.cancel();
    final gameService = ref.read(onlineGameServiceProvider);
    if (gameSessionId.isNotEmpty) {
      gameService.disposeGameSession(gameSessionId);
      gameService.setPlayerNotReady(gameSessionId);
    }
    super.dispose();
  }
}

// providers
final onlineGameStateNotifierProvider =
    StateNotifierProvider.family<OnlineGameNotifier, GameState, GameConfig>(
  (ref, config) {
    final supabase = ref.watch(supabaseProvider);
    return OnlineGameNotifier(ref, config, supabase);
  },
);
