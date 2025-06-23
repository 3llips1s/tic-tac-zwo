import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/features/auth/logic/auth_providers.dart';
import 'package:tic_tac_zwo/features/game/online/data/services/matchmaking_service.dart';
import 'package:tic_tac_zwo/features/profile/data/models/game_history_entry.dart';
import 'package:tic_tac_zwo/features/profile/data/models/user_profile.dart';
import 'package:tic_tac_zwo/features/profile/data/repositories/user_profile_repo.dart';

import '../data/mock_data.dart';

// todo: remove mock data
const bool useMockData = true;

final userProfileRepoProvider = Provider<UserProfileRepo>((ref) {
  final supabaseClient = ref.watch(supabaseProvider);
  return UserProfileRepo(supabaseClient);
});

final userProfileProvider =
    FutureProvider.family<UserProfile, String>((ref, userId) async {
  if (useMockData) {
    final mockUser = MockDataService.mockUsers.firstWhere((u) => u.id == userId,
        orElse: () => MockDataService.currentUser);
    return Future.value(mockUser);
  }

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
    if (useMockData) {
      return Future.value(MockDataService.mockGameHistory);
    }

    final repo = ref.watch(userProfileRepoProvider);
    final history = repo.getGameHistory(userId);
    return history;
  },
);

final mockCurrentUserIdProvider = Provider<String?>((ref) {
  if (useMockData) {
    return 'mock_id_7';
  }

  final authService = ref.watch(authServiceProvider);
  final currentUserId = authService.currentUserId;
  return currentUserId;
});

final currentUserProfileProvider = FutureProvider<UserProfile>((ref) {
  if (useMockData) {
    final userId = ref.watch(mockCurrentUserIdProvider);
    return ref.watch(userProfileProvider(userId!).future);
  }

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
