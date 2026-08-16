// ─────────────────────────────────────────────────────────────
// RideMate — Onboarding persistence
//
// WHAT THIS FLAG MEANS, PRECISELY:
//
//   hasSeenOnboarding == true  ->  the intro presentation has been completed.
//
// It does NOT mean an account exists, that anyone signed in, or that any
// identity was verified. RideMate has no authentication and no account concept
// yet. The flag is named narrowly on purpose — never `isRegistered`,
// `hasAccount`, `isAuthenticated` or `userCreated` — so a future auth
// integration cannot inherit the wrong assumption from it.
//
// Three concepts stay separate and are never coupled:
//   OnboardingState   -> this flag                (persisted)
//   AuthState         -> not implemented at all
//   VerificationState -> in-memory mock only, never persisted
//
// This is device-local UI state, not a backend service, so the repository is
// owned by the feature rather than a shared services layer.
// ─────────────────────────────────────────────────────────────

import 'package:shared_preferences/shared_preferences.dart';

/// Stores whether the intro presentation has been completed.
///
/// A real implementation backed by an account profile can replace this without
/// the presentation layer changing.
abstract interface class OnboardingRepository {
  /// Whether the intro has already been shown and completed on this device.
  Future<bool> hasSeenOnboarding();

  /// Records that the intro presentation was completed.
  Future<void> markOnboardingSeen();
}

/// The only production implementation: a single local boolean.
class SharedPreferencesOnboardingRepository implements OnboardingRepository {
  SharedPreferencesOnboardingRepository();

  /// Namespaced so it cannot collide with a future auth or profile key.
  static const String storageKey = 'ridemate.onboarding.hasSeenOnboarding';

  /// Resolved once and reused; `SharedPreferences.getInstance()` is not called
  /// again on every read.
  Future<SharedPreferences>? _prefs;

  Future<SharedPreferences> get _instance =>
      _prefs ??= SharedPreferences.getInstance();

  @override
  Future<bool> hasSeenOnboarding() async {
    final SharedPreferences prefs = await _instance;
    return prefs.getBool(storageKey) ?? false;
  }

  @override
  Future<void> markOnboardingSeen() async {
    final SharedPreferences prefs = await _instance;
    await prefs.setBool(storageKey, true);
  }
}
