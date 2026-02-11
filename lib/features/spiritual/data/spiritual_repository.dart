import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../challenges/data/challenges_repository.dart';
import '../../challenges/data/models/challenge.dart';

import 'models/spiritual_log.dart';
import 'models/adhkar_item.dart';

/// Repository for spiritual exercise operations
class SpiritualRepository {
  final SupabaseClient _client;

  SpiritualRepository(this._client);

  String? get _userId => _client.auth.currentUser?.id;

  // ========================================
  // SPIRITUAL LOG OPERATIONS
  // ========================================

  /// Get today's spiritual log (creates if not exists)
  Future<SpiritualLog?> getTodaysLog() async {
    // First try to get existing
    final response = await _client
        .from('spiritual_logs')
        .select()
        .eq('user_id', _userId!)
        .eq('log_date', DateTime.now().toIso8601String().split('T')[0])
        .maybeSingle();

    if (response != null) {
      return SpiritualLog.fromJson(response);
    }

    // Create new log
    final logId = await _client.rpc('get_or_create_spiritual_log');

    final newLog = await _client
        .from('spiritual_logs')
        .select()
        .eq('id', logId)
        .single();

    return SpiritualLog.fromJson(newLog);
  }

  /// Get logs for a date range
  Future<List<SpiritualLog>> getLogs({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _client
        .from('spiritual_logs')
        .select()
        .eq('user_id', _userId!)
        .gte('log_date', startDate.toIso8601String().split('T')[0])
        .lte('log_date', endDate.toIso8601String().split('T')[0])
        .order('log_date', ascending: false);

    return (response as List)
        .map((json) => SpiritualLog.fromJson(json))
        .toList();
  }

  /// Increment dhikr count
  Future<int> incrementDhikr(DhikrType type, {int count = 1}) async {
    final response = await _client.rpc(
      'increment_dhikr',
      params: {'p_dhikr_type': type.dbColumn, 'p_count': count},
    );
    return response['new_count'] as int;
  }

  /// Mark prayer as completed
  Future<void> markPrayerDone(Prayer prayer) async {
    await _client.rpc(
      'mark_prayer_done',
      params: {'p_prayer': prayer.dbColumn},
    );
  }

  /// Mark adhkar session as completed
  Future<void> markAdhkarCompleted(AdhkarCategory category) async {
    String session;
    switch (category) {
      case AdhkarCategory.morning:
        session = 'morning';
        break;
      case AdhkarCategory.evening:
        session = 'evening';
        break;
      case AdhkarCategory.sleep:
        session = 'sleep';
        break;
      default:
        return; // Only these 3 sessions are tracked
    }

    await _client.rpc('mark_adhkar_completed', params: {'p_session': session});
  }

  /// Get spiritual streak
  Future<int> getSpiritualStreak() async {
    final result = await _client.rpc('get_spiritual_streak');
    return result as int;
  }

  /// Update Quran reading
  Future<void> updateQuranReading({int? pages, int? minutes}) async {
    final logId = await _client.rpc('get_or_create_spiritual_log');

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (pages != null) updates['quran_pages_read'] = pages;
    if (minutes != null) updates['quran_minutes_read'] = minutes;

    await _client.from('spiritual_logs').update(updates).eq('id', logId);
  }

  // ========================================
  // ADHKAR CONTENT OPERATIONS
  // ========================================

  /// Get all adhkar for a category
  Future<List<AdhkarItem>> getAdhkarByCategory(AdhkarCategory category) async {
    final response = await _client
        .from('adhkar_content')
        .select()
        .eq('category', category.value)
        .eq('is_active', true)
        .order('display_order');

    return (response as List).map((json) => AdhkarItem.fromJson(json)).toList();
  }

  /// Get all adhkar categories with counts
  Future<Map<AdhkarCategory, int>> getAdhkarCategoryCounts() async {
    final counts = <AdhkarCategory, int>{};

    for (final category in AdhkarCategory.values) {
      final response = await _client
          .from('adhkar_content')
          .select('id')
          .eq('category', category.value)
          .eq('is_active', true);

      counts[category] = (response as List).length;
    }

    return counts;
  }
}

/// Provider for SpiritualRepository
final spiritualRepositoryProvider = Provider<SpiritualRepository>((ref) {
  return SpiritualRepository(Supabase.instance.client);
});

/// AsyncNotifier for today's log (handles optimistic updates & sync)
class TodaysSpiritualLogNotifier extends AsyncNotifier<SpiritualLog?> {
  @override
  Future<SpiritualLog?> build() {
    return ref.watch(spiritualRepositoryProvider).getTodaysLog();
  }

