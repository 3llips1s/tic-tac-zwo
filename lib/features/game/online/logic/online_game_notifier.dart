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
        ) {
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

    state = state.copyWith(
      selectedCellIndex: index,
      currentNoun: noun,
      revealedArticle: null,
      revealedArticleIsCorrect: null,
      isTimerActive: true,
      onlineGamePhase: OnlineGamePhase.cellSelected,
    );

    final gameService = ref.read(onlineGameServiceProvider);
    try {
      await gameService.updateGameSessionState(
        gameSessionId,
        selectedCellIndex: index,
        currentNounId: noun.id,
      );
      print(
          '[OnlineGameNotifier] Cell $index selected and noun ${noun.noun} sent to server.');
    } catch (e) {
      print('[OnlineGameNotifier] Error sending cell selection to server: $e');

      state = state.copyWith(
        selectedCellIndex: null,
        currentNoun: null,
        isTimerActive: false,
        onlineGamePhase: OnlineGamePhase.waiting,
      );
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

    final int cellIndex = state.selectedCellIndex!;
    final GermanNoun currentNoun = state.currentNoun!;
    final bool isCorrectMove = currentNoun.article == selectedArticle;

    // update local state immediately
    state = state.copyWith(
      revealedArticle: selectedArticle,
      revealedArticleIsCorrect: isCorrectMove,
      articleRevealedAt: DateTime.now(),
      isTimerActive: false,
      onlineGamePhase: OnlineGamePhase.articleRevealed,
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

    final nextPlayer =
        state.players.firstWhere((p) => p.userId != state.currentPlayer.userId);
    final nextPlayerId = nextPlayer.userId;

    try {
      await gameService.updateGameSessionState(
        gameSessionId,
        board: state.board,
        selectedCellIndex: cellIndex,
        currentNounId: currentNoun.id,
        revealedArticle: selectedArticle,
        revealedArticleIsCorrect: isCorrectMove,
        currentPlayerId: nextPlayerId,
        isGameOver: state.isGameOver,
        winnerId: state.winningPlayer?.userId,
      );

      await gameService.recordGameRound(
        gameSessionId,
        playerId: currentUserId!,
        nounId: currentNoun.id,
        selectedArticle: selectedArticle,
        isCorrect: isCorrectMove,
        cellIndex: cellIndex,
      );

      print(
          '[OnlineGameNotifier] Article choice and board state sent to server.');

      Future.delayed(const Duration(seconds: 2), () {
        if (state.onlineGamePhase == OnlineGamePhase.articleRevealed) {
          state = state.copyWith(
            selectedCellIndex: null,
            currentNoun: null,
            revealedArticle: null,
            revealedArticleIsCorrect: null,
            articleRevealedAt: null,
            isTimerActive: false,
            onlineGamePhase: OnlineGamePhase.turnComplete,
          );
          print(
              '[OnlineGameNotifier] Forfeit: Transitioned to turnComplete phase locally.');

          Future.delayed(const Duration(milliseconds: 500), () {
            if (state.onlineGamePhase == OnlineGamePhase.turnComplete) {
              state = state.copyWith(onlineGamePhase: OnlineGamePhase.waiting);
              print(
                  '[OnlineGameNotifier] Transitioned to waiting phase locally.');
            }
          });
        }
      });
    } catch (e) {
      print('[OnlineGameNotifier] Error making move in online mode: $e');
    }
  }

  @override
  void forfeitTurn() async {
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

    // local feedback
    state = state.copyWith(
      revealedArticle: correctArticle,
      revealedArticleIsCorrect: false,
      articleRevealedAt: DateTime.now(),
      isTimerActive: false,
      onlineGamePhase: OnlineGamePhase.articleRevealed,
    );

    _applyMoveLocally(
        cellIndex, false, currentUserId!, correctArticle, currentNoun.noun);

    // remote update
    final gameService = ref.read(onlineGameServiceProvider);
    final nextPlayer =
        state.players.firstWhere((p) => p.userId != state.currentPlayer.userId);
    final nextPlayerId = nextPlayer.userId;

    try {
      await gameService.updateGameSessionState(
        gameSessionId,
        board: state.board,
        selectedCellIndex: cellIndex,
        currentNounId: currentNoun.id,
        revealedArticle: correctArticle,
        revealedArticleIsCorrect: false,
        currentPlayerId: nextPlayerId,
        isGameOver: state.isGameOver,
        winnerId: state.winningPlayer?.userId,
      );

      await gameService.recordGameRound(
        gameSessionId,
        playerId: currentUserId!,
        nounId: currentNoun.id,
        selectedArticle: 'forfeited',
        isCorrect: false,
        cellIndex: cellIndex,
      );

      print('[OnlineGameNotifier] Turn forfeited and state sent to server.');

      Future.delayed(const Duration(seconds: 2), () {
        if (state.onlineGamePhase == OnlineGamePhase.articleRevealed) {
          state = state.copyWith(
            selectedCellIndex: null,
            currentNoun: null,
            revealedArticle: null,
            revealedArticleIsCorrect: null,
            articleRevealedAt: null,
            isTimerActive: false,
            onlineGamePhase: OnlineGamePhase.turnComplete,
          );
          print(
              '[OnlineGameNotifier] Forfeit: Transitioned to turnComplete phase locally.');
          Future.delayed(const Duration(milliseconds: 500), () {
            if (state.onlineGamePhase == OnlineGamePhase.turnComplete) {
              state = state.copyWith(onlineGamePhase: OnlineGamePhase.waiting);
              print(
                  '[OnlineGameNotifier] Forfeit: Transitioned to waiting phase locally.');
            }
          });
        }
      });
    } catch (e) {
      print('[OnlineGameNotifier] Error forfeiting turn in online mode: $e');
    }
  }

  void _listenToGameSessionUpdates() {
    final gameService = ref.read(onlineGameServiceProvider);
    _gameStateSubscription =
        gameService.getGameStateStream(gameSessionId).listen((gameData) async {
      if (_lastProcessedUpdate != null &&
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
    final String? currentNounId = gameData['current_noun_id'];
    GermanNoun? noun;
    if (currentNounId != null) {
      await _loadNounFromId(currentNounId);
      noun = state.currentNoun;
    }

    final String? player1Id = gameData['player1_id'];
    final String? player2Id = gameData['player2_id'];
    final String? currentPlayerId = gameData['current_player_id'];

    final Player player1 =
        state.players.firstWhere((p) => p.userId == player1Id);
    final Player player2 =
        state.players.firstWhere((p) => p.userId == player2Id);
    final Player? currentPlayer =
        state.players.firstWhere((p) => p.userId == currentPlayerId);

    final currentUserId = supabase.auth.currentUser?.id;
    _isLocalPlayerTurn = currentPlayerId == currentUserId;

    OnlineGamePhase newPhase = OnlineGamePhase.waiting;

    if (gameData['is_game_over'] == true) {
      newPhase = OnlineGamePhase.turnComplete;
    } else if (gameData['revealed_article'] != null ||
        gameData['revealed_article_is_correct'] != null) {
      newPhase = OnlineGamePhase.articleRevealed;
      Future.delayed(const Duration(seconds: 2), () {
        if (state.onlineGamePhase == OnlineGamePhase.articleRevealed) {
          state = state.copyWith(
            selectedCellIndex: null,
            currentNoun: null,
            revealedArticle: null,
            revealedArticleIsCorrect: null,
            articleRevealedAt: null,
            isTimerActive: false,
            onlineGamePhase: OnlineGamePhase.turnComplete,
          );
          print(
              '[OnlineGameNotifier] Remote: Transitioned to turnComplete phase.');
          Future.delayed(const Duration(milliseconds: 500), () {
            if (state.onlineGamePhase == OnlineGamePhase.turnComplete) {
              state = state.copyWith(onlineGamePhase: OnlineGamePhase.waiting);
              print(
                  '[OnlineGameNotifier] Remote: Transitioned to waiting phase.');
            }
          });
        }
      });
    } else if (gameData['selected_cell_index'] != null &&
        gameData['current_noun_id'] != null) {
      newPhase = OnlineGamePhase.cellSelected;
    } else {
      newPhase = OnlineGamePhase.waiting;
    }

    DateTime? updatedAt = gameData['updated_at'] != null
        ? DateTime.parse(gameData['updated_at'])
        : null;

    // update state with incoming data
    state = state.copyWith(
      board: List<String?>.from(gameData['board'] ?? List.filled(9, null)),
      selectedCellIndex: gameData['selected_cell_index'],
      currentNoun: noun,
      isGameOver: gameData['is_game_over'] ?? false,
      winningPlayer: gameData['winner_id'] != null
          ? (player1.userId == gameData['winner_id'] ? player1 : player2)
          : null,
      revealedArticle: gameData['revealed_article'],
      revealedArticleIsCorrect: gameData['revealed_article_is_correct'],
      articleRevealedAt: updatedAt,
      isTimerActive: (newPhase == OnlineGamePhase.cellSelected),
      onlineGamePhase: newPhase,
    );

    if (_isLocalPlayerTurn &&
        state.onlineGamePhase == OnlineGamePhase.waiting &&
        state.selectedCellIndex == null) {
      print(
          '[OnlineGameNotifier] Local player turn starting. Clearing previous noun/article feedback.');
      state = state.copyWith(
        revealedArticle: null,
        revealedArticleIsCorrect: null,
        articleRevealedAt: null,
        currentNoun: null,
        selectedCellIndex: null,
      );
    }
  }

  void _applyMoveLocally(int index, bool isCorrect, String playerId,
      String selectedArticle, String noun) {
    final String mark = isCorrect
        ? state.currentPlayer.symbolString
        : (state.currentPlayer.symbol == PlayerSymbol.X
            ? PlayerSymbol.O.string
            : PlayerSymbol.X.string);

    // update board
    final updatedBoard = List<String?>.from(state.board);
    updatedBoard[index] = mark;

    state = state.copyWith(board: updatedBoard);

    // check for winner locally
    final (gameResult, winningPattern) = state.checkWinner();
    if (gameResult != null) {
      if (gameResult != 'Draw' && winningPattern != null) {
        state = state.copyWith(winningCells: winningPattern);
      }
      handleWinOrDraw();
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
        currentNoun: null, // Clear current noun
        isGameOver: false,
        winningPlayer: null,
        startingPlayer: state.players.firstWhere((p) =>
            p.userId == newStartingPlayerIdOnServer), // Set new starting player
        revealedArticle: null,
        revealedArticleIsCorrect: null,
        articleRevealedAt: null, // Clear timestamp
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
}

// providers
final onlineGameStateNotifierProvider =
    StateNotifierProvider.family<OnlineGameNotifier, GameState, GameConfig>(
  (ref, config) {
    final supabase = ref.watch(supabaseProvider);
    return OnlineGameNotifier(ref, config, supabase);
  },
);
