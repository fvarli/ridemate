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

  // ── Pushed over the shell ──────────────────────────────────

  /// The centre action of the navigation bar: publish a route as a driver.
  static const String createRoute = 'createRoute';
  static const String createRoutePath = '/route/create';

  // ── Developer tooling ──────────────────────────────────────

  /// The design-system gallery. Registered only in debug builds.
  static const String gallery = 'gallery';
  static const String galleryPath = '/gallery';

  /// The branch destinations, in the order the design's tab bar shows them.
  static const List<String> shellPaths = <String>[
    homePath,
    searchPath,
    messagesPath,
    profilePath,
  ];
}
