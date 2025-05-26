import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tic_tac_zwo/features/game/online/data/services/matchmaking_service.dart';

class OnlineGameService {
  final SupabaseClient _supabase;

  // stream subscriptions
  final Map<String, StreamSubscription> _gameStreamSubscriptions = {};

  // Cache for last received data to prevent redundant processing if Supabase stream sends duplicates
  final Map<String, Map<String, dynamic>> _lastReceivedStreamData = {};

  // Debounce timers for updates to Supabase
  final Map<String, Timer> _updateDebounceTimers = {};

  OnlineGameService(this._supabase);

  String? get _localUserId => _supabase.auth.currentUser?.id;

  Future<void> setPlayerReady(String gameSessionId) async {
    if (_localUserId == null) {
      print(
          '[OnlineGameService] setPlayerReady: Local user ID is null. Cannot set ready state.');
      return;
    }

    try {
      // fetch game sessions
      final gameSession = await _supabase
          .from('game_sessions')
          .select('player1_id, player2_id')
          .eq('id', gameSessionId)
          .single();

      final isPlayerOne = gameSession['player1_id'] == _localUserId;
      final readyField = isPlayerOne ? 'player1_ready' : 'player2_ready';

      print(
          '[OnlineGameService] Setting player ready: $_localUserId (${isPlayerOne ? 'player1' : 'player2'}) in session $gameSessionId.');

      // update ready field
      await _supabase.from('game_sessions').update({
        readyField: true,
        'last_activity': DateTime.now().toIso8601String(),
      }).eq('id', gameSessionId);
    } catch (e) {
      print(
          '[OnlineGameService] Error setting player ready for session $gameSessionId: $e');
    }
  }

  Future<void> setPlayerNotReady(String gameSessionId) async {
    if (_localUserId == null) {
      print('[OnlineGameService] setPlayerNotReady: Local user ID is null.');
      return;
    }

    try {
      // fetch game sessions
      final gameSession = await _supabase
          .from('game_sessions')
          .select('player1_id, player2_id')
          .eq('id', gameSessionId)
          .single();

      final isPlayerOne = gameSession['player1_id'] == _localUserId;
      final readyField = isPlayerOne ? 'player1_ready' : 'player2_ready';

      // update ready field
      await _supabase.from('game_sessions').update({
        readyField: false,
        'last_activity': DateTime.now().toIso8601String(),
      }).eq('id', gameSessionId);
      print(
          '[OnlineGameService] Player $_localUserId set to not ready for session $gameSessionId.');
    } catch (e) {
      print(
          '[OnlineGameService] Error setting player not ready for session $gameSessionId: $e');
    }
  }

  // stream for general game state updates
  Stream<Map<String, dynamic>> getGameStateStream(String gameSessionId) {
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    final String streamKey = 'gameState_$gameSessionId';

    _gameStreamSubscriptions[streamKey]?.cancel();

    print(
        '[OnlineGameService] Setting up game state stream for session: $gameSessionId');

    _gameStreamSubscriptions[streamKey] = _supabase
        .from('game_sessions')
        .stream(primaryKey: ['id'])
        .eq('id', gameSessionId)
        .listen((dataList) {
          if (controller.isClosed) return;

          if (dataList.isEmpty) {
            print(
                '[OnlineGameService] Game state stream for $gameSessionId received empty data list.');
            // handle as error / session ended
            return;
          }

          final gameData = dataList.first;
          print(
              '[OnlineGameService] RAW STREAM DATA RECEIVED for $gameSessionId: $gameData');

          // Prevent processing identical consecutive updates if Supabase sends them
          final String lastDataKey = 'lastStreamData_$gameSessionId';
          final lastData = _lastReceivedStreamData[lastDataKey];

          if (lastData != null &&
              lastData['updated_at'] == gameData['updated_at'] &&
              _areMapsEqual(lastData, gameData)) {
            return;
          }

          _lastReceivedStreamData[lastDataKey] =
              Map<String, dynamic>.from(gameData);
          controller.add(Map<String, dynamic>.from(gameData));
        }, onError: (error) {
          print('Error in game state stream: $error');
          controller.addError(error);
        });

    return controller.stream;
  }

  // Helper to compare values
  bool _areMapsEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    for (final key in map1.keys) {
      if (!map2.containsKey(key)) return false;

      if (key == 'board') {
        if (map1[key].toString() != map2[key].toString()) return false;
      } else if (map1[key] != map2[key]) {
        return false;
      }
    }
    return true;
  }

