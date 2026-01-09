import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final contentRepositoryProvider = Provider((ref) => ContentRepository(Supabase.instance.client));

final contentStreamProvider = StreamProvider.family<List<Map<String, dynamic>>, String?>((ref, type) {
  return ref.watch(contentRepositoryProvider).getContentStream(type: type);
});

class ContentRepository {
  final SupabaseClient _client;

  ContentRepository(this._client);

  Stream<List<Map<String, dynamic>>> getContentStream({String? type}) {
    var query = _client.from('content_resources').stream(primaryKey: ['id']);
    if (type != null) {
      // Stream filtering is limited, so we act like we are filtering or just fetch all
      // For simplicity/correctness with Supabase stream, we'll fetch all and filter in app if needed,
      // or just trust the RLS. But 'stream' doesn't support complex filtering easily in early versions.
      // Let's stick to simple stream for now.
      return query.map((data) => data.where((item) => item['type'] == type).toList());
    }
    return query;
  }
}
