import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';

class WeeklyStreakWidget extends StatelessWidget {
  final List<String> completedDates;
  final List<String> relapseDates;

  const WeeklyStreakWidget({
    super.key,
    required this.completedDates,
    this.relapseDates = const [],
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Start of week (Sunday)
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));

    // Generate week days
    final weekDays = List.generate(
      7,
      (index) => startOfWeek.add(Duration(days: index)),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Progress',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${completedDates.length}/7 Days',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weekDays.map((date) {
              final dateStr = date.toIso8601String().split('T')[0];
              final isCompleted = completedDates.contains(dateStr);
              final isRelapse = relapseDates.contains(dateStr);
              final isToday =
                  date.day == now.day &&
                  date.month == now.month &&
                  date.year == now.year;
              final isFuture =
                  date.isAfter(now) && !isToday; // Ensure today is not future
              final dayName = DateFormat('E').format(date)[0]; // S, M, T...

              return Column(
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      color: isToday ? Colors.white : Colors.white38,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDayIndicator(isCompleted, isRelapse, isToday, isFuture),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().slideY(
      begin: -0.2,
      end: 0,
      duration: 600.ms,
      curve: Curves.easeOutBack,
    );
  }

  Widget _buildDayIndicator(
    bool isCompleted,
    bool isRelapse,
    bool isToday,
    bool isFuture,
  ) {
    if (isRelapse) {
      return Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: AppColors.error, // Red for relapse
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x66FF5252),
              blurRadius: 8,
              spreadRadius: 1,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.close, color: Colors.white, size: 20),
      ).animate().shake(duration: 400.ms); // Shake animation for negative event
    } else if (isCompleted) {
      return Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent,
              blurRadius: 8,
              spreadRadius: 1,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 20),
      ).animate().scale(duration: 400.ms, curve: Curves.elasticOut);
    } else if (isToday) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.blue.withOpacity(0.5), width: 1.5),
        ),
      );
    } else {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
      );
    }
  }
}
