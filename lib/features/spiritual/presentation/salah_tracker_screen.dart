import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/spiritual_repository.dart';
import '../data/models/spiritual_log.dart';

/// Prayer (Salah) tracking screen
class SalahTrackerScreen extends ConsumerStatefulWidget {
  const SalahTrackerScreen({super.key});

  @override
  ConsumerState<SalahTrackerScreen> createState() => _SalahTrackerScreenState();
}

class _SalahTrackerScreenState extends ConsumerState<SalahTrackerScreen> {
  Map<Prayer, bool> _prayerStatus = {
    Prayer.fajr: false,
    Prayer.dhuhr: false,
    Prayer.asr: false,
    Prayer.maghrib: false,
    Prayer.isha: false,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final log = await ref.read(todaysSpiritualLogProvider.future);
    if (log != null && mounted) {
      setState(() {
        _prayerStatus = {
          Prayer.fajr: log.fajrPrayed,
          Prayer.dhuhr: log.dhuhrPrayed,
          Prayer.asr: log.asrPrayed,
          Prayer.maghrib: log.maghribPrayed,
          Prayer.isha: log.ishaPrayed,
        };
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePrayer(Prayer prayer) async {
    if (_prayerStatus[prayer] == true) return; // Can't uncheck

    setState(() => _prayerStatus[prayer] = true);

    try {
      await ref.read(spiritualRepositoryProvider).markPrayerDone(prayer);
      ref.invalidate(todaysSpiritualLogProvider);
    } catch (e) {
      setState(() => _prayerStatus[prayer] = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _prayerStatus.values.where((v) => v).length;
    final progress = completedCount / 5;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Salah Tracker'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4ECDC4)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Progress header
                  _buildProgressCard(completedCount, progress),
                  const SizedBox(height: 24),

                  // Quran verse
                  _buildQuranVerse(),
                  const SizedBox(height: 24),

                  // Prayer list
                  ...Prayer.values.map((prayer) => _buildPrayerTile(prayer)),
                ],
              ),
            ),
    );
  }

  Widget _buildProgressCard(int completed, double progress) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4ECDC4).withValues(alpha: 0.2),
            const Color(0xFF1A1A2E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4ECDC4).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: const Color(0xFF2D2D44),
                      valueColor: AlwaysStoppedAnimation(
                        completed == 5 ? Colors.green : const Color(0xFF4ECDC4),
                      ),
                    ),
                  ),
                  Text(
                    '$completed/5',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    completed == 5 ? 'All prayers complete!' : 'Keep going!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    completed == 5
                        ? 'MashaAllah, amazing!'
                        : '${5 - completed} prayer${5 - completed == 1 ? '' : 's'} remaining',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuranVerse() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَّوْقُوتًا',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 22,
              color: Color(0xFF4ECDC4),
              height: 1.6,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '"Indeed, prayer has been decreed upon the believers at specified times."',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '— Quran 4:103',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTile(Prayer prayer) {
    final isDone = _prayerStatus[prayer] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDone ? null : () => _togglePrayer(prayer),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDone
                    ? const Color(0xFF4ECDC4).withValues(alpha: 0.5)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                // Circle checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? const Color(0xFF4ECDC4)
                        : const Color(0xFF2D2D44),
                    border: Border.all(
                      color: isDone ? const Color(0xFF4ECDC4) : Colors.white24,
                      width: 2,
                    ),
                  ),
                  child: isDone
                      ? const Icon(Icons.check, color: Colors.black, size: 18)
                      : null,
                ),
                const SizedBox(width: 16),

                // Prayer info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prayer.displayName,
                        style: TextStyle(
                          color: isDone ? Colors.white : Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      Text(
                        prayer.arabicName,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          color: isDone
                              ? const Color(0xFF4ECDC4).withValues(alpha: 0.7)
                              : Colors.white38,
                          fontSize: 14,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),

                // Status
                if (isDone)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ECDC4).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Prayed ✓',
                      style: TextStyle(
                        color: Color(0xFF4ECDC4),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
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
