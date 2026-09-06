// ─────────────────────────────────────────────────────────────
// RideMate — Create Route asks the server again when it is reopened
//
// THE DEFECT THIS FILE EXISTS FOR
//
// Found on a physical device during the unreachable-backend acceptance. The
// catalogue provider lived for the whole process, so leaving Create Route kept
// the loaded places. With the device tunnel removed and the backend genuinely
// unreachable, re-entering the screen showed NO failure at all: the previous
// endpoints still rendered and the picker still opened, listing places the
// server was no longer confirming. `GET /places` was never even attempted.
//
// A screen whose purpose is to choose server-owned endpoints must not offer a
// list the server has not just confirmed.
//
// The tests are written against OBSERVABLE BEHAVIOUR — how many times the
// repository is asked, and what the member ends up seeing — rather than against
// `isAutoDispose`. A future implementation that fixes staleness another way
// should keep these passing.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/places/mock_places.dart';
import 'package:ridemate/core/places/place.dart';
import 'package:ridemate/features/create_route/application/place_catalogue_providers.dart';
import 'package:ridemate/features/create_route/presentation/create_route_screen.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/pump.dart';

void main() {
  setUpAll(loadRideMateFonts);

  /// The copy the endpoints surface shows when the catalogue could not be read.
  const String failureCopy = 'Yer listesi alınamadı.';
  const String retryCopy = 'Yeniden dene';

  /// Labels that exist ONLY in the fixture. If one of these ever renders on
  /// this surface, something fell back to `MockPlaces` — which is the failure
  /// this phase exists to make impossible.
  final List<String> fixtureOnlyLabels = <String>[
    MockPlaces.kadikoy.label,
    MockPlaces.maslak.label,
    MockPlaces.university.label,
  ];

  void expectNoFixtureEverywhere() {
    for (final String label in fixtureOnlyLabels) {
      expect(
        find.textContaining(label),
        findsNothing,
        reason: 'a fixture place must never reach the publication surface',
      );
    }
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// Popped through the Navigator, which is what a back control delegates to.
  /// What matters is that the route is popped and the screen disposed, which is
  /// what releases the last listener.
  Future<void> leave(WidgetTester tester) async {
    tester.state<NavigatorState>(find.byType(Navigator).last).pop();
    await tester.pumpAndSettle();
  }

  group('Reopening Create Route asks the server again', () {
    /// CARRIES WEIGHT. The defect, reproduced through the real widget and
    /// navigation lifecycle rather than by poking the provider.
    testWidgets('a catalogue that changed while away is read again on reopen', (
      WidgetTester tester,
    ) async {
      final FakePlaceRepository places = FakePlaceRepository(
        places: const <Place>[
          Place(id: '01991a00-0000-7000-8000-0000000000a1', label: 'Yer Bir'),
        ],
      );

      await tester.pumpRm(
        const _CreateRouteHost(),
        surfaceSize: const Size(393, 852),
        overrides: <Override>[
          placeRepositoryProvider.overrideWithValue(places),
        ],
      );

      await open(tester);
      expect(places.callCount, 1, reason: 'one entry, one read');

      await leave(tester);

      // The server has moved on while the screen was closed.
      places.places = const <Place>[
        Place(id: '01991a00-0000-7000-8000-0000000000a2', label: 'Yer İki'),
      ];

      await open(tester);

      expect(
        places.callCount,
        2,
        reason: 'reopening must ask the server again, not serve a stale list',
      );
      expectNoFixtureEverywhere();
    });

    /// CARRIES WEIGHT. This is the physical symptom: the backend went away
    /// while the screen was closed, and the reopened screen must say so instead
    /// of rendering the catalogue it happened to be holding.
    testWidgets('an unreachable backend on reopen produces an honest failure', (
      WidgetTester tester,
    ) async {
      final FakePlaceRepository places = FakePlaceRepository(
        places: const <Place>[
          Place(id: '01991a00-0000-7000-8000-0000000000b1', label: 'Yer Bir'),
        ],
      );

      await tester.pumpRm(
        const _CreateRouteHost(),
        surfaceSize: const Size(393, 852),
        overrides: <Override>[
          placeRepositoryProvider.overrideWithValue(places),
        ],
      );

      await open(tester);
      expect(places.callCount, 1);
      expect(
        find.text(failureCopy),
        findsNothing,
        reason: 'the first entry loaded the catalogue successfully',
      );

      // The catalogue really is available on this first visit.
      await tester.tap(find.text('Kalkış noktası seç'));
      await tester.pumpAndSettle();
      expect(find.text('Yer Bir'), findsWidgets);
      tester.state<NavigatorState>(find.byType(Navigator).last).pop();
      await tester.pumpAndSettle();

      await leave(tester);

      // The tunnel goes away, exactly as it did on the device.
      places.failure = const RmFailure.transport();

      await open(tester);

      expect(places.callCount, 2, reason: 'the reopen must attempt a read');
      expect(
        find.text(failureCopy),
        findsOneWidget,
        reason: 'the member must be told the catalogue could not be read',
      );
      expect(find.text(retryCopy), findsOneWidget);
      expect(
        find.textContaining('Yer Bir'),
        findsNothing,
        reason: 'the previously loaded catalogue must not survive the failure',
      );

      // And the picker offers nothing, rather than offering something stale.
      await tester.tap(find.text('Kalkış noktası seç'));
      await tester.pumpAndSettle();
      expect(
        find.text('Nereden yola çıkıyorsun?'),
        findsNothing,
        reason: 'the picker must not open without a confirmed catalogue',
      );
      expect(find.textContaining('Yer Bir'), findsNothing);
      expectNoFixtureEverywhere();
    });

    testWidgets('staying on the screen does not re-read on rebuild', (
      WidgetTester tester,
    ) async {
      final FakePlaceRepository places = FakePlaceRepository();

      await tester.pumpRm(
        const _CreateRouteHost(),
        surfaceSize: const Size(393, 852),
        overrides: <Override>[
          placeRepositoryProvider.overrideWithValue(places),
        ],
      );

      await open(tester);
      expect(places.callCount, 1);

      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(
        places.callCount,
        1,
        reason: 'a rebuild while still observed must not re-read',
      );
    });
  });

  group('Provider lifecycle, observed through the repository', () {
    /// Disposal is scheduled rather than synchronous, so the test lets
    /// Riverpod's own lifecycle run instead of assuming when it happens.
    test(
      'a new subscription after the last one ends performs one new read',
      () async {
        final FakePlaceRepository places = FakePlaceRepository(
          places: const <Place>[
            Place(id: '01991a00-0000-7000-8000-0000000000c1', label: 'Yer Bir'),
          ],
        );
        final ProviderContainer c = ProviderContainer(
          overrides: <Override>[
            placeRepositoryProvider.overrideWithValue(places),
          ],
        );
        addTearDown(c.dispose);

        final ProviderSubscription<AsyncValue<List<Place>>> first = c
            .listen<AsyncValue<List<Place>>>(
              placeCatalogueProvider,
              (AsyncValue<List<Place>>? _, AsyncValue<List<Place>> _) {},
              fireImmediately: true,
            );
        await c.read(placeCatalogueProvider.future);
        expect(places.callCount, 1);

        // A second listener alongside the first changes nothing.
        final ProviderSubscription<AsyncValue<List<Place>>> second = c
            .listen<AsyncValue<List<Place>>>(
              placeCatalogueProvider,
              (AsyncValue<List<Place>>? _, AsyncValue<List<Place>> _) {},
              fireImmediately: true,
            );
        await pumpEventQueue();
        expect(places.callCount, 1, reason: 'still observed — no new read');

        first.close();
        second.close();
        await pumpEventQueue();

        places.places = const <Place>[
          Place(id: '01991a00-0000-7000-8000-0000000000c2', label: 'Yer İki'),
        ];

        c.listen<AsyncValue<List<Place>>>(
          placeCatalogueProvider,
          (AsyncValue<List<Place>>? _, AsyncValue<List<Place>> _) {},
          fireImmediately: true,
        );
        final List<Place> reread = await c.read(placeCatalogueProvider.future);

        expect(places.callCount, 2, reason: 'exactly one new read, not more');
        expect(
          <String>[for (final Place p in reread) p.label],
          <String>['Yer İki'],
          reason: 'the re-read must expose data the first read could not see',
        );
      },
    );

    /// The retry policy must survive the auto-dispose change: a failed read is
    /// still one request that stays failed until somebody asks again.
    test('noAutomaticRetry is still in force', () async {
      final FakePlaceRepository places = FakePlaceRepository.offline();
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          placeRepositoryProvider.overrideWithValue(places),
        ],
      );
      addTearDown(c.dispose);

      c.listen<AsyncValue<List<Place>>>(
        placeCatalogueProvider,
        (AsyncValue<List<Place>>? _, AsyncValue<List<Place>> _) {},
        fireImmediately: true,
      );
      await pumpEventQueue();

      expect(places.callCount, 1);
      expect(c.read(placeCatalogueProvider).hasError, isTrue);

      // Riverpod's default would have retried on a backoff by now.
      await Future<void>.delayed(const Duration(milliseconds: 700));

      expect(
        places.callCount,
        1,
        reason: 'a failed read must not retry itself',
      );
    });
  });
}

/// A host with a route to push, so the test exercises the real navigation
/// lifecycle — pushing and popping a screen — rather than mounting the widget
/// directly, which would never release the listener the way a pop does.
class _CreateRouteHost extends StatelessWidget {
  const _CreateRouteHost();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext context) => const CreateRouteScreen(),
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
}
