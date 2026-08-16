// ─────────────────────────────────────────────────────────────
// RideMate — Router
//
// The router is a Riverpod provider rather than a global, so it can read
// application state, be overridden in tests, and carry redirect guards.
//
// THE ONLY GUARD, and what it does NOT mean:
//
// The redirect gates on whether the intro presentation has been completed.
// It is NOT an auth guard — RideMate has no accounts, sessions or sign-in yet.
// A future auth guard is a separate condition and must not be folded into this
// one. See onboarding_repository.dart.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/gallery/presentation/gallery_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/application/onboarding_controller.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/verification/presentation/verification_screen.dart';
import '../app_shell.dart';
import '../startup_screen.dart';
import 'app_routes.dart';

/// The application router.
final Provider<GoRouter> routerProvider = Provider<GoRouter>((Ref ref) {
  // Bridges the async onboarding state to GoRouter, which needs a Listenable.
  // Disposed with the provider so it can never retain a stale listener.
  final ValueNotifier<int> refresh = ValueNotifier<int>(0);
  ref.listen<AsyncValue<bool>>(
    onboardingControllerProvider,
    (_, _) => refresh.value++,
  );
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.startupPath,
    debugLogDiagnostics: false,
    refreshListenable: refresh,
    redirect: (BuildContext context, GoRouterState state) {
      final AsyncValue<bool> onboarding = ref.read(
        onboardingControllerProvider,
      );

      // Not resolved yet: decide nothing, so neither Onboarding nor Home can
      // flash before the stored value is known.
      if (!onboarding.hasValue) {
        return state.matchedLocation == AppRoutes.startupPath
            ? null
            : AppRoutes.startupPath;
      }

      final bool hasSeenOnboarding = onboarding.requireValue;
      final String location = state.matchedLocation;
      final bool atLaunchSurface = location == AppRoutes.startupPath;
      final bool atOnboarding = location == AppRoutes.onboardingPath;

      if (!hasSeenOnboarding) {
        return atOnboarding ? null : AppRoutes.onboardingPath;
      }
      // Intro already completed: the launch surface and the intro itself are
      // both dead ends, so send them on. Everything else is left alone.
      return atLaunchSurface || atOnboarding ? AppRoutes.homePath : null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.startupPath,
        name: AppRoutes.startup,
        builder: (BuildContext context, GoRouterState state) =>
            const StartupScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingPath,
        name: AppRoutes.onboarding,
        builder: (BuildContext context, GoRouterState state) =>
            const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.verificationPath,
        name: AppRoutes.verification,
        builder: (BuildContext context, GoRouterState state) =>
            const VerificationScreen(),
      ),
      StatefulShellRoute.indexedStack(
        // indexedStack keeps each branch alive, so switching tabs preserves
        // scroll position and in-progress input — which matters once the
        // search and create-route flows are real.
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell shell,
            ) => AppShell(navigationShell: shell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.homePath,
                name: AppRoutes.home,
                builder: (BuildContext context, GoRouterState state) =>
                    const HomeScreen(),
              ),
            ],
          ),
          _placeholderBranch(
            path: AppRoutes.searchPath,
            name: AppRoutes.search,
            title: 'Search',
            phase: 'Phase 3 — Search routes',
          ),
          _placeholderBranch(
            path: AppRoutes.messagesPath,
            name: AppRoutes.messages,
            title: 'Messages',
            phase: 'Phase 5 — Chat',
          ),
          _placeholderBranch(
            path: AppRoutes.profilePath,
            name: AppRoutes.profile,
            title: 'Profile',
            phase: 'Phase 6 — Profile / Trust',
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.createRoutePath,
        name: AppRoutes.createRoute,
        builder: (BuildContext context, GoRouterState state) =>
            const PlaceholderScreen(
              routeName: 'Create route',
              phase: 'Phase 4 — Create route',
              showBackButton: true,
            ),
      ),
      // Developer tooling: never reachable in a release build.
      if (kDebugMode)
        GoRoute(
          path: AppRoutes.galleryPath,
          name: AppRoutes.gallery,
          builder: (BuildContext context, GoRouterState state) =>
              const GalleryScreen(),
        ),
    ],
  );
});

StatefulShellBranch _placeholderBranch({
  required String path,
  required String name,
  required String title,
  required String phase,
}) {
  return StatefulShellBranch(
    routes: <RouteBase>[
      GoRoute(
        path: path,
        name: name,
        builder: (BuildContext context, GoRouterState state) =>
            PlaceholderScreen(routeName: title, phase: phase),
      ),
    ],
  );
}
