// ─────────────────────────────────────────────────────────────
// RideMate — Test doubles
//
// These live in `test/` on purpose. Production ships no fake implementations;
// `architecture.md` forbids building them "so the architecture looks
// complete".
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:ridemate/app/data/app_preferences_repository.dart';
import 'package:ridemate/features/onboarding/data/onboarding_repository.dart';

/// In-memory [OnboardingRepository].
///
/// Records how many times the intro was marked complete, so a test can prove
/// an action did NOT touch persistence.
class InMemoryOnboardingRepository implements OnboardingRepository {
  InMemoryOnboardingRepository({bool seen = false}) : _seen = seen;

  bool _seen;

  /// How many times [markOnboardingSeen] was called.
  int markCallCount = 0;

  bool get seen => _seen;

  @override
  Future<bool> hasSeenOnboarding() async => _seen;

  @override
  Future<void> markOnboardingSeen() async {
    markCallCount++;
    _seen = true;
  }
}

/// An [AppPreferencesRepository] whose writes can be made to fail.
///
/// The in-memory repository in `lib/` is production degraded-mode behaviour,
/// not a double, so it cannot grow test affordances. This one wraps it to add
/// the two things a test needs: a failing store, and a record of what was
/// written.
class RecordingAppPreferencesRepository implements AppPreferencesRepository {
  RecordingAppPreferencesRepository({
    ThemeMode? themeMode,
    Locale? locale,
    this.failWrites = false,
  }) : _themeMode = themeMode,
       _locale = locale;

  /// When true, every write throws — the "storage is broken" case.
  final bool failWrites;

  ThemeMode? _themeMode;
  Locale? _locale;

  /// Every value handed to a write, in order, including failed attempts.
  final List<Object?> writes = <Object?>[];

  @override
  ThemeMode? themeMode() => _themeMode;

  @override
  Locale? locale() => _locale;

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    writes.add(mode);
    if (failWrites) throw StateError('preference store unavailable');
    _themeMode = mode;
  }

  @override
  Future<void> setLocale(Locale? locale) async {
    writes.add(locale);
    if (failWrites) throw StateError('preference store unavailable');
    _locale = locale;
  }
}
