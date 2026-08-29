// ─────────────────────────────────────────────────────────────
// RideMate — Backend reads are retried by the member, not by the app
//
// ONE INVARIANT, BOTH SERVER-BACKED READ SURFACES
//
//   build failure -> one repository call
//                 -> a stable, visible error
//                 -> the member presses Retry
//                 -> exactly one more call
//
// WHY THIS FILE EXISTS
//
// Riverpod retries a failed `build` automatically unless the provider says
// otherwise: ten attempts on a backoff reaching 6.4 seconds, eleven requests in
// all. `RmFailure implements Exception`, so it qualifies, and this was really
// happening — measured at eleven requests per failure on both screens before
// `noAutomaticRetry` was passed.
//
// It is invisible in an ordinary test, because a test that asserts right after
// the failure sees the first call and stops looking. So these tests advance the
// clock instead.
//
// HOW "NO LATER RETRY" IS PROVED
//
// `testWidgets` runs on a fake clock, so `pump(Duration(seconds: 60))` moves
// time past every delay the default policy could schedule — its longest is 6.4
// seconds and it gives up after ten — without waiting for any of it. A pending
// retry timer would fire during that pump and the count would climb. No sleeps,
// no polling, no tolerance for a call arriving late.
// ─────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/api/rm_error_code.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/routes/published_route.dart';
import 'package:ridemate/features/create_route/application/place_catalogue_providers.dart';
import 'package:ridemate/features/create_route/presentation/create_route_screen.dart';
import 'package:ridemate/features/my_routes/application/my_routes_providers.dart';
import 'package:ridemate/features/my_routes/data/my_routes_repository.dart';
import 'package:ridemate/features/my_routes/presentation/my_routes_screen.dart';

import '../support/fakes.dart';
import '../support/fonts.dart';
import '../support/pump.dart';

