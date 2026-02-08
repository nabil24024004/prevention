import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final contentRepositoryProvider = Provider(
  (ref) => ContentRepository(Supabase.instance.client),
);

final contentStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String?>((ref, type) {
      return ref.watch(contentRepositoryProvider).getContentStream(type: type);
    });

class ContentRepository {
  final SupabaseClient _client;
  static const _cacheKeyPrefix = 'cached_content_';

  ContentRepository(this._client);

  Future<SharedPreferences> _getPrefs() async => SharedPreferences.getInstance();

  Stream<List<Map<String, dynamic>>> getContentStream({String? type}) async* {
    final prefs = await _getPrefs();
    final cacheKey = _cacheKeyPrefix + (type ?? 'all');

    // First, emit cached data immediately
    final cachedJson = prefs.getString(cacheKey);
    if (cachedJson != null) {
      try {
        final cached = (jsonDecode(cachedJson) as List).cast<Map<String, dynamic>>();
        debugPrint('[ContentRepository] Emitting ${cached.length} cached items for type: $type');
        yield cached;
      } catch (e) {
        debugPrint('[ContentRepository] Error parsing cache: $e');
      }
    } else {
      debugPrint('[ContentRepository] No cache found for key: $cacheKey');
    }

    // Then try to connect to the real-time stream
    try {
      debugPrint('[ContentRepository] Connecting to Supabase stream for type: $type');
      var query = _client.from('content_resources').stream(primaryKey: ['id']);
      
      await for (final data in query) {
        List<Map<String, dynamic>> result;
        if (type != null) {
          result = data.where((item) => item['type'] == type).toList();
        } else {
          result = List<Map<String, dynamic>>.from(data);
        }
        
        // Cache the fresh data
        debugPrint('[ContentRepository] Caching ${result.length} items for type: $type');
        await prefs.setString(cacheKey, jsonEncode(result));
        yield result;
      }
    } catch (e) {
      debugPrint('[ContentRepository] Stream error (offline?): $e');
      // On error (offline), we already emitted cached data, just return silently
      if (cachedJson != null) return;
      // No cached data and error - yield empty list so UI handles it gracefully (or shows empty state)
      yield [];
    }
  }
}

