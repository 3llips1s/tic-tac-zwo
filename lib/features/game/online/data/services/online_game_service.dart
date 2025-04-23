import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tic_tac_zwo/features/game/online/data/services/matchmaking_service.dart';

class OnlineGameService {
  final SupabaseClient _supabase;

  // stream subscriptions
  Map<String, StreamSubscription> _gameSubscriptions = {};

  OnlineGameService(this._supabase);

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  Future<void> setPlayerReady(String gameSessionId) async {
    if (_currentUserId == null) return;

    try {
      // fetch game sessions
      final gameSession = await _supabase
          .from('game_sessions')
          .select()
          .eq('id', gameSessionId)
          .single();

      final isPlayerOne = gameSession['player1_id'] == _currentUserId;

      // update ready field
      await _supabase.from('game_sessions').update({
        isPlayerOne ? 'player1_ready' : 'player2_ready': true,
      }).eq('id', gameSessionId);
    } catch (e) {
      print('error setting player ready');
    }
  }

  Future<void> setPlayerNotReady(String gameSessionId) async {
    if (_currentUserId == null) return;

    try {
      // fetch game sessions
      final gameSession = await _supabase
          .from('game_sessions')
          .select()
          .eq('id', gameSessionId)
          .single();

      final isPlayerOne = gameSession['player1_id'] == _currentUserId;

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
    if (_currentUserId == null) return Stream.value(false);

    final controller = StreamController<bool>.broadcast();

    // get game session to determine which player we are
    _supabase
        .from('game_sessions')
        .select()
        .eq('id', gameSessionId)
        .single()
        .then(
      (gameSession) {
        if (gameSession == null) {
          controller.add(false);
          return;
        }

        final isPlayerOne = gameSession['player1_id'] == _currentUserId;

        // listen to opp ready state
        _gameSubscriptions[gameSessionId] = _supabase
            .from('game_sessions')
            .stream(primaryKey: ['id'])
            .eq('id', gameSessionId)
            .listen((data) {
              if (data.isEmpty) {
                controller.add(false);
                return;
              }

              final session = data.first;
              final opponentReady = isPlayerOne
                  ? session['player2_ready'] ?? false
                  : session['player1_ready'] ?? false;

              controller.add(opponentReady);
            }, onError: (error) {
              print('error in opp ready stream');
              controller.add(false);
            });
      },
    );

    return controller.stream;
  }

  // stream for general game state updates
  Stream<Map<String, dynamic>> getGameStateStream(String gameSessionId) {
    final controller = StreamController<Map<String, dynamic>>.broadcast();

    _gameSubscriptions['state_$gameSessionId'] ==
        _supabase
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
    StreamProvider.family<Map<String, dynamic>, String>((ref, gameSessionId) {
  final service = ref.watch(onlineGameServiceProvider);
  return service.getGameStateStream(gameSessionId);
});
