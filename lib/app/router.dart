import 'package:go_router/go_router.dart';

import '../core/widgets/main_shell.dart';
import '../core/widgets/placeholder_screen.dart';
import '../features/auth/login/login_screen.dart';
import '../features/auth/register/register_screen.dart';
import '../features/auth/state/auth_controller.dart';
import '../features/home/home_screen.dart';
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
                builder: (context, state) => const PlaceholderScreen(
                  title: 'My Profile',
                  showBack: false,
                ),
              ),
            ],
          ),
        ],
      ),
      ..._stackedFeatureRoutes(),
    ],
  );
}

List<RouteBase> _stackedFeatureRoutes() {
  const destinations = <(String, String, String)>[
    (AppRoutes.quickAccess, 'quickAccess', 'Quick Access'),
    (AppRoutes.agenda, 'agenda', 'Congress Agenda'),
    (AppRoutes.speakers, 'speakers', 'Speakers'),
    (AppRoutes.nameTag, 'nameTag', 'My Name Tag'),
    (AppRoutes.venue, 'venue', 'Venue'),
    (AppRoutes.voting, 'voting', 'Live Voting'),
    (AppRoutes.qa, 'qa', 'Ask Q&A'),
    (AppRoutes.resources, 'resources', 'Resources'),
    (AppRoutes.exhibitors, 'exhibitors', 'Exhibitors'),
  ];

  return [
    for (final destination in destinations)
      GoRoute(
        path: destination.$1,
        name: destination.$2,
        builder: (context, state) => PlaceholderScreen(title: destination.$3),
      ),
  ];
}
