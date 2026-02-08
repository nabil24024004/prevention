import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';
import 'package:prevention/core/theme/app_colors.dart';
import '../../auth/data/user_repository.dart';
import '../../auth/data/user_model.dart';
import '../data/dashboard_repository.dart';
import '../../blocking/data/blocker_repository.dart';
import 'widgets/weekly_streak_widget.dart';
import 'widgets/streak_timer_widget.dart';
import '../../progress/presentation/progress_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isBlockerActive = false;
  bool _isOffline = false;

  // Dashboard motivation
  late String _dailyQuote;
  final List<String> _dashboardQuotes = [
    "Indeed, the soul constantly commands toward evil—except those shown mercy by Allah. (Quran 12:53)",
    "The soul and the One who fashioned it, and inspired it with wickedness and righteousness. (Quran 91:7,8)",
    "Successful is the one who purifies the soul. (Quran 91:9)",
    "Ruined is the one who corrupts the soul. (Quran 91:10)",
    "Do not follow desire, for it will mislead you from the path of Allah. (Quran 38:26)",
    "Have you seen the one who takes his desire as his god? (Quran 45:23)",
    "The human soul is ever inclined to impatience. (Quran 70:19)",
    "Man is truly ungrateful to his Lord. (Quran 100:6)",
    "Man transgresses when he sees himself self-sufficient. (Quran 96:6,7)",
    "Do not claim yourselves pure; Allah knows best who is righteous. (Quran 53:32)",
    "Indeed, man was created weak. (Quran 4:28)",
    "Every soul will be questioned for what it earned. (Quran 74:38)",
    "Worldly life is nothing but enjoyment of delusion. (Quran 3:185)",
    "Your wealth and children are only a test. (Quran 64:15)",
    "Many follow nothing but assumptions and desires. (Quran 6:116)",
    "The self urges toward miserliness. (Quran 4:128)",
    "Whoever restrains his soul from desire will find Paradise. (Quran 79:40,41)",
    "Man prays for evil as he prays for good; man is ever hasty. (Quran 17:11)",
    "The soul whispers softly, then commands loudly. (Reflective)",
    "Desire promises pleasure but delivers regret. (Reflective)",
    "Every unchecked habit strengthens the ego. (Reflective)",
    "Discipline starves the nafs; indulgence feeds it. (Reflective)",
    "The nafs hates patience because patience breaks its power. (Reflective)",
    "What the nafs wants quickly, the soul pays for slowly. (Reflective)",
    "The nafs disguises sins as small and harmless. (Reflective)",
    "Comfort is the favorite weapon of the ego. (Reflective)",
    "The nafs fears silence because silence exposes it. (Reflective)",
    "Every temptation is a test of obedience. (Reflective)",
    "The nafs loves excuses more than repentance. (Reflective)",
    "Victory over the nafs is the greatest inner struggle. (Hadith meaning)",
    "The nafs grows loud when remembrance fades. (Reflective)",
    "A disciplined soul finds freedom; a spoiled soul finds chains. (Reflective)",
    "The nafs bows only when humbled by truth. (Reflective)",
    "Your strongest enemy is the soul within you. (Hadith meaning)",
    "True strength is control over the self. (Hadith meaning)",
    "The wise restrain their souls and prepare for the hereafter. (Hadith meaning)",
    "Following desire while hoping for mercy is self-deception. (Hadith meaning)",
    "Paradise is surrounded by hardship; Hell by desire. (Hadith meaning)",
    "Unchecked desire blinds the heart. (Hadith meaning)",
    "Self-accountability today prevents regret tomorrow. (Hadith meaning)",
    "The soul grows arrogant when left unchallenged. (Reflective)",
    "Silence and restraint are shields against the ego. (Hadith meaning)",
    "Whoever humbles himself is raised in rank. (Hadith meaning)",
    "Excess comfort hardens the heart. (Hadith meaning)",
    "When the heart is corrupt, actions follow. (Hadith meaning)",
    "Discipline the soul before it disciplines you. (Reflective)",
    "The ego loves praise and hates correction. (Reflective)",
    "Remembering Allah weakens the nafs. (Reflective)",
    "Purifying the soul is the path to peace. ( 91:9)",
  ];

  @override
  void initState() {
    super.initState();
    _checkBlockerStatus();
    _checkConnectivity();
    _dailyQuote = _dashboardQuotes[Random().nextInt(_dashboardQuotes.length)];
    // Ensure streak is accurate on load
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(dashboardRepositoryProvider).recalculateStreak();
      // Force refresh profile to sync start_date and other fields
      await ref.read(userRepositoryProvider).refreshProfile();
      // Restart the stream to pick up the updated cache
      if (mounted) {
        ref.invalidate(userProfileStreamProvider);
      }
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      await ref.read(dashboardRepositoryProvider).hasCheckedInToday();
      if (mounted) setState(() => _isOffline = false);
    } catch (_) {
      if (mounted) setState(() => _isOffline = true);
    }
  }

  Future<void> _checkBlockerStatus() async {
    final status = await ref.read(blockerRepositoryProvider).isVpnActive();
    if (mounted) setState(() => _isBlockerActive = status);
  }

  Future<void> _toggleBlocker() async {
    try {
      if (_isBlockerActive) {
        await ref.read(blockerRepositoryProvider).stopBlocking();
      } else {
        // Request notification permission for Android 13+
        final status = await Permission.notification.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Notification permission is required to run the blocker.',
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }

        await ref.read(blockerRepositoryProvider).startBlocking();
      }
      // Give Android time to start/stop the VPN service
      await Future.delayed(const Duration(milliseconds: 500));
      await _checkBlockerStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isBlockerActive
                  ? 'Browser Protection Enabled'
                  : 'Browser Protection Disabled',
            ),
            backgroundColor: _isBlockerActive ? Colors.green : Colors.grey,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileStreamProvider);

    return Scaffold(
      backgroundColor: Colors.black, // Dark background
      body: userProfileAsync.when(
        data: (profile) => Stack(
          children: [
            _buildDashboard(context, profile),
            if (_isOffline)
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Offline Mode - Showing cached data',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: -1, end: 0),
              ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 48, color: Colors.grey[600]),
              const SizedBox(height: 16),
              Text('Offline', style: TextStyle(color: Colors.grey[400], fontSize: 18)),
              const SizedBox(height: 8),
              Text('Connect to internet to sync data', 
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, UserProfile profile) {
    return Stack(
      children: [
        // 1. Ambient Background Gradient
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.15),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 100,
                  spreadRadius: 50,
                ),
              ],
            ),
          ),
        ),

        SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userProfileStreamProvider);
              ref.invalidate(weeklyCheckInsProvider);
              ref.invalidate(weeklyRelapsesProvider);
              await Future.wait([
                ref.read(weeklyCheckInsProvider.future),
                ref.read(weeklyRelapsesProvider.future),
                ref.read(progressDataProvider.future),
              ]);
              await _checkBlockerStatus();
            },
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Protection Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assalamualaikum,',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            profile.username ?? 'Brother',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Protection Status Badge
                          GestureDetector(
                            onTap: _toggleBlocker,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _isBlockerActive
                                    ? const Color(0xFF1B5E20) // Dark Green
                                    : const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _isBlockerActive
                                      ? Colors.greenAccent.withOpacity(0.5)
                                      : Colors.white12,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _isBlockerActive
                                        ? Icons.security
                                        : Icons.gpp_bad_outlined,
                                    color: _isBlockerActive
                                        ? Colors.white
                                        : Colors.redAccent,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isBlockerActive ? 'Protected' : 'Unsafe',
                                    style: TextStyle(
                                      color: _isBlockerActive
                                          ? Colors.white
                                          : Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(
                              Icons.settings_outlined,
                              color: Colors.white,
                            ),
                            onPressed: () => context.push('/settings'),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Weekly Streak Tracker (Compact)
                  Consumer(
                    builder: (context, ref, _) {
                      final checkInsAsync = ref.watch(weeklyCheckInsProvider);
                      final relapsesAsync = ref.watch(weeklyRelapsesProvider);
                      return checkInsAsync.when(
                        data: (dates) => relapsesAsync.when(
                          data: (relapses) => WeeklyStreakWidget(
                            completedDates: dates,
                            relapseDates: relapses,
                          ),
                          loading: () =>
                              WeeklyStreakWidget(completedDates: dates),
                          error: (_, __) =>
                              WeeklyStreakWidget(completedDates: dates),
                        ),
                        loading: () => const SizedBox(height: 60),
                        error: (err, _) => const SizedBox.shrink(),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Hero Streak Section (Compacted)
                  Center(
                    child: GestureDetector(
                      onTap: () => context.push('/progress'),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer Glow
                          Container(
                                width: 180, // Reduced from 220
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(
                                        0.15,
                                      ),
                                      blurRadius: 40,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                              )
                              .animate(
                                onPlay: (controller) =>
                                    controller.repeat(reverse: true),
                              )
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.05, 1.05),
                                duration: 2.seconds,
                              ),

                          // Ring
                          Container(
                            width: 160, // Reduced from 200
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                                width: 2,
                              ),
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withOpacity(0.1),
                                  Colors.transparent,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),

                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${profile.currentStreakDays}',
                                style: GoogleFonts.outfit(
                                  fontSize: 60, // Reduced from 72
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                              const Text(
                                'DAYS FREE',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  letterSpacing: 3,
                                  fontSize: 10, // Reduced from 12
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // Live Timer
                              StreakTimerWidget(
                                startDate: profile.startDate,
                                isPaused: profile.currentStreakDays == 0,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Action Grid: Panic Button + Daily Motivation side-by-side?
                  // No, Panic Button usually needs full width for urgency.
                  // But we can compact the layout.

                  // Panic Button
                  _buildPanicButton(context),

                  const SizedBox(height: 20),

                  // Motivation Card (Compacted)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2A2A2A), Color(0xFF1F1F1F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.format_quote_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _dailyQuote,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ).animate().slideY(begin: 0.1, end: 0, duration: 500.ms),

                  const SizedBox(height: 20), // Bottom padding for NavBar + FAB
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPanicButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.error, Color(0xFFD32F2F)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/panic-mode'),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'PANIC MODE',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().shimmer(delay: 5.seconds, duration: 1.seconds);
  }
}
