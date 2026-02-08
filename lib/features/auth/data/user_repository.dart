import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/local_cache_service.dart';
import 'user_model.dart';

final userRepositoryProvider = Provider((ref) => UserRepository(Supabase.instance.client));

final userProfileStreamProvider = StreamProvider<UserProfile>((ref) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getUserProfileStream();
});

class UserRepository {
  final SupabaseClient _client;
  LocalCacheService? _cacheService;

  UserRepository(this._client);

  Future<LocalCacheService> _getCache() async {
    _cacheService ??= LocalCacheService(await SharedPreferences.getInstance());
    return _cacheService!;
  }

  Stream<UserProfile> getUserProfileStream() async* {
    final cache = await _getCache();
    
    // Always try to emit cached data first for instant display
    final cached = cache.getCachedUserProfile();
    if (cached != null) {
      yield cached;
    }

    // Check if user is authenticated
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      // Not logged in - use cached data only
      if (cached == null) {
        throw Exception('Please sign in');
      }
      return;
    }

    // Try to fetch fresh data from network
    try {
      await for (final data in _client
          .from('users')
          .stream(primaryKey: ['id'])
          .eq('id', userId)) {
        if (data.isNotEmpty) {
          final profile = UserProfile.fromJson(data.first);
          await cache.cacheUserProfile(profile);
          yield profile;
        }
      }
    } catch (e) {
      // Network error - already yielded cached data above, so just log and exit
      debugPrint('[UserRepository] Offline mode - using cached data: $e');
      // If we have cached data, we already yielded it, so just return
      if (cached != null) return;
      // No cached data - rethrow to show error
      rethrow;
    }
  }

  /// Force fetch profile from network and update cache
  Future<void> refreshProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final data = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      
      final profile = UserProfile.fromJson(data);
      final cache = await _getCache();
      await cache.cacheUserProfile(profile);
      debugPrint('[UserRepository] Profile forced refreshed: ${profile.toJson()}');
    } catch (e) {
      debugPrint('[UserRepository] Failed to force refresh profile: $e');
    }
  }
}


