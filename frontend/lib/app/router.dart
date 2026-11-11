import 'package:go_router/go_router.dart';

import '../core/widgets/main_shell.dart';
import '../features/agenda/agenda_screen.dart';
import '../features/auth/login/login_screen.dart';
import '../features/auth/register/register_screen.dart';
import '../features/auth/state/auth_controller.dart';
import '../features/exhibitors/exhibitors_screen.dart';
import '../features/home/home_screen.dart';
import '../features/name_tag/name_tag_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/qa/qa_screen.dart';
import '../features/quick_access/quick_access_screen.dart';
import '../features/resources/resources_screen.dart';
import '../features/speakers/speakers_screen.dart';
import '../features/venue/venue_screen.dart';
import '../features/voting/voting_screen.dart';
import 'app_routes.dart';

GoRouter createRouter(AuthController authController) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: authController,
    redirect: (context, state) {
      final signedIn = authController.isSignedIn;
      final location = state.matchedLocation;
      final onAuthGate =
          location == AppRoutes.login || location == AppRoutes.register;

      if (!signedIn && !onAuthGate) return AppRoutes.login;
      if (signedIn && onAuthGate) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.quickAccess,
        name: 'quickAccess',
        builder: (context, state) => const QuickAccessScreen(),
      ),
      GoRoute(
        path: AppRoutes.agenda,
        name: 'agenda',
        builder: (context, state) => const AgendaScreen(),
      ),
      GoRoute(
        path: AppRoutes.speakers,
        name: 'speakers',
        builder: (context, state) => const SpeakersScreen(),
      ),
      GoRoute(
        path: AppRoutes.nameTag,
        name: 'nameTag',
        builder: (context, state) => const NameTagScreen(),
      ),
      GoRoute(
        path: AppRoutes.venue,
        name: 'venue',
        builder: (context, state) => const VenueScreen(),
      ),
      GoRoute(
        path: AppRoutes.voting,
        name: 'voting',
        builder: (context, state) => const VotingScreen(),
      ),
      GoRoute(
        path: AppRoutes.qa,
        name: 'qa',
        builder: (context, state) => const QaScreen(),
      ),
      GoRoute(
        path: AppRoutes.resources,
        name: 'resources',
        builder: (context, state) => const ResourcesScreen(),
      ),
      GoRoute(
        path: AppRoutes.exhibitors,
        name: 'exhibitors',
        builder: (context, state) => const ExhibitorsScreen(),
      ),
    ],
  );
}
