import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

// Provider for fetching progress data
final progressDataProvider = FutureProvider<Map<DateTime, String>>((ref) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return {};

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

  final Map<DateTime, String> events = {};
  
  // Mark check-in days as 'success'
  for (final log in logs) {
    final date = DateTime.parse(log['date']);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    events[normalizedDate] = 'success';
  }

  // Mark relapse days as 'relapse' (override check-ins)
  for (final relapse in relapses) {
    final date = DateTime.parse(relapse['timestamp']);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    events[normalizedDate] = 'relapse';
  }

  return events;
});

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final progressAsync = ref.watch(progressDataProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Progress', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: progressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Error: $err', style: TextStyle(color: AppColors.error))),
        data: (events) => Column(
          children: [
            // Calendar
            TableCalendar(
              firstDay: DateTime.utc(2024, 1, 1),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle: TextStyle(color: AppColors.textPrimary),
                weekendTextStyle: TextStyle(color: AppColors.textSecondary),
                todayDecoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                selectedDecoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                titleTextStyle: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 18),
                formatButtonTextStyle: TextStyle(color: AppColors.primary),
                formatButtonDecoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(12),
                ),
                leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.textPrimary),
                rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.textPrimary),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: AppColors.textSecondary),
                weekendStyle: TextStyle(color: AppColors.textSecondary),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, _) {
                  final normalizedDate = DateTime(date.year, date.month, date.day);
                  final event = events[normalizedDate];
                  if (event == null) return null;
                  
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: event == 'success' ? Colors.green : AppColors.error,
                      ),
                    ),
                  );
                },
              ),
            ),
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
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
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
          Container(width: 1, height: 40, color: AppColors.textSecondary.withOpacity(0.3)),
          _buildStatItem('$relapseDays', 'Relapses', AppColors.error),
          Container(width: 1, height: 40, color: AppColors.textSecondary.withOpacity(0.3)),
          _buildStatItem(
            relapseDays > 0 ? '${(successDays / (successDays + relapseDays) * 100).toStringAsFixed(0)}%' : '100%',
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
        Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
