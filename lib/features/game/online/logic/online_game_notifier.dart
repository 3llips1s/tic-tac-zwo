import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tic_tac_zwo/features/game/core/data/models/game_config.dart';
import 'package:tic_tac_zwo/features/game/core/data/repositories/german_noun_repo.dart';
import 'package:tic_tac_zwo/features/game/core/logic/game_notifier.dart';
import 'package:tic_tac_zwo/features/game/core/logic/game_state.dart';
import 'package:tic_tac_zwo/features/game/online/data/services/matchmaking_service.dart';
import 'package:tic_tac_zwo/features/game/online/data/services/online_game_service.dart';

import '../../core/data/models/player.dart';

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
    if (gameSessionId.isNotEmpty && currentUserId != null) {
      _initOnlineGame();
    } else {
      if (gameSessionId.isEmpty) {
        print(
            '[OnlineGameNotifier] Game Session ID is empty. Cannot initialize online game.');
      }
      if (currentUserId == null) {
        print(
            '[OnlineGameNotifier] Current User ID is null. Cannot initialize online game.');
      }
    }
  }

  void _initOnlineGame() async {
    final gameService = ref.read(onlineGameServiceProvider);

    // get initial game session data
    try {
      final initialSessionData =
          await gameService.getGameSession(gameSessionId);
      if (initialSessionData.isEmpty) {
        print(
            '[OnlineGameNotifier] Failed to fetch initial game session data or data is empty for session $gameSessionId.');
        // Handle error appropriately, maybe notify user or retry
        return;
      }

      gameSessionData = initialSessionData;

      final serverCurrentPlayerId = gameSessionData?['current_player_id'];
      _isLocalPlayerTurn = serverCurrentPlayerId == currentUserId;

      // sync current player with server's current_player_id
      _syncLocalTurnWithServer(serverCurrentPlayerId);

      // update initial opponent ready state
      _updateLocalOpponentReadyStatus(gameSessionData!);

      // initialize player ready status
      print(
          '[OnlineGameNotifier] Setting player $currentUserId as ready for session $gameSessionId.');
      await gameService.setPlayerReady(gameSessionId);

      // sub to game state updates
      await _gameStateSubscription?.cancel();
      _gameStateSubscription = gameService
          .getGameStateStream(gameSessionId)
          .listen(_handleGameStateUpdate, onError: (error) {
        print(
            '[OnlineGameNotifier] Error in game state stream for session $gameSessionId: $error');
      });
      // Handle stream errors, e.g., retry subscription or notify user.
      print(
          '[OnlineGameNotifier] Subscribed to game state stream for session $gameSessionId.');
    } catch (e) {
      print(
          '[OnlineGameNotifier] Critical error initializing online game for session $gameSessionId: $e');
    }
  }

  void _syncLocalTurnWithServer(String? serverCurrentPlayerId) {
    if (serverCurrentPlayerId == null) {
      print(
          '[OnlineGameNotifier] _synchronizeLocalTurnWithServer: serverActualCurrentPlayerId is null. Cannot synchronize. For session $gameSessionId');
      return;
    }

    // todo: remove this after testing
    if (state.players.length != 2) {
      print(
          '[OnlineGameNotifier] _synchronizeLocalTurnWithServer: state.players list is not set up correctly (length != 2). Cannot synchronize. For session $gameSessionId');
      return;
    }

    Player? serverDesignatedCurrentPlayer;
    Player? serverDesignatedOpponent;

    try {
      serverDesignatedCurrentPlayer = state.players
          .firstWhere((player) => player.userId == serverCurrentPlayerId);
      serverDesignatedOpponent = state.players
          .firstWhere((player) => player.userId != serverCurrentPlayerId);
    } catch (e) {
      print(
          '[OnlineGameNotifier] _synchronizeLocalTurnWithServer: ERROR - Could not find player with ID $serverCurrentPlayerId in local state.players for session $gameSessionId. Local players: ${state.players.map((p) => "ID:${p.userId}").toList()}');
      return;
    }

    Player? newLastPlayedPlayer;
    final bool boardIsEmpty = state.board.every((cell) => cell == null);

    if (state.startingPlayer.userId == serverDesignatedCurrentPlayer.userId &&
        boardIsEmpty) {
      newLastPlayedPlayer = null;
    } else {
      newLastPlayedPlayer = serverDesignatedOpponent;
    }

    if (state.lastPlayedPlayer != newLastPlayedPlayer ||
        (state.lastPlayedPlayer == null && newLastPlayedPlayer != null) ||
        (state.lastPlayedPlayer != null && newLastPlayedPlayer == null)) {
      state = state.copyWith(
          lastPlayedPlayer: newLastPlayedPlayer,
          allowNullLastPlayedPlayer: true);
      print(
          '[OnlineGameNotifier] _synchronizeLocalTurnWithServer: Local turn synced with server for session $gameSessionId. Server current_player_id: $serverCurrentPlayerId. New local GameState.currentPlayer: ID=${state.currentPlayer.userId}, Symbol=${state.currentPlayer.symbolString}. LastPlayed: ${state.lastPlayedPlayer?.userId}');
    } else {
      print(
          '[OnlineGameNotifier] _synchronizeLocalTurnWithServer: Local turn already matches server. GameState.currentPlayer: ID=${state.currentPlayer.userId}, Symbol=${state.currentPlayer.symbolString}. For session $gameSessionId');
    }
  }

  void _updateLocalOpponentReadyStatus(
      Map<String, dynamic> currentSessionData) {
    if (currentUserId == null) {
      if (state.isOpponentReady) state = state.copyWith(isOpponentReady: false);
      return;
    }

    final String? player1Id = currentSessionData['player1_id'];
    final String? player2Id = currentSessionData['player2_id'];
    final bool player1Ready = currentSessionData['player1_ready'] ?? false;
    final bool player2Ready = currentSessionData['player2_ready'] ?? false;

    bool newOpponentReadyState = false;
    if (currentUserId == player1Id) {
      newOpponentReadyState = player2Ready;
    } else if (currentUserId == player2Id) {
      newOpponentReadyState = player1Ready;
    }

    if (state.isOpponentReady != newOpponentReadyState) {
      print(
          '[OnlineGameNotifier] Opponent ready state changed to: $newOpponentReadyState for session $gameSessionId');
      state = state.copyWith(isOpponentReady: newOpponentReadyState);
    }
  }

  @override
  void loadTurnNoun() async {
    if (!_isLocalPlayerTurn || _processingRemoteUpdate) return;

    super.loadTurnNoun();

    // update loaded noun to server
    if (state.currentNoun != null && gameSessionId.isNotEmpty) {
      final gameService = ref.read(onlineGameServiceProvider);
      final currentNounId = state.currentNoun!.id;
      print(
          '[OnlineGameNotifier] Local player loaded noun ${state.currentNoun!.noun}. Updating server for session $gameSessionId.');

      try {
        await gameService.updateGameState(
          gameSessionId,
          currentNounId: currentNounId,
        );
      } catch (e) {
        print(
            '[OnlineGameNotifier] Error updating current_noun_id to server: $e');
      }
    }
  }

  @override
  Future<void> selectCell(int index) async {
    if (!_isLocalPlayerTurn || _processingRemoteUpdate) {
      print(
          '[OnlineGameNotifier] selectCell blocked: isLocalPlayerTurn: $_isLocalPlayerTurn, processingRemoteUpdate: $_processingRemoteUpdate');
      return;
    }

    super.selectCell(index);

    if (gameSessionId.isNotEmpty && state.selectedCellIndex != null) {
      final gameService = ref.read(onlineGameServiceProvider);
      print(
          '[OnlineGameNotifier] Local player selected cell ${state.selectedCellIndex}. Updating server for session $gameSessionId.');
      try {
        // send selected cell index and current noun id
        await gameService.updateGameState(
          gameSessionId,
          selectedCellIndex: state.selectedCellIndex,
          currentNounId: state.currentNoun?.id,
        );
      } catch (e) {
        print(
            '[OnlineGameNotifier] Error updating selected_cell_index to server: $e');
      }
    }
  }

  @override
  void makeMove(String selectedArticle) async {
    if (!_isLocalPlayerTurn || _processingRemoteUpdate) {
      print(
          '[OnlineGameNotifier] makeMove blocked: isLocalPlayerTurn: $_isLocalPlayerTurn, processingRemoteUpdate: $_processingRemoteUpdate');
      return;
    }
    ;
    if (state.selectedCellIndex == null ||
        !state.isTimerActive ||
        gameSessionId.isEmpty) {
      print(
          '[OnlineGameNotifier] makeMove blocked: local state check failed (no cell selected, timer not active, or no session ID).');
      return;
    }

    // _processingRemoteUpdate = true;
    final int committedCellIndex = state.selectedCellIndex!;
    final String? committedNounId = state.currentNoun?.id;
    bool isCorrectMove = state.currentNoun?.article == selectedArticle;

    // identify current player
    Player playerMakingCurrentMove;
    try {
      playerMakingCurrentMove =
          state.players.firstWhere((player) => player.userId == currentUserId);
      print(
          '[OnlineGameNotifier] makeMove: Player making move (ID: ${playerMakingCurrentMove.userId}, Symbol: ${playerMakingCurrentMove.symbolString}) for $gameSessionId');
    } catch (e) {
      print(
          '[OnlineGameNotifier] makeMove: CRITICAL ERROR - currentUserId $currentUserId not found in state.players. Cannot make move for $gameSessionId.');
      return;
    }

    // update local state
    if (state.currentPlayer.userId != playerMakingCurrentMove.userId) {
      print(
          "[OnlineGameNotifier] makeMove: WARNING - Mismatch! state.currentPlayer.userId (${state.currentPlayer.userId}) != playerMakingTheMove.userId (${playerMakingCurrentMove.userId}) before super.makeMove(). This might lead to wrong symbol placement. For $gameSessionId");
    }

    super.makeMove(selectedArticle);

    print(
        '[OnlineGameNotifier] makeMove: Local state updated by super.makeMove() for $gameSessionId. New board: ${state.board}, GameOver: ${state.isGameOver}');

    // After super.makeMove(), state.board, state.isGameOver, state.winningPlayer are updated.
    print(
        '[OnlineGameNotifier] Local player made a move. Correct: $isCorrectMove. Board after local update: ${state.board}');
    print(
        '[OnlineGameNotifier] Game over after local update: ${state.isGameOver}, Winner: ${state.winningPlayer?.userId}');

    final gameService = ref.read(onlineGameServiceProvider);

    try {
      // record move attempt == record attempt
      if (committedNounId != null) {
        print(
            '[OnlineGameNotifier] Recording game round for session $gameSessionId.');
        await gameService.recordGameRound(
          gameSessionId,
          playerId: playerMakingCurrentMove.userId!,
          nounId: committedNounId,
          selectedArticle: selectedArticle,
          isCorrect: isCorrectMove,
          cellIndex: committedCellIndex,
        );
      } else {
        print(
            '[OnlineGameNotifier] Warning: committedNounId is null during makeMove. Round not recorded.');
      }
    } catch (e) {
      print('[OnlineGameNotifier] Error recording game round: $e');
    }

    // determine server's next player id
    final String? player1ServerId = gameSessionData?['player1_id'];
    final String? player2ServerId = gameSessionData?['player2_id'];
    String? nextPlayerUserId;

    if (player1ServerId != null &&
        player2ServerId != null &&
        currentUserId != null) {
      nextPlayerUserId = (currentUserId == player1ServerId)
          ? player2ServerId
          : player1ServerId;
    } else {
      print(
          "[OnlineGameNotifier] ERROR: Player IDs not found in gameSessionData. Cannot determine next player.");
      return;
    }

    print(
        '[OnlineGameNotifier] Current player: $currentUserId, Next player determined: $nextPlayerUserId for session $gameSessionId.');

    try {
      // update the game state over the server with full info
      print(
          '[OnlineGameNotifier] Updating game state on server for session $gameSessionId. Board: ${state.board}, Next Player: $nextPlayerUserId, Game Over: ${state.isGameOver}');
      await gameService.updateGameState(
        gameSessionId,
        board: state.board,
        selectedCellIndex: null,
        currentPlayerId: state.isGameOver ? null : nextPlayerUserId,
        currentNounId: null,
        isGameOver: state.isGameOver,
        winnerId: state.winningPlayer?.userId,
      );
      print(
          '[OnlineGameNotifier] makeMove: Update sent to server for $gameSessionId. Waiting for stream to confirm turn.');
    } catch (e) {
      print(
          '[OnlineGameNotifier] Error updating game state to server after move: $e');
      // on error, restore local interaction ability
    } finally {
      _processingRemoteUpdate = false;
    }
  }

  @override
  void forfeitTurn() {
    if (!_isLocalPlayerTurn || _processingRemoteUpdate) return;

    super.forfeitTurn();
    print(
        '[OnlineGameNotifier] forfeitTurn: Local state updated by super.forfeitTurn() for $gameSessionId.');

    final gameService = ref.read(onlineGameServiceProvider);

    final String? player1ServerId = gameSessionData?['player1_id'];
    final String? player2ServerId = gameSessionData?['player2_id'];
    String? nextPlayerUserId;

    if (player1ServerId != null && player2ServerId != null) {
      nextPlayerUserId = (currentUserId == player1ServerId)
          ? player2ServerId
          : player1ServerId;
    } else {
      print(
          "[OnlineGameNotifier] ERROR: Player IDs not found in gameSessionData during forfeit. Cannot determine next player.");
      return;
    }

    print(
        '[OnlineGameNotifier] forfeitTurn: Local player $currentUserId forfeited. Updating server. Next player: $nextPlayerUserId for session $gameSessionId.');

    gameService
        .updateGameState(
      gameSessionId,
      selectedCellIndex: null,
      currentPlayerId: nextPlayerUserId,
      currentNounId: null,
      board: state.board,
      isGameOver: state.isGameOver,
      winnerId: state.winningPlayer?.userId,
    )
        .then((_) {
      print(
          '[OnlineGameNotifier] Forfeit successful. Turn passed to $nextPlayerUserId on server for session $gameSessionId.');
    }).catchError((e) {
      // todo: consider how to handle: revert local forfeit?
      print(
          '[OnlineGameNotifier] Error updating game state to server for forfeit: $e for session $gameSessionId.');
    });
  }

  void _handleGameStateUpdate(Map<String, dynamic> remoteGameSessionData) {
    if (remoteGameSessionData.isEmpty) {
      print(
          '[OnlineGameNotifier] Received empty game session data from stream for session $gameSessionId.');
      return;
    }

    if (_isIdenticalToLastUpdate(remoteGameSessionData)) {
      print(
          '[OnlineGameNotifier] Received identical game state data, skipping processing for session $gameSessionId.');
      return;
    }

    print(
        '[OnlineGameNotifier] Received new game state from stream for session $gameSessionId: $remoteGameSessionData');

    _processingRemoteUpdate = true;
    gameSessionData = remoteGameSessionData;

    try {
      _updateLocalOpponentReadyStatus(remoteGameSessionData);

      // update turn information
      final remoteCurrentPlayerId = remoteGameSessionData['current_player_id'];
      final remoteIsGameOver = remoteGameSessionData['is_game_over'] ?? false;
      final remoteBoard = List<String?>.from(
          remoteGameSessionData['board'] ?? List.filled(9, null));

      // update _isLocalPlayerTurn from server data
      final newIsLocalPlayerTurn =
          (remoteCurrentPlayerId == currentUserId) && !remoteIsGameOver;
      if (_isLocalPlayerTurn != newIsLocalPlayerTurn) {
        print(
            '[OnlineGameNotifier] _handleGameStateUpdate: Local turn flag changing for $gameSessionId. Was: $_isLocalPlayerTurn, Now: $newIsLocalPlayerTurn. Server current_player_id: $remoteCurrentPlayerId');
        _isLocalPlayerTurn = newIsLocalPlayerTurn;
      }

      // sync local game state's currentPlayer with server's current player_id
      if (!remoteIsGameOver) {
        _syncLocalTurnWithServer(remoteCurrentPlayerId);
      } else {
        print(
            '[OnlineGameNotifier] _handleGameStateUpdate: Game is over according to server for $gameSessionId. _isLocalPlayerTurn set to false.');
      }

      // update board state
      if (state.board.toString() != remoteBoard.toString()) {
        print(
            '[OnlineGameNotifier] _handleGameStateUpdate: Board changed remotely for $gameSessionId.');
        state = state.copyWith(board: remoteBoard);
      }

      // handle opponent cell selection
      final remoteSelectedCell = remoteGameSessionData['selected_cell_index'];
      if (!_isLocalPlayerTurn &&
          remoteSelectedCell != null &&
          remoteSelectedCell != state.selectedCellIndex) {
        print(
            '[OnlineGameNotifier] Opponent selected cell $remoteSelectedCell for session $gameSessionId.');

        var newCellPressed = List.filled(9, false);
        newCellPressed[remoteSelectedCell] = true;

        state = state.copyWith(
          selectedCellIndex: remoteSelectedCell,
          allowNullSelectedCellIndex: true,
          cellPressed: newCellPressed,
        );
      } else if (_isLocalPlayerTurn &&
          state.selectedCellIndex != null &&
          remoteSelectedCell == null) {
        state = state.copyWith(
            selectedCellIndex: null,
            allowNullSelectedCellIndex: true,
            cellPressed: List.filled(9, false));
      }

      // handle current noun from opponent
      final remoteNounId = remoteGameSessionData['current_noun_id'];
      if (remoteNounId != null &&
          (state.currentNoun == null ||
              state.currentNoun!.id != remoteNounId)) {
        print(
            '[OnlineGameNotifier] Remote noun ID $remoteNounId received. Loading noun for session $gameSessionId.');
        _loadNounFromId(remoteNounId);
      } else if (remoteNounId == null && state.currentNoun != null) {
        print(
            '[OnlineGameNotifier] _handleGameStateUpdate: Remote noun ID is null. Clearing local noun for $gameSessionId.');
        state = state.copyWith(currentNoun: null, allowNullCurrentNoun: true);
      }

      // check game over state from remote
      if (remoteIsGameOver && !state.isGameOver) {
        final remoteWinnerId = remoteGameSessionData['winner_id'];
        Player? winningPlayer;
        if (remoteWinnerId != null) {
          try {
            winningPlayer = state.players
                .firstWhere((player) => player.userId == remoteWinnerId);
          } catch (e) {
            print(
                "[OnlineGameNotifier] Winner ID $remoteWinnerId not found in local players list: ${state.players.map((p) => p.userId).toList()}. Error: $e");
            winningPlayer = null;
          }
        }

        print(
            '[OnlineGameNotifier] _handleGameStateUpdate: Game over remotely for $gameSessionId. Winner: $remoteWinnerId');

        state = state.copyWith(
          isGameOver: true,
          winningPlayer: winningPlayer,
          allowNullWinningPlayer: true,
          selectedCellIndex: null,
          allowNullSelectedCellIndex: true,
          currentNoun: null,
          allowNullCurrentNoun: true,
          isTimerActive: false,
        );
        _isLocalPlayerTurn = false;
      } else if (!remoteIsGameOver && state.isGameOver) {
        print(
            '[OnlineGameNotifier] _handleGameStateUpdate: Game reset by server for $gameSessionId (was game over locally).');

        // Potentially reset local game state if a rematch is signaled through these fields.
        state = state.copyWith(
          isGameOver: false,
          winningPlayer: null,
          allowNullWinningPlayer: true,
          board: remoteBoard,
        );

        // todo: consider (more specific) remote_rematch()
        _syncLocalTurnWithServer(remoteCurrentPlayerId);
        _isLocalPlayerTurn =
            (remoteCurrentPlayerId == currentUserId) && !remoteIsGameOver;
      }

      // ui cleanup when it's local player's turn
      if (_isLocalPlayerTurn &&
          !state.isGameOver &&
          (state.selectedCellIndex != null || state.isTimerActive)) {
        if (remoteSelectedCell == null) {
          print(
              '[OnlineGameNotifier] _handleGameStateUpdate: Clean start for local player\'s turn on $gameSessionId (clearing local selection/timer).');
          state = state.copyWith(
              isTimerActive: false, cellPressed: List.filled(9, false));
        }
      }
    } catch (e, s) {
      print(
          '[OnlineGameNotifier] Error processing game state update for session $gameSessionId: $e');
      print(s);
    } finally {
      if (mounted) {
        Future.delayed(
          Duration(milliseconds: 50),
          () {
            if (mounted) _processingRemoteUpdate = false;
          },
        );
      } else {
        _processingRemoteUpdate = false;
      }
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
      'winner_id',
      'player1_ready',
      'player2_ready',
      'last_activity'
    ];

    bool identical = true;
    for (var field in criticalFields) {
      // deep equality for lists
      if (field == 'board') {
        List? oldBoard = _lastProcessedUpdate![field];
        List? newBoard = newData[field];

        if (oldBoard?.toString() != newBoard?.toString()) {
          identical = false;
          break;
        }
      } else if (_lastProcessedUpdate![field] != newData[field]) {
        identical = false;
        break;
      }
    }

    if (!identical) {
      _lastProcessedUpdate = Map<String, dynamic>.from(newData);
      print(
          "[OnlineGameNotifier] Data is not identical to last update. New data: $newData");
    }
    return identical;
  }

  Future<void> _loadNounFromId(String nounId, {int retryCount = 3}) async {
    if (state.currentNoun?.id == nounId && state.currentNoun != null) return;

    print(
        '[OnlineGameNotifier] Loading noun by ID: $nounId for session $gameSessionId.');
    for (int attempt = 0; attempt < retryCount; attempt++) {
      try {
        final germanNounsRepository = ref.read(germanNounRepoProvider);
        final noun = await germanNounsRepository.getNounById(nounId);

        if (noun != null) {
          if (mounted) {
            state = state.copyWith(currentNoun: noun);
            print(
                '[OnlineGameNotifier] Successfully loaded noun: ${noun.noun} for session $gameSessionId.');
          }
          return;
        } else {
          print(
              '[OnlineGameNotifier] Noun with ID $nounId not found locally (attempt ${attempt + 1}).');
        }

        if (attempt < retryCount - 1) {
          await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
        }
      } catch (e) {
        print(
            '[OnlineGameNotifier] Error loading noun by ID $nounId (attempt ${attempt + 1}): $e for session $gameSessionId.');
        if (attempt == retryCount - 1) {
          // On last attempt, notify the user
          // todo:Consider setting a placeholder error noun or notifying the user
          print(
              '[OnlineGameNotifier] Failed to load noun $nounId after $retryCount attempts for session $gameSessionId.');
        } else {
          // Wait before retry with exponential backoff
          await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
        }
      }
      if (!mounted) return;
    }
  }

  @override
  void rematch() {
    super.rematch();

    print(
        '[OnlineGameNotifier] Local rematch initiated. Resetting local state for session $gameSessionId.');

    int currentP1Score = state.player1Score;
    int currentP2Score = state.player2Score;
    int currentGamesPlayed = state.gamesPlayed;

    state = GameState.initial(state.players, state.startingPlayer).copyWith(
      player1Score: currentP1Score,
      player2Score: currentP2Score,
      gamesPlayed: currentGamesPlayed,
      isOpponentReady: false,
    );

    if (gameSessionId.isNotEmpty) {
      final gameService = ref.read(onlineGameServiceProvider);
      final newStartingPlayerIdOnServer = state.currentPlayer.userId;

      // reset game session on server
      gameService
          .updateGameState(
        gameSessionId,
        board: List.filled(9, null),
        selectedCellIndex: null,
        currentNounId: null,
        isGameOver: null,
        winnerId: null,
        currentPlayerId: newStartingPlayerIdOnServer,
        // todo: add player ready state to avoid auto starting
      )
          .then(
        (_) async {
          print(
              '[OnlineGameNotifier] Server reset for rematch. Session $gameSessionId.');
          if (currentUserId != null) {
            await gameService.setPlayerReady(gameSessionId);
            print(
                '[OnlineGameNotifier] Local player set to ready for new game. Waiting for stream update for turn/opponent status.');
          }
        },
      ).catchError((e) {
        print(
            '[OnlineGameNotifier] Error resetting game state on server for rematch: $e for session $gameSessionId.');
      });
    }
  }

  @override
  void dispose() {
    _gameStateSubscription?.cancel();
    _gameStateSubscription = null;
    final gameService = ref.read(onlineGameServiceProvider);
    if (gameSessionId.isNotEmpty) {
      gameService.clientDisposeGameSessionResources(gameSessionId);
    }
    _lastProcessedUpdate = null;
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
