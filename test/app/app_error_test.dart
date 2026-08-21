// ─────────────────────────────────────────────────────────────
// RideMate — Application error handling
//
// Two things are worth protecting here: that an error is observed rather than
// dropped, and that nothing diagnostic reaches the member. The second is the
// one a refactor breaks quietly — printing `state.error` into the screen is a
// one-line "improvement" that leaks internals to whoever is holding the phone.
// ─────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/app/error/app_error_screen.dart';
import 'package:ridemate/app/error/rm_error_reporter.dart';
import 'package:ridemate/app/providers/app_preferences_provider.dart';
import 'package:ridemate/app/ride_mate_app.dart';
import 'package:ridemate/app/router/app_router.dart';
import 'package:ridemate/features/home/presentation/home_screen.dart';
import 'package:ridemate/features/onboarding/application/onboarding_controller.dart';

import '../support/fakes.dart';

Future<ProviderContainer> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        onboardingRepositoryProvider.overrideWithValue(
          InMemoryOnboardingRepository(seen: true),
        ),
      ],
      child: const RideMateApp(),
    ),
  );
  await tester.pumpAndSettle();

  final ProviderContainer container = ProviderScope.containerOf(
    tester.element(find.byType(RideMateApp)),
  );
  container.read(localeProvider.notifier).set(const Locale('tr'));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('The routing error surface', () {
    testWidgets('an unresolvable location renders the RideMate error screen', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await _pumpApp(tester);

      container.read(routerProvider).go('/this-route-does-not-exist');
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorScreen), findsOneWidget);
      expect(find.text('Bir şeyler ters gitti'), findsOneWidget);
    });

    testWidgets('it shows nothing a member cannot act on', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await _pumpApp(tester);

      container.read(routerProvider).go('/this-route-does-not-exist');
      await tester.pumpAndSettle();

      // The attempted path, the exception type, and anything that reads as a
      // diagnostic must all be absent from the rendered tree.
      for (final String leaked in <String>[
        'this-route-does-not-exist',
        'GoException',
        'Exception',
        'no routes for location',
        '#0',
        'package:',
        '/lib/',
      ]) {
        expect(
          find.textContaining(leaked, skipOffstage: false),
          findsNothing,
          reason: 'the error screen must not surface "$leaked"',
        );
      }
    });

    testWidgets('its one recovery action actually recovers', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await _pumpApp(tester);

      container.read(routerProvider).go('/this-route-does-not-exist');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ana sayfaya dön'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(AppErrorScreen), findsNothing);
    });
  });

  group('The error seam', () {
    test('reporting never throws, whatever it is handed', () {
      expect(() => reportError('a bare string', null), returnsNormally);
      expect(
        () => reportError(Exception('boom'), StackTrace.current, hint: 'x'),
        returnsNormally,
      );
    });

    test('a failing operation degrades to the caller\'s fallback', () async {
      final int value = await reportingFailures<int>(
        () async => throw StateError('storage unavailable'),
        orElse: () => 42,
        hint: 'test',
      );
      expect(value, 42, reason: 'the caller decides the degraded behaviour');
    });

    test('a succeeding operation is returned untouched', () async {
      final int value = await reportingFailures<int>(
        () async => 7,
        orElse: () => 0,
      );
      expect(value, 7);
    });
  });

  group('The seam observes without suppressing', () {
    /// The reporter source, with `//` comments removed — the rules below are
    /// written down in its header, so a raw scan would match the explanation.
    String code() => File('lib/app/error/rm_error_reporter.dart')
        .readAsLinesSync()
        .map((String line) {
          final int slash = line.indexOf('//');
          return slash == -1 ? line : line.substring(0, slash);
        })
        .join('\n');

    test('PlatformDispatcher.onError returns false, never true', () {
      final String source = code();
      expect(source, contains('PlatformDispatcher.instance.onError'));
      expect(
        source,
        contains('return false;'),
        reason: 'returning true would silence a crash nothing is recording',
      );
      expect(source, isNot(contains('return true;')));
    });

    test('the framework keeps presenting its own errors', () {
      expect(code(), contains('FlutterError.presentError(details)'));
    });

    test('runZonedGuarded is not used, so nothing reports twice', () {
      // It would catch the same uncaught async errors PlatformDispatcher
      // already delivers, and every one of them would be recorded twice.
      expect(code(), isNot(contains('runZonedGuarded')));
      expect(
        File('lib/main.dart').readAsStringSync(),
        isNot(contains('runZonedGuarded')),
      );
    });

    test('no crash-reporting vendor is introduced', () {
      final String pubspec = File('pubspec.yaml').readAsStringSync();
      for (final String vendor in <String>[
        'sentry',
        'firebase_crashlytics',
        'bugsnag',
        'datadog',
      ]) {
        expect(pubspec, isNot(contains(vendor)), reason: vendor);
      }
    });
  });

  group('The release error widget', () {
    test('is installed only in release builds', () {
      final String source = File(
        'lib/app/ride_mate_app.dart',
      ).readAsStringSync();
      expect(source, contains('kReleaseMode'));
      expect(
        source,
        contains('ErrorWidget.builder'),
        reason: 'the default box prints the exception onto the screen',
      );
    });

    testWidgets('debug and test keep the framework error box', (
      WidgetTester tester,
    ) async {
      // Guards the gate above: if it ever stops being release-only, a broken
      // subtree in a test would render a blank box instead of announcing
      // itself, and the suite would go quiet in the worst possible way.
      await _pumpApp(tester);
      expect(ErrorWidget.builder, isNotNull);

      final Widget box = ErrorWidget.builder(
        FlutterErrorDetails(exception: Exception('boom')),
      );
      expect(box, isA<ErrorWidget>());
    });
  });
}
