import 'dart:developer' as developer;
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

enum MatchmakingState {
  idle,
  searching,
  matched,
  error,
}

class MatchmakingService {
  final SupabaseClient _supabase;

  // realtime updates subscription
  StreamSubscription? _matchSubscription;
  StreamSubscription? _nearbySubscription;

  // stream controllers for state management
  final _matchStateController = StreamController<MatchmakingState>.broadcast();
  final _matchedGameIdController = StreamController<String?>.broadcast();

  final _nearbyPlayersController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // streams for ui to listen to
  Stream<MatchmakingState> get matchmakingStateStream =>
      _matchStateController.stream;
  Stream<String?> get matchedGameIdStream => _matchedGameIdController.stream;
  Stream<List<Map<String, dynamic>>> get nearbyPlayersStream =>
      _nearbyPlayersController.stream;
  Stream<String> get errorStream => _errorController.stream;

  String? _userId;
  bool _isInQueue = false;
  String? _currentQueueEntryId;

  MatchmakingService(this._supabase) {
    _init();
  }

  void _init() async {
    _userId = _supabase.auth.currentUser?.id;
    if (_userId == null) {
      _errorController.add('user not authenticated');
      return;
    }
  }

  // global match making
  Future<void> startGlobalMatchmaking() async {
    final userId = _userId;

    if (userId == null) {
      _errorController.add('user not authenticated.');
      return;
    }

    if (_isInQueue) return;

    // update state
    _matchStateController.add(MatchmakingState.searching);
    _isInQueue = true;

    try {
      // delete existing entries for user
      await _supabase
          .from('matchmaking_queue')
          .delete()
          .eq('user_id', userId)
          .eq('is_nearby_match', false);

      // insert new entry into queue
      final response = await _supabase.from('matchmaking_queue').insert({
        'user_id': userId,
        'is_nearby_match': false,
        'is_matched': false,
      }).select('id');

      if (response.isEmpty || response[0]['id'] == null) {
        throw Exception('failed to insert into queue or retrieve entry id');
      }

      _currentQueueEntryId = response[0]['id'];

      // start listening for matches
      _startMatchListener();
    } catch (e) {
      _errorController.add('failed to start matchmaking: $e');
      _matchStateController.add(MatchmakingState.error);
      _isInQueue = false;
      _currentQueueEntryId = null;
      developer.log('[MatchmakingService] Error starting global:$e');
    }
  }

  // nearby matchmaking
  Future<void> startNearbyMatchmaking() async {
    final userId = _userId;

    if (userId == null) {
      _errorController.add('user not authenticated.');
      return;
    }

    if (_isInQueue) return;

    // get location permission and coordinates
    bool hasPermission = await _requestLocationPermission();
    if (!hasPermission) {
      _errorController.add('location permission denied');
      developer.log('[MatchmakingService] location permission denied');
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();

      // update state
      _matchStateController.add(MatchmakingState.searching);
      _isInQueue = true;

      // delete existing entries for the user
      await _supabase.from('matchmaking_queue').delete().eq('user_id', userId);

      // insert new entry in matchmaking queue with location
      final response = await _supabase.from('matchmaking_queue').insert({
        'user_id': userId,
        'is_nearby_match': true,
        'lat': position.latitude,
        'lng': position.longitude,
        'is_matched': false,
      }).select('id');

      if (response.isEmpty || response[0]['id'] == null) {
        throw Exception('failed to insert into queue or retrieve entry id');
      }

      _currentQueueEntryId = response[0]['id'];

      // update user location in user table
      await _supabase.from('users').update({
        'lat': position.latitude,
        'lng': position.longitude,
        'last_online': DateTime.now().toIso8601String(),
        'is_online': true,
      }).eq('id', userId);

      // start listening for matches
      _startMatchListener();

      _startNearbyPlayersListener(position.latitude, position.longitude);
    } catch (e) {
      _errorController.add('failed to start nearby matchmaking: $e');
      _matchStateController.add(MatchmakingState.error);
      _isInQueue = false;
      _currentQueueEntryId = null;
      developer.log('[MatchmakingService] Error starting nearby match: $e');
    }
  }

