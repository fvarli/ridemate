// ─────────────────────────────────────────────────────────────
// RideMate — Route registry
//
// Names and paths are declared together so the router and its call sites can
// never drift. Navigate by NAME, never by a literal path string.
// ─────────────────────────────────────────────────────────────

/// Every route in the application.
abstract final class AppRoutes {
  const AppRoutes._();

  // ── Launch ─────────────────────────────────────────────────

  /// Neutral surface shown while the stored onboarding flag resolves.
  /// See [StartupScreen] — launch scaffolding, not product UI.
  static const String startup = 'startup';
  static const String startupPath = '/startup';

  // ── New-user flow (outside the shell — neither screen has a tab bar) ──

  static const String onboarding = 'onboarding';
  static const String onboardingPath = '/onboarding';

  static const String verification = 'verification';
  static const String verificationPath = '/verification';

  // ── Sign-in ────────────────────────────────────────────────
  //
  // Registered and reachable, but linked from nowhere yet: onboarding still
  // offers its own CTAs and the router still gates on the onboarding flag
  // alone. Wiring the entry point needs the session-aware redirect, because
  // otherwise a successful sign-in has nowhere honest to go — see the router.
  //
  // NOT behind kDebugMode. That guard is for screens promising a capability
  // that does not exist; these promise sign-in and deliver it.

  static const String authPhone = 'authPhone';
  static const String authPhonePath = '/auth';

  static const String authPasscode = 'authPasscode';
  static const String authPasscodePath = '/auth/passcode';

  // ── Shell branches ─────────────────────────────────────────
  // The four bottom-navigation destinations from the design's tab bar.

  static const String home = 'home';
  static const String homePath = '/home';

  static const String search = 'search';
  static const String searchPath = '/search';

  static const String messages = 'messages';
  static const String messagesPath = '/messages';

  static const String profile = 'profile';
  static const String profilePath = '/profile';

  // ── Discovery, pushed over the shell ───────────────────────
  // Neither screen has a tab bar in the design, so both render above the
  // shell. Route details is keyed by id rather than nested under matches,
  // because Home reaches the same screen.

  static const String matches = 'matches';
  static const String matchesPath = '/matches';

  static const String routeDetails = 'routeDetails';
  static const String routeDetailsPath = '/routes/:routeId';

  /// Builds the concrete path for [routeId].
  static String routeDetailsPathFor(String routeId) => '/routes/$routeId';

  /// The path parameter carrying the offer id.
  static const String routeIdParam = 'routeId';

  // ── Pushed over the shell ──────────────────────────────────

  /// The centre action of the navigation bar: publish a route as a driver.
  static const String createRoute = 'createRoute';
  static const String createRoutePath = '/route/create';

  /// A member's reputation in full, reached from Profile. Above the shell:
  /// the comp draws a back control and no tab bar.
  static const String reviews = 'reviews';
  static const String reviewsPath = '/reviews';

  /// A conversation with one other member. Reached from Route Details, and
  /// from Active Trip in debug builds. The design has no inbox, so there is no
  /// conversation-list route.
  static const String chat = 'chat';
  static const String chatPath = '/chat';

  // ── Developer tooling ──────────────────────────────────────

  /// The design-system gallery. Registered only in debug builds.
  static const String gallery = 'gallery';
  static const String galleryPath = '/gallery';

  /// A journey in progress. Registered only in debug builds, and linked from
  /// nowhere: reaching it honestly needs a trip lifecycle that does not exist,
  /// and it carries an SOS control and a live-location claim that no real
  /// member should meet. See active_trip_screen.dart.
  static const String activeTrip = 'activeTrip';
  static const String activeTripPath = '/trip/active';

  /// Emergency help and safety tools. Registered only in debug builds, and
  /// linked from no product surface: its SOS card promises that pressing it
  /// sends your location to your emergency contacts, a tile offers to call
  /// 112, and a row says two trusted contacts exist. None of that is backed
  /// by anything. See safety_screen.dart for what must exist before it can
  /// become reachable.
  static const String safety = 'safety';
  static const String safetyPath = '/safety';

  /// The branch destinations, in the order the design's tab bar shows them.
  static const List<String> shellPaths = <String>[
    homePath,
    searchPath,
    messagesPath,
    profilePath,
  ];
}
