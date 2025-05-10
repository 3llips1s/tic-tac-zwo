import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tic_tac_zwo/features/game/online/data/services/matchmaking_service.dart';

class OnlineGameService {
  final SupabaseClient _supabase;

  // stream subscriptions
  final Map<String, StreamSubscription> _gameSubscriptions = {};

  OnlineGameService(this._supabase);

  String? get _localUserId => _supabase.auth.currentUser?.id;

  Future<void> setPlayerReady(String gameSessionId) async {
    if (_localUserId == null) return;

    try {
      // fetch game sessions
      final gameSession = await _supabase
          .from('game_sessions')
          .select()
          .eq('id', gameSessionId)
          .single();

      final isPlayerOne = gameSession['player1_id'] == _localUserId;

      print(
          'setting player ready: ${isPlayerOne ? 'player1' : 'player2'} in session $gameSessionId');

      // update ready field
      await _supabase.from('game_sessions').update({
        isPlayerOne ? 'player1_ready' : 'player2_ready': true,
      }).eq('id', gameSessionId);

      // todo: consider getting rid of this verification
      final updatedSession = await _supabase
          .from('game_sessions')
          .select()
          .eq('id', gameSessionId)
          .single();

      print(
          'after update - player1 ready: ${updatedSession['player1_ready']}, player2 ready: ${updatedSession['player2_ready']}');
    } catch (e) {
      print('error setting player ready');
    }
  }

  Future<void> setPlayerNotReady(String gameSessionId) async {
    if (_localUserId == null) return;

    try {
      // fetch game sessions
      final gameSession = await _supabase
          .from('game_sessions')
          .select()
          .eq('id', gameSessionId)
          .single();

      final isPlayerOne = gameSession['player1_id'] == _localUserId;

      // update ready field
      await _supabase.from('game_sessions').update({
        isPlayerOne ? 'player1_ready' : 'player2_ready': false,
      }).eq('id', gameSessionId);
    } catch (e) {
      print('error setting player not ready');
    }
  }

  // check if opp is ready
  Stream<bool> getOpponentReadyStream(String gameSessionId) {
    if (_localUserId == null) {
      print(
          '[OnlineGameService] getOpponentReadyStream: No local user ID, returning false stream.');
      return Stream.value(false);
    }
    ;

    final controller = StreamController<bool>.broadcast();

    print(
        '[OnlineGameService] getOpponentReadyStream: Initializing for session $gameSessionId, user $_localUserId');

    // get game session to determine which player we are
    _supabase
        .from('game_sessions')
        .select()
        .eq('id', gameSessionId)
        .single()
        .then(
      (gameSession) {
        final isPlayerOne = gameSession['player1_id'] == _localUserId;
        print(
            '[OnlineGameService] Initial fetch for $gameSessionId: Current user is ${isPlayerOne ? 'player1' : 'player2'}. P1: ${gameSession['player1_id']}, P2: ${gameSession['player2_id']}');
        print(
            '[OnlineGameService] Initial session data: player1_ready: ${gameSession['player1_ready']}, player2_ready: ${gameSession['player2_ready']}');

        // listen to opp ready state
        _gameSubscriptions[gameSessionId] = _supabase
            .from('game_sessions')
            .stream(primaryKey: ['id'])
            .eq('id', gameSessionId)
            .listen(
              (data) {
                if (data.isEmpty) {
                  print(
                      '[OnlineGameService] OpponentReadyStream for $gameSessionId: Received empty data array.');
                  return;
                }

                // todo: remove after testing
                final session = data.first;

                final p1ReadyFromStream = session['player1_ready'] ?? false;
                final p2ReadyFromStream = session['player2_ready'] ?? false;

                print(
                    '[OnlineGameService] RAW STREAM DATA RECEIVED for $gameSessionId: $session');

                final opponentReady = isPlayerOne
                    ? session['player2_ready'] ?? false
                    : session['player1_ready'] ?? false;

                '[OnlineGameService] Opponent ready stream update for $gameSessionId: derived_opponentReady: $opponentReady - Stream P1_ready: $p1ReadyFromStream - Stream P2_ready: $p2ReadyFromStream (User is P1: $isPlayerOne)';

                controller.add(opponentReady);
              },
              onError: (error) {
                print(
                    '[OnlineGameService] ERROR in opponent ready stream for $gameSessionId: $error');
                controller.addError(error);
              },
              onDone: () {
                print(
                    '[OnlineGameService] Opponent ready stream DONE for $gameSessionId');
              },
            );
      },
    ).catchError((error) {
      print(
          '[OnlineGameService] ERROR fetching initial game session $gameSessionId: $error');
      controller.addError(error);
    });

    return controller.stream;
  }

