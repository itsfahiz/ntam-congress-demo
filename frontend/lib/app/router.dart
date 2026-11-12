import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/main_shell.dart';
import '../features/agenda/agenda_screen.dart';
import '../features/assistant/assistant_screen.dart';
import '../features/auth/login/login_screen.dart';
import '../features/auth/register/register_screen.dart';
import '../features/auth/splash/auth_splash_screen.dart';
import '../features/auth/state/auth_controller.dart';
import '../features/exhibitors/exhibitors_screen.dart';
import '../features/home/home_screen.dart';
import '../features/name_tag/name_tag_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/qa/qa_screen.dart';
import '../features/quick_access/quick_access_screen.dart';
import '../features/resources/resources_screen.dart';
import '../features/saved/saved_items_screen.dart';
import '../features/speakers/speakers_screen.dart';
import '../features/venue/venue_screen.dart';
import '../features/voting/voting_screen.dart';
import 'app_routes.dart';

GoRouter createRouter(AuthController authController) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authController,
    redirect: (context, state) {
      final location = state.matchedLocation;
      switch (authController.lifecycle) {
        case AuthLifecycle.restoring:
          return location == AppRoutes.splash ? null : AppRoutes.splash;
        case AuthLifecycle.authenticated:
          if (location == AppRoutes.splash ||
              location == AppRoutes.login ||
              location == AppRoutes.register) {
            return AppRoutes.home;
          }
          return null;
        case AuthLifecycle.unauthenticated:
          if (location == AppRoutes.splash) return AppRoutes.login;
          final onAuthGate =
              location == AppRoutes.login || location == AppRoutes.register;
          if (!onAuthGate) return AppRoutes.login;
          return null;
      }
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const AuthSplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) {
          final extra = state.extra;
          final fromExtra = extra is String ? extra : null;
          final fromQuery = state.uri.queryParameters['email'];
          final email = (fromQuery ?? fromExtra)?.trim();
          final initialEmail =
              (email == null || email.isEmpty) ? null : email;
          return MaterialPage<void>(
            key: ValueKey(state.uri.toString()),
            name: state.name,
            child: LoginScreen(initialEmail: initialEmail),
          );
        },
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
        path: AppRoutes.saved,
        name: 'saved',
        builder: (context, state) => const SavedItemsScreen(),
      ),
      GoRoute(
        path: AppRoutes.exhibitors,
        name: 'exhibitors',
        builder: (context, state) => const ExhibitorsScreen(),
      ),
      GoRoute(
        path: AppRoutes.assistant,
        name: 'assistant',
        builder: (context, state) => const AssistantScreen(),
      ),
    ],
  );
}
