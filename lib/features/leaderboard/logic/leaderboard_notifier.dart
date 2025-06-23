import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/features/leaderboard/data/leaderboard_entry.dart';
import 'package:tic_tac_zwo/features/leaderboard/data/leaderboard_repo.dart';
import 'package:tic_tac_zwo/features/profile/data/mock_data.dart';

class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final LeaderboardRepo _repo;

  // todo: remove mock data

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
            isCurrentUser: user.id == userId,
          );
        }).toList();
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