  // stream for general game state updates
  Stream<Map<String, dynamic>> getGameStateStream(String gameSessionId) {
    final controller = StreamController<Map<String, dynamic>>.broadcast();

    _gameSubscriptions['state_$gameSessionId']?.cancel();

    _gameSubscriptions['state_$gameSessionId'] = _supabase
        .from('game_sessions')
        .stream(primaryKey: ['id'])
        .eq('id', gameSessionId)
        .listen((data) {
          if (data.isEmpty) {
            controller.add({});
            return;
          }

          controller.add(data.first);
        }, onError: (error) {
          print('error in game state stream: $error');
          controller.add({});
        });

    return controller.stream;
  }

  // update game state after a move
  Future<void> updateGameState(
    String gameSessionId, {
    List<String?>? board,
    int? selectedCellIndex,
    String? currentPlayerId,
    String? currentNounId,
    bool? isGameOver,
    String? winnerId,
  }) async {
    try {
      await _supabase.from('game_sessions').update({
        if (board != null) 'board': board,
        if (selectedCellIndex != null) 'selected_cell_index': selectedCellIndex,
        if (currentPlayerId != null) 'current_player_id': currentPlayerId,
        if (currentNounId != null) 'current_noun_id': currentNounId,
        if (isGameOver != null) 'is_game_over': isGameOver,
        if (winnerId != null) 'winner_id': winnerId,
        'last_activity': DateTime.now().toIso8601String(),
      }).eq('id', gameSessionId);
    } catch (e) {
      print('error updating game state');
    }
  }

  // record game move
  Future<void> recordGameRound(
    String gameSessionId, {
    required String playerId,
    required String nounId,
    required String selectedArticle,
    required bool isCorrect,
    required int cellIndex,
  }) async {
    try {
      await _supabase.from('game_rounds').insert({
        'game_id': gameSessionId,
        'player_id': playerId,
        'noun_id': nounId,
        'selected_article': selectedArticle,
        'is_correct': isCorrect,
        'cell_index': cellIndex,
      });
    } catch (e) {
      print('Error recording game round: $e');
    }
  }

  // clean up subs
  void disposeGameSession(String gameSessionId) {
    print('Disposing game session subscriptions for $gameSessionId');
    _gameSubscriptions[gameSessionId]?.cancel();
    _gameSubscriptions['state_$gameSessionId']?.cancel();
    _gameSubscriptions.remove(gameSessionId);
    _gameSubscriptions.remove('state_$gameSessionId');
  }

  // dispose subs
  void dispose() {
    _gameSubscriptions.forEach((_, subscription) => subscription.cancel());
    _gameSubscriptions.clear();
  }
}

// providers

final onlineGameServiceProvider = Provider(
  (ref) {
    final supabase = ref.watch(supabaseProvider);
    return OnlineGameService(supabase);
  },
);

final opponentReadyProvider = StreamProvider.family<bool, String>(
  (ref, gameSessionId) {
    final service = ref.watch(onlineGameServiceProvider);
    return service.getOpponentReadyStream(gameSessionId);
  },
);

final onlineGameStateProvider =
    StreamProvider.family<Map<String, dynamic>, String>(
  (ref, gameSessionId) {
    final service = ref.watch(onlineGameServiceProvider);
    return service.getGameStateStream(gameSessionId);
  },
);
