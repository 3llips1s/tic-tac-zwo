import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tic_tac_zwo/config/game_config/config.dart';
import 'package:tic_tac_zwo/features/game/core/data/models/game_config.dart';
import 'package:tic_tac_zwo/features/game/core/data/models/german_noun.dart';
import 'package:tic_tac_zwo/features/game/core/data/repositories/german_noun_repo.dart';
import 'package:tic_tac_zwo/features/game/core/logic/game_notifier.dart';
import 'package:tic_tac_zwo/features/game/core/logic/game_state.dart';
import 'package:tic_tac_zwo/features/game/online/data/services/matchmaking_service.dart';
import 'package:tic_tac_zwo/features/game/online/data/services/online_game_service.dart';

import '../../core/data/models/player.dart';

class OnlineGameNotifier extends GameNotifier {
  final SupabaseClient supabase;
  Timer? _timer;

  final String gameSessionId;
  String? currentUserId;
  Map<String, dynamic>? _lastProcessedUpdate;

  StreamSubscription? _gameStateSubscription;
  bool _processingRemoteUpdate = false;
  bool _isLocalPlayerTurn = false;

  OnlineGameNotifier(Ref ref, GameConfig gameConfig, this.supabase)
      : gameSessionId = gameConfig.gameSessionId ?? '',
        currentUserId = supabase.auth.currentUser?.id,
        super(
          ref,
          gameConfig.players,
          gameConfig.startingPlayer,
          initialOnlineGamePhase: OnlineGamePhase.waiting,
          currentPlayerId: gameConfig.startingPlayer.userId,
        ) {
    print('[DEBUG CONSTRUCTOR] gameSessionId: $gameSessionId');
    print('[DEBUG CONSTRUCTOR] currentUserId: $currentUserId');
    print(
        '[DEBUG CONSTRUCTOR] startingPlayer.userId: ${gameConfig.startingPlayer.userId}');

    _isLocalPlayerTurn = gameConfig.startingPlayer.userId == currentUserId;
    print(
        '[DEBUG CONSTRUCTOR] _isLocalPlayerTurn initialized to: $_isLocalPlayerTurn');
    print(
        '[DEBUG CONSTRUCTOR] Starting player: ${gameConfig.startingPlayer.userName}');
    print(
        '[DEBUG CONSTRUCTOR] Is local user the starting player? $_isLocalPlayerTurn');

    if (gameSessionId.isNotEmpty && currentUserId != null) {
      _listenToGameSessionUpdates();
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

  Future<void> selectCellOnline(int index) async {
    if (state.isGameOver ||
        _processingRemoteUpdate ||
        !_isLocalPlayerTurn ||
        state.board[index] != null) {
      print(
          '[OnlineGameNotifier] Cannot select cell: Game over, processing remote update, not local player\'s turn, or cell already taken.');
      return;
    }

    if (state.selectedCellIndex != null) {
      print(
          '[OnlineGameNotifier] Cell already selected, cannot select another.');
      return;
    }

    final noun = await ref.read(germanNounRepoProvider).loadRandomNoun();

    var newCellPressed = List<bool>.from(state.cellPressed);
    newCellPressed[index] = true;

    state = state.copyWith(
      cellPressed: newCellPressed,
      selectedCellIndex: index,
      currentNoun: noun,
      revealedArticle: null,
      revealedArticleIsCorrect: null,
      isTimerActive: true,
      onlineGamePhase: OnlineGamePhase.cellSelected,
      lastPlayedPlayer: null,
    );

    final gameService = ref.read(onlineGameServiceProvider);
    try {
      await gameService.updateGameSessionState(
        gameSessionId,
        selectedCellIndex: index,
        currentNounId: noun.id,
        revealedArticle: null,
        revealedArticleIsCorrect: null,
        onlineGamePhaseString: OnlineGamePhase.cellSelected.string,
      );
      print(
          '[OnlineGameNotifier] Cell $index selected and noun ${noun.noun} sent to server.');
    } catch (e) {
      print('[OnlineGameNotifier] Error sending cell selection to server: $e');

      state = state.copyWith(
        cellPressed: List<bool>.from(state.cellPressed),
        selectedCellIndex: null,
        currentNoun: null,
        isTimerActive: false,
        onlineGamePhase: OnlineGamePhase.waiting,
      );
    }

    if (_isLocalPlayerTurn) {
      _startTimer();
    }
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

  @override
  Future<void> makeMove(String selectedArticle) async {
    if (state.selectedCellIndex == null ||
        state.currentNoun == null ||
        !_isLocalPlayerTurn ||
        state.isGameOver ||
        _processingRemoteUpdate) {
      print(
          '[OnlineGameNotifier] Cannot make move: Invalid state for making a move.');
      return;
    }

    _timer?.cancel();

    final int cellIndex = state.selectedCellIndex!;
    final GermanNoun currentNoun = state.currentNoun!;
    final bool isCorrectMove = currentNoun.article == selectedArticle;

    final previousPlayer = state.currentPlayer;

    // update local state immediately
    state = state.copyWith(
      cellPressed: List<bool>.from(state.cellPressed),
      revealedArticle: selectedArticle,
      revealedArticleIsCorrect: isCorrectMove,
      articleRevealedAt: DateTime.now(),
      isTimerActive: false,
      onlineGamePhase: OnlineGamePhase.articleRevealed,
      lastPlayedPlayer: previousPlayer,
    );

    _applyMoveLocally(
      cellIndex,
      isCorrectMove,
      currentUserId!,
      selectedArticle,
      currentNoun.noun,
    );

    // remote state update
    final gameService = ref.read(onlineGameServiceProvider);

    final Player nextPlayer = state.players
        .firstWhere((player) => player.userId != previousPlayer.userId);
    final nextPlayerId = nextPlayer.userId;

    final GermanNoun nounPlayed = state.currentNoun!;
    final selectedCellIndex = state.selectedCellIndex;

    try {
      await gameService.updateGameSessionState(
        gameSessionId,
        board: state.board,
        selectedCellIndex: selectedCellIndex,
        currentNounId: nounPlayed.id,
        revealedArticle: selectedArticle,
        revealedArticleIsCorrect: isCorrectMove,
        currentPlayerId: nextPlayerId,
        isGameOver: state.isGameOver,
        winnerId: state.winningPlayer?.userId,
        onlineGamePhaseString: OnlineGamePhase.articleRevealed.string,
      );

      Timer(Duration(milliseconds: 1500), () async {
        if (!state.isGameOver && mounted) {
          try {
            await gameService.updateGameSessionState(
              gameSessionId,
              selectedCellIndex: null,
              currentNounId: null,
              revealedArticle: null,
              revealedArticleIsCorrect: null,
              onlineGamePhaseString: OnlineGamePhase.waiting.string,
            );
          } catch (e) {
            print('[OnlineGameNotifier] Error resetting phase to waiting: $e');
          }
        }
      });

      await gameService.recordGameRound(
        gameSessionId,
        playerId: currentUserId!,
        nounId: currentNoun.id,
        selectedArticle: selectedArticle,
        isCorrect: isCorrectMove,
        cellIndex: cellIndex,
      );

      print(
          '[OnlineGameNotifier] Move sent to server. Waiting for remote update.');
    } catch (e) {
      print('[OnlineGameNotifier] Error making move in online mode: $e');
    }
  }

  @override
  Future<void> forfeitTurn() async {
    _timer?.cancel();

    if (!_isLocalPlayerTurn ||
        _processingRemoteUpdate ||
        state.selectedCellIndex == null ||
        state.currentNoun == null ||
        state.isGameOver) {
      print(
          '[OnlineGameNotifier] Cannot forfeit turn: Invalid state for forfeiture.');
      return;
    }

    final int cellIndex = state.selectedCellIndex!;
    final GermanNoun currentNoun = state.currentNoun!;
    final String correctArticle = currentNoun.article;
    final Player previousPlayer = state.currentPlayer;

    // local feedback
    state = state.copyWith(
      revealedArticle: correctArticle,
      revealedArticleIsCorrect: false,
      articleRevealedAt: DateTime.now(),
      isTimerActive: false,
      onlineGamePhase: OnlineGamePhase.articleRevealed,
      lastPlayedPlayer: previousPlayer,
    );

    // remote update
    final gameService = ref.read(onlineGameServiceProvider);
    final nextPlayer = state.players
        .firstWhere((player) => player.userId != previousPlayer.userId);
    final nextPlayerId = nextPlayer.userId;

    try {
      await gameService.updateGameSessionState(
        gameSessionId,
        board: state.board,
        selectedCellIndex: null,
        currentNounId: null,
        revealedArticle: correctArticle,
        revealedArticleIsCorrect: false,
        currentPlayerId: nextPlayerId,
        isGameOver: state.isGameOver,
        winnerId: state.winningPlayer?.userId,
        onlineGamePhaseString: OnlineGamePhase.articleRevealed.string,
      );

      Timer(Duration(milliseconds: 1500), () async {
        if (!state.isGameOver && mounted) {
          try {
            await gameService.updateGameSessionState(
              gameSessionId,
              revealedArticle: null,
              currentNounId: null,
              selectedCellIndex: null,
              onlineGamePhaseString: OnlineGamePhase.waiting.string,
            );
            print(
                '[OnlineGameNotifier] Forfeit: Phase reset to waiting on server.');
          } catch (e) {
            print(
                '[OnlineGameNotifier] Forfeit: Error resetting phase to waiting: $e');
          }
        }
      });

      await gameService.recordGameRound(
        gameSessionId,
        playerId: currentUserId!,
        nounId: currentNoun.id,
        selectedArticle: correctArticle,
        isCorrect: false,
        cellIndex: cellIndex,
        isForfeited: true,
      );

      print('[OnlineGameNotifier] Turn forfeited and state sent to server.');
    } catch (e) {
      print('[OnlineGameNotifier] Error forfeiting turn in online mode: $e');
    }
  }

  void _listenToGameSessionUpdates() {
    final gameService = ref.read(onlineGameServiceProvider);
    _gameStateSubscription =
        gameService.getGameStateStream(gameSessionId).listen((gameData) async {
      if (_lastProcessedUpdate != null &&
          _lastProcessedUpdate!['current_player_id'] != null &&
          _lastProcessedUpdate!['updated_at'] == gameData['updated_at'] &&
          _lastProcessedUpdate!['selected_cell_index'] ==
              gameData['selected_cell_index'] &&
          _lastProcessedUpdate!['current_noun_id'] ==
              gameData['current_noun_id'] &&
          _lastProcessedUpdate!['revealed_article'] ==
              gameData['revealed_article'] &&
          _lastProcessedUpdate!['revealed_article_is_correct'] ==
              gameData['revealed_article_is_correct'] &&
          _lastProcessedUpdate!['current_player_id'] ==
              gameData['current_player_id'] &&
          _lastProcessedUpdate!['is_game_over'] == gameData['is_game_over'] &&
          _lastProcessedUpdate!['winner_id'] == gameData['winner_id']) {
        print('[OnlineGameNotifier] Skipping redundant update.');
        return;
      }

      _processingRemoteUpdate = true;
      _lastProcessedUpdate = gameData;
      print('[OnlineGameNotifier] Received remote update: $gameData');

      await _handleRemoteUpdate(gameData);
      _processingRemoteUpdate = false;
    }, onError: (e) {
      print('[OnlineGameNotifier] Error listening to game session: $e');
      _processingRemoteUpdate = false;
    });
  }

  Future<void> _handleRemoteUpdate(Map<String, dynamic> gameData) async {
    print('[DEBUG REMOTE UPDATE START]');
    print('[DEBUG] currentUserId: $currentUserId');
    print(
        '[DEBUG] gameData current_player_id: ${gameData['current_player_id']}');
    print('[DEBUG] _isLocalPlayerTurn BEFORE: $_isLocalPlayerTurn');

    final String? currentNounId = gameData['current_noun_id'];
    GermanNoun? noun;

    if (currentNounId != null && currentNounId != state.currentNoun?.id) {
      await _loadNounFromId(currentNounId);
      noun = state.currentNoun;
    } else if (currentNounId == null) {
      noun = null;
    } else {
      noun = state.currentNoun;
    }

    final String? remoteCurrentPlayerId = gameData['current_player_id'];
    final newIsLocalPlayerTurn =
        remoteCurrentPlayerId?.trim() == currentUserId?.trim();
    _isLocalPlayerTurn = newIsLocalPlayerTurn;

    if (!_isLocalPlayerTurn) {
      _timer?.cancel();
    }

    print('[DEBUG] _isLocalPlayerTurn AFTER: $_isLocalPlayerTurn');
    print(
        '[DEBUG] Comparison result: ${remoteCurrentPlayerId == currentUserId}');

    OnlineGamePhase serverPhase =
        OnlineGamePhaseExtension.fromString(gameData['online_game_phase']);
    OnlineGamePhase stateUpdatePhase = serverPhase;

    DateTime? updatedAt = gameData['updated_at'] != null
        ? DateTime.parse(gameData['updated_at'])
        : null;

    DateTime? newArticleRevealedAt = state.articleRevealedAt;
    if (gameData['revealed_article'] != null &&
        gameData['online_game_phase'] ==
            OnlineGamePhase.articleRevealed.string) {
      newArticleRevealedAt = updatedAt ?? DateTime.now();
    } else if (gameData['online_game_phase'] !=
        OnlineGamePhase.articleRevealed.string) {
      newArticleRevealedAt = null;
    }

    bool newIsTimerActive = _isLocalPlayerTurn &&
        (stateUpdatePhase == OnlineGamePhase.cellSelected);

    // update state with incoming data
    state = state.copyWith(
      board: List<String?>.from(gameData['board'] ?? List.filled(9, null)),
      selectedCellIndex: gameData['selected_cell_index'],
      allowNullSelectedCellIndex: true,
      currentNoun: noun,
      allowNullCurrentNoun: true,
      isGameOver: gameData['is_game_over'] ?? false,
      winningPlayer: gameData['winner_id'] != null
          ? state.players.firstWhere(
              (player) => player.userId == gameData['winner_id'],
              orElse: () => state.players.first,
            )
          : null,
      allowNullWinningPlayer: true,
      currentPlayerId: remoteCurrentPlayerId,
      revealedArticle: gameData['online_game_phase'] ==
              OnlineGamePhase.articleRevealed.string
          ? gameData['revealed_article']
          : null,
      allowNullRevealedArticle: true,
      revealedArticleIsCorrect: gameData['online_game_phase'] ==
              OnlineGamePhase.articleRevealed.string
          ? gameData['revealed_article_is_correct']
          : null,
      allowNullRevealedArticleIsCorrect: true,
      articleRevealedAt: newArticleRevealedAt,
      allowNullArticleRevealedAt: true,
      isTimerActive: newIsTimerActive,
      onlineGamePhase: stateUpdatePhase,
    );

    if (stateUpdatePhase == OnlineGamePhase.waiting && _isLocalPlayerTurn) {
      state = state.copyWith(
        cellPressed: List.filled(9, false),
        selectedCellIndex: null,
        currentNoun: null,
        revealedArticle: null,
        revealedArticleIsCorrect: null,
        articleRevealedAt: null,
      );
    }

    if (_isLocalPlayerTurn) {
      if (state.onlineGamePhase == OnlineGamePhase.waiting) {
        state = state.copyWith(remainingSeconds: GameState.turnDurationSeconds);
        print(
            '[OnlineGameNotifier] Remote state updated. Local player is now in WAITING. Phase: ${state.onlineGamePhase}, isLocalTurn: $_isLocalPlayerTurn');
      } else if (state.onlineGamePhase == OnlineGamePhase.cellSelected &&
          state.isTimerActive &&
          state.remainingSeconds == GameState.turnDurationSeconds) {
        _startTimer();
        print(
            '[OnlineGameNotifier] Remote state updated. Local player is in CELL_SELECTED. Phase: ${state.onlineGamePhase}, isLocalTurn: $_isLocalPlayerTurn, Timer Active: ${state.isTimerActive}');
      }
    } else {
      print(
          '[OnlineGameNotifier] Remote state updated. Opponent\'s turn. Phase: ${state.onlineGamePhase}, isLocalTurn: $_isLocalPlayerTurn');
      if (state.isTimerActive) {
        _timer?.cancel();
        state = state.copyWith(isTimerActive: false);
      }
    }

    print(
        '[OnlineGameNotifier] Final state after remote update: Phase: ${state.onlineGamePhase}, isLocalTurn: $_isLocalPlayerTurn, CurrentPlayerID: ${state.currentPlayerId}');
  }

  void _applyMoveLocally(int index, bool isCorrect, String playerId,
      String selectedArticle, String noun) {
    // update board
    if (isCorrect) {
      final updatedBoard = List<String?>.from(state.board);
      updatedBoard[index] = state.currentPlayer.symbolString;
      state = state.copyWith(board: updatedBoard);

      // check winner
      final (gameResult, winningPattern) = state.checkWinner();
      if (gameResult != null) {
        if (gameResult != 'Draw' && winningPattern != null) {
          state = state.copyWith(winningCells: winningPattern);
        }
        handleWinOrDraw();
      }
    }
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

  Future<void> resetGameForRematch(
      {String? newStartingPlayerIdOnServer}) async {
    final gameService = ref.read(onlineGameServiceProvider);

    if (gameSessionId.isNotEmpty) {
      state = state = state.copyWith(
        board: List.filled(9, null),
        selectedCellIndex: null,
        cellPressed: List<bool>.from(state.cellPressed),
        currentNoun: null, // clear current noun
        isGameOver: false,
        winningPlayer: null,
        startingPlayer: state.players
            .firstWhere((p) => p.userId == newStartingPlayerIdOnServer),
        currentPlayerId: newStartingPlayerIdOnServer,
        lastPlayedPlayer: null, // set new starting player
        revealedArticle: null,
        revealedArticleIsCorrect: null,
        articleRevealedAt: null, // clear timestamp
        isTimerActive: false,
        onlineGamePhase: OnlineGamePhase.waiting,
      );

      // send reset command to server
      await gameService
          .updateGameSessionState(
        gameSessionId,
        board: List.filled(9, null),
        selectedCellIndex: null,
        currentNounId: null,
        isGameOver: false,
        winnerId: null,
        currentPlayerId: newStartingPlayerIdOnServer,
        revealedArticle: null,
        revealedArticleIsCorrect: null,
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

  bool get canLocalPlayerMakeMove {
    print(
        '[DEBUG canLocalPlayerMakeMove] _isLocalPlayerTurn: $_isLocalPlayerTurn');
    print('[DEBUG canLocalPlayerMakeMove] currentUserId: $currentUserId');
    print(
        '[DEBUG canLocalPlayerMakeMove] state.currentPlayerId: ${state.currentPlayerId}');

    final result =
        _isLocalPlayerTurn && !state.isGameOver && !_processingRemoteUpdate;
    print('[DEBUG canLocalPlayerMakeMove] result: $result');
    return result;
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
