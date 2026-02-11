import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/spiritual_repository.dart';

/// Compact widget for dashboard showing today's spiritual progress
class SpiritualWidget extends ConsumerWidget {
  const SpiritualWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logAsync = ref.watch(todaysSpiritualLogProvider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/spiritual'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1A1A2E),
                const Color(0xFF4ECDC4).withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF4ECDC4).withValues(alpha: 0.2),
            ),
          ),
          child: logAsync.when(
            loading: () => _buildLoadingState(),
            error: (_, _) => _buildErrorState(),
            data: (log) => _buildContent(log),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          color: Color(0xFF4ECDC4),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Row(
      children: [
        Icon(
          Icons.mosque,
          color: Colors.white.withValues(alpha: 0.3),
          size: 32,
        ),
        const SizedBox(width: 12),
        const Text('Tap to start', style: TextStyle(color: Colors.white54)),
      ],
    );
  }

  Widget _buildContent(dynamic log) {
    final prayers = log?.prayersCompleted ?? 0;
    final dhikr = log?.totalDhikrCount ?? 0;
    final adhkar = log?.adhkarCompleted ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4ECDC4).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.mosque,
                color: Color(0xFF4ECDC4),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'Spiritual Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white24,
              size: 14,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Stats row
        Row(
          children: [
            _buildMiniStat('Prayers', '$prayers/5', prayers == 5),
            const SizedBox(width: 8),
            _buildMiniStat('Dhikr', '$dhikr', dhikr >= 100),
            const SizedBox(width: 8),
            _buildMiniStat('Adhkar', '$adhkar/3', adhkar == 3),
          ],
        ),

        // Progress bar
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _calculateProgress(prayers, dhikr, adhkar),
            minHeight: 4,
            backgroundColor: const Color(0xFF2D2D44),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF4ECDC4)),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, bool isComplete) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isComplete
              ? const Color(0xFF4ECDC4).withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: isComplete ? const Color(0xFF4ECDC4) : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateProgress(int prayers, int dhikr, int adhkar) {
    // Weight: prayers (40%), dhikr target of 100 (30%), adhkar (30%)
    final prayerProgress = (prayers / 5) * 0.4;
    final dhikrProgress = (dhikr.clamp(0, 100) / 100) * 0.3;
    final adhkarProgress = (adhkar / 3) * 0.3;
    return (prayerProgress + dhikrProgress + adhkarProgress).clamp(0.0, 1.0);
  }
}
