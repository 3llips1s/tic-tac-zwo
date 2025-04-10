import 'package:supabase_flutter/supabase_flutter.dart';

class NounSyncService {
  final SupabaseClient client;

  NounSyncService({required this.client});

  Future<List<Map<String, dynamic>>> fetchNouns({
    DateTime? since,
    int? lastVersions,
  }) async {
    var query = client.from('german_nouns').select();

    // only fetch nouns updated since last sync date
    if (since != null) {
      query = query.gte('updated_at', since.toIso8601String());
    }

    // or fetch nouns with higher version number
    if (lastVersions != null) {
      query = query.gt('version', lastVersions);
    }

    final data = await query;

    return List<Map<String, dynamic>>.from(data);
  }

  Future<int> getLatestVersion() async {
    final data = await client
        .from('german_nouns')
        .select('version')
        .order('version', ascending: false)
        .limit(1);

    if (data.isEmpty) {
      return 0;
    }

    return data[0]['version'] as int;
  }
}

final supabaseClient = Supabase.instance.client;
