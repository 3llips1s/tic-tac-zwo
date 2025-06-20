import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tic_tac_zwo/features/profile/data/models/game_history_entry.dart';

import '../models/user_profile.dart';

class UserProfileRepo {
  final SupabaseClient _supabase;

  UserProfileRepo(this._supabase);

  Future<UserProfile?> getUserProfile(String userId) async {
    final response =
        await _supabase.from('users').select().eq('id', userId).single();

    return UserProfile.fromJson(response);
  }

  Future<void> createUserProfile({
    required String userId,
    required String username,
    String? countryCode,
  }) async {
    final userData = {
      'id': userId,
      'username': username,
      'country_code': countryCode,
      'points': 0,
      'games_played': 0,
      'games_won': 0,
      'games_drawn': 0,
      'last_online': DateTime.now().toIso8601String(),
      'is_online': false,
      'total_article_attempts': 0,
      'total_correct_articles': 0
    };

    await _supabase.from('users').update(userData).eq('id', userId);
  }

  Future<void> updateUserProfile({
    required String userId,
    String? username,
    String? countryCode,
  }) async {
    final updates = <String, dynamic>{};
    if (username != null) updates['username'] = username;
    if (countryCode != null) updates['country_code'] = countryCode;

    await _supabase.from('users').update(updates).eq('id', userId);
  }

  Future<String> uploadAvatar(String userId, File imageFile) async {
    final fileExt = imageFile.path.split('.').last;
    final filePath = '$userId/avatar.$fileExt';

    await _supabase.storage.from('avatars').upload(filePath, imageFile);

    final String avatarUrl =
        _supabase.storage.from('avatars').getPublicUrl(filePath);

    // update avatar url in db
    await _supabase
        .from('users')
        .update({'avatar_url': avatarUrl}).eq('id', userId);

    return avatarUrl;
  }

  Future<void> updateUserLocation(String userId, double lat, double lng) async {
    await _supabase.from('users').update({
      'lat': lat,
      'lng': lng,
      'last_online': DateTime.now().toIso8601String(),
      'is_online': true
    }).eq('id', userId);
  }

  Future<void> setUserOffline(String userId) async {
    await _supabase.from('users').update({
      'is_online': false,
      'last_online': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  Future<bool> checkUsernameAvailability(String username) async {
    final response = await _supabase
        .from('users')
        .select('username')
        .eq('username', username)
        .maybeSingle();

    return response == null;
  }

  Future<List<GameHistoryEntry>> getGameHistory(
    String userId, {
    int limit = 9,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_game_history',
        params: {
          'p_user_id': userId,
          'p_limit': limit,
        },
      );

      final history = (response as List<dynamic>)
          .map(
              (item) => GameHistoryEntry.fromJson(item as Map<String, dynamic>))
          .toList();

      return history;
    } catch (e) {
      print('Error fetching game history: $e');
      return [];
    }
  }
}
