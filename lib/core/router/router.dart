import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/islamic_corner/presentation/islamic_corner_screen.dart';
import '../../features/dashboard/presentation/relapse_flow_screen.dart';
import '../../features/dashboard/presentation/panic_mode_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/progress/presentation/progress_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../presentation/main_scaffold.dart';
import '../../features/checkin/presentation/checkin_screen.dart';
import '../../features/statistics/presentation/statistics_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/blocking/data/blocker_repository.dart';
import '../../features/about/presentation/about_screen.dart';

GoRouter createRouter(
  bool isFirstLaunch, {
  bool isPanicActive = false,
  int panicSecondsRemaining = 0,
}) {
  // Store panic state for access in panic screen
  if (isPanicActive) {
    BlockerRepository.cachedPanicSeconds = panicSecondsRemaining;
  }

  return GoRouter(
    initialLocation: isPanicActive
        ? '/panic-mode'
        : (isFirstLaunch ? '/onboarding' : '/dashboard'),
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/welcome' ||
          state.matchedLocation == '/onboarding';
      final isPanicRoute = state.matchedLocation == '/panic-mode';

      // If panic mode is active, ALWAYS stay on panic screen (takes priority over auth)
      if (isPanicActive && !isPanicRoute) {
        return '/panic-mode';
      }

      // If on panic route (perhaps resumed), don't redirect away
      if (isPanicRoute && isPanicActive) {
        return null;
      }

      if (session == null) {
        return isAuthRoute ? null : '/welcome';
      } else {
        return isAuthRoute ? '/dashboard' : null;
      }
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),

      // Main App Shell
      ShellRoute(
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: '/islamic-corner',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: IslamicCornerScreen()),
          ),
          GoRoute(
            path: '/check-in',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CheckInScreen()),
          ),
          GoRoute(
            path: '/statistics',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: StatisticsScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),

      // Standalone Routes
      GoRoute(
        path: '/relapse',
        builder: (context, state) => const RelapseFlowScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/progress',
        builder: (context, state) => const ProgressScreen(),
      ),
      GoRoute(
        path: '/panic-mode',
        builder: (context, state) => const PanicModeScreen(),
      ),
      GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
    ],
  );
}
