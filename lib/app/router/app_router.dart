// ─────────────────────────────────────────────────────────────
// RideMate — Router
//
// The router is a Riverpod provider rather than a global, so it can read
// application state, be overridden in tests, and later gain a redirect guard
// without being rebuilt from scratch.
//
// NO GUARDS YET. The first real redirect is the verification gate in Phase 2;
// adding a placeholder one now would be architecture theatre.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/gallery/presentation/gallery_screen.dart';
import '../app_shell.dart';
import 'app_routes.dart';

/// The application router.
final Provider<GoRouter> routerProvider = Provider<GoRouter>((Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.homePath,
    debugLogDiagnostics: false,
    routes: <RouteBase>[
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
          _branch(
            path: AppRoutes.homePath,
            name: AppRoutes.home,
            title: 'Home',
            phase: 'Phase 3 — Home / Map',
          ),
          _branch(
            path: AppRoutes.searchPath,
            name: AppRoutes.search,
            title: 'Search',
            phase: 'Phase 3 — Search routes',
          ),
          _branch(
            path: AppRoutes.messagesPath,
            name: AppRoutes.messages,
            title: 'Messages',
            phase: 'Phase 5 — Chat',
          ),
          _branch(
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

StatefulShellBranch _branch({
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
