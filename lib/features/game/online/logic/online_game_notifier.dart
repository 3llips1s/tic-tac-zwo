import 'dart:async';
import 'dart:math';

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

  void _initOnlineGame() {
    final gameService = ref.read(onlineGameServiceProvider);
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
      gameService.updateGameState(
        gameSessionId,
        selectedCellIndex: state.selectedCellIndex,
      );
    }
  }

  @override
  void makeMove(String selectedArticle) async {
    if (!_isLocalPlayerTurn || _processingRemoteUpdate) return;
    if (state.selectedCellIndex == null ||
        !state.isTimerActive ||
        gameSessionId.isEmpty) return;

    bool isCorrect = state.currentNoun?.article == selectedArticle;

    super.makeMove(selectedArticle);

    final gameService = ref.read(onlineGameServiceProvider);

    await gameService.recordGameRound(
      gameSessionId,
      playerId: currentUserId ?? '',
      nounId: state.currentNoun?.id ?? '',
      selectedArticle: selectedArticle,
      isCorrect: isCorrect,
      cellIndex: state.selectedCellIndex!,
    );

    final nextPlayerId =
        state.lastPlayedPlayer?.userName == state.players[0].userName
            ? state.players[1].userName
            : state.players[0].userName;

    await gameService.updateGameState(
      gameSessionId,
      board: state.board,
      selectedCellIndex: null,
      currentPlayerId: nextPlayerId,
      isGameOver: state.isGameOver,
      winnerId: state.winningPlayer?.userName,
    );

    _isLocalPlayerTurn = false;
  }

  void _handleGameStateUpdate(Map<String, dynamic> gameSessionData) {
    if (gameSessionData.isEmpty) return;
    _processingRemoteUpdate = true;

    try {
      // update turn information
      final currentPlayerId = gameSessionData['current_player_id'];
      _isLocalPlayerTurn = currentPlayerId == currentUserId;

      if (!_isLocalPlayerTurn) {
        final remoteBoard = List<String?>.from(
            gameSessionData['board'] ?? List.filled(9, null));

        // check if board is different from local state
        bool boardChanged = false;
        for (int i = 0; i < 9; i++) {
          if (state.board[i] != remoteBoard[i]) {
            boardChanged = true;
            break;
          }
        }

        if (boardChanged) {
          state = state.copyWith(board: remoteBoard);
        }

        // handle cell selection from opponent
        final remoteSelectedCell = gameSessionData['selected_cell_index'];
        if (remoteSelectedCell != null &&
            remoteSelectedCell != state.selectedCellIndex) {
          var newCellPressed = List<bool>.from(state.cellPressed);
          newCellPressed[remoteSelectedCell] = true;

          state = state.copyWith(
            selectedCellIndex: remoteSelectedCell,
            cellPressed: newCellPressed,
          );
        }

        // handle current noun from opponent
        final remoteNounId = gameSessionData['current_noun_id'];
        if (remoteNounId != null && state.currentNoun == null) {
          _loadNounFromId(remoteNounId);
        }

        // check game over state
        final isGameOver = gameSessionData['is_game_over'] ?? false;
        if (isGameOver && !state.isGameOver) {
          final winnerId = gameSessionData['winner_id'];
          final winningPlayer = winnerId != null
              ? state.players.firstWhere((player) => player.userId == winnerId,
                  orElse: () => state.players[Random().nextInt(2)])
              : null;

          state = state.copyWith(
            isGameOver: true,
            winningPlayer: winningPlayer,
          );
        }
      }
    } finally {
      _processingRemoteUpdate = false;
    }
  }

  Future<void> _loadNounFromId(String nounId) async {
    try {
      final germanNounsRepository = ref.read(germanNounRepoProvider);
      final noun = await germanNounsRepository.getNounById(nounId);

      if (noun != null) {
        state = state.copyWith(currentNoun: noun);
      }
    } catch (e) {
      print('error loading noun by id: $e');
    }
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
