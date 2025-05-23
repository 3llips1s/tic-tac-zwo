import 'dart:async';

import 'package:flutter/foundation.dart';
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
      if (kDebugMode) {
        print('[MatchmakingService] Error:  user not authenticated');
      }
      return;
    }
    if (kDebugMode) {
      print('[MatchmakingService] initialized for user:$_userId');
    }
  }

  // global match making
  Future<void> startGlobalMatchmaking() async {
    final userId = _userId;

    if (userId == null) {
      _errorController.add('user not authenticated.');
      if (kDebugMode) {
        print(
            '[MatchmakingService] Error starting global:  user not authenticated');
      }
      return;
    }

    if (_isInQueue) {
      if (kDebugMode) {
        print('[MatchmakingService] already in queue, cannot start global');
      }
      return;
    }

    // update state
    _matchStateController.add(MatchmakingState.searching);
    _isInQueue = true;

    if (kDebugMode) {
      print('[MatchmakingService] start global match for user: $_userId');
    }

    try {
      // delete existing entries for user
      await _supabase
          .from('matchmaking_queue')
          .delete()
          .eq('user_id', userId)
          .eq('is_nearby_match', false);
      if (kDebugMode) {
        print(
            '[MatchmakingService] deleted previous queue entries for user:$_userId');
      }

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
      if (kDebugMode) {
        print(
            '[MatchmakingService] added to global queue. entry id: $_currentQueueEntryId');
      }

      // start listening for matches
      _startMatchListener();
    } catch (e) {
      _errorController.add('failed to start matchmaking: $e');
      _matchStateController.add(MatchmakingState.error);
      _isInQueue = false;
      _currentQueueEntryId = null;
      if (kDebugMode) {
        print('[MatchmakingService] Error starting global:$e');
      }
    }
  }

  // nearby matchmaking
  Future<void> startNearbyMatchmaking() async {
    final userId = _userId;

    if (userId == null) {
      _errorController.add('user not authenticated.');
      if (kDebugMode) {
        print(
            '[MatchmakingService] Error starting nearby:  user not authenticated');
      }
      return;
    }

    if (_isInQueue) {
      if (kDebugMode) {
        print('[MatchmakingService] already in queue. cannot start nearby');
      }
      return;
    }

    // get location permission and coordinates
    bool hasPermission = await _requestLocationPermission();
    if (!hasPermission) {
      _errorController.add('location permission denied');
      if (kDebugMode) {
        print('[MatchmakingService] location permission denied');
      }
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      if (kDebugMode) {
        print(
            '[MatchmakingService] got location:  ${position.latitude} : ${position.longitude}');
      }

      // update state
      _matchStateController.add(MatchmakingState.searching);
      _isInQueue = true;
      if (kDebugMode) {
        print('[MatchmakingService] starting nearby match for user:$_userId');
      }

      // delete existing entries for the user
      await _supabase.from('matchmaking_queue').delete().eq('user_id', userId);
      if (kDebugMode) {
        print(
            '[MatchmakingService] deleted previous queue entries for user:$_userId');
      }

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
      if (kDebugMode) {
        print(
            '[MatchmakingService] added to nearby queue. entry id:$_currentQueueEntryId');
      }

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
      if (kDebugMode) {
        print('[MatchmakingService] Error starting nearby match: $e');
      }
    }
  }

  // listen for match updates
  // listen for match updates
  void _startMatchListener() {
    final userId = _userId;
    final entryId = _currentQueueEntryId;

    if (userId == null || entryId == null) {
      _errorController
          .add('cannot start listener: user or queue entry id missing.');
      if (kDebugMode) {
        print(
            '[MatchmakingService] Error:  cannot start listener. user or entry id missing');
      }
      return;
    }

    _matchSubscription?.cancel();
    if (kDebugMode) {
      print(
          '[MatchmakingService] starting match listener for entry id: $entryId');
    }

    // subscribe to channel for realtime updates
    _matchSubscription = _supabase
        .from('matchmaking_queue')
        .stream(primaryKey: ['id'])
        .eq('id', entryId)
        .listen(
          (data) {
            if (kDebugMode) {
              print(
                  '[MatchmakingService] received data on match stream: $data');
            }
            if (data.isNotEmpty) {
              final matchData = data.first;
              final bool isMatched = matchData['is_matched'] ?? false;
              final String? gameId = matchData['game_id'];

              if (kDebugMode) {
                print(
                    '[MatchmakingService] processing queue entry update: is_matched=$isMatched, game_id=$gameId');
              }

              if (isMatched && gameId != null) {
                _onMatchFound(gameId);
              } else {
                if (kDebugMode) {
                  print('queue entry updated, but not matched yet.');
                }
              }
            } else {
              if (kDebugMode) {
                print(
                    '[MatchmakingService] received empty data for entry id $entryId. entry might have been deleted.');
              }
              if (_isInQueue && _currentQueueEntryId == entryId) {
                if (kDebugMode) {
                  print(
                      '[MatchmakingService] Queue entry $entryId disappeared. Cancelling matchmaking.');
                }
                cancelMatchmaking();
              }
            }
          },
          onError: (error) {
            if (kDebugMode) {
              print(
                  '[MatchmakingService] match listener error for entry $entryId: $error');
            }
            _errorController.add('match listener error: $error');

            if (_isInQueue && _currentQueueEntryId == entryId) {
              if (kDebugMode) {
                print(
                    '[MatchmakingService] Error on active match listener for $entryId. Cancelling matchmaking.');
              }
              cancelMatchmaking();
              _matchStateController.add(MatchmakingState.error);
            } else {
              if (kDebugMode) {
                print(
                    '[MatchmakingService] Match listener error for an old/inactive entry $entryId. Ignoring cancellation for current queue.');
              }
            }
          },
          onDone: () {
            if (kDebugMode) {
              print('[MatchmakingService] match listener done (closed).');
            }
          },
        );
  }

  // listen for nearby players
  void _startNearbyPlayersListener(double lat, double lng) {
    _nearbySubscription?.cancel();
    if (kDebugMode) {
      print('[MatchmakingService] starting nearby players listener.');
    }

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

              if (kDebugMode) {
                print(
                    '[MatchmakingService] user stream update detected, fetching nearby players...');
              }

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
                if (kDebugMode) {
                  print(
                      '[MatchmakingService] found nearby players: ${players.length}');
                }
                _nearbyPlayersController.add(players);
              } else {
                if (kDebugMode) {
                  print(
                      '[MatchmakingService] unexpected response type from find_nearby players rpc: ${response.runtimeType}');
                }
                _nearbyPlayersController.add([]);
              }
            } catch (e) {
              if (kDebugMode) {
                print(
                    '[MatchmakingService] error finding nearby players via rpc: $e');
              }
              _errorController.add('error finding nearby players: $e');
            }
          },
          onError: (error) {
            if (kDebugMode) {
              print(
                  '[MatchmakingService] nearby players listener error: $error');
            }
            _errorController.add('nearby players listener error: $error');
          },
          onDone: () {
            if (kDebugMode) {
              print(
                  '[MatchmakingService] nearby players listener done/ closed');
            }
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
      if (kDebugMode) {
        print('[MatchmakingService] location services disabled');
      }
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _errorController.add('location permissions are denied');
        if (kDebugMode) {
          print('[MatchmakingService] location permissions denied');
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _errorController.add('location permissions are permanently denied');
      if (kDebugMode) {
        print('[MatchmakingService] location permissions denied forever');
      }
      return false;
    }

    if (kDebugMode) {
      print('[MatchmakingService] location permissions granted');
    }
    return true;
  }

  // cancel matchmaking
  Future<void> cancelMatchmaking() async {
    final userId = _userId;
    final entryId = _currentQueueEntryId;

    if (userId == null) {
      _errorController.add('user not authenticated.');
      if (kDebugMode) {
        print('[MatchmakingService] cannot cancel, user not auth\'d');
      }
      return;
    }

    if (!_isInQueue) {
      if (kDebugMode) {
        print('[MatchmakingService] Cannot cancel: Not in queue.');
      }
      return; // Nothing to cancel
    }

    if (kDebugMode) {
      print(
          '[MatchmakingService] Canceling matchmaking for user $userId, entry $entryId');
    }

    _isInQueue = false;
    _currentQueueEntryId = null;
    _matchSubscription?.cancel();
    _nearbySubscription?.cancel();

    try {
      if (entryId != null) {
        await _supabase.from('matchmaking_queue').delete().eq('id', entryId);
        if (kDebugMode) {
          print('[MatchmakingService] Deleted queue entry $entryId.');
        } else {
          // delete any user entries as fallback
          await _supabase
              .from('matchmaking_queue')
              .delete()
              .eq('user_id', userId);
          if (kDebugMode) {
            print(
                '[MatchmakingService] Deleted queue entries by user ID (fallback).');
          }
        }
      }

      _matchStateController.add(MatchmakingState.idle);
      if (kDebugMode) {
        print('[MatchmakingService] Matchmaking cancelled. State set to idle.');
      }
    } catch (e) {
      _errorController.add('error canceling matchmaking: $e');
      _matchStateController.add(MatchmakingState.idle);
      if (kDebugMode) {
        print(
            '[MatchmakingService] Error cancelling matchmaking: $e. State set to idle.');
      }
    }
  }

  void _onMatchFound(String gameId) {
    if (!_isInQueue) {
      if (kDebugMode) {
        print(
            '[MatchmakingService] _onMatchFound called but _isInQueue is false. Match likely already processed or cancelled. Ignoring gameId: $gameId');
      }
      return;
    }

    _isInQueue = false;
    _currentQueueEntryId = null;

    if (kDebugMode) {
      print(
          '[MatchmakingService] Match found! Game ID: $gameId. Cleaning up and notifying.');
    }

    _matchStateController.add(MatchmakingState.matched);
    _matchedGameIdController.add(gameId);

    _nearbySubscription?.cancel();
    _nearbySubscription = null;

    _cleanupListener();
  }

  void _cleanupListener() {
    if (kDebugMode) print('[MatchmakingService] Cleaning up match listener.');
    _matchSubscription?.cancel();
    _matchSubscription = null;
  }

  // directly initiate a match with a specific (nearby) player
  Future<void> initiateDirectMatch(String targetUserId) async {
    final localUserId = _userId;

    if (localUserId == null) {
      _errorController.add('user not authenticated');
      if (kDebugMode) {
        print(
            '[MatchmakingService] cannot initiate direct match: user not authenticated');
      }
      return;
    }

    if (kDebugMode) {
      print('[MatchmakingService] Initiating direct match with $targetUserId');
    }

    if (_isInQueue) {
      await cancelMatchmaking();
    }

    _matchStateController.add(MatchmakingState.searching);

    try {
      // create game session
      final gameId = Uuid().v4();
      await _createDirectGameSession(gameId, localUserId, targetUserId, true);

      if (kDebugMode) {
        print(
            '[MatchmakingService] Direct match game session created: $gameId');
      }

      // add entries to matchmaking queue for both players
      await _supabase.rpc(
        'create_direct_match_queue_entries',
        params: {
          'p_initiator_id': localUserId,
          'p_target_id': targetUserId,
          'p_game_id': gameId,
        },
      );

      if (kDebugMode) {
        print('[MatchmakingService] added both queue entries for direct match');
      }

      _onMatchFound(gameId);
    } catch (e) {
      _errorController.add('error initiating direct match: $e');
      _matchStateController.add(MatchmakingState.error);
      if (kDebugMode) {
        print('[MatchmakingService] error initiating direct match: $e');
      }
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
      if (kDebugMode) {
        print(
            '[MatchmakingService] _createGameSessionDirect successful for game $gameId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[MatchmakingService] Error in _createGameSessionDirect: $e');
      }
      _errorController.add('error creating direct game session: $e');
      throw Exception('failed to create direct game session: $e');
    }
  }

  Future<void> debugCheckQueueStatus() async {
    try {
      final userId = _userId;
      if (userId == null) return;

      final myEntry = await _supabase
          .from('matchmaking_queue')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      print('my queue entry: $myEntry');

      final allEntries = await _supabase
          .from('matchmaking_queue')
          .select()
          .eq('is_matched', false);

      print('my queue entry: $allEntries');
    } catch (e) {
      print('debug queue check error: $e');
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
      print('error updating online status: $e');
    }
  }

  Future<void> goOnline() async {
    await _updateOnlineStatus(true);
  }

  Future<void> goOffline() async {
    await _updateOnlineStatus(false);
  }

  void dispose() {
    if (kDebugMode) print('[MatchmakingService] Disposing service.');
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
