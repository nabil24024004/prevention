import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:prevention/core/theme/app_colors.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../auth/data/user_repository.dart';
import '../../progress/presentation/progress_screen.dart';

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  bool _isCheckingIn = false;
  bool _alreadyCheckedIn = false;
  bool _hasRelapsedToday = false;

  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      // Check for internet by trying to fetch data
      final checkedIn = await ref.read(dashboardRepositoryProvider).hasCheckedInToday();
      final relapsed = await ref.read(dashboardRepositoryProvider).hasRelapsedToday();
      
      if (mounted) {
        setState(() {
          _alreadyCheckedIn = checkedIn;
          _hasRelapsedToday = relapsed;
          _isOffline = false;
        });
      }
    } catch (e) {
      // If fetch fails, assume offline
      if (mounted) {
        setState(() {
          _isOffline = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isOffline) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(
                  'Offline Mode',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check-in is unavailable while offline.\nPlease connect to the internet to record your progress.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _checkStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    'Retry Connection',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Sophisticated Ambient Background
          _buildAmbientBackground(),
          
          // 2. Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  
                  // Label
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      'DAILY ACCOUNTABILITY',
                      style: GoogleFonts.outfit(
                        color: AppColors.primary,
                        fontSize: 14, // Bumped from 12
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ).animate().fadeIn().slideY(begin: -0.5),
                  
                  const Spacer(),
                  
                  // Main Question
                  Text(
                    'Did you stay\nclean today?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1,
                    ),
                  ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.9, 0.9)),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'Your honesty builds your strength.',
                    style: GoogleFonts.outfit(
                      color: AppColors.textSecondary, // Changed from grey[500]
                      fontSize: 16,
                      fontWeight: FontWeight.w500, // Bumped from w400
                    ),
                  ).animate().fadeIn(delay: 300.ms),

                  const Spacer(flex: 2),

                  // YES Button (The Primary Action)
                  _buildYesButton(),

                  const SizedBox(height: 16),

                  // NO Button (Subtle & Supportive)
                  _buildNoButton(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          
          // Loading Overlay
          if (_isCheckingIn)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ).animate().fadeIn(),
        ],
      ),
    );
  }

  Widget _buildAmbientBackground() {
    return Stack(
      children: [
        // Dark Base Gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0A0A0A), Colors.black],
            ),
          ),
        ),
        // Top Left Blob
        Positioned(
          top: -150,
          left: -50,
          child: _AmbientBlob(color: AppColors.primary.withOpacity(0.12), radius: 250),
        ),
        // Center Bottom Blob
        Positioned(
          bottom: -200,
          right: -50,
          child: _AmbientBlob(color: AppColors.secondary.withOpacity(0.1), radius: 350),
        ),
        // Dynamic Noise Texture (Optional - if you had a noise asset, but we'll use a subtle opacity overlay)
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
          child: Container(color: Colors.transparent),
        ),
      ],
    );
  }

  Widget _buildYesButton() {
    // Determine if button should be disabled
    final isDisabled = _alreadyCheckedIn || _hasRelapsedToday;
    
    return Opacity(
      opacity: isDisabled ? 0.4 : 1.0,
      child: Container(
        width: double.infinity,
        height: 84,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: isDisabled 
              ? [Colors.grey.shade700, Colors.grey.shade800]
              : [AppColors.secondary, const Color(0xFF1B5E20)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: isDisabled ? [] : [
            BoxShadow(
              color: AppColors.secondary.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 10),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: isDisabled ? null : _handleCheckIn,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDisabled ? Icons.lock_outline : Icons.check_rounded, 
                    color: Colors.white, 
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDisabled 
                        ? (_hasRelapsedToday ? 'Relapsed Today' : 'Already Checked In')
                        : 'Yes, Alhamdulillah',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (isDisabled)
                      Text(
                        'Come back tomorrow',
                        style: GoogleFonts.outfit(
                          fontSize: 14, // Bumped from 12
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(onPlay: isDisabled ? null : (controller) => controller.repeat(reverse: true))
     .shimmer(duration: 3.seconds, delay: 2.seconds, color: Colors.white10);
  }

  Widget _buildNoButton() {
    // Disable if already checked in OR already relapsed today
    final isDisabled = _alreadyCheckedIn || _hasRelapsedToday;
    
    String buttonText = 'No, I failed again..;(';
    if (_alreadyCheckedIn) {
      buttonText = 'Already checked in';
    } else if (_hasRelapsedToday) {
      buttonText = 'Already relapsed';
    }
    
    return Opacity(
      opacity: isDisabled ? 0.4 : 1.0,
      child: TextButton(
        onPressed: isDisabled ? null : () => context.push('/relapse'),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          foregroundColor: isDisabled ? Colors.grey : Colors.white54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDisabled ? Colors.grey.withOpacity(0.2) : Colors.white.withOpacity(0.05), 
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDisabled ? Icons.lock_outline : Icons.close_rounded, 
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              buttonText,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Future<void> _handleCheckIn() async {
    setState(() => _isCheckingIn = true);
    try {
      // Check if user has relapsed today
      final hasRelapsed = await ref.read(dashboardRepositoryProvider).hasRelapsedToday();
      if (hasRelapsed) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('You cannot check in after a relapse. Stay strong and try again tomorrow!'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height - 150,
                left: 10,
                right: 10,
              ),
            ),
          );
        }
        return;
      }

      // Check if already checked in today
      final alreadyCheckedIn = await ref.read(dashboardRepositoryProvider).hasCheckedInToday();
      if (alreadyCheckedIn) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('You have already checked in today!'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height - 150,
                left: 10,
                right: 10,
              ),
            ),
          );
        }
        return;
      }

      await ref.read(dashboardRepositoryProvider).logDailyCheckIn(mood: 'strong');
      
      // Sync all progress related data
      ref.invalidate(userProfileStreamProvider);
      ref.invalidate(weeklyCheckInsProvider);
      ref.invalidate(weeklyRelapsesProvider);
      ref.invalidate(progressDataProvider);
      
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingIn = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E).withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
            side: const BorderSide(color: Colors.white10),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              // Glowing Checkmark
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withOpacity(0.1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.3),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.done_all_rounded, color: AppColors.secondary, size: 64),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              
              const SizedBox(height: 32),
              
              Text(
                'MashaAllah!',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 12),
              
              const Text(
                'Your discipline is an inspiration.\nKeep moving forward.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.go('/dashboard');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue Journey',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmbientBlob extends StatelessWidget {
  final Color color;
  final double radius;

  const _AmbientBlob({required this.color, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
