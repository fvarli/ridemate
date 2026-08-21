// ─────────────────────────────────────────────────────────────
// RideMate — Preference persistence
//
// The behaviour matrix these tests exist for:
//
//   stored valid value   -> restored
//   missing value        -> device default
//   corrupt value        -> safe default AND observed
//   write failure        -> the member keeps their choice; failure reported
//   restart              -> stored choice restored
//   late overwrite       -> impossible by construction, and pinned as such
//
// The last row is the important one. There is no hydration step to race
// against, because the store is resolved before the first frame; the tests
// below assert that property directly rather than trying to provoke a race
// the design does not contain.
// ─────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/app/data/app_preferences_repository.dart';
import 'package:ridemate/app/providers/app_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fakes.dart';

/// A container bound to [repository], as `main()` binds the real one.
ProviderContainer _containerWith(AppPreferencesRepository repository) {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      appPreferencesRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('Restoring a stored preference', () {
    test('a stored theme and locale are the initial state', () {
      final ProviderContainer container = _containerWith(
        RecordingAppPreferencesRepository(
          themeMode: ThemeMode.dark,
          locale: const Locale('en'),
        ),
      );

      // First read, no pump, no settle: the value is there before anything
      // could have hydrated it.
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(container.read(localeProvider), const Locale('en'));
    });

    test('nothing stored means follow the device', () {
      final ProviderContainer container = _containerWith(
        RecordingAppPreferencesRepository(),
      );

      expect(container.read(themeModeProvider), ThemeMode.system);
      expect(container.read(localeProvider), isNull);
    });

    test('a restart restores the choice', () async {
      final RecordingAppPreferencesRepository store =
          RecordingAppPreferencesRepository();

      _containerWith(
        store,
      ).read(themeModeProvider.notifier).set(ThemeMode.light);
      await Future<void>.delayed(Duration.zero);

      // A second container over the same store is what a restart looks like.
      expect(_containerWith(store).read(themeModeProvider), ThemeMode.light);
    });
  });

  group('A newer choice always wins', () {
    test(
      'setting a value cannot be undone by anything arriving later',
      () async {
        final RecordingAppPreferencesRepository store =
            RecordingAppPreferencesRepository(themeMode: ThemeMode.dark);
        final ProviderContainer container = _containerWith(store);

        expect(container.read(themeModeProvider), ThemeMode.dark);

        container.read(themeModeProvider.notifier).set(ThemeMode.light);
        expect(container.read(themeModeProvider), ThemeMode.light);

        // Drain every pending microtask and timer. If a hydration step existed,
        // this is where it would land on top of the member's choice.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(
          container.read(themeModeProvider),
          ThemeMode.light,
          reason: 'a late read must never overwrite a newer selection',
        );
      },
    );

    test('the providers contain no asynchronous hydration at all', () {
      // The structural half of the guarantee above: build() reads a resolved
      // store synchronously. An async build(), a .then() or a Future in this
      // file would reintroduce exactly the race the design removes.
      final String source =
          File('lib/app/providers/app_preferences_provider.dart')
              .readAsLinesSync()
              .map((String line) {
                final int slash = line.indexOf('//');
                return slash == -1 ? line : line.substring(0, slash);
              })
              .join('\n');

      expect(source, isNot(contains('build() async')));
      expect(source, isNot(contains('.then(')));
      expect(source, isNot(contains('await ')));
      expect(source, isNot(contains('AsyncNotifier')));
      expect(source, isNot(contains('Future<ThemeMode')));
      expect(source, isNot(contains('Future<Locale')));
      // Writes are fire-and-forget, and the lint requires saying so.
      expect(source, contains('unawaited('));
    });
  });

  group('Failure never costs the member their choice', () {
    test('a failed write leaves the chosen value in place', () async {
      final RecordingAppPreferencesRepository store =
          RecordingAppPreferencesRepository(failWrites: true);
      final ProviderContainer container = _containerWith(store);

      container.read(themeModeProvider.notifier).set(ThemeMode.dark);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(store.writes, <Object?>[ThemeMode.dark]);
      // It did not persist, and that is the honest outcome: the choice holds
      // for the session and the failure was reported, not thrown.
      expect(store.themeMode(), isNull);
    });

    test('a failed write does not escape as an unhandled error', () async {
      final ProviderContainer container = _containerWith(
        RecordingAppPreferencesRepository(failWrites: true),
      );

      container.read(localeProvider.notifier).set(const Locale('en'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(container.read(localeProvider), const Locale('en'));
    });
  });

  group('A corrupt store degrades safely', () {
    setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

    Future<SharedPreferencesAppPreferencesRepository> storeWith(
      Map<String, Object> values,
    ) async {
      SharedPreferences.setMockInitialValues(values);
      return SharedPreferencesAppPreferencesRepository(
        await SharedPreferences.getInstance(),
      );
    }

    test('an unknown theme value falls back to the device default', () async {
      final SharedPreferencesAppPreferencesRepository store = await storeWith(
        <String, Object>{AppPreferenceKeys.themeMode: 'aubergine'},
      );

      expect(store.themeMode(), isNull);
      expect(_containerWith(store).read(themeModeProvider), ThemeMode.system);
    });

    test('an unknown locale value falls back to the device default', () async {
      final SharedPreferencesAppPreferencesRepository store = await storeWith(
        <String, Object>{AppPreferenceKeys.locale: 'not-a-language-tag'},
      );

      expect(store.locale(), isNull);
      expect(_containerWith(store).read(localeProvider), isNull);
    });

    test('a valid stored value round-trips through the real store', () async {
      final SharedPreferencesAppPreferencesRepository store = await storeWith(
        <String, Object>{},
      );

      await store.setThemeMode(ThemeMode.dark);
      await store.setLocale(const Locale('en'));

      expect(store.themeMode(), ThemeMode.dark);
      expect(store.locale(), const Locale('en'));

      // Clearing the locale override returns to following the device.
      await store.setLocale(null);
      expect(store.locale(), isNull);
    });
  });

  group('Preferences are not onboarding, and not a session', () {
    test('the keys are namespaced and claim nothing about a member', () {
      for (final String key in AppPreferenceKeys.all) {
        expect(key, startsWith('ridemate.prefs.'));

        final String lower = key.toLowerCase();
        for (final String forbidden in <String>[
          'auth',
          'account',
          'session',
          'token',
          'user',
          'verified',
          'onboarding',
        ]) {
          expect(
            lower.contains(forbidden),
            isFalse,
            reason: 'a UI preference key must not read as "$forbidden"',
          );
        }
      }
    });

    test('the preference store knows nothing about onboarding', () {
      final String source = File(
        'lib/app/data/app_preferences_repository.dart',
      ).readAsStringSync();

      // Separate concepts, separate repositories. They share a platform store
      // because that is one store, not one concept.
      expect(source, isNot(contains('OnboardingRepository')));
      expect(source, isNot(contains('hasSeenOnboarding')));
    });

    test('the interface exposes preferences and nothing else', () {
      // Guards against this quietly becoming a general settings or session
      // store, the way onboarding_test.dart guards its own interface.
      final String source = File(
        'lib/app/data/app_preferences_repository.dart',
      ).readAsStringSync();
      final int start = source.indexOf('abstract interface class');
      final int end = source.indexOf('}', start);
      final String contract = source.substring(start, end);

      expect(contract, contains('themeMode'));
      expect(contract, contains('locale'));
      for (final String forbidden in <String>[
        'signIn',
        'token',
        'session',
        'account',
        'profile',
      ]) {
        expect(contract, isNot(contains(forbidden)), reason: forbidden);
      }
    });
  });
}
