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

GoRouter createRouter(bool isFirstLaunch) {
  return GoRouter(
    initialLocation: isFirstLaunch ? '/onboarding' : '/welcome',
    redirect: (context, state) {
      // if (isFirstLaunch && state.matchedLocation == '/onboarding') return null;
      // if (isFirstLaunch && state.matchedLocation != '/onboarding') return '/onboarding';

      final session = Supabase.instance.client.auth.currentSession;
      final isAuthRoute = state.matchedLocation == '/login' || 
                          state.matchedLocation == '/signup' || 
                          state.matchedLocation == '/welcome' ||
                          state.matchedLocation == '/onboarding';

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
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/islamic-corner',
        builder: (context, state) => const IslamicCornerScreen(),
      ),
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
    ],
  );
}
