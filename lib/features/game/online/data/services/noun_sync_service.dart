import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// TODO: ensure that fallbacknouns are not updated twice

class NounSyncService {
  final SupabaseClient client;

  NounSyncService({required this.client});

  Future<List<Map<String, dynamic>>> fetchNouns({
    DateTime? since,
    int? lastVersions,
  }) async {
    List<Map<String, dynamic>> allData = [];
    int batchSize = 1000;
    int offset = 0;

    while (true) {
      var query = client.from('german_nouns').select();

      // Apply filters if provided
      if (since != null) {
        query = query.gte('updated_at', since.toIso8601String());
      }
      if (lastVersions != null) {
        query = query.gt('version', lastVersions);
      }

      // Fetch the data
      final data = await query.range(offset, offset + batchSize - 1);

      if (data.isEmpty) {
        break; // Exit the loop if no more data is returned
      }

      allData.addAll(List<Map<String, dynamic>>.from(data));
      offset += batchSize; // Increment the offset for the next batch
    }

    print('Total fetched: ${allData.length} nouns');
    return allData;
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

final nounSyncServiceProvider = Provider<NounSyncService>(
  (ref) {
    final supabaseClient = Supabase.instance.client;
    return NounSyncService(client: supabaseClient);
  },
);