void main() {
  setUpAll(loadRideMateFonts);

  group('Every backend read states its retry policy', () {
    /// Source with `//` comments removed, so the prose explaining the rule is
    /// not mistaken for the rule.
    String code(File file) => file
        .readAsLinesSync()
        .map((String line) {
          final int comment = line.indexOf('//');

          return comment == -1 ? line : line.substring(0, comment);
        })
        .join('\n');

    Iterable<File> dartFilesIn(String path) => Directory(path)
        .listSync(recursive: true)
        .whereType<File>()
        .where((File f) => f.path.endsWith('.dart'))
        .where((File f) => !f.path.contains('app_localizations'));

    /// CARRIES WEIGHT. An exact list, so a third read surface is a decision.
    ///
    /// Leaving `retry` unset is not neutral — it opts into ten automatic
    /// attempts. A provider added later would inherit that silently, and the
    /// only symptom would be a backend seeing eleven times the traffic it
    /// expected from screens nobody was touching.
    test('exactly these providers declare one', () {
      final List<String> declaring = <String>[
        for (final File file in dartFilesIn('lib'))
          if (code(file).contains('AsyncNotifierProvider<') &&
              code(file).contains('retry:'))
            file.path,
      ];

      expect(declaring..sort(), <String>[
        'lib/features/create_route/application/place_catalogue_providers.dart',
        'lib/features/my_routes/application/my_routes_providers.dart',
      ]);
    });

    /// The one that deliberately does not, and why.
    ///
    /// Onboarding reads a local boolean out of SharedPreferences. It is not a
    /// backend read: retrying it costs no server anything and duplicates no
    /// request, so the default is harmless there. Named here so the omission
    /// reads as a decision rather than an oversight.
    test('onboarding is the deliberate exception', () {
      final String source = code(
        File('lib/features/onboarding/application/onboarding_controller.dart'),
      );

      expect(source, contains('AsyncNotifierProvider<'));
      expect(source, isNot(contains('retry:')));
      // And it genuinely does not reach the network.
      expect(source, isNot(contains('RmSession')));
      expect(source, isNot(contains('RmApiClient')));
    });
  });

  /// Long enough for the default policy to have run out entirely: ten attempts,
  /// the last few 6.4 seconds apart, about thirty-eight seconds in total.
  const Duration wellPastEveryBackoff = Duration(seconds: 60);

  const RmFailure transport = RmFailure.transport();
  const RmFailure serverError = RmFailure.fromBackend(
    status: 500,
    code: RmErrorCode.internalError,
  );

  group('The place catalogue asks once, and only once', () {
    Future<FakePlaceRepository> pumpFailing(
      WidgetTester tester,
      RmFailure failure,
    ) async {
      final FakePlaceRepository places = FakePlaceRepository(failure: failure);

      await tester.pumpRm(
        const CreateRouteScreen(),
        surfaceSize: const Size(393, 852),
        overrides: <Override>[
          placeRepositoryProvider.overrideWithValue(places),
        ],
      );
      await tester.pump();
      await tester.pump();

      return places;
    }

    for (final (String label, RmFailure failure) in <(String, RmFailure)>[
      ('an unreachable backend', transport),
      ('a server error', serverError),
    ]) {
      testWidgets('$label produces exactly one request, and no more', (
        WidgetTester tester,
      ) async {
        final FakePlaceRepository places = await pumpFailing(tester, failure);

        expect(places.callCount, 1, reason: 'the initial read');

        // The whole of the default backoff, passed in one frame.
        await tester.pump(wellPastEveryBackoff);

        expect(
          places.callCount,
          1,
          reason: 'nothing may ask again because time went by',
        );
      });
    }

    /// CARRIES WEIGHT. The member must be told, not left watching a spinner.
    testWidgets('the failure is on screen, not a loading state', (
      WidgetTester tester,
    ) async {
      await pumpFailing(tester, transport);

      expect(find.text('Yer listesi alınamadı.'), findsOneWidget);
      expect(find.text('Yerler yükleniyor…'), findsNothing);
      expect(find.text('Yeniden dene'), findsOneWidget);

      // And it stays that way. A retrying provider would flip back to loading.
      await tester.pump(wellPastEveryBackoff);

      expect(find.text('Yer listesi alınamadı.'), findsOneWidget);
      expect(find.text('Yerler yükleniyor…'), findsNothing);
    });

    testWidgets('pressing Retry asks exactly once more', (
      WidgetTester tester,
    ) async {
      final FakePlaceRepository places = await pumpFailing(tester, transport);

      expect(places.callCount, 1);

      await tester.tap(find.text('Yeniden dene'));
      await tester.pump();
      await tester.pump();

      expect(places.callCount, 2, reason: 'one deliberate action, one request');

      // Still failing, and still not retrying itself.
      await tester.pump(wellPastEveryBackoff);

      expect(places.callCount, 2);
    });
  });

  group('My Routes asks once, and only once', () {
    Future<FakeMyRoutesRepository> pumpFailing(
      WidgetTester tester,
      RmFailure failure,
    ) async {
      final FakeMyRoutesRepository routes = FakeMyRoutesRepository(
        failure: failure,
      );

      await tester.pumpRm(
        const MyRoutesScreen(),
        surfaceSize: const Size(393, 852),
        overrides: <Override>[
          myRoutesRepositoryProvider.overrideWithValue(routes),
        ],
      );
      await tester.pump();
      await tester.pump();

      return routes;
    }

    for (final (String label, RmFailure failure) in <(String, RmFailure)>[
      ('an unreachable backend', transport),
      ('a server error', serverError),
    ]) {
      testWidgets('$label produces exactly one request, and no more', (
        WidgetTester tester,
      ) async {
        final FakeMyRoutesRepository routes = await pumpFailing(
          tester,
          failure,
        );

        expect(routes.callCount, 1, reason: 'the initial read');

        await tester.pump(wellPastEveryBackoff);

        expect(
          routes.callCount,
          1,
          reason: 'nothing may ask again because time went by',
        );
      });
    }

    testWidgets('the failure is on screen, not a loading state', (
      WidgetTester tester,
    ) async {
      await pumpFailing(tester, transport);

      expect(find.text('Yeniden dene'), findsOneWidget);
      expect(find.text('Yükleniyor'), findsNothing);
      // Nothing is invented in place of the list.
      expect(find.text('Henüz rota yayınlamadın'), findsNothing);

      await tester.pump(wellPastEveryBackoff);

      expect(find.text('Yeniden dene'), findsOneWidget);
      expect(find.text('Yükleniyor'), findsNothing);
    });

    testWidgets('pressing Retry asks exactly once more', (
      WidgetTester tester,
    ) async {
      final FakeMyRoutesRepository routes = await pumpFailing(
        tester,
        transport,
      );

      expect(routes.callCount, 1);

      await tester.tap(find.text('Yeniden dene'));
      await tester.pump();
      await tester.pump();

      expect(routes.callCount, 2, reason: 'one deliberate action, one request');

      await tester.pump(wellPastEveryBackoff);

      expect(routes.callCount, 2);
    });

    /// A refresh that succeeds is still one request, and it must land.
    testWidgets('a retry that works replaces the error with the list', (
      WidgetTester tester,
    ) async {
      final FakeMyRoutesRepository routes = await pumpFailing(
        tester,
        transport,
      );

      routes
        ..failure = null
        ..chain(<MyRoutesResult>[
          MyRoutesResult(
            routes: <PublishedRoute>[fakeRoute(originLabel: 'Gerçek')],
            nextCursor: null,
          ),
        ]);

      await tester.tap(find.text('Yeniden dene'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Gerçek'), findsOneWidget);
      expect(routes.callCount, 2);
    });
  });
}
