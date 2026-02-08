import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'features/auth/data/user_repository.dart';
import 'features/blocking/data/blocker_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.scheduleDailyNotifications();

  final prefs = await SharedPreferences.getInstance();
  final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

  // Check if panic mode is still active from previous session
  int panicSecondsRemaining = 0;
  bool isPanicActive = false;
  try {
    final blockerRepository = BlockerRepository();
    panicSecondsRemaining = await blockerRepository.getPanicSecondsRemaining();
    isPanicActive = panicSecondsRemaining > 0;
  } catch (e) {
    debugPrint('Error checking panic mode: $e');
    // Default to no panic mode if check fails
  }

  runApp(
    ProviderScope(
      child: PreventionApp(
        isFirstLaunch: isFirstLaunch,
        isPanicActive: isPanicActive,
        panicSecondsRemaining: panicSecondsRemaining,
      ),
    ),
  );
}

class PreventionApp extends ConsumerStatefulWidget {
  final bool isFirstLaunch;
  final bool isPanicActive;
  final int panicSecondsRemaining;

  const PreventionApp({
    super.key,
    required this.isFirstLaunch,
    this.isPanicActive = false,
    this.panicSecondsRemaining = 0,
  });

  @override
  ConsumerState<PreventionApp> createState() => _PreventionAppState();
}

class _PreventionAppState extends ConsumerState<PreventionApp> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onResume: _handleResume);
  }

  DateTime? _lastNotificationTime;

  Future<void> _handleResume() async {
    // Show instant motivational notification with 5-minute cooldown
    final now = DateTime.now();
    if (_lastNotificationTime == null ||
        now.difference(_lastNotificationTime!) > const Duration(minutes: 5)) {
      final notificationService = NotificationService();
      await notificationService.showMotivationalNotification();
      _lastNotificationTime = now;
    }

    // Force session refresh on resume to prevent "Token has expired" errors
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      try {
        await Supabase.instance.client.auth.refreshSession();
        debugPrint('Session refreshed successfully on resume');
        // Restart the stream with the new token
        ref.invalidate(userProfileStreamProvider);
      } catch (e) {
        debugPrint('Error refreshing session on resume: $e');
      }
    }
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Prevention',
      theme: AppTheme.darkTheme,
      routerConfig: createRouter(
        widget.isFirstLaunch,
        isPanicActive: widget.isPanicActive,
        panicSecondsRemaining: widget.panicSecondsRemaining,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
