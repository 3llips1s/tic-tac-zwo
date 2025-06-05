import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardRepo {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getLeaderboard({
    required String userId,
    int showCount = 99,
  }) async {
    try {
      final response =
          await _supabase.rpc('get_leaderboard_with_user', params: {
        'user_uuid': userId,
        'show_count': showCount,
      });

      if (response == null) return [];
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw LeaderboardException('Database error: ${e.message}');
    } catch (e) {
      throw LeaderboardException('Failed to fetch leaderboard: $e');
    }
  }
}

class LeaderboardException implements Exception {
  final String message;
  LeaderboardException(this.message);

  @override
  String toString() => 'LeaderboardException: $message';
}
