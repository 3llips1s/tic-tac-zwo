import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/features/leaderboard/data/leaderboard_entry.dart';
import 'package:tic_tac_zwo/features/leaderboard/data/leaderboard_repo.dart';
import 'package:tic_tac_zwo/features/profile/data/mock_data.dart';

class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final LeaderboardRepo _repo;

  final bool _useMockData = true;

  LeaderboardNotifier(this._repo) : super(const LeaderboardState.initial());

  Future<void> loadLeaderboard(String userId, {int showCount = 99}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      List<LeaderboardEntry> entries;

      if (_useMockData) {
        await Future.delayed(const Duration(seconds: 1));
        entries = MockDataService.mockUsers.map((user) {
          final rank = MockDataService.mockUsers.indexOf(user) + 1;
          final accuracy = user.totalArticleAttempts == 0
              ? 0.0
              : (user.totalCorrectArticles / user.totalArticleAttempts) * 100;

          return LeaderboardEntry(
            id: user.id,
            rank: rank,
            username: user.username,
            countryCode: user.countryCode ?? '',
            gamesPlayed: user.gamesPlayed,
            gamesWon: user.gamesWon,
            gamesDrawn: user.gamesDrawn,
            accuracy: accuracy,
            points: user.points,
            isCurrentUser: user.id == MockDataService.currentUser.id,
          );
        }).toList();

        _generateMockLeaderboardData(userId: userId, count: 50);
      } else {
        final data =
            await _repo.getLeaderboard(userId: userId, showCount: showCount);
        // todo: add final to data?
        entries = data.map((json) => LeaderboardEntry.fromJson(json)).toList();
      }

      final top3 = entries.take(3).toList();
      final remaining = entries.skip(3).toList();

      state = LeaderboardState.loaded(
        top3: top3,
        remaining: remaining,
        lastUpdated: DateTime.now(),
      );
    } on LeaderboardException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Unexpected error');
    }
  }

  Future<void> refreshLeaderboard(String userId) async {
    await loadLeaderboard(userId);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

class LeaderboardState {
  final List<LeaderboardEntry> top3;
  final List<LeaderboardEntry> remaining;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const LeaderboardState(
      {required this.top3,
      required this.remaining,
      required this.isLoading,
      this.error,
      this.lastUpdated});

  const LeaderboardState.initial()
      : top3 = const [],
        remaining = const [],
        isLoading = false,
        error = null,
        lastUpdated = null;

  const LeaderboardState.loaded({
    required this.top3,
    required this.remaining,
    required this.lastUpdated,
  })  : isLoading = false,
        error = null;

  LeaderboardState copyWith({
    List<LeaderboardEntry>? top3,
    List<LeaderboardEntry>? remaining,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return LeaderboardState(
      top3: top3 ?? this.top3,
      remaining: remaining ?? this.remaining,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  bool get hasData => top3.isNotEmpty || remaining.isNotEmpty;
  bool get isEmpty => top3.isEmpty && remaining.isEmpty;
  List<LeaderboardEntry> get allEntries => [...top3, ...remaining];
}

// todo: remove mock data

List<Map<String, dynamic>> _generateMockLeaderboardData({
  required String userId,
  int count = 50,
}) {
  final Random random = Random();
  final List<String> mockUsernames = [
    'PlayerOne',
    'CyberCat',
    'ZeroCool',
    'AcidBurn',
    'Marindany',
    'Cereal',
    'Phantom',
    'Gaicha',
    'Trinity',
    'Morpheus',
    'Rogue',
    'Ghost',
    'Viper',
    'Chwakie',
    'Yoyo',
    'Boi',
    'Neo',
    'Bo',
    'Mungai',
    'Mimmo'
  ];

  final List<String> mockCountries = [
    'DE',
    'US',
    'GB',
    'FR',
    'CA',
    'AU',
    'JP',
    'CH'
  ];

  List<Map<String, dynamic>> entries = [];

  for (int i = 0; i < count; i++) {
    String baseName = mockUsernames[random.nextInt(mockUsernames.length)];
    int number = random.nextInt(99);
    String username = '$baseName$number';
    if (username.length > 9) {
      int availableDigits = 9 - baseName.length;
      if (availableDigits > 0) {
        int maxNumber = pow(10, availableDigits).toInt() - 1;
        number = random.nextInt(maxNumber + 1);
        username = '$baseName$number';
      } else {
        username = baseName.substring(0, 9);
      }
    }

    int points = (1000 - i * 15) + random.nextInt(10);
    int gamesPlayed = 20 + random.nextInt(50);
    int gamesWon = (gamesPlayed * (0.4 + random.nextDouble() * 0.5)).round();
    int gamesDrawn = min((gamesPlayed - gamesWon), random.nextInt(5));
    double accuracy = 65 + random.nextDouble() * 34;

    entries.add({
      'id': 'mock_user_id_$i',
      'rank': i + 1,
      'username': username,
      'country_code': mockCountries[random.nextInt(mockCountries.length)],
      'games_played': gamesPlayed,
      'games_won': gamesWon,
      'games_drawn': gamesDrawn,
      'accuracy': accuracy,
      'points': points,
      'is_current_user': false,
    });
  }

  int currentUserIndex = 14;
  if (count > currentUserIndex) {
    entries[currentUserIndex]['id'] = userId;
    entries[currentUserIndex]['username'] = 'Du';
    entries[currentUserIndex]['is_current_user'] = true;
    entries[currentUserIndex]['country_code'] = 'KE';
  }

  return entries;
}

final leaderboardRepoProvider = Provider<LeaderboardRepo>((ref) {
  return LeaderboardRepo();
});

final leaderboardProvider =
    StateNotifierProvider<LeaderboardNotifier, LeaderboardState>(
  (ref) {
    final repo = ref.watch(leaderboardRepoProvider);
    return LeaderboardNotifier(repo);
  },
);
