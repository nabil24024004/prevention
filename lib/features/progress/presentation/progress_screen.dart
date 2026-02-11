import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/calendar_widget.dart';

// Provider for fetching progress data
final progressDataProvider = FutureProvider<Map<DateTime, String>>((ref) async {
  const cacheKey = 'cached_progress_events';
  final prefs = await SharedPreferences.getInstance();
  final client = Supabase.instance.client;
  
  Map<DateTime, String> parseEvents(List<dynamic> logs, List<dynamic> relapses) {
    final Map<DateTime, String> events = {};
    for (final log in logs) {
      final date = DateTime.parse(log['date']);
      final normalizedDate = DateTime(date.year, date.month, date.day);
      events[normalizedDate] = 'success';
    }
    for (final relapse in relapses) {
      final date = DateTime.parse(relapse['timestamp']);
      final normalizedDate = DateTime(date.year, date.month, date.day);
      events[normalizedDate] = 'relapse';
    }
    return events;
  }

  // Helper to load from cache
  Map<DateTime, String>? loadFromCache() {
    final cachedStr = prefs.getString(cacheKey);
    if (cachedStr != null) {
      try {
        final cached = jsonDecode(cachedStr) as Map<String, dynamic>;
        final logs = cached['logs'] as List;
        final relapses = cached['relapses'] as List;
        return parseEvents(logs, relapses);
      } catch (_) {}
    }
    return null;
  }

  // Try to fetch fresh data
  try {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      return loadFromCache() ?? {};
    }

    // Fetch daily logs
    final logs = await client
        .from('daily_log')
        .select('date, mood')
        .eq('user_id', userId)
        .order('date');

    // Fetch relapses
    final relapses = await client
        .from('relapses')
        .select('timestamp')
        .eq('user_id', userId);

    // Cache the raw data
    await prefs.setString(cacheKey, jsonEncode({
      'logs': logs,
      'relapses': relapses,
    }));

    return parseEvents(logs, relapses);
  } catch (e) {
    // On error (offline), fall back to cache
    return loadFromCache() ?? {};
  }
});

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  @override
  Widget build(BuildContext context) {
    final progressAsync = ref.watch(progressDataProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Progress',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: progressAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 48, color: Colors.grey[600]),
              const SizedBox(height: 16),
              Text('Offline', style: TextStyle(color: Colors.grey[400], fontSize: 18)),
            ],
          ),
        ),
        data: (events) => Column(
          children: [
            // Calendar
            const CalendarWidget(),
            const SizedBox(height: 24),

            // Legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(Colors.green, 'Clean Day'),
                  const SizedBox(width: 24),
                  _buildLegendItem(AppColors.error, 'Relapse'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Stats
            _buildStatsCard(events),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildStatsCard(Map<DateTime, String> events) {
    final successDays = events.values.where((v) => v == 'success').length;
    final relapseDays = events.values.where((v) => v == 'relapse').length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('$successDays', 'Clean Days', Colors.green),
          Container(
            width: 1,
            height: 40,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          _buildStatItem('$relapseDays', 'Relapses', AppColors.error),
          Container(
            width: 1,
            height: 40,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          _buildStatItem(
            relapseDays > 0
                ? '${(successDays / (successDays + relapseDays) * 100).toStringAsFixed(0)}%'
                : '100%',
            'Success Rate',
            AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
