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

import '../../core/session/rm_session.dart';
import '../../features/auth/presentation/passcode_entry_screen.dart';
import '../../features/auth/presentation/phone_entry_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/create_route/presentation/create_route_screen.dart';
import '../../features/discovery/presentation/match_results_screen.dart';
import '../../features/discovery/presentation/route_details_screen.dart';
import '../../features/discovery/presentation/search_screen.dart';
import '../../features/gallery/presentation/gallery_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/application/onboarding_controller.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/reviews/presentation/reviews_screen.dart';
import '../../features/safety/presentation/safety_screen.dart';
import '../../features/trip/presentation/active_trip_screen.dart';
import '../../features/verification/presentation/verification_screen.dart';
import '../../l10n/app_localizations.dart';
import '../app_shell.dart';
import '../error/app_error_screen.dart';
import '../error/rm_error_reporter.dart';
import '../providers/session_provider.dart';
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

  // The session is already a ValueListenable, so it needs no bridge of its own.
  // Merging keeps the two dimensions separate all the way to the redirect:
  // either can change without the other, and neither is derived from the other.
  final RmSession session = ref.read(rmSessionProvider);

  return GoRouter(
    initialLocation: AppRoutes.startupPath,
    debugLogDiagnostics: false,
    refreshListenable: Listenable.merge(<Listenable>[refresh, session.state]),
    // go_router's default error page is unthemed, unlocalized, and prints the
    // exception and the attempted path to the member. The failure is recorded
    // instead, and the screen says only what a member can act on.
    errorBuilder: (BuildContext context, GoRouterState state) {
      reportError(
        state.error ?? Exception('Unresolved route'),
        StackTrace.current,
        hint: 'router: ${state.matchedLocation}',
      );
      return const AppErrorScreen();
    },
    // TWO DIMENSIONS, IN A FIXED ORDER, AND THEY ARE NOT THE SAME QUESTION.
    //
    //   "has this person seen the intro"   — a device-local flag
    //   "is there a usable session"        — a credential the server accepts
    //
    // Neither is derived from the other. A member who reinstalls has a session
    // and no flag; a member who signed out has the flag and no session. Folding
    // them into one boolean would make both cases wrong, and it is the mistake
    // this file has warned against since the flag was the only condition here.
    redirect: (BuildContext context, GoRouterState state) {
      final AsyncValue<bool> onboarding = ref.read(
        onboardingControllerProvider,
      );
      final RmSessionState sessionState = session.state.value;

      final String location = state.matchedLocation;
      final bool atLaunchSurface = location == AppRoutes.startupPath;
      final bool atOnboarding = location == AppRoutes.onboardingPath;
      final bool atAuth =
          location == AppRoutes.authPhonePath ||
          location == AppRoutes.authPasscodePath;

      // 1. Either dimension still resolving: decide nothing.
      //
      // The session matters as much as the flag here. A cold start with a
      // perfectly good stored credential spends a network round trip finding
      // that out, and without this the member would watch a sign-in screen
      // appear and then vanish.
      if (!onboarding.hasValue || sessionState is RmSessionUnresolved) {
        return atLaunchSurface ? null : AppRoutes.startupPath;
      }

      // 2. The intro wins. Someone who has never seen it should not meet a
      //    sign-in form first, whatever their credential says.
      if (!onboarding.requireValue) {
        return atOnboarding ? null : AppRoutes.onboardingPath;
      }

      // 3. Signed in. The launch surface, the intro and the sign-in screens
      //    are all dead ends now — this is what stops a restored session being
      //    sent back to a sign-in form by stale navigation history.
      if (sessionState is RmSignedIn) {
        return atLaunchSurface || atOnboarding || atAuth
            ? AppRoutes.homePath
            : null;
      }

      // 4. Signed out, and somewhere that needs an account.
      //
      // Auth routes are excluded, so a signed-out member moves freely between
      // the phone and passcode screens — the redirect that would otherwise send
      // /auth/passcode back to /auth on every keystroke.
      return atAuth ? null : AppRoutes.authPhonePath;
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
      // Debug only, and for the same reason as Active Trip and Safety: the
      // screen states things that are not true once account identity is real.
      // Its email step reads "verified" from a fixture, its progression is a
      // scripted demo no backend drives, and its Trust Score has no engine
      // behind it. Those were harmless while every account was imaginary; they
      // are false claims about a real member's account now.
      //
      // The screen, its fixtures, its tests and its goldens are all kept as the
      // approved design reference. Only the release entry point goes.
      //
      // IT RETURNS TO RELEASE WHEN ALL OF THESE HOLD:
      //   * verification presentation state is served by the backend;
      //   * the Trust Score is a value the server computes and owns;
      //   * at least one non-phone step has a real submission path;
      //   * every displayed status is traceable to backend state;
      //   * and it migrates in one coherent change, never as a hybrid of real
      //     and fixture data.
      if (kDebugMode)
        GoRoute(
          path: AppRoutes.verificationPath,
          name: AppRoutes.verification,
          builder: (BuildContext context, GoRouterState state) =>
              const VerificationScreen(),
        ),
      // Sign-in. Registered in every build — these screens do what they say —
      // but linked from nowhere yet: the redirect below still gates on the
      // onboarding flag alone, and giving a completed sign-in somewhere to go
      // is the router change that comes with session state.
      GoRoute(
        path: AppRoutes.authPhonePath,
        name: AppRoutes.authPhone,
        builder: (BuildContext context, GoRouterState state) =>
            const PhoneEntryScreen(),
      ),
      GoRoute(
        path: AppRoutes.authPasscodePath,
        name: AppRoutes.authPasscode,
        builder: (BuildContext context, GoRouterState state) {
          final Object? phone = state.extra;

          // Reached without the number it is supposed to confirm — a deep link
          // or a restored stack. Asking for it again is the only honest
          // option; a passcode screen that does not know the number cannot
          // verify anything.
          return phone is String && phone.isNotEmpty
              ? PasscodeEntryScreen(phone: phone)
              : const PhoneEntryScreen();
        },
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
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.searchPath,
                name: AppRoutes.search,
                builder: (BuildContext context, GoRouterState state) =>
                    const SearchScreen(),
              ),
            ],
          ),
          // Chat itself shipped in Phase 5, reached from Route Details. What
          // is missing is the inbox: the design has no conversation-list
          // screen, and wiring this tab to the one fixture thread would fake
          // one. Recorded in design-system.md §8.
          //
          // This is a release-reachable tab, so its copy is localized like any
          // other product surface.
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.messagesPath,
                name: AppRoutes.messages,
                builder: (BuildContext context, GoRouterState state) {
                  final AppLocalizations l10n = AppLocalizations.of(context);
                  return PlaceholderScreen(
                    routeName: l10n.navMessages,
                    phase: l10n.messagesPlaceholderBody,
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.profilePath,
                name: AppRoutes.profile,
                builder: (BuildContext context, GoRouterState state) =>
                    const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.matchesPath,
        name: AppRoutes.matches,
        builder: (BuildContext context, GoRouterState state) =>
            const MatchResultsScreen(),
      ),
      GoRoute(
        path: AppRoutes.routeDetailsPath,
        name: AppRoutes.routeDetails,
        builder: (BuildContext context, GoRouterState state) =>
            RouteDetailsScreen(
              routeId: state.pathParameters[AppRoutes.routeIdParam] ?? '',
            ),
      ),
      GoRoute(
        path: AppRoutes.createRoutePath,
        name: AppRoutes.createRoute,
        builder: (BuildContext context, GoRouterState state) =>
            const CreateRouteScreen(),
      ),
      // Above the shell: the comp draws a back control and no tab bar.
      GoRoute(
        path: AppRoutes.reviewsPath,
        name: AppRoutes.reviews,
        builder: (BuildContext context, GoRouterState state) =>
            const ReviewsScreen(),
      ),
      // Above the shell: the comp draws no tab bar. Reached from Route Details
      // in every build, and from Active Trip in debug ones.
      GoRoute(
        path: AppRoutes.chatPath,
        name: AppRoutes.chat,
        builder: (BuildContext context, GoRouterState state) =>
            const ChatScreen(),
      ),
      // Developer tooling: never reachable in a release build.
      if (kDebugMode)
        GoRoute(
          path: AppRoutes.galleryPath,
          name: AppRoutes.gallery,
          builder: (BuildContext context, GoRouterState state) =>
              const GalleryScreen(),
        ),
      // Debug only, and deliberately linked from nowhere. Active Trip needs a
      // trip lifecycle this product does not have, so rather than fabricate one
      // to unlock the screen it is kept out of the release route table
      // altogether. See active_trip_screen.dart.
      if (kDebugMode)
        GoRoute(
          path: AppRoutes.activeTripPath,
          name: AppRoutes.activeTrip,
          builder: (BuildContext context, GoRouterState state) =>
              const ActiveTripScreen(),
        ),
      // Debug only, for the same reason and more sharply. The Safety Center
      // promises emergency behaviour that does not exist anywhere in this
      // app, so the route is absent from the release table rather than merely
      // unlinked. Reached from Active Trip's SOS button in debug builds, which
      // gives the two withheld screens one coherent flow to review.
      if (kDebugMode)
        GoRoute(
          path: AppRoutes.safetyPath,
          name: AppRoutes.safety,
          builder: (BuildContext context, GoRouterState state) =>
              const SafetyScreen(),
        ),
    ],
  );
});
