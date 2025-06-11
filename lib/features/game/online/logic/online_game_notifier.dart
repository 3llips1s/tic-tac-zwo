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

  DateTime? _lastUpdateTimestamp;

  StreamSubscription? _gameStateSubscription;
  bool _processingRemoteUpdate = false;
  bool _isLocalPlayerTurn = false;
  bool _isInitialGameLoad = true;
  bool _gameOverHandled = false;

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

      _startInitialDelayTimer();
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

  void _startInitialDelayTimer() {
    Timer(
      Duration(milliseconds: 3900),
      () {
        _isInitialGameLoad = false;

        if (_isLocalPlayerTurn && !state.isGameOver) {
          _startInactivityTimer();
        }
      },
    );
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
    print('[ONLINEGAMENOTIFIER] inactivity timer is active');
    _inactivityRemainingSeconds = GameState.turnDurationSeconds;

    state = state.copyWith(
      remainingSeconds: GameState.turnDurationSeconds,
    );

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
  }

  void _handleInactivityTimeout() {
    _inactivityTimer?.cancel();
    _isInactivityTimerActive = false;

    state = state.copyWith(
      isTimerActive: true,
      remainingSeconds: GameState.turnDurationSeconds,
    );
    _startTurnTimer();
  }

  void _cancelInactivityTimer() {
    _inactivityTimer?.cancel();
    _isInactivityTimerActive = false;
    _inactivityRemainingSeconds = GameState.turnDurationSeconds;
  }

  Future<void> selectCellOnline(int index) async {
    print('[DEBUG selectCellOnline] _isInitialGameLoad: $_isInitialGameLoad');
    print(
        '[DEBUG selectCellOnline] canLocalPlayerMakeMove: $canLocalPlayerMakeMove');
    print(
        '[DEBUG selectCellOnline] _isInactivityTimerActive: $_isInactivityTimerActive');
    print('[DEBUG selectCellOnline] state.isGameOver: ${state.isGameOver}');
    print(
        '[DEBUG selectCellOnline] _processingRemoteUpdate: $_processingRemoteUpdate');
    print('[DEBUG selectCellOnline] _isLocalPlayerTurn: $_isLocalPlayerTurn');
    if (_isInitialGameLoad) return;

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
    final Player previousPlayer = state.currentPlayer;
    final Player nextPlayer = state.players
        .firstWhere((player) => player.userId != previousPlayer.userId);

    // active player determines outcome
    var updatedBoard = List<String?>.from(state.board);
    bool isGameOver = false;
    Player? winner;
    List<int>? winningPattern;
    int p1Score = state.player1Score;
    int p2Score = state.player2Score;
    int gamesPlayed = state.gamesPlayed;

    if (isCorrectMove) {
      updatedBoard[cellIndex] = previousPlayer.symbolString;
      final (gameResult, pattern) = state.checkWinner();

      if (gameResult != null) {
        isGameOver = true;
        gamesPlayed++;
        winningPattern = pattern;
        if (gameResult != 'Draw') {
          winner = state.players
              .firstWhere((player) => player.symbolString == gameResult);
          if (winner.userId == state.players[0].userId) {
            p1Score++;
          } else {
            p2Score++;
          }
        }
      }
    }

    // update local state immediately
    state = state.copyWith(
      board: updatedBoard,
      revealedArticle: selectedArticle,
      revealedArticleIsCorrect: isCorrectMove,
      articleRevealedAt: DateTime.now(),
      isTimerActive: false,
      onlineGamePhase: OnlineGamePhase.articleRevealed,
      lastPlayedPlayer: previousPlayer,
      isGameOver: isGameOver,
      winningPlayer: winner,
      allowNullWinningPlayer: true,
      winningCells: winningPattern,
      player1Score: p1Score,
      player2Score: p2Score,
      gamesPlayed: gamesPlayed,
    );

    // remote state update
    final gameService = ref.read(onlineGameServiceProvider);

    try {
      await gameService.updateGameSessionState(
        gameSessionId,
        board: updatedBoard,
        currentPlayerId: nextPlayer.userId,
        isGameOver: isGameOver,
        winnerId: winner?.userId,
        player1Score: p1Score,
        player2Score: p2Score,
        revealedArticle: selectedArticle,
        revealedArticleIsCorrect: isCorrectMove,
        selectedCellIndex: cellIndex,
        currentNounId: currentNoun.id,
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

    if (!_isLocalPlayerTurn || _processingRemoteUpdate || state.isGameOver) {
      print(
          '[OnlineGameNotifier] Cannot forfeit turn: Invalid state for forfeiture.');
      return;
    }

    final Player previousPlayer = state.currentPlayer;
    final Player nextPlayer = state.players
        .firstWhere((player) => player.userId != previousPlayer.userId);
    final String nextPlayerId = nextPlayer.userId!;

    final gameService = ref.read(onlineGameServiceProvider);

    // player completely inactive and never selected cell
    if (state.selectedCellIndex == null || state.currentNoun == null) {
      print("[OnlineGameNotifier] Forfeiting turn due to total inactivity.");

      state = state.copyWith(
        isTimerActive: false,
        onlineGamePhase: OnlineGamePhase.waiting,
      );

      try {
        await gameService.updateGameSessionState(
          gameSessionId,
          currentPlayerId: nextPlayerId,
          onlineGamePhaseString: OnlineGamePhase.waiting.string,
          selectedCellIndex: null,
          currentNounId: null,
          revealedArticle: null,
          revealedArticleIsCorrect: null,
        );
        print(
            '[OnlineGameNotifier] Total inactivity forfeit: Turn passed to $nextPlayerId.');
      } catch (e) {
        print(
            '[OnlineGameNotifier] Error forfeiting turn (total inactivity): $e');
      }
    } else {
      print(
          "[OnlineGameNotifier] Forfeiting turn due to expired article selection timer.");
      final GermanNoun currentNoun = state.currentNoun!;
      final String correctArticle = currentNoun.article;

      state = state.copyWith(
        revealedArticle: correctArticle,
        revealedArticleIsCorrect: false,
        articleRevealedAt: DateTime.now(),
        isTimerActive: false,
        onlineGamePhase: OnlineGamePhase.articleRevealed,
        lastPlayedPlayer: previousPlayer,
      );

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
                onlineGamePhaseString: OnlineGamePhase.waiting.string,
              );
            } catch (e) {
              print(
                  '[OnlineGameNotifier] Forfeit: Error resetting phase to waiting: $e');
            }
          }
        });

        await gameService.recordGameRound(
          gameSessionId,
          playerId: currentUserId!,
          selectedArticle: null,
          isCorrect: false,
        );

        print('[OnlineGameNotifier] Timed-out forfeit sent to server.');
      } catch (e) {
        print('[OnlineGameNotifier] Error forfeiting turn (timed out): $e');
      }
    }
  }

  void _listenToGameSessionUpdates() {
    _gameStateSubscription =
        _gameService.getGameStateStream(gameSessionId).listen((gameData) async {
      final newTimeStamp = gameData['updated_at'] != null
          ? DateTime.tryParse(gameData['udpated_at'])
          : null;

      if (newTimeStamp != null &&
          _lastUpdateTimestamp != null &&
          (newTimeStamp.isBefore(_lastUpdateTimestamp!) ||
              newTimeStamp == _lastUpdateTimestamp)) {
        print('[OnlineGameNotifier] Skipping redundant update.');
        return;
      }

      _processingRemoteUpdate = true;
      print('[OnlineGameNotifier] Received remote update: $gameData');

      final previousTimestamp = _lastUpdateTimestamp;
      _lastUpdateTimestamp = newTimeStamp;

      print('[OnlineGameNotifier] Received remote update: $gameData');

      try {
        await _handleRemoteUpdate(gameData);
      } catch (e) {
        _lastUpdateTimestamp = previousTimestamp;
      }
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

    final GameState previousState = state;

    final String? serverCurrentPlayerId = gameData['current_player_id'];
    final bool wasLocalPlayerTurn = _isLocalPlayerTurn;
    _isLocalPlayerTurn = serverCurrentPlayerId == currentUserId;

    print(
        '[DEBUG TURN CALCULATION] remoteCurrentPlayerId: "$serverCurrentPlayerId"');
    print('[DEBUG TURN CALCULATION] currentUserId: "$currentUserId"');
    print(
        '[DEBUG TURN CALCULATION] Are they equal? ${serverCurrentPlayerId == currentUserId}');

    if (_isLocalPlayerTurn != wasLocalPlayerTurn) {
      print(
          '[DEBUG TURN CHANGE] wasLocalPlayerTurn: $wasLocalPlayerTurn, _isLocalPlayerTurn: $_isLocalPlayerTurn');
      print('[DEBUG TURN CHANGE] _isInitialGameLoad: $_isInitialGameLoad');
      print('[DEBUG TURN CHANGE] state.isGameOver: ${state.isGameOver}');
      print(
          '[DEBUG TURN CHANGE] state.onlineGamePhase: ${state.onlineGamePhase}');
      if (_isLocalPlayerTurn && !state.isGameOver) {
        // check incoming server phase
        OnlineGamePhase serverPhase =
            OnlineGamePhaseExtension.fromString(gameData['online_game_phase']);
        print('[DEBUG TURN CHANGE] serverPhase: $serverPhase');

        if (!_isInitialGameLoad) {
          print(
              '[DEBUG TURN CHANGE] Starting inactivity timer for subsequent turn');
          _startInactivityTimer();
        } else {
          print(
              '[DEBUG TURN CHANGE] Skipping inactivity timer - still initial load');
        }
      } else if (!_isLocalPlayerTurn) {
        _cancelInactivityTimer();
        _turnTimer?.cancel();
      }
    }

    OnlineGamePhase serverPhase =
        OnlineGamePhaseExtension.fromString(gameData['online_game_phase']);

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

    bool serverIsGameOver = gameData['is_game_over'] ?? false;

    // handle rematch logic
    OnlineRematchStatus newOnlineRematchStatus = OnlineRematchStatus.none;
    bool newLocalPlayerWantsRematch = false;
    bool newRemotePlayerWantsRematch = false;

    if (serverIsGameOver) {
      String? player1Id = gameData['player1_id'];
      bool p1Ready = gameData['player1_ready'] ?? false;
      bool p2Ready = gameData['player2_ready'] ?? false;

      if (currentUserId == player1Id) {
        newLocalPlayerWantsRematch = p1Ready;
        newRemotePlayerWantsRematch = p2Ready;
      } else {
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
    }

    // update state with incoming data
    state = state.copyWith(
      board: List<String?>.from(gameData['board'] ?? List.filled(9, null)),
      selectedCellIndex: gameData['selected_cell_index'],
      allowNullSelectedCellIndex: true,
      currentNoun: noun,
      allowNullCurrentNoun: true,
      isGameOver: serverIsGameOver,
      winningPlayer: gameData['winner_id'] != null
          ? state.players.firstWhere(
              (player) => player.userId == gameData['winner_id'],
            )
          : null,
      allowNullWinningPlayer: true,
      currentPlayerId: serverCurrentPlayerId,
      revealedArticle: gameData['revealed_article'],
      allowNullRevealedArticle: true,
      revealedArticleIsCorrect: gameData['revealed_article_is_correct'],
      allowNullRevealedArticleIsCorrect: true,
      articleRevealedAt: (gameData['revealed_article'] != null &&
              serverPhase == OnlineGamePhase.articleRevealed)
          ? DateTime.now()
          : null,
      allowNullArticleRevealedAt: true,
      player1Score: gameData['player1_score'] ?? previousState.player1Score,
      player2Score: gameData['player2_score'] ?? previousState.player2Score,
      gamesPlayed: state.gamesPlayed,
      isTimerActive:
          _isLocalPlayerTurn && (serverPhase == OnlineGamePhase.cellSelected),
      onlineGamePhase: serverPhase,
      lastStarterId: gameData['last_starter_id'] ?? state.lastStarterId,
      onlineRematchStatus: newOnlineRematchStatus,
      localPlayerWantsRematch: newLocalPlayerWantsRematch,
      remotePlayerWantsRematch: newRemotePlayerWantsRematch,
    );

    if (_isLocalPlayerTurn &&
        state.onlineGamePhase == OnlineGamePhase.cellSelected) {
      if (state.remainingSeconds == GameState.turnDurationSeconds) {
        _startTurnTimer();
      }
    }

    if (_isInitialGameLoad &&
        _isLocalPlayerTurn &&
        serverPhase == OnlineGamePhase.waiting &&
        !serverIsGameOver) {
      _isInitialGameLoad = false;
    }

    if (serverIsGameOver && !previousState.isGameOver) {
      _handleGameOver();
    }

    // reset ui for rematch
    if (!serverIsGameOver && previousState.isGameOver) {
      state = state.copyWith(
        pointsEarnedPerGame: null,
        allowNullPointsEarnedPerGame: true,
        winningCells: null,
        onlineRematchStatus: OnlineRematchStatus.none,
      );
      _gameOverHandled = false;
      print(
          '[OnlineGameNotifier] Final state after remote update: Phase: ${state.onlineGamePhase}, isLocalTurn: $_isLocalPlayerTurn, CurrentPlayerID: ${state.currentPlayerId}');
    }
  }

  void _handleGameOver() async {
    if (_gameOverHandled) return;
    _gameOverHandled = true;

    _turnTimer?.cancel();
    _cancelInactivityTimer();

    final correctMoves =
        await _gameService.getCorrectMoves(gameSessionId, currentUserId!);
    int pointsPerGame = correctMoves;
    if (state.winningPlayer?.userId == currentUserId) {
      pointsPerGame += 3;
    } else if (state.winningPlayer == null) {
      pointsPerGame += 1;
    }
    state = state.copyWith(pointsEarnedPerGame: pointsPerGame);

    if (state.winningPlayer != null) {
      final (_, winningPattern) = state.checkWinner();
      if (winningPattern != null) {
        state = state.copyWith(winningCells: winningPattern);
      }
    }
  }

  TimerDisplayState get timerDisplayState {
    print('[DEBUG TIMER STATE] _isLocalPlayerTurn: $_isLocalPlayerTurn');
    print('[DEBUG TIMER STATE] state.isGameOver: ${state.isGameOver}');
    print(
        '[DEBUG TIMER STATE] state.selectedCellIndex: ${state.selectedCellIndex}');
    print(
        '[DEBUG TIMER STATE] _isInactivityTimerActive: $_isInactivityTimerActive');
    print('[DEBUG TIMER STATE] state.isTimerActive: ${state.isTimerActive}');

    if (state.isGameOver) {
      return TimerDisplayState.static;
    }

    if (_isLocalPlayerTurn) {
      if (state.selectedCellIndex == null) {
        return _isInactivityTimerActive
            ? TimerDisplayState.inactivity
            : TimerDisplayState.static;
      } else {
        return state.isTimerActive
            ? TimerDisplayState.countdown
            : TimerDisplayState.static;
      }
    }

    return TimerDisplayState.static;
  }

  // rematch methods
  Future<void> requestRematch() async {
    if (!state.isGameOver || currentUserId == null) return;
    _rematchOfferTimer?.cancel();

    state = state.copyWith(
      onlineRematchStatus: OnlineRematchStatus.localOffered,
      localPlayerWantsRematch: true,
    );
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
    }
  }

  Future<void> cancelRematchRequest() async {
    if (!state.isGameOver || currentUserId == null) return;
    _rematchOfferTimer?.cancel();

    try {
      await _gameService.setPlayerRematchStatus(
          gameSessionId, currentUserId!, false);
    } catch (e) {
      print("[OnlineGameNotifier] Error cancelling rematch request: $e");
    }
  }

  Future<void> acceptRematch() async {
    if (!state.isGameOver || currentUserId == null) return;
    _rematchOfferTimer?.cancel();

    try {
      await _gameService.setPlayerRematchStatus(
          gameSessionId, currentUserId!, true);
    } catch (e) {
      print("[OnlineGameNotifier] Error accepting rematch: $e");
    }
  }

  Future<void> declineRematch() async {
    if (!state.isGameOver || currentUserId == null) return;
    _rematchOfferTimer?.cancel();

    try {
      await _gameService.setPlayerRematchStatus(
          gameSessionId, currentUserId!, false);
    } catch (e) {
      print("[OnlineGameNotifier] Error declining rematch: $e");
    }
  }

  Future<void> initiateNewGameAfterRematch() async {
    if (currentUserId == null ||
        state.lastStarterId == null ||
        _processingRemoteUpdate) {
      print(
          "[OnlineGameNotifier] Cannot initiate rematch: missing user ID or last starter ID.");
      return;
    }

    final Player newStarter =
        state.players.firstWhere((p) => p.userId != state.lastStarterId);

    if (currentUserId != newStarter.userId) return;

    _rematchOfferTimer?.cancel();

    print(
        "[OnlineGameNotifier] Both players accepted. This client is initiating the new game.");

    state = state.copyWith(
      onlineRematchStatus: OnlineRematchStatus.bothAccepted,
      pointsEarnedPerGame: null,
      allowNullPointsEarnedPerGame: true,
    );

    try {
      await _gameService.resetSessionForRematch(
          gameSessionId, newStarter.userId!);
      print(
          "[OnlineGameNotifier] New game initiated after rematch. New starter: ${newStarter.userName}");
    } catch (e) {
      print("[OnlineGameNotifier] Error initiating new game after rematch: $e");
      state = state.copyWith(onlineRematchStatus: OnlineRematchStatus.none);
    }
  }

  void handleRematchTimeout() {
    if (state.onlineRematchStatus == OnlineRematchStatus.localOffered) {
      state = state.copyWith(onlineRematchStatus: OnlineRematchStatus.timeout);

      if (currentUserId != null) {
        cancelRematchRequest();
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

    if (currentUserId != null) {
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
