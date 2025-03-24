import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';

class UserProfileRepo {
  final SupabaseClient _supabase;

  UserProfileRepo(this._supabase);

  Future<UserProfile?> getUserProfile(String userId) async {
    final response =
        await _supabase.from('users').select().eq('id', userId).single();

    return UserProfile.fromJson(response);
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
}
