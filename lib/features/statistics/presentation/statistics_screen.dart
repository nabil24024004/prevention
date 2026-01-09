import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:prevention/core/theme/app_colors.dart';
import '../../dashboard/data/dashboard_repository.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(relapseHistoryProvider);
    final checkInsAsync = ref.watch(weeklyCheckInsProvider);
    final relapsesAsync = ref.watch(weeklyRelapsesProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            24,
            24,
            140,
          ), // Restored side padding, kept bottom clearance
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Insights',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track your recovery journey',
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),

              const SizedBox(height: 32),

              // Chart Card
              Container(
                height: 300,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Activity',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Check-ins vs Relapses',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: checkInsAsync.when(
                        data: (checkIns) => relapsesAsync.when(
                          data: (relapses) => _buildChart(checkIns, relapses),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (_, __) => const SizedBox(),
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const SizedBox(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Relapse History',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              historyAsync.when(
                data: (history) {
                  if (history.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(30),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.history_toggle_off,
                            color: Colors.grey[700],
                            size: 40,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'No records yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: history.map((record) {
                      final date = DateTime.parse(
                        record['timestamp'],
                      ).toLocal();
                      return GestureDetector(
                        onTap: () => _showRelapseDetails(context, record),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat(
                                        'MMM d, yyyy • h:mm a',
                                      ).format(date),
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      record['trigger'] ??
                                          'No trigger recorded',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (record['reflection'] != null &&
                                        record['reflection']
                                            .toString()
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        '"${record['reflection']}"',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.grey[300],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text(
                  'Error: $e',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),

              const SizedBox(height: 100), // Bottom Pad
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart(List<String> checkIns, List<String> relapses) {
    // Basic logic: Last 7 days.
    // X-axis: 0 to 6 (Mon-Sun or relative to today).
    // Y-axis: 1 (Clean), 0 (Relapse), 0.5 (Neutral/Unknown).

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Start of week (Mon) to End of week (Sun) or just last 7 days?
    // Let's do last 7 days window for better "trend" feeling.

    List<FlSpot> spots = [];
    List<String> bottomTitles = [];

    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final dateStr = day.toIso8601String().split('T')[0];

      double yVal = 0.5; // No data
      if (relapses.contains(dateStr)) {
        yVal = 0; // Relapse
      } else if (checkIns.contains(dateStr)) {
        yVal = 1; // Clean
      }

      spots.add(FlSpot((6 - i).toDouble(), yVal));
      bottomTitles.add(DateFormat('E').format(day)); // Mon, Tue...
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < bottomTitles.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      bottomTitles[value.toInt()],
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  );
                }
                return const Text('');
              },
              interval: 1,
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: -0.2,
        maxY: 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                Color color = Colors.grey;
                if (spot.y == 1) color = AppColors.primary;
                if (spot.y == 0) color = AppColors.error;

                return FlDotCirclePainter(
                  radius: 4,
                  color: color,
                  strokeWidth: 2,
                  strokeColor: Colors.black,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  void _showRelapseDetails(BuildContext context, Map<String, dynamic> record) {
    final date = DateTime.parse(record['timestamp']).toLocal();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Relapse Details',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),
              _buildDetailItem(
                'Date',
                DateFormat.yMMMd().add_jm().format(date),
              ),
              const SizedBox(height: 16),
              _buildDetailItem('Trigger', record['trigger'] ?? 'Unknown'),
              const SizedBox(height: 16),
              if (record['reflection'] != null &&
                  record['reflection'].toString().isNotEmpty)
                _buildDetailItem('Reflection', record['reflection']),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ],
    );
  }
}