  // listen for match updates
  void _startMatchListener() {
    final userId = _userId;
    final entryId = _currentQueueEntryId;

    if (userId == null || entryId == null) {
      _errorController
          .add('cannot start listener: user or queue entry id missing.');
      return;
    }

    _matchSubscription?.cancel();

    // subscribe to channel for realtime updates
    _matchSubscription = _supabase
        .from('matchmaking_queue')
        .stream(primaryKey: ['id'])
        .eq('id', entryId)
        .listen(
          (data) {
            if (data.isNotEmpty) {
              final matchData = data.first;
              final bool isMatched = matchData['is_matched'] ?? false;
              final String? gameId = matchData['game_id'];

              if (isMatched && gameId != null) {
                _onMatchFound(gameId);
              } else {
                developer.log('queue entry updated, but not matched yet.');
              }
            } else {
              developer.log(
                  '[MatchmakingService] received empty data for entry id $entryId. entry might have been deleted.');

              if (_isInQueue && _currentQueueEntryId == entryId) {
                cancelMatchmaking();
              }
            }
          },
          onError: (error) {
            developer.log(
                '[MatchmakingService] match listener error for entry $entryId: $error');

            _errorController.add('match listener error: $error');

            if (_isInQueue && _currentQueueEntryId == entryId) {
              cancelMatchmaking();
              _matchStateController.add(MatchmakingState.error);
            } else {
              developer.log(
                  '[MatchmakingService] Match listener error for an old/inactive entry $entryId. Ignoring cancellation for current queue.');
            }
          },
          onDone: () {
            developer.log('[MatchmakingService] match listener done (closed).');
          },
        );
  }

  // listen for nearby players
  void _startNearbyPlayersListener(double lat, double lng) {
    _nearbySubscription?.cancel();

    // listen to user status changes
    _nearbySubscription = _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('is_online', true)
        .listen(
          (data) async {
            try {
              // rpc call to find nearby player
              final userId = _userId;
              if (userId == null) return;

              final response = await _supabase.rpc('find_nearby_players',
                  params: {
                    'p_user_id': userId,
                    'p_lat': lat,
                    'p_lng': lng,
                    'p_radius_meters': 30
                  });

              if (response is List) {
                final List<Map<String, dynamic>> players =
                    List<Map<String, dynamic>>.from(
                        response.map((item) => item as Map<String, dynamic>));

                _nearbyPlayersController.add(players);
              } else {
                _nearbyPlayersController.add([]);
              }
            } catch (e) {
              developer.log(
                  '[MatchmakingService] error finding nearby players via rpc: $e');

              _errorController.add('error finding nearby players: $e');
            }
          },
          onError: (error) {
            developer.log(
                '[MatchmakingService] nearby players listener error: $error');

            _errorController.add('nearby players listener error: $error');
          },
          onDone: () {
            developer.log(
                '[MatchmakingService] nearby players listener done/ closed');
          },
        );
  }

  // request location permission
  Future<bool> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _errorController.add('location services are disabled');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _errorController.add('location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _errorController.add('location permissions are permanently denied');
      return false;
    }

