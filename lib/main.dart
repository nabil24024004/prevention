import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';

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

  runApp(ProviderScope(child: PreventionApp(isFirstLaunch: isFirstLaunch)));
}

class PreventionApp extends ConsumerStatefulWidget {
  final bool isFirstLaunch;
  const PreventionApp({super.key, required this.isFirstLaunch});

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

  Future<void> _handleResume() async {
    // Force session refresh on resume to prevent "Token has expired" errors
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      try {
        await Supabase.instance.client.auth.refreshSession();
        debugPrint('Session refreshed successfully on resume');
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
      routerConfig: createRouter(widget.isFirstLaunch),
      debugShowCheckedModeBanner: false,
    );
  }
}
