import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../blocking/data/blocker_repository.dart';

final dashboardRepositoryProvider = Provider((ref) => DashboardRepository(Supabase.instance.client));

final weeklyCheckInsProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getWeeklyCheckIns();
});

class DashboardRepository {
  final SupabaseClient _client;

  DashboardRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  /// Logs a security event to audit trail
  Future<void> _logSecurityEvent(String eventType, Map<String, dynamic> data) async {
    try {
      await _client.rpc('log_security_event', params: {
        'p_event_type': eventType,
        'p_event_data': data,
      });
    } catch (e) {
      // Fail silently - logging should not block critical operations
    }
  }

  Future<void> logRelapse({required String trigger, required String reflection}) async {
    // Insert relapse record
    await _client.from('relapses').insert({
      'user_id': _userId,
      'trigger': trigger,
      'reflection': reflection,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Reset streak by updating start_date to now
    await _client.from('users').update({
      'start_date': DateTime.now().toIso8601String(),
      'last_relapse_date': DateTime.now().toIso8601String(),
      'current_streak_days': 0,
    }).eq('id', _userId);
  }

  Future<void> logDailyCheckIn({required String mood, String? notes}) async {
    // Check for external VPN
    final blockerRepo = BlockerRepository();
    final externalVpn = await blockerRepo.isExternalVpnActive();
    
    if (externalVpn) {
      // Log security event
      await _logSecurityEvent('vpn_detected_during_checkin', {'vpn': 'external'});
      throw Exception('External VPN detected. Please disable VPN to maintain streak integrity.');
    }
    
    // Call the server-side function to securely logs check-in and update streak
    await _client.rpc('log_daily_checkin', params: {
      'p_mood': mood,
      'p_notes': notes,
    });
  }

  Future<void> recalculateStreak() async {
    await _client.rpc('recalculate_streak');
  }

  Future<List<String>> getWeeklyCheckIns() async {
    final now = DateTime.now();
    // Find previous Sunday (or today if Sunday)
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
}
