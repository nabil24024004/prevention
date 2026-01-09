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

class PreventionApp extends ConsumerWidget {
  final bool isFirstLaunch;
  const PreventionApp({super.key, required this.isFirstLaunch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Prevention',
      theme: AppTheme.darkTheme,
      routerConfig: createRouter(isFirstLaunch),
      debugShowCheckedModeBanner: false,
    );
  }
}
