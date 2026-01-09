import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';
import '../../../core/theme/app_colors.dart';
import '../../blocking/data/blocker_repository.dart';

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
    "Regret is heavier than the struggle of discipline."
  ];

  late String _currentDua;

  @override
  void initState() {
    super.initState();
    _currentDua = _duas[Random().nextInt(_duas.length)];
    _enableProtection();
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
  Widget build(BuildContext context) {
    return Scaffold(
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
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2.seconds),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.shield, size: 80, color: AppColors.error)
                       .animate().shake(duration: 500.ms),
                   
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

                   const SizedBox(height: 16),
                   
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                     decoration: BoxDecoration(
                       color: AppColors.secondary.withOpacity(0.2),
                       borderRadius: BorderRadius.circular(20),
                       border: Border.all(color: AppColors.secondary.withOpacity(0.5)),
                     ),
                     child: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         const Icon(Icons.check_circle, color: AppColors.secondary, size: 16),
                         const SizedBox(width: 8),
                         Text(
                           "Browser Protection Enabled",
                           style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
                         ),
                       ],
                     ),
                   ).animate().fadeIn(delay: 300.ms),

                   const SizedBox(height: 48),

                   Container(
                     padding: const EdgeInsets.all(24),
                     decoration: BoxDecoration(
                       color: const Color(0xFF1A1A1A),
                       borderRadius: BorderRadius.circular(16),
                       border: Border.all(color: Colors.white10),
                     ),
                     child: Column(
                       children: [
                         Text(
                           "Read this out loud:",
                           style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                         ),
                         const SizedBox(height: 16),
                         Text(
                           _currentDua,
                           textAlign: TextAlign.center,
                           style: GoogleFonts.outfit(
                             color: Colors.white,
                             fontSize: 24,
                             fontWeight: FontWeight.w500,
                             height: 1.4,
                           ),
                         ),
                       ],
                     ),
                   ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),

                   const Spacer(),

                   SizedBox(
                     width: double.infinity,
                     height: 56,
                     child: ElevatedButton(
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.white,
                         foregroundColor: Colors.black,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                       ),
                       onPressed: () => context.pop(),
                       child: Text(
                         "I AM CALM NOW",
                         style: GoogleFonts.outfit(
                           fontWeight: FontWeight.bold,
                           fontSize: 16,
                           letterSpacing: 1,
                         ),
                       ),
                     ),
                   ).animate().fadeIn(delay: 2.seconds),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
