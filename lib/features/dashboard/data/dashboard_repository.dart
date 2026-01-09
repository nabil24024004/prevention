import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../blocking/data/blocker_repository.dart';

final dashboardRepositoryProvider = Provider(
  (ref) => DashboardRepository(Supabase.instance.client),
);

final weeklyCheckInsProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getWeeklyCheckIns();
});

final weeklyRelapsesProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getWeeklyRelapses();
});

final relapseHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  return ref.watch(dashboardRepositoryProvider).getRelapseHistory();
});

class DashboardRepository {
  final SupabaseClient _client;

  DashboardRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  /// Logs a security event to audit trail
  Future<void> _logSecurityEvent(
    String eventType,
    Map<String, dynamic> data,
  ) async {
    try {
      await _client.rpc(
        'log_security_event',
        params: {'p_event_type': eventType, 'p_event_data': data},
      );
    } catch (e) {
      // Fail silently - logging should not block critical operations
    }
  }

  Future<void> logRelapse({
    required String trigger,
    required String reflection,
  }) async {
    // Insert relapse record
    await _client.from('relapses').insert({
      'user_id': _userId,
      'trigger': trigger,
      'reflection': reflection,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });

    // Reset streak by updating start_date to now
    await _client
        .from('users')
        .update({
          'start_date': DateTime.now().toUtc().toIso8601String(),
          'last_relapse_date': DateTime.now().toUtc().toIso8601String(),
          'current_streak_days': 0,
        })
        .eq('id', _userId);
  }

  Future<void> logDailyCheckIn({required String mood, String? notes}) async {
    // Check for external VPN
    final blockerRepo = BlockerRepository();
    final externalVpn = await blockerRepo.isExternalVpnActive();

    if (externalVpn) {
      // Log security event
      await _logSecurityEvent('vpn_detected_during_checkin', {
        'vpn': 'external',
      });
      throw Exception(
        'External VPN detected. Please disable VPN to maintain streak integrity.',
      );
    }

    // Check current streak to see if we need to reset the timer
    final userResponse = await _client
        .from('users')
        .select('current_streak_days')
        .eq('id', _userId)
        .single();

    final currentStreak = userResponse['current_streak_days'] as int;

    // If streak is 0, this check-in marks the start of a new streak timer
    if (currentStreak == 0) {
      await _client
          .from('users')
          .update({'start_date': DateTime.now().toUtc().toIso8601String()})
          .eq('id', _userId);
    }

    // Call the server-side function to securely logs check-in and update streak
    await _client.rpc(
      'log_daily_checkin',
      params: {'p_mood': mood, 'p_notes': notes},
    );
  }

  Future<void> recalculateStreak() async {
    await _client.rpc('recalculate_streak');
  }

  /// Check if user has already checked in today
  Future<bool> hasCheckedInToday() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final response = await _client
        .from('daily_log')
        .select('date')
        .eq('user_id', _userId)
        .eq('date', today)
        .maybeSingle();
    return response != null;
  }

  /// Check if user has relapsed today
  Future<bool> hasRelapsedToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toUtc();
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final response = await _client
        .from('relapses')
        .select('timestamp')
        .eq('user_id', _userId)
        .gte('timestamp', startOfDay.toIso8601String())
        .lt('timestamp', endOfDay.toIso8601String())
        .maybeSingle();

    return response != null;
  }

  Future<List<String>> getWeeklyCheckIns() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final startStr = startOfWeek.toIso8601String().split('T')[0];
    final endStr = endOfWeek.toIso8601String().split('T')[0];

    final response = await _client
        .from('daily_log')
        .select('date')
        .eq('user_id', _userId)
        .gte('date', startStr)
        .lte('date', endStr)
        .eq('completed_checkin', true);

    return (response as List).map((e) => e['date'] as String).toList();
  }

  Future<List<String>> getWeeklyRelapses() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    // relapses store timestamp (timestamptz)
    final startStr = startOfWeek.toUtc().toIso8601String();
    final endStr = endOfWeek
        .add(const Duration(days: 1))
        .toUtc()
        .toIso8601String(); // End of week + 1 day to catch all

    final response = await _client
        .from('relapses')
        .select('timestamp')
        .eq('user_id', _userId)
        .gte('timestamp', startStr)
        .lt('timestamp', endStr);

    return (response as List).map((e) {
      final ts = DateTime.parse(e['timestamp'] as String).toLocal();
      return ts.toIso8601String().split('T')[0];
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getRelapseHistory({int limit = 10}) async {
    final response = await _client
        .from('relapses')
        .select('timestamp, trigger, reflection')
        .eq('user_id', _userId)
        .order('timestamp', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }
}
