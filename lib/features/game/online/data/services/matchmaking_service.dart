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
  Timer? _queueTimer;
  bool _isInQueue = false;

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
      await _supabase.from('matchmaking_queue').insert({
        'user_id': userId,
        'is_nearby_match': false,
        'is_matched': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      // start listening for matches
      _startMatchListener();

      // check for matches periodically
      _queueTimer = Timer.periodic(
        Duration(seconds: 5),
        (_) {
          _checkForMatch();
        },
      );
    } catch (e) {
      _errorController.add('failed to start matchmaking: $e');
      _matchStateController.add(MatchmakingState.error);
    }
  }

  // nearby matchmaking
  Future<void> startNearbyMatchmaking() async {
    final userId = _userId;

    if (userId == null) {
      _errorController.add('user not authenticated.');
      return;
    }

    // get location permission and coordinates
    bool hasPermission = await _requestLocationPermission();
    if (!hasPermission) {
      _errorController.add('location permission denied');
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();

      // update state
      _matchStateController.add(MatchmakingState.searching);
      _isInQueue = true;

      // delete existing entries for the user
      await _supabase
          .from('matchmaking_queue')
          .delete()
          .eq('user_id', userId)
          .eq('is_nearby_match', true);

      // insert new entry in matchmaking queue with location
      await _supabase.from('matchmaking_queue').insert({
        'user_id': userId,
        'is_nearby_match': true,
        'lat': position.latitude,
        'lng': position.longitude,
        'is_matched': false,
        'created_at': DateTime.now().toIso8601String(),
      });

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

      _queueTimer = Timer.periodic(Duration(seconds: 5), (_) {
        _checkForMatch();
      });
    } catch (e) {
      _errorController.add('failed to start nearby matchmaking: $e');
      _matchStateController.add(MatchmakingState.error);
    }
  }

  // listen for match updates
  void _startMatchListener() {
    final userId = _userId;

    if (userId == null) {
      _errorController.add('user not authenticated.');
      return;
    }

    _matchSubscription?.cancel();
    _matchSubscription = _supabase
        .from('matchmaking_queue')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((data) {
          if (data.isNotEmpty) {
            final matchData = data.first;
            if (matchData['is_matched'] == true &&
                matchData['game_id'] != null) {
              _matchStateController.add(MatchmakingState.matched);
              _matchedGameIdController.add(matchData['game_id']);
              _cleanupQueue();
            }
          }
        }, onError: (error) {
          _errorController.add('match listener error: $error');
        });
  }

  // listen for nearby players
  void _startNearbyPlayersListener(double lat, double lng) {
    _nearbySubscription?.cancel();

    // listen to user status changes
    _nearbySubscription = _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('is_online', true)
        .listen((data) async {
          try {
            // rpc call to find nearby player
            final userId = _userId;
            if (userId == null) return;

            final response = await _supabase.rpc('find_nearby_players',
                params: {
                  'p_user_id': userId,
                  'p_lat': lat,
                  'p_lng': lng,
                  'p_radius_meters': 20
                });

            _nearbyPlayersController.add(response);
          } catch (e) {
            _errorController.add('error finding nearby players: $e');
          }
        });
  }

  // check for available matches
  Future<void> _checkForMatch() async {
    if (!_isInQueue) return;

    final userId = _userId;
    if (userId == null) return;

    try {
      // queue entries excluding current user
      final result = await _supabase
          .from('matchmaking_queue')
          .select()
          .eq('is_matched', false)
          .neq('user_id', userId);

      if (result.isEmpty) return;

      // get current user entry
      final localUserEntry = await _supabase
          .from('matchmaking_queue')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      // Check if we got a valid response
      if (localUserEntry == null) return;

      // find a match with compatible criteria (same type of matchmaking)
      Map<String, dynamic>? match;
      for (var entry in result) {
        if (entry['is_nearby_match'] == localUserEntry['is_nearby_match']) {
          match = entry;
          break;
        }
      }

      if (match == null) return;

      // create game session
      final gameId = Uuid().v4();
      await _createGameSession(
        gameId,
        userId,
        match['user_id'],
        localUserEntry['is_nearby_match'],
      );

      // update both players' matchmaking entries
      await _supabase.from('matchmaking_queue').update({
        'is_matched': true,
        'game_id': gameId,
      }).eq('user_id', userId);

      await _supabase.from('matchmaking_queue').update({
        'is_matched': true,
        'game_id': gameId,
      }).eq('user_id', match['user_id']);
    } catch (e) {
      _errorController.add('error checking for match: $e');
    }
  }

  // create a new game session
  Future<void> _createGameSession(String gameId, String player1Id,
      String player2Id, bool isNearbyMatch) async {
    try {
      // randomize who starts first
      final playerIds = [player1Id, player2Id];
      playerIds.shuffle();
      final startingPlayerId = playerIds[0];

      await _supabase.from('game_sessions').insert({
        'id': gameId,
        'player1_id': player1Id,
        'player2_id': player2Id,
        'current_player_id': startingPlayerId,
        'is_nearby_match': isNearbyMatch,
        'created_at': DateTime.now().toIso8601String(),
        'last_activity': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _errorController.add('error creating game session: $e');
    }
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

    if (userId == null) {
      _errorController.add('user not authenticated.');
      return;
    }

    _isInQueue = false;
    _queueTimer?.cancel();
    _matchSubscription?.cancel();
    _nearbySubscription?.cancel();

    try {
      await _supabase.from('matchmaking_queue').delete().eq('user_id', userId);

      _matchStateController.add(MatchmakingState.idle);
    } catch (e) {
      _errorController.add('error canceling matchmaking: $e');
    }
  }

  // clean up queue after successful match
  void _cleanupQueue() {
    _isInQueue = false;
    _queueTimer?.cancel();
  }

  // directly initiate a match with a specific (nearby) player
  Future<void> initiateDirectMatch(String targetUserId) async {
    if (_userId == null) {
      _errorController.add('user not authenticated');
      return;
    }

    try {
      // create game session
      final gameId = Uuid().v4();
      await _createGameSession(gameId, _userId!, targetUserId, true);

      // add entries to matchmaking queue for both players
      await _supabase.from('matchmaking_queue').insert([
        {
          'user_id': _userId,
          'is_nearby_match': true,
          'is_matched': true,
          'game_id': gameId,
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'user_id': targetUserId,
          'is_nearby_match': true,
          'is_matched': true,
          'game_id': gameId,
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);

      _matchStateController.add(MatchmakingState.matched);
      _matchedGameIdController.add(gameId);
    } catch (e) {
      _errorController.add('error initiating direct match: $e');
    }
  }

  void dispose() {
    _matchSubscription?.cancel();
    _nearbySubscription?.cancel();
    _queueTimer?.cancel();
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