  /// Update Quran reading with optimistic UI + Challenges Sync
  Future<void> updateQuranReading({int? pages, int? minutes}) async {
    final currentState = state.value;
    if (currentState == null) return;

    // 1. Optimistic Update (Local)
    final updatedLog = SpiritualLog(
      id: currentState.id,
      userId: currentState.userId,
      logDate: currentState.logDate,
      createdAt: currentState.createdAt,
      updatedAt: DateTime.now(),
      // Copy all existing fields
      fajrPrayed: currentState.fajrPrayed,
      dhuhrPrayed: currentState.dhuhrPrayed,
      asrPrayed: currentState.asrPrayed,
      maghribPrayed: currentState.maghribPrayed,
      ishaPrayed: currentState.ishaPrayed,
      subhanallahCount: currentState.subhanallahCount,
      alhamdulillahCount: currentState.alhamdulillahCount,
      allahuakbarCount: currentState.allahuakbarCount,
      istighfarCount: currentState.istighfarCount,
      salawatCount: currentState.salawatCount,
      customDhikrCount: currentState.customDhikrCount,
      customDhikrText: currentState.customDhikrText,
      morningAdhkarCompleted: currentState.morningAdhkarCompleted,
      eveningAdhkarCompleted: currentState.eveningAdhkarCompleted,
      sleepAdhkarCompleted: currentState.sleepAdhkarCompleted,
      notes: currentState.notes,

      // Update targeted fields (accumulate)
      quranPagesRead: currentState.quranPagesRead + (pages ?? 0),
      quranMinutesRead: currentState.quranMinutesRead + (minutes ?? 0),
    );

    state = AsyncData(updatedLog);

    try {
      // 2. Sync to Supabase (Spiritual Log)
      await ref
          .read(spiritualRepositoryProvider)
          .updateQuranReading(
            pages: updatedLog.quranPagesRead,
            minutes: updatedLog.quranMinutesRead,
          );

      // 3. Sync to Challenges (Background)
      final challengesRepo = ref.read(challengesRepositoryProvider);
      final activeChallenges = await challengesRepo.getActiveChallenges();

      // Filter for Quran challenges
      final quranChallenges = activeChallenges.where(
        (c) => c.challengeType == ChallengeType.quran,
      );

      for (final challenge in quranChallenges) {
        // For Quran challenges, we usually track pages or minutes.
        // Assuming target_unit tells us what to track.
        int progressToAdd = 0;
        if (challenge.targetUnit == 'pages') {
          progressToAdd = pages ?? 0;
        } else if (challenge.targetUnit == 'minutes') {
          progressToAdd = minutes ?? 0;
        } else {
          // Default fallback or smart detection
          progressToAdd = (pages != null && pages > 0) ? pages : (minutes ?? 0);
        }

        if (progressToAdd > 0) {
          await challengesRepo.updateProgress(challenge.id, progressToAdd);
        }
      }
    } catch (e) {
      // Revert on failure (or keep optimistic state and show error?)
      // For now, reload true state from DB to be safe
      state = AsyncValue.error(e, StackTrace.current);
      ref.invalidateSelf();
    }
  }
}

/// Provider for today's spiritual log
final todaysSpiritualLogProvider =
    AsyncNotifierProvider<TodaysSpiritualLogNotifier, SpiritualLog?>(
      TodaysSpiritualLogNotifier.new,
    );

/// Provider for spiritual streak
final spiritualStreakProvider = FutureProvider<int>((ref) {
  return ref.watch(spiritualRepositoryProvider).getSpiritualStreak();
});

/// Provider for adhkar by category
final adhkarByCategoryProvider =
    FutureProvider.family<List<AdhkarItem>, AdhkarCategory>((ref, category) {
      return ref
          .watch(spiritualRepositoryProvider)
          .getAdhkarByCategory(category);
    });
