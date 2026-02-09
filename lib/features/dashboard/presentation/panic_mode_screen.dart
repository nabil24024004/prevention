import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../blocking/data/blocker_repository.dart';
import '../../auth/data/user_repository.dart';

class PanicModeScreen extends ConsumerStatefulWidget {
  const PanicModeScreen({super.key});

  @override
  ConsumerState<PanicModeScreen> createState() => _PanicModeScreenState();
}

class _PanicModeScreenState extends ConsumerState<PanicModeScreen> {
  // Same list as notifications, maybe move to a shared constants file later
  final List<String> _duas = [
    "O Allah, I seek refuge in You from anxiety and sorrow, weakness and laziness. (Bukhari)",
    "Do not follow your desires, for they will lead you astray from the path of Allah. (Quran 38:26)",
    "Verily, in the remembrance of Allah do hearts find rest. (Quran 13:28)",
    "And whoever stops himself from his desires, Paradise will be his home. (Quran 79:40-41)",
    "Seek help through patience and prayer. (Quran 2:45)",
    "Shaytan only wants to cause animosity and hatred between you. (Quran 5:91)",
    "Repel evil with that which is better. (Quran 41:34)",
    "O Turner of hearts, firm my heart upon Your religion.",
    "This moment is a test. Passes it with patience.",
    "Regret is heavier than the struggle of discipline.",
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

  // Dua carousel
  late PageController _duaPageController;
  int _duaPageIndex = 0;

  // Timer related variables
  int _secondsRemaining = 240; // 4 minutes default
  Timer? _timer;
  bool _canExit = false;

  /// Duration for new panic sessions
  static const int _panicDurationSeconds = 240; // 4 minutes

  @override
  void initState() {
    super.initState();
    // Start at a random dua
    _duaPageIndex = Random().nextInt(_duas.length);
    _duaPageController = PageController(initialPage: _duaPageIndex);
    _initPanicSession();
    _enableProtection();
  }

  Future<void> _initPanicSession() async {
    final blockerRepo = ref.read(blockerRepositoryProvider);

    // Check if we have persisted panic state (app was killed and restarted)
    final persistedSeconds = await blockerRepo.getPanicSecondsRemaining();

    if (persistedSeconds > 0) {
      // Resume existing session
      setState(() {
        _secondsRemaining = persistedSeconds;
      });
    } else {
      // Start new panic session - save to SharedPreferences
      await blockerRepo.setPanicModeActive(_panicDurationSeconds);
      setState(() {
        _secondsRemaining = _panicDurationSeconds;
      });
    }

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_secondsRemaining > 0) {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
        }
      } else {
        _timer?.cancel();
        // Clear panic mode state
        await ref.read(blockerRepositoryProvider).clearPanicMode();
        if (mounted) {
          setState(() {
            _canExit = true;
          });
        }
      }
    });
  }

  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _enableProtection() async {
    // Auto-enable browser protection
    try {
      await ref.read(blockerRepositoryProvider).startBlocking();
    } catch (e) {
      debugPrint('Failed to auto-enable protection: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _duaPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileStreamProvider);

    return PopScope(
      canPop: _canExit, // Prevent back button until timer ends
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please wait until the panic timer ends.'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Background Red Gradient Pulse
            Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          AppColors.error.withOpacity(0.2),
                          Colors.black,
                        ],
                        radius: 1.5,
                        center: Alignment.center,
                      ),
                    ),
                  ),
                )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: 2.seconds,
                ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Timer Display
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        _formatTime(_secondsRemaining),
                        style: GoogleFonts.robotoMono(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ).animate().fadeIn().scale(),

                    const SizedBox(height: 32),

                    Text(
                      "EMERGENCY PROTECTION ACTIVE",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: AppColors.error,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ).animate().fadeIn().slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 24),

                    // Motivational Stats Section
                    userProfileAsync.when(
                      data: (profile) => Column(
                        children: [
                          Text(
                            "Don't break your streak of",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${profile.currentStreakDays} DAYS",
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "One moment of weakness isn't worth losing this progress.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 300.ms),
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const SizedBox(),
                    ),

                    const SizedBox(height: 32),

                    Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  20,
                                  24,
                                  8,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.format_quote_rounded,
                                      color: AppColors.secondary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Swipe for reflection",
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 110,
                                child: PageView.builder(
                                  controller: _duaPageController,
                                  itemCount: _duas.length,
                                  onPageChanged: (index) {
                                    setState(() => _duaPageIndex = index);
                                  },
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                      ),
                                      child: Center(
                                        child: Text(
                                          _duas[index],
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              // Page indicators
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 16,
                                  top: 8,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    _duas.length > 10 ? 10 : _duas.length,
                                    (index) {
                                      final realIndex = _duaPageIndex < 5
                                          ? index
                                          : (_duaPageIndex > _duas.length - 6
                                                ? _duas.length - 10 + index
                                                : _duaPageIndex - 5 + index);
                                      return AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 3,
                                        ),
                                        width: _duaPageIndex == realIndex
                                            ? 16
                                            : 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                          color: _duaPageIndex == realIndex
                                              ? AppColors.secondary
                                              : Colors.white24,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 600.ms)
                        .slideY(begin: 0.1, end: 0),

                    const Spacer(),

                    // Future Warning
                    if (!_canExit)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child:
                            Text(
                                  "Wait for the storm to pass...",
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                                .animate(onPlay: (c) => c.repeat())
                                .shimmer(duration: 2.seconds),
                      ),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _canExit
                              ? Colors.white
                              : Colors.grey[800],
                          foregroundColor: _canExit
                              ? Colors.black
                              : Colors.white38,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _canExit ? () => context.pop() : null,
                        child: Text(
                          _canExit
                              ? "I AM CALM NOW"
                              : "LOCKED (${_formatTime(_secondsRemaining)})",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
