// ─────────────────────────────────────────────────────────────
// RideMate — Application preference storage
//
// WHAT THESE VALUES ARE, PRECISELY:
//
//   theme mode + locale  ->  device-local UI preferences.
//
// They are NOT account settings, NOT profile data and NOT session state. A
// member who signs in on a second device does not inherit them, because they
// describe this installation rather than this person.
//
// Three concepts stay separate and are never merged into one store:
//
//   AppPreferences    -> this file                 (device-local UI)
//   OnboardingState   -> onboarding_repository.dart (intro completed)
//   AuthState         -> does not exist at all
//
// They share a SharedPreferences instance because that is one platform store,
// not one concept; the key namespaces (`ridemate.prefs.*` against
// `ridemate.onboarding.*`) keep them apart, and a test asserts the preference
// keys never read as an account, session or identity claim.
//
// READS ARE SYNCHRONOUS, BY CONSTRUCTION.
//
// The instance is resolved once during bootstrap and injected, so a provider
// can read a stored value while building its initial state. That is the whole
// reason there is no hydration step: nothing arrives later, so nothing late
// can overwrite a newer choice the member has already made.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../error/rm_error_reporter.dart';

/// Device-local UI preferences.
///
/// Reads are synchronous; writes are not, and a failed write is reported
/// rather than thrown — losing a preference must never interrupt what the
/// member was doing.
abstract interface class AppPreferencesRepository {
  /// The stored theme mode, or null to follow the device.
  ThemeMode? themeMode();

  /// The stored locale, or null to follow the device.
  Locale? locale();

  Future<void> setThemeMode(ThemeMode mode);

  /// [locale] of null clears the override.
  Future<void> setLocale(Locale? locale);
}

/// Namespaced so they can never collide with the onboarding flag or with a
/// future account, session or profile key.
///
/// Public because the notifiers name them when reporting a failed write, and
/// because the test that asserts they never read as an account or session
/// claim has to enumerate them.
abstract final class AppPreferenceKeys {
  static const String themeMode = 'ridemate.prefs.themeMode';
  static const String locale = 'ridemate.prefs.locale';

  static const List<String> all = <String>[themeMode, locale];
}

/// The production implementation.
///
/// Construct it with an already-resolved [SharedPreferences]; see
/// [loadAppPreferencesRepository].
class SharedPreferencesAppPreferencesRepository
    implements AppPreferencesRepository {
  const SharedPreferencesAppPreferencesRepository(this._prefs);

  final SharedPreferences _prefs;

  @override
  ThemeMode? themeMode() {
    final String? stored = _read(AppPreferenceKeys.themeMode);
    if (stored == null) return null;

    for (final ThemeMode mode in ThemeMode.values) {
      if (mode.name == stored) return mode;
    }
    // An unrecognised value is a real signal — a downgrade, a hand-edited
    // store, or a rename that shipped without a migration. Fall back to the
    // device default, but never silently.
    reportError(
      StateError('Unknown stored theme mode: $stored'),
      StackTrace.current,
      hint: AppPreferenceKeys.themeMode,
    );
    return null;
  }

  @override
  Locale? locale() {
    final String? stored = _read(AppPreferenceKeys.locale);
    if (stored == null || stored.isEmpty) return null;

    // Only a bare language tag is ever written, so anything else is corrupt.
    if (!RegExp(r'^[a-zA-Z]{2,3}$').hasMatch(stored)) {
      reportError(
        StateError('Unknown stored locale: $stored'),
        StackTrace.current,
        hint: AppPreferenceKeys.locale,
      );
      return null;
    }
    return Locale(stored);
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) =>
      _write(AppPreferenceKeys.themeMode, mode.name);

  @override
  Future<void> setLocale(Locale? locale) =>
      _write(AppPreferenceKeys.locale, locale?.languageCode);

  String? _read(String key) {
    try {
      return _prefs.getString(key);
    } on Object catch (error, stack) {
      reportError(error, stack, hint: 'reading $key');
      return null;
    }
  }

  Future<void> _write(String key, String? value) async {
    try {
      if (value == null) {
        await _prefs.remove(key);
      } else {
        await _prefs.setString(key, value);
      }
    } on Object catch (error, stack) {
      // The member's choice is already applied in memory. A store that cannot
      // be written is worth knowing about, but it is not worth undoing what
      // they just asked for.
      reportError(error, stack, hint: 'writing $key');
    }
  }
}

/// Preferences that live only as long as the process.
///
/// NOT a test double — this is the degraded mode. If the platform store cannot
/// be opened, preferences still work for the session and simply do not survive
/// a restart. That is honest behaviour and, more importantly, it means a
/// broken preference store cannot stop the app from starting.
class InMemoryAppPreferencesRepository implements AppPreferencesRepository {
  InMemoryAppPreferencesRepository({ThemeMode? themeMode, Locale? locale})
    : _themeMode = themeMode,
      _locale = locale;

  ThemeMode? _themeMode;
  Locale? _locale;

  @override
  ThemeMode? themeMode() => _themeMode;

  @override
  Locale? locale() => _locale;

  @override
  Future<void> setThemeMode(ThemeMode mode) async => _themeMode = mode;

  @override
  Future<void> setLocale(Locale? locale) async => _locale = locale;
}

/// Resolves the store, degrading to in-memory if it cannot be opened.
///
/// Called from `main()` before `runApp`, which is what makes every later read
/// synchronous. Never throws.
Future<AppPreferencesRepository> loadAppPreferencesRepository() {
  return reportingFailures<AppPreferencesRepository>(
    () async => SharedPreferencesAppPreferencesRepository(
      await SharedPreferences.getInstance(),
    ),
    orElse: InMemoryAppPreferencesRepository.new,
    hint: 'opening the preference store',
  );
}
