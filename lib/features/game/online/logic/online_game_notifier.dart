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
import 'package:tic_tac_zwo/features/navigation/navigation_provider.dart';

import '../../core/data/models/player.dart';

class OnlineGameNotifier extends GameNotifier {
  final SupabaseClient supabase;
  Timer? _turnTimer;
  Timer? _rematchOfferTimer;

  Timer? _inactivityTimer;
  bool _isInactivityTimerActive = false;
  int _inactivityRemainingSeconds = GameState.turnDurationSeconds;

  final String gameSessionId;
  String? currentUserId;
  Map<String, dynamic>? _lastProcessedUpdate;

  StreamSubscription? _gameStateSubscription;
  bool _processingRemoteUpdate = false;
  bool _isLocalPlayerTurn = false;
  bool _isInitialGameLoad = true;

  OnlineGameService get _gameService => ref.read(onlineGameServiceProvider);

  OnlineGameNotifier(Ref ref, GameConfig gameConfig, this.supabase)
      : gameSessionId = gameConfig.gameSessionId ?? '',
        currentUserId = supabase.auth.currentUser?.id,
        super(
          ref,
          gameConfig.players,
          gameConfig.startingPlayer,
          initialOnlineGamePhase: OnlineGamePhase.waiting,
          currentPlayerId: gameConfig.startingPlayer.userId,
          initialLastStarterId: gameConfig.startingPlayer.userId,
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
      _gameService.updateGameSessionState(
        gameSessionId,
        lastStarterId: state.startingPlayer.userId,
      );
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

  void _startTurnTimer() {
    _turnTimer?.cancel();
    _turnTimer = Timer.periodic(
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

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _isInactivityTimerActive = true;
    _inactivityRemainingSeconds = GameState.turnDurationSeconds;

    state = state.copyWith(
      remainingSeconds: GameState.turnDurationSeconds,
    );

    Timer(
      Duration(seconds: _isInitialGameLoad ? 4 : 0),
      () {
        if (!mounted || !_isInactivityTimerActive) return;

        if (_isInitialGameLoad) {
          _isInitialGameLoad = false;
        }

        _inactivityTimer = Timer.periodic(
          Duration(seconds: 1),
          (timer) {
            if (_inactivityRemainingSeconds > 0) {
              _inactivityRemainingSeconds--;
            } else {
              _handleInactivityTimeout();
            }
          },
        );
      },
    );
  }

  void _handleInactivityTimeout() {
    _inactivityTimer?.cancel();
    _isInactivityTimerActive = false;
    _startTurnTimer();
  }

  void _cancelInactivityTimer() {
    _inactivityTimer?.cancel();
    _isInactivityTimerActive = false;
    _inactivityRemainingSeconds = GameState.turnDurationSeconds;
  }

  Future<void> selectCellOnline(int index) async {
    if (state.lastPlayedPlayer == null && _isInitialGameLoad) return;

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

    _cancelInactivityTimer();

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
      _startTurnTimer();
    }
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

    _turnTimer?.cancel();

    final int cellIndex = state.selectedCellIndex!;
    final GermanNoun currentNoun = state.currentNoun!;
    final bool isCorrectMove = currentNoun.article == selectedArticle;
    final previousPlayer = state.currentPlayer;

    // assign points locally
    if (isCorrectMove) {
      state =
          state.copyWith(correctMovesPerGame: state.correctMovesPerGame + 1);
    }

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
    final selectedCellIndex = state.selectedCellIndex!;

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
        selectedArticle: selectedArticle,
        isCorrect: isCorrectMove,
      );

      print(
          '[OnlineGameNotifier] Move sent to server. Waiting for remote update.');
    } catch (e) {
      print('[OnlineGameNotifier] Error making move in online mode: $e');
    }
  }

  @override
  Future<void> forfeitTurn() async {
    _turnTimer?.cancel();

    if (!_isLocalPlayerTurn ||
        _processingRemoteUpdate ||
        state.selectedCellIndex == null ||
        state.currentNoun == null ||
        state.isGameOver) {
      print(
          '[OnlineGameNotifier] Cannot forfeit turn: Invalid state for forfeiture.');
      return;
    }

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
              currentNounId: null,
              selectedCellIndex: null,
              revealedArticle: null,
              revealedArticleIsCorrect: null,
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
        selectedArticle: correctArticle,
        isCorrect: false,
      );

      print('[OnlineGameNotifier] Turn forfeited and state sent to server.');
    } catch (e) {
      print('[OnlineGameNotifier] Error forfeiting turn in online mode: $e');
    }
  }

  void _listenToGameSessionUpdates() {
    _gameStateSubscription =
        _gameService.getGameStateStream(gameSessionId).listen((gameData) async {
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

    if (!mounted) return;

    final String? remoteCurrentPlayerId = gameData['current_player_id'];
    final bool wasLocalPlayerTurn = _isLocalPlayerTurn;
    _isLocalPlayerTurn = remoteCurrentPlayerId == currentUserId;

    if (_isLocalPlayerTurn != wasLocalPlayerTurn) {
      if (_isLocalPlayerTurn &&
          !state.isGameOver &&
          state.onlineGamePhase == OnlineGamePhase.waiting) {
        _startInactivityTimer();
      } else if (!_isLocalPlayerTurn) {
        _cancelInactivityTimer();
        _turnTimer?.cancel();
      }
    }

    OnlineGamePhase serverPhase =
        OnlineGamePhaseExtension.fromString(gameData['online_game_phase']);
    OnlineGamePhase stateUpdatePhase = serverPhase;

    GermanNoun? noun;
    final String? currentNounId = gameData['current_noun_id'];

    if (currentNounId != null && currentNounId != state.currentNoun?.id) {
      final currentNoun =
          await ref.read(germanNounRepoProvider).getNounById(currentNounId);
      noun = currentNoun;
    } else if (currentNounId == null) {
      noun = null;
    } else {
      noun = state.currentNoun;
    }

    DateTime? updatedAt = gameData['updated_at'] != null
        ? DateTime.parse(gameData['updated_at'])
        : null;

    DateTime? newArticleRevealedAt = state.articleRevealedAt;
    if (gameData['revealed_article'] != null &&
        serverPhase == OnlineGamePhase.articleRevealed) {
      newArticleRevealedAt = updatedAt ?? DateTime.now();
    } else if (serverPhase != OnlineGamePhase.articleRevealed) {
      newArticleRevealedAt = null;
    }

    bool newIsTimerActive = _isLocalPlayerTurn &&
        (stateUpdatePhase == OnlineGamePhase.cellSelected);
    bool serverIsGameOver = gameData['is_game_over'] ?? false;

    // handle rematch logic
    OnlineRematchStatus newOnlineRematchStatus = OnlineRematchStatus.none;
    bool newLocalPlayerWantsRematch = false;
    bool newRemotePlayerWantsRematch = false;
    String? player1Id = gameData['player1_id'];
    String? player2Id = gameData['player2_id'];
    bool p1Ready = gameData['player1_ready'] ?? false;
    bool p2Ready = gameData['player2_ready'] ?? false;

    if (serverIsGameOver) {
      if (currentUserId == player1Id) {
        newLocalPlayerWantsRematch = p1Ready;
        newRemotePlayerWantsRematch = p2Ready;
      } else if (currentUserId == player2Id) {
        newLocalPlayerWantsRematch = p2Ready;
        newRemotePlayerWantsRematch = p1Ready;
      }

      if (newLocalPlayerWantsRematch && newRemotePlayerWantsRematch) {
        newOnlineRematchStatus = OnlineRematchStatus.bothAccepted;
      } else if (newLocalPlayerWantsRematch) {
        newOnlineRematchStatus = OnlineRematchStatus.localOffered;
      } else if (newRemotePlayerWantsRematch) {
        newOnlineRematchStatus = OnlineRematchStatus.remoteOffered;
      } else {
        newOnlineRematchStatus = OnlineRematchStatus.none;
      }
    } else {
      newOnlineRematchStatus = OnlineRematchStatus.none;
    }

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
      player1Score: state.player1Score,
      player2Score: state.player2Score,
      gamesPlayed: state.gamesPlayed,
      isTimerActive: newIsTimerActive,
      onlineGamePhase: stateUpdatePhase,
      lastStarterId: gameData['last_starter_id'] ?? state.lastStarterId,
      onlineRematchStatus: newOnlineRematchStatus,
      localPlayerWantsRematch: newLocalPlayerWantsRematch,
      remotePlayerWantsRematch: newRemotePlayerWantsRematch,
    );

    if (stateUpdatePhase == OnlineGamePhase.waiting &&
        _isLocalPlayerTurn &&
        !state.isGameOver) {
      state = state.copyWith(
        cellPressed: List.filled(9, false),
        selectedCellIndex: null,
        currentNoun: null,
        revealedArticle: null,
        revealedArticleIsCorrect: null,
        articleRevealedAt: null,
        remainingSeconds: GameState.turnDurationSeconds,
      );
    } else if (_isLocalPlayerTurn &&
        state.onlineGamePhase == OnlineGamePhase.cellSelected &&
        state.isTimerActive &&
        state.remainingSeconds == GameState.turnDurationSeconds) {
      _startTurnTimer();
    }

    if (!state.isGameOver) {
      _rematchOfferTimer?.cancel();
    }

    print(
        '[OnlineGameNotifier] Final state after remote update: Phase: ${state.onlineGamePhase}, isLocalTurn: $_isLocalPlayerTurn, CurrentPlayerID: ${state.currentPlayerId}');
  }

  @override
  void handleWinOrDraw() {
    super.handleWinOrDraw();

    if (state.isGameOver) {
      int pointsPerGame = state.correctMovesPerGame;
      if (state.winningPlayer?.userId == currentUserId) {
        pointsPerGame += 3;
      } else if (state.winningPlayer == null) {
        pointsPerGame += 1;
      }
      state = state.copyWith(pointsEarnedPerGame: pointsPerGame);

      _gameService.updateGameSessionState(
        gameSessionId,
        isGameOver: true,
        winnerId: state.winningPlayer?.userId,
        player1Ready: false,
        player2Ready: false,
      );
    }
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

  TimerDisplayState get timerDisplayState {
    if (!_isLocalPlayerTurn || state.isGameOver) {
      return TimerDisplayState.static;
    }

    // local player + no cell selected
    if (state.selectedCellIndex == null && _isInactivityTimerActive) {
      return TimerDisplayState.inactivity;
    }

    // cell selected
    if (state.selectedCellIndex != null && state.isTimerActive) {
      return TimerDisplayState.countdown;
    }

    return TimerDisplayState.static;
  }

  // rematch methods
  Future<void> requestMatch() async {
    if (!state.isGameOver || currentUserId == null) return;
    _rematchOfferTimer?.cancel();

    state =
        state.copyWith(onlineRematchStatus: OnlineRematchStatus.localOffered);
    try {
      await _gameService.setPlayerRematchStatus(
          gameSessionId, currentUserId!, true);
      _rematchOfferTimer = Timer(const Duration(seconds: 30), () {
        if (state.onlineRematchStatus == OnlineRematchStatus.localOffered) {
          handleRematchTimeout();
        }
      });
    } catch (e) {
      print("[OnlineGameNotifier] Error requesting rematch: $e");
      state = state.copyWith(onlineRematchStatus: OnlineRematchStatus.none);
    }
  }

  Future<void> cancelRematchRequest() async {
    if (!state.isGameOver ||
        currentUserId == null ||
        state.onlineRematchStatus != OnlineRematchStatus.localOffered) {
      return;
    }
    _rematchOfferTimer?.cancel();

    state =
        state.copyWith(onlineRematchStatus: OnlineRematchStatus.localCancelled);
    try {
      await _gameService.setPlayerRematchStatus(
          gameSessionId, currentUserId!, false);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted &&
            state.onlineRematchStatus == OnlineRematchStatus.localCancelled) {
          state = state.copyWith(onlineRematchStatus: OnlineRematchStatus.none);
        }
      });
    } catch (e) {
      print("[OnlineGameNotifier] Error cancelling rematch request: $e");
    }
  }

  Future<void> acceptRematch() async {
    if (!state.isGameOver ||
        currentUserId == null ||
        state.onlineRematchStatus != OnlineRematchStatus.remoteOffered) {
      return;
    }
    _rematchOfferTimer?.cancel();

    state =
        state.copyWith(onlineRematchStatus: OnlineRematchStatus.bothAccepted);
    try {
      await _gameService.setPlayerRematchStatus(
          gameSessionId, currentUserId!, true);
      await initiateNewGameAfterRematch();
    } catch (e) {
      print("[OnlineGameNotifier] Error accepting rematch: $e");
      // revert status, may need to re-sync from server?
      state = state.copyWith(
          onlineRematchStatus: OnlineRematchStatus.remoteOffered);
    }
  }

  Future<void> declineRematch() async {
    if (!state.isGameOver ||
        currentUserId == null ||
        state.onlineRematchStatus == OnlineRematchStatus.remoteOffered) {
      return;
    }
    _rematchOfferTimer?.cancel();

    state =
        state.copyWith(onlineRematchStatus: OnlineRematchStatus.localDeclined);
    try {
      final Player opponent =
          state.players.firstWhere((player) => player.userId != currentUserId);
      await _gameService.setPlayerRematchStatus(
          gameSessionId, currentUserId!, false);
      await _gameService.setPlayerRematchStatus(
          gameSessionId, opponent.userId!, false);

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted &&
            state.onlineRematchStatus == OnlineRematchStatus.localDeclined) {
          state = state.copyWith(onlineRematchStatus: OnlineRematchStatus.none);
        }
      });
    } catch (e) {
      print("[OnlineGameNotifier] Error declining rematch: $e");
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

  Future<void> initiateNewGameAfterRematch() async {
    if (currentUserId == null || state.lastStarterId == null) {
      print(
          "[OnlineGameNotifier] Cannot initiate rematch: missing user ID or last starter ID.");
      state = state.copyWith(onlineRematchStatus: OnlineRematchStatus.none);
      return;
    }
    _rematchOfferTimer?.cancel();

    final Player player1 = state.players[0];
    final Player player2 = state.players[1];
    final String newStarterId = (state.lastStarterId == player1.userId)
        ? player2.userId!
        : player1.userId!;

    state = state.copyWith(
      onlineRematchStatus: OnlineRematchStatus.bothAccepted,
      correctMovesPerGame: 0,
      pointsEarnedPerGame: null,
      allowNullPointsEarnedPerGame: true,
    );

    try {
      await _gameService.resetSessionForRematch(gameSessionId, newStarterId);
      print(
          "[OnlineGameNotifier] New game initiated after rematch. New starter: $newStarterId");
    } catch (e) {
      print("[OnlineGameNotifier] Error initiating new game after rematch: $e");
      state = state.copyWith(onlineRematchStatus: OnlineRematchStatus.none);
    }
  }

  void handleRematchTimeout() {
    if (state.onlineRematchStatus == OnlineRematchStatus.localOffered) {
      state = state.copyWith(onlineRematchStatus: OnlineRematchStatus.timeout);

      if (currentUserId != null) {
        _gameService.setPlayerRematchStatus(
            gameSessionId, currentUserId!, false);
      }
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted &&
            state.onlineRematchStatus == OnlineRematchStatus.timeout) {
          state = state.copyWith(onlineRematchStatus: OnlineRematchStatus.none);
        }
      });
    }
  }

  Future<void> findNewOpponent() async {
    _rematchOfferTimer?.cancel();
    _turnTimer?.cancel();

    if (currentUserId != null && state.isGameOver) {
      await _gameService.setPlayerRematchStatus(
          gameSessionId, currentUserId!, false);
    }
    ref.read(navigationTargetProvider.notifier).state =
        NavigationTarget.matchmaking;

    print(
        "[OnlineGameNotifier] Player chose to find new opponent. Leaving session $gameSessionId.");
  }

  Future<void> goHomeAndCleanupSession() async {
    _rematchOfferTimer?.cancel();
    _turnTimer?.cancel();

    if (currentUserId != null && state.isGameOver) {
      await _gameService.setPlayerRematchStatus(
          gameSessionId, currentUserId!, false);
    }

    ref.read(navigationTargetProvider.notifier).state = NavigationTarget.home;
  }

  bool get canLocalPlayerMakeMove {
    final result =
        _isLocalPlayerTurn && !state.isGameOver && !_processingRemoteUpdate;
    return result;
  }

  bool get isInactivityTimerActive => _isInactivityTimerActive;

  @override
  void dispose() {
    _turnTimer?.cancel();
    _inactivityTimer?.cancel();
    _rematchOfferTimer?.cancel();
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
