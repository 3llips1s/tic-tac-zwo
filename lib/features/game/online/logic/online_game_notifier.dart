import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tic_tac_zwo/config/game_config/config.dart';
import 'package:tic_tac_zwo/features/auth/logic/auth_providers.dart';
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
        '[DEBUG CONSTRUCTOR] Starting player: ${gameConfig.startingPlayer.username}');
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
        if (!mounted) return;
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
    _inactivityRemainingSeconds = GameState.turnDurationSeconds;

    state = state.copyWith(
      remainingSeconds: GameState.turnDurationSeconds,
    );

    _inactivityTimer = Timer.periodic(
      const Duration(seconds: 1),
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

    if (_isInitialGameLoad ||
        state.isGameOver ||
        _processingRemoteUpdate ||
        !_isLocalPlayerTurn ||
        state.board[index] != null ||
        state.selectedCellIndex != null) {
      print(
          '[OnlineGameNotifier] Cannot select cell: Game over, processing remote update, not local player\'s turn, or cell already taken.');
      return;
    }

    _cancelInactivityTimer();

    final noun = await ref.read(germanNounRepoProvider).loadRandomNoun();

    state = state.copyWith(
      selectedCellIndex: index,
      currentNoun: noun,
      isTimerActive: true,
      onlineGamePhase: OnlineGamePhase.cellSelected,
      remainingSeconds: GameState.turnDurationSeconds,
    );

    try {
      await _gameService.updateGameSessionState(
        gameSessionId,
        selectedCellIndex: index,
        currentNounId: noun.id,
        onlineGamePhaseString: OnlineGamePhase.cellSelected.string,
      );
      print(
          '[OnlineGameNotifier] Cell $index selected and noun ${noun.noun} sent to server.');
    } catch (e) {
      print('[OnlineGameNotifier] Error sending cell selection to server: $e');

      state = state.copyWith(
        selectedCellIndex: null,
        allowNullSelectedCellIndex: true,
        currentNoun: null,
        allowNullCurrentNoun: true,
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

    var updatedBoard = List<String?>.from(state.board);
    if (isCorrectMove) {
      updatedBoard[cellIndex] = previousPlayer.symbolString;
    }

    state = state.copyWith(
      board: updatedBoard,
      revealedArticle: selectedArticle,
      revealedArticleIsCorrect: isCorrectMove,
      articleRevealedAt: DateTime.now(),
      isTimerActive: false,
      onlineGamePhase: OnlineGamePhase.articleRevealed,
      lastPlayedPlayer: previousPlayer,
    );

    final (gameResult, winningPattern) = state.checkWinner(board: updatedBoard);
    final bool isGameOver = gameResult != null;

    await _gameService.recordGameRound(
      gameSessionId,
      playerId: currentUserId!,
      selectedArticle: selectedArticle,
      isCorrect: isCorrectMove,
    );

    if (isGameOver) {
      _handleLocalWinOrDraw(gameResult, winningPattern, updatedBoard);
    } else {
      final Player nextPlayer = state.players
          .firstWhere((player) => player.userId != previousPlayer.userId);

      await _gameService.updateGameSessionState(
        gameSessionId,
        board: updatedBoard,
        currentPlayerId: nextPlayer.userId,
        revealedArticle: selectedArticle,
        revealedArticleIsCorrect: isCorrectMove,
        selectedCellIndex: cellIndex,
        currentNounId: currentNoun.id,
        onlineGamePhaseString: OnlineGamePhase.articleRevealed.string,
      );
    }

    Timer(
      Duration(milliseconds: 1500),
      () async {
        if (!state.isGameOver && mounted) {
          try {
            await _gameService.updateGameSessionState(
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
      },
    );
  }

  void _handleLocalWinOrDraw(
      String? gameResult, List<int>? winningPattern, List<String?> board) {
    if (_gameOverHandled) return;
    _gameOverHandled = true;

    Player? winner;
    int p1Score = state.player1Score;
    int p2Score = state.player2Score;

    if (gameResult != 'Draw' && gameResult != null) {
      winner = state.players.firstWhere((p) => p.symbolString == gameResult);
      if (winner.userId == state.players[0].userId) {
        p1Score++;
      } else {
        p2Score++;
      }
    }

    state = state.copyWith(
      isGameOver: true,
      winningPlayer: winner,
      allowNullWinningPlayer: true,
      winningCells: winningPattern,
      board: board,
      player1Score: p1Score,
      player2Score: p2Score,
    );

    _calculatePointsForDialog();

    _gameService.updateGameSessionState(
      gameSessionId,
      isGameOver: true,
      winnerId: winner?.userId,
      board: board,
      player1Score: p1Score,
      player2Score: p2Score,
    );
  }

  void _handleRemoteWinOrDraw() {
    if (_gameOverHandled) return;
    _gameOverHandled = true;
    _calculatePointsForDialog();
  }

  void _calculatePointsForDialog() async {
    if (currentUserId == null) return;
    final correctMoves =
        await _gameService.getCorrectMoves(gameSessionId, currentUserId!);
    int pointsPerGame = correctMoves;
    if (state.winningPlayer?.userId == currentUserId) {
      pointsPerGame += 3;
    } else if (state.winningPlayer == null) {
      pointsPerGame += 1;
    }
    if (mounted) {
      state = state.copyWith(pointsEarnedPerGame: pointsPerGame);
    }
  }

  @override
  Future<void> forfeitTurn() async {
    _turnTimer?.cancel();
    _cancelInactivityTimer();

    if (!_isLocalPlayerTurn || _processingRemoteUpdate || state.isGameOver) {
      print(
          '[OnlineGameNotifier] Cannot forfeit turn: Invalid state for forfeiture.');
      return;
    }

    final Player previousPlayer = state.currentPlayer;
    final Player nextPlayer = state.players
        .firstWhere((player) => player.userId != previousPlayer.userId);

    await _gameService.updateGameSessionState(
      gameSessionId,
      currentPlayerId: nextPlayer.userId,
      onlineGamePhaseString: OnlineGamePhase.waiting.string,
      selectedCellIndex: null,
      currentNounId: null,
      revealedArticle: null,
      revealedArticleIsCorrect: null,
    );

    await _gameService.recordGameRound(
      gameSessionId,
      playerId: currentUserId!,
      selectedArticle: null,
      isCorrect: false,
    );
  }

  void _listenToGameSessionUpdates() {
    _gameStateSubscription =
        _gameService.getGameStateStream(gameSessionId).listen((gameData) async {
      final newTimeStamp = gameData['updated_at'] != null
          ? DateTime.tryParse(gameData['updated_at'])
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

      _lastUpdateTimestamp = newTimeStamp;

      print('[OnlineGameNotifier] Received remote update: $gameData');

      try {
        await _handleRemoteUpdate(gameData);
      } catch (e) {
        print('Error handling remote update: $e');
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

    if (serverIsGameOver) {
      final p1Ready = gameData['player1_ready'] ?? false;
      final p2Ready = gameData['player2_ready'] ?? false;
      final String? dbPlayer1Id = gameData['player1_id'];
      final localUserIsDbPlayer1 = dbPlayer1Id == currentUserId;

      final localPlayerWantsRematch = localUserIsDbPlayer1 ? p1Ready : p2Ready;
      final remotePlayerWantsRematch = localUserIsDbPlayer1 ? p2Ready : p1Ready;

      if (localPlayerWantsRematch && remotePlayerWantsRematch) {
        newOnlineRematchStatus = OnlineRematchStatus.bothAccepted;
      } else if (localPlayerWantsRematch) {
        newOnlineRematchStatus = OnlineRematchStatus.localOffered;
      } else if (remotePlayerWantsRematch) {
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
      isTimerActive:
          _isLocalPlayerTurn && (serverPhase == OnlineGamePhase.cellSelected),
      onlineGamePhase: serverPhase,
      lastStarterId: gameData['last_starter_id'] ?? state.lastStarterId,
      onlineRematchStatus: newOnlineRematchStatus,
    );

    if (state.isGameOver && !previousState.isGameOver) {
      _handleRemoteWinOrDraw();
    }

    if (state.onlineRematchStatus == OnlineRematchStatus.bothAccepted &&
        previousState.onlineRematchStatus != OnlineRematchStatus.bothAccepted) {
      initiateNewGameAfterRematch();
    }

    // reset ui and symbols for rematch
    if (!serverIsGameOver && previousState.isGameOver) {
      _gameOverHandled = false;

      final Player previousRoundPlayer1 = previousState.players[0];
      final Player previousRoundPlayer2 = previousState.players[1];
      final newStarterId =
          previousRoundPlayer1.userId == previousState.lastStarterId
              ? previousRoundPlayer2.userId!
              : previousRoundPlayer1.userId!;

      final Player starter = newStarterId == previousRoundPlayer1.userId
          ? previousRoundPlayer1
          : previousRoundPlayer2;
      final Player opponent = newStarterId == previousRoundPlayer1.userId
          ? previousRoundPlayer2
          : previousRoundPlayer1;

      final List<Player> newPlayersList = [
        starter.copyWith(symbol: previousState.players[0].symbol),
        opponent.copyWith(symbol: previousState.players[1].symbol),
      ];

      final newStartingPlayer = newPlayersList[0];

      state = state.copyWith(
        pointsEarnedPerGame: null,
        allowNullPointsEarnedPerGame: true,
        winningCells: null,
        winningPlayer: null,
        allowNullWinningPlayer: true,
        players: newPlayersList,
        startingPlayer: newStartingPlayer,
      );

      if (_isLocalPlayerTurn) {
        _startInactivityTimer();
      }

      print(
          '[OnlineGameNotifier] Final state after remote update: Phase: ${state.onlineGamePhase}, isLocalTurn: $_isLocalPlayerTurn, CurrentPlayerID: ${state.currentPlayerId}');
    }
  }

  // rematch methods
  Future<void> requestRematch() async {
    if (!state.isGameOver || currentUserId == null) return;
    await _gameService.setPlayerRematchStatus(
        gameSessionId, currentUserId!, true);
  }

  Future<void> cancelRematchRequest() async {
    if (!state.isGameOver || currentUserId == null) return;
    await _gameService.setPlayerRematchStatus(
        gameSessionId, currentUserId!, false);
  }

  Future<void> acceptRematch() async {
    if (!state.isGameOver || currentUserId == null) return;
    await _gameService.setPlayerRematchStatus(
        gameSessionId, currentUserId!, true);
  }

  Future<void> declineRematch() async {
    if (!state.isGameOver || currentUserId == null) return;
    await _gameService.setPlayerRematchStatus(
        gameSessionId, currentUserId!, false);
  }

  Future<void> initiateNewGameAfterRematch() async {
    if (state.lastStarterId == null) return;

    _rematchOfferTimer?.cancel();

    // The new starter is the one who was NOT the last starter.
    final newStarterId = state.players
        .firstWhere((p) => p.userId != state.lastStarterId)
        .userId!;

    print(
        "[OnlineGameNotifier] Both players accepted. Attempting to reset game. New starter: $newStarterId");

    try {
      await _gameService.resetSessionForRematch(gameSessionId, newStarterId);
    } catch (e) {
      print("[OnlineGameNotifier] Error initiating new game after rematch: $e");
    }
  }

  Future<void> findNewOpponent() async {
    if (currentUserId != null) {
      await _gameService.setPlayerRematchStatus(
          gameSessionId, currentUserId!, false);
    }
    ref.read(navigationTargetProvider.notifier).state =
        NavigationTarget.matchmaking;
  }

  Future<void> goHomeAndCleanupSession() async {
    if (currentUserId != null) {
      await _gameService.setPlayerRematchStatus(
          gameSessionId, currentUserId!, false);
    }
    ref.read(navigationTargetProvider.notifier).state = NavigationTarget.home;
  }

  TimerDisplayState get timerDisplayState {
    if (state.isGameOver || !_isLocalPlayerTurn) {
      return TimerDisplayState.static;
    }
    if (state.selectedCellIndex != null) {
      return state.isTimerActive
          ? TimerDisplayState.countdown
          : TimerDisplayState.static;
    }
    return _isInactivityTimerActive
        ? TimerDisplayState.inactivity
        : TimerDisplayState.static;
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
