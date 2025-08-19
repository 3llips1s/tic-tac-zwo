import 'dart:developer' as developer;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:tic_tac_zwo/features/auth/logic/auth_providers.dart';
import 'package:tic_tac_zwo/features/game/online/data/services/matchmaking_service.dart';
import 'package:tic_tac_zwo/features/profile/data/models/game_history_entry.dart';
import 'package:tic_tac_zwo/features/profile/data/models/user_profile.dart';
import 'package:tic_tac_zwo/features/profile/data/repositories/user_profile_repo.dart';

import '../data/models/user_profile_hive.dart';

final userProfileRepoProvider = Provider<UserProfileRepo>((ref) {
  final supabaseClient = ref.watch(supabaseProvider);
  return UserProfileRepo(supabaseClient);
});

final userProfileProvider =
    FutureProvider.family<UserProfile, String>((ref, userId) async {
  final repo = ref.watch(userProfileRepoProvider);
  final userProfile = await repo.getUserProfile(userId);

  if (userProfile == null) {
    throw Exception('User profile not found for userId:$userId');
  }

  return userProfile;
});

final gamesHistoryProvider =
    FutureProvider.family<List<GameHistoryEntry>, String>(
  (ref, userId) {
    final repo = ref.watch(userProfileRepoProvider);
    final history = repo.getGameHistory(userId);
    return history;
  },
);

final currentUserProfileProvider = FutureProvider<UserProfile>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (state) {
      final userId = state.session?.user.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      return ref.watch(userProfileProvider(userId).future);
    },
    loading: () {
      return Completer<UserProfile>().future;
    },
    error: (error, stackTrace) {
      throw Exception('Auth state error: $error');
    },
  );
});

final cachedCurrentUserProfileProvider =
    FutureProvider<UserProfile?>((ref) async {
  try {
    final authService = ref.watch(authServiceProvider);

    if (!authService.isAuthenticated) {
      return null;
    }

    final freshProfile = await ref.watch(currentUserProfileProvider.future);

    await _cacheUserProfile(freshProfile);

    return freshProfile;
  } catch (error) {
    final cachedProfile = await _getCachedUserProfile();

    if (cachedProfile != null) {
      return cachedProfile;
    }

    return null;
  }
});

Future<void> _cacheUserProfile(UserProfile userProfile) async {
  try {
    final box = Hive.box('user_preferences');
    final hiveProfile = UserProfileHive.fromUserProfile(userProfile);
    await box.put('cached_user_profile', hiveProfile);
  } catch (e) {
    developer.log('failed to cache user profile: $e',
        name: 'user_profile_providers');
  }
}

Future<UserProfile?> _getCachedUserProfile() async {
  try {
    final box = Hive.box('user_preferences');
    final UserProfileHive? cachedHiveProfile = box.get('cached_user_profile');

    if (cachedHiveProfile != null) {
      return cachedHiveProfile.toUserProfile();
    }

    return null;
  } catch (e) {
    developer.log('failed to get cached user profile: $e',
        name: 'user_profile_providers');
    return null;
  }
}

Future<void> clearCachedUserProfile() async {
  try {
    final box = Hive.box('user_preferences');
    await box.delete('cached_user_profile');
  } catch (e) {
    developer.log('failed to clear cached user profile: $e',
        name: 'user_profile_providers');
  }
}
