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
import '../../features/accountability/presentation/accountability_screen.dart';
import '../../features/accountability/presentation/partner_settings_screen.dart';
import '../../features/spiritual/presentation/spiritual_hub_screen.dart';
import '../../features/spiritual/presentation/dhikr_counter_screen.dart';
import '../../features/spiritual/presentation/salah_tracker_screen.dart';
import '../../features/spiritual/presentation/adhkar_reader_screen.dart';
import '../../features/challenges/presentation/challenges_screen.dart';
import '../../features/challenges/presentation/challenge_detail_screen.dart';
import '../../features/challenges/presentation/badges_screen.dart';
import '../../features/challenges/presentation/create_challenge_screen.dart';
import '../../features/quran/presentation/quran_screen.dart';
import '../../features/quran/presentation/surah_reader_screen.dart';
import '../../features/quran/presentation/juz_reader_screen.dart';

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

      // Accountability Partner Routes
      GoRoute(
        path: '/accountability',
        builder: (context, state) => const AccountabilityScreen(),
      ),
      GoRoute(
        path: '/accountability/settings/:id',
        builder: (context, state) =>
            PartnerSettingsScreen(partnershipId: state.pathParameters['id']!),
      ),

      // Spiritual Exercises Routes
      GoRoute(
        path: '/spiritual',
        builder: (context, state) => const SpiritualHubScreen(),
      ),
      GoRoute(
        path: '/spiritual/dhikr',
        builder: (context, state) => const DhikrCounterScreen(),
      ),
      GoRoute(
        path: '/spiritual/salah',
        builder: (context, state) => const SalahTrackerScreen(),
      ),
      GoRoute(
        path: '/spiritual/adhkar',
        builder: (context, state) {
          final category = state.uri.queryParameters['category'];
          return AdhkarReaderScreen(initialCategory: category);
        },
      ),
      GoRoute(
        path: '/spiritual/quran',
        builder: (context, state) => const QuranScreen(),
      ),
      GoRoute(
        path: '/spiritual/quran/surah/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return SurahReaderScreen(surahNumber: id);
        },
      ),
      GoRoute(
        path: '/spiritual/quran/juz/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return JuzReaderScreen(juzNumber: id);
        },
      ),

      // Community Challenges Routes
      GoRoute(
        path: '/challenges',
        builder: (context, state) => const ChallengesScreen(),
      ),
      GoRoute(
        path: '/challenges/badges',
        builder: (context, state) => const BadgesScreen(),
      ),
      GoRoute(
        path: '/challenges/create',
        builder: (context, state) => const CreateChallengeScreen(),
      ),
      GoRoute(
        path: '/challenges/:id',
        builder: (context, state) =>
            ChallengeDetailScreen(challengeId: state.pathParameters['id']!),
      ),
    ],
  );
}
