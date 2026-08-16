// ─────────────────────────────────────────────────────────────
// RideMate — Application-level UI preferences
//
// THE PHASE 1 RIVERPOD BOUNDARY:
//
// Providers in Phase 1 own app-level UI state ONLY — theme mode and locale.
// There are deliberately no repositories, services, mock data or persistence
// yet. Nothing is created merely to make the architecture look complete; each
// arrives in the phase that genuinely needs it.
//
// Both preferences are in-memory. Persisting them needs shared_preferences,
// which is a Phase 2 dependency (added alongside the onboarding/verification
// flag it also serves). Until then a restart returns to following the system.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which theme the app should use.
///
/// Defaults to [ThemeMode.system]; the design provides both a light and a
/// dark treatment and neither is privileged.
final NotifierProvider<ThemeModeNotifier, ThemeMode> themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void set(ThemeMode mode) => state = mode;

  /// Cycles system -> light -> dark -> system. Used by the debug gallery.
  void cycle() => state = switch (state) {
    ThemeMode.system => ThemeMode.light,
    ThemeMode.light => ThemeMode.dark,
    ThemeMode.dark => ThemeMode.system,
  };
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
  Locale? build() => null;

  void set(Locale? locale) => state = locale;
}
