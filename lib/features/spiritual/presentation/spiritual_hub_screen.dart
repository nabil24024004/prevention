import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/spiritual_repository.dart';

/// Main spiritual exercises hub screen
class SpiritualHubScreen extends ConsumerWidget {
  const SpiritualHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logAsync = ref.watch(todaysSpiritualLogProvider);
    final streakAsync = ref.watch(spiritualStreakProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Spiritual Journey',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
              const SizedBox(height: 24),

              // Today's progress card
              logAsync.when(
                loading: () => _buildLoadingCard(),
                error: (_, _) => _buildErrorCard(),
                data: (log) => _buildProgressCard(log, streakAsync),
              ),
              const SizedBox(height: 24),

              // Quran verse
              _buildInspirationalVerse(),
              const SizedBox(height: 24),

              // Quick actions grid
              const Text(
                'Spiritual Activities',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildActionsGrid(context),
              const SizedBox(height: 24),

              // Adhkar shortcuts
              const Text(
                'Daily Adhkar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildAdhkarShortcuts(context, logAsync.valueOrNull),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF4ECDC4)),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Text(
          'Unable to load progress',
          style: TextStyle(color: Colors.white54),
        ),
      ),
    );
  }

  Widget _buildProgressCard(dynamic log, AsyncValue<int> streakAsync) {
    final prayers = log?.prayersCompleted ?? 0;
    final dhikr = log?.totalDhikrCount ?? 0;
    final adhkar = log?.adhkarCompleted ?? 0;
    final streak = streakAsync.valueOrNull ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4ECDC4).withValues(alpha: 0.15),
            const Color(0xFF1A1A2E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Today's Progress",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ECDC4).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Color(0xFFFF6B6B),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$streak day streak',
                      style: const TextStyle(
                        color: Color(0xFF4ECDC4),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatItem('Prayers', '$prayers/5', Icons.mosque),
              const SizedBox(width: 8),
              _buildStatItem('Dhikr', '$dhikr', Icons.favorite),
              const SizedBox(width: 8),
              _buildStatItem('Adhkar', '$adhkar/3', Icons.menu_book),
              const SizedBox(width: 8),
              _buildStatItem(
                'Quran',
                '${log?.quranPagesRead ?? 0}p',
                Icons.auto_stories,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF4ECDC4), size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInspirationalVerse() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 24,
              color: Color(0xFF4ECDC4),
              height: 1.5,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '"Verily, in the remembrance of Allah do hearts find rest."',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '— Quran 13:28',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildActionCard(
          context,
          'Dhikr Counter',
          'سُبْحَانَ اللهِ',
          Icons.touch_app,
          const Color(0xFF4ECDC4),
          '/spiritual/dhikr',
        ),
        _buildActionCard(
          context,
          'Salah Tracker',
          'الصلاة',
          Icons.mosque,
          const Color(0xFF6BCB77),
          '/spiritual/salah',
        ),
        _buildActionCard(
          context,
          'Adhkar Reader',
          'الأذكار',
          Icons.menu_book,
          const Color(0xFFFFD93D),
          '/spiritual/adhkar',
        ),
        _buildActionCard(
          context,
          'Quran Log',
          'القرآن',
          Icons.auto_stories,
          const Color(0xFFFF6B6B),
          '/spiritual/quran',
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String arabicLabel,
    IconData icon,
    Color color,
    String route,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 28),
                  Text(
                    arabicLabel,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      color: color.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdhkarShortcuts(BuildContext context, dynamic log) {
    final morning = log?.morningAdhkarCompleted ?? false;
    final evening = log?.eveningAdhkarCompleted ?? false;
    final sleep = log?.sleepAdhkarCompleted ?? false;

    return Row(
      children: [
        _buildAdhkarChip(context, 'Morning', 'الصباح', morning, 'morning'),
        const SizedBox(width: 8),
        _buildAdhkarChip(context, 'Evening', 'المساء', evening, 'evening'),
        const SizedBox(width: 8),
        _buildAdhkarChip(context, 'Sleep', 'النوم', sleep, 'sleep'),
      ],
    );
  }

  Widget _buildAdhkarChip(
    BuildContext context,
    String label,
    String arabic,
    bool isComplete,
    String category,
  ) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/spiritual/adhkar?category=$category'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isComplete
                  ? const Color(0xFF4ECDC4).withValues(alpha: 0.15)
                  : const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isComplete
                    ? const Color(0xFF4ECDC4)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              children: [
                if (isComplete)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF4ECDC4),
                    size: 20,
                  )
                else
                  Text(
                    arabic,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isComplete
                        ? const Color(0xFF4ECDC4)
                        : Colors.white70,
                    fontSize: 13,
                    fontWeight: isComplete
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