// fetch game session
  Future<Map<String, dynamic>> getGameSession(String gameSessionId) async {
    try {
      print('[OnlineGameService] Fetching game session: $gameSessionId');

      final response = await _supabase
          .from('game_sessions')
          .select()
          .eq('id', gameSessionId)
          .single();
      return response;
    } catch (e) {
      print(
          '[OnlineGameService] Error getting game session $gameSessionId: $e');
      return {};
    }
  }

  // update game state after a move
  Future<void> updateGameSessionState(
    String gameSessionId, {
    List<String?>? board,
    dynamic selectedCellIndex,
    String? currentPlayerId,
    dynamic currentNounId,
    bool? isGameOver,
    dynamic winnerId,
    String? revealedArticle,
    bool? revealedArticleIsCorrect,
  }) async {
    const debounceDuration = Duration(milliseconds: 100);

    if (_updateDebounceTimers[gameSessionId]?.isActive ?? false) {
      _updateDebounceTimers[gameSessionId]!.cancel();
    }

    _updateDebounceTimers[gameSessionId] = Timer(debounceDuration, () async {
      try {
        final updatePayload = <String, dynamic>{
          'last_activity': DateTime.now().toIso8601String(),
        };

        if (board != null) updatePayload['board'] = board;

        if (selectedCellIndex != null || board != null) {
          updatePayload['selected_cell_index'] = selectedCellIndex;
        }

        if (currentNounId != null || board != null) {
          updatePayload['current_noun_id'] = currentNounId;
        }
        if (winnerId != null || isGameOver != null) {
          updatePayload['winner_id'] = winnerId;
        }

        if (currentPlayerId != null) {
          updatePayload['current_player_id'] = currentPlayerId;
        }

        if (isGameOver != null) updatePayload['is_game_over'] = isGameOver;

        if (revealedArticle != null) {
          updatePayload['revealed_article'] = revealedArticle;
        }

        if (revealedArticleIsCorrect != null) {
          updatePayload['revealed_article_is_correct'] =
              revealedArticleIsCorrect;
        }

        if (updatePayload.length == 1 &&
            updatePayload.containsKey('last_activity')) {
          // print('[OnlineGameService] updateGameState for $gameSessionId: No actual game data to update, only last_activity. Skipping DB call.');
          return;
        }

        print(
            '[OnlineGameService] Debounced update executing for $gameSessionId. Payload: $updatePayload');

        await _supabase
            .from('game_sessions')
            .update(updatePayload)
            .eq('id', gameSessionId);

        print(
            '[OnlineGameService] Game state update completed via debounce for $gameSessionId.');
      } catch (e) {
        print(
            '[OnlineGameService] Error in debounced game state update for $gameSessionId: $e');
      }
    });
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
      print(
          '[OnlineGameService] Recording game round for session $gameSessionId, player $playerId.');

      await _supabase.from('game_rounds').insert({
        'game_id': gameSessionId,
        'player_id': playerId,
        'noun_id': nounId,
        'selected_article': selectedArticle,
        'is_correct': isCorrect,
        'cell_index': cellIndex,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print(
          '[OnlineGameService] Error recording game round for session $gameSessionId: $e');
    }
  }

  // clean up subs
  void clientDisposeGameSessionResources(String gameSessionId) {
    print(
        '[OnlineGameService] Disposing client-specific resources for game session $gameSessionId.');

    final gameStateStreamKey = 'gameState_$gameSessionId';

    _gameStreamSubscriptions[gameStateStreamKey]?.cancel();
    _gameStreamSubscriptions.remove(gameStateStreamKey);
    _lastReceivedStreamData.remove('lastStreamData_$gameSessionId');

    _updateDebounceTimers[gameSessionId]?.cancel();
    _updateDebounceTimers.remove(gameSessionId);
  }

  // dispose subs
  void dispose() {
    for (var timer in _updateDebounceTimers.values) {
      timer.cancel();
    }
    _updateDebounceTimers.clear();

    for (var subscription in _gameStreamSubscriptions.values) {
      subscription.cancel();
    }
    _gameStreamSubscriptions.clear();
    _lastReceivedStreamData.clear();
  }
}

// providers
final onlineGameServiceProvider = Provider(
  (ref) {
    final supabase = ref.watch(supabaseProvider);
    final service = OnlineGameService(supabase);
    ref.onDispose(() => service.dispose());
    return service;
  },
);

final onlineGameStateProvider =
    StreamProvider.family<Map<String, dynamic>, String>(
  (ref, gameSessionId) {
    final service = ref.watch(onlineGameServiceProvider);
    return service.getGameStateStream(gameSessionId);
  },
);
