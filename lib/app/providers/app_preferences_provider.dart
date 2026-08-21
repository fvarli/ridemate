// ─────────────────────────────────────────────────────────────
// RideMate — Application-level UI preferences
//
// Providers here own app-level UI state only: theme mode and locale. Both are
// now persisted, device-locally, through AppPreferencesRepository.
//
// WHY BUILD() CAN READ STORAGE SYNCHRONOUSLY
//
// The repository is resolved in `main()` and injected into the root
// ProviderScope, so by the time any of this builds the stored value is already
// in memory. That is deliberate and it is the whole design:
//
//   there is NO asynchronous hydration, so there is nothing that can arrive
//   late and overwrite a newer choice the member has already made.
//
// A pattern where build() returns a default and then kicks off a read is
// race-prone — tap the theme toggle quickly enough and the disk wins. This
// avoids the race by construction rather than guarding against it.
//
// Writes go the other way and are fire-and-forget: state changes immediately
// so the UI is never waiting on a disk, and a failed write is reported rather
// than thrown. The member keeps the theme they chose either way.
//
// These preferences are NOT onboarding state and NOT session state. See
// app_preferences_repository.dart.
// ─────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_preferences_repository.dart';
import '../error/rm_error_reporter.dart';

/// Where preferences are read and written.
///
/// Overridden in `main()` with the resolved store, and in tests with an
/// in-memory one. The default keeps a process-lifetime store so nothing that
/// forgets to override it silently reaches the platform.
final Provider<AppPreferencesRepository> appPreferencesRepositoryProvider =
    Provider<AppPreferencesRepository>(
      (Ref ref) => InMemoryAppPreferencesRepository(),
    );

/// Which theme the app should use.
///
/// Defaults to [ThemeMode.system] when nothing is stored; the design provides
/// both a light and a dark treatment and neither is privileged.
final NotifierProvider<ThemeModeNotifier, ThemeMode> themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() =>
      ref.read(appPreferencesRepositoryProvider).themeMode() ??
      ThemeMode.system;

  void set(ThemeMode mode) {
    state = mode;
    _persist(
      ref.read(appPreferencesRepositoryProvider).setThemeMode(mode),
      AppPreferenceKeys.themeMode,
    );
  }

  /// Cycles system -> light -> dark -> system. Used by the debug gallery.
  void cycle() => set(switch (state) {
    ThemeMode.system => ThemeMode.light,
    ThemeMode.light => ThemeMode.dark,
    ThemeMode.dark => ThemeMode.system,
  });
}

/// The locale override, or null to follow the device.
///
/// Turkish is the source product language and English is the second locale.
/// German, Spanish, French and Arabic are declared future targets; the
/// architecture is already RTL-safe for Arabic, but no translations ship yet.
final NotifierProvider<LocaleNotifier, Locale?> localeProvider =
    NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() => ref.read(appPreferencesRepositoryProvider).locale();

  void set(Locale? locale) {
    state = locale;
    _persist(
      ref.read(appPreferencesRepositoryProvider).setLocale(locale),
      AppPreferenceKeys.locale,
    );
  }
}

/// Fires a write and forgets it, without letting a failure escape.
///
/// The repository contract says a write never throws, and the production
/// implementation honours it. This does not depend on that: an implementation
/// that ever breaks the contract would otherwise turn a lost preference into
/// an unhandled asynchronous error, and the member's choice is already applied
/// either way.
void _persist(Future<void> write, String hint) {
  unawaited(
    write.catchError((Object error, StackTrace stack) {
      reportError(error, stack, hint: 'writing $hint');
    }),
  );
}