    return true;
  }

  // cancel matchmaking
  Future<void> cancelMatchmaking() async {
    final userId = _userId;
    final entryId = _currentQueueEntryId;

    if (userId == null) {
      _errorController.add('user not authenticated.');
      return;
    }

    if (!_isInQueue) return;

    _isInQueue = false;
    _currentQueueEntryId = null;
    _matchSubscription?.cancel();
    _nearbySubscription?.cancel();

    try {
      if (entryId != null) {
        await _supabase.from('matchmaking_queue').delete().eq('id', entryId);
        developer.log('Deleted queue entry $entryId.',
            name: 'MatchmakingService');
      } else {
        // delete any user entries as fallback
        await _supabase
            .from('matchmaking_queue')
            .delete()
            .eq('user_id', userId);
        developer.log('Deleted queue entries by user ID (fallback).',
            name: 'MatchmakingService');
      }

      _matchStateController.add(MatchmakingState.idle);
      developer.log('Matchmaking cancelled. State set to idle.',
          name: 'MatchmakingService');
    } catch (e) {
      _errorController.add('error canceling matchmaking: $e');
      _matchStateController.add(MatchmakingState.idle);
      developer.log('Error cancelling matchmaking: $e. State set to idle.',
          name: 'MatchmakingService');
    }
  }

  void _onMatchFound(String gameId) {
    if (!_isInQueue) return;

    _isInQueue = false;
    _currentQueueEntryId = null;

    _matchStateController.add(MatchmakingState.matched);
    _matchedGameIdController.add(gameId);

    _nearbySubscription?.cancel();
    _nearbySubscription = null;

    _cleanupListener();
  }

  void _cleanupListener() {
    _matchSubscription?.cancel();
    _matchSubscription = null;
  }

  // directly initiate a match with a specific (nearby) player
  Future<void> initiateDirectMatch(String targetUserId) async {
    final localUserId = _userId;

    if (localUserId == null) {
      _errorController.add('user not authenticated');
      return;
    }

    if (_isInQueue) {
      await cancelMatchmaking();
    }

    _matchStateController.add(MatchmakingState.searching);

    try {
      // create game session
      final gameId = Uuid().v4();
      await _createDirectGameSession(gameId, localUserId, targetUserId, true);

      // add entries to matchmaking queue for both players
      await _supabase.rpc(
        'create_direct_match_queue_entries',
        params: {
          'p_initiator_id': localUserId,
          'p_target_id': targetUserId,
          'p_game_id': gameId,
        },
      );

      _onMatchFound(gameId);
    } catch (e) {
      _errorController.add('error initiating direct match: $e');
      _matchStateController.add(MatchmakingState.error);
      developer.log('[MatchmakingService] error initiating direct match: $e');
      _isInQueue = false;
    }
  }

  Future<void> _createDirectGameSession(String gameId, String player1Id,
      String player2Id, bool isNearbyMatch) async {
    try {
      final playerIds = [player1Id, player2Id];
      playerIds.shuffle();
      final startingPlayerId = playerIds[0];

      await _supabase.from('game_sessions').insert({
        'id': gameId,
        'player1_id': player1Id,
        'player2_id': player2Id,
        'current_player_id': startingPlayerId,
        'is_nearby_match': isNearbyMatch,
      });
    } catch (e) {
      developer
          .log('[MatchmakingService] Error in _createGameSessionDirect: $e');
      _errorController.add('error creating direct game session: $e');
      throw Exception('failed to create direct game session: $e');
    }
  }

  // online status
  Future<void> _updateOnlineStatus(bool isOnline) async {
    try {
      final userId = _userId;
      if (userId == null) return;

      await _supabase.from('users').update({
        'is_online': isOnline,
        'last_online': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      developer.log('error updating online status: $e');
    }
  }

  Future<void> goOnline() async {
    await _updateOnlineStatus(true);
  }

  Future<void> goOffline() async {
    await _updateOnlineStatus(false);
  }

  void dispose() {
    _matchSubscription?.cancel();
    _nearbySubscription?.cancel();
    _matchStateController.close();
    _matchedGameIdController.close();
    _nearbyPlayersController.close();
    _errorController.close();
  }
}

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final matchmakingServiceProvider = Provider<MatchmakingService>(
  (ref) {
    final supabase = ref.watch(supabaseProvider);
    return MatchmakingService(supabase);
  },
);

final matchmakingStateProvider = StreamProvider<MatchmakingState>(
  (ref) {
    final service = ref.watch(matchmakingServiceProvider);
    return service.matchmakingStateStream;
  },
);

final matchedGameIdProvider = StreamProvider<String?>(
  (ref) {
    final service = ref.watch(matchmakingServiceProvider);
    return service.matchedGameIdStream;
  },
);

final nearbyPlayersProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) {
    final service = ref.watch(matchmakingServiceProvider);
    return service.nearbyPlayersStream;
  },
);

final matchmakingErrorProvider = StreamProvider<String>((ref) {
  final service = ref.watch(matchmakingServiceProvider);
  return service.errorStream;
});
