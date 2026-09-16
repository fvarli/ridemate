// ─────────────────────────────────────────────────────────────
// RideMate — The driver's journey feed and one journey's lifecycle
//
// WHAT CARRIES THE WEIGHT: THE DAY IS PART OF THE IDENTITY
//
// A plan may have several journeys, and they are separate things that happen to
// share a route id. So the cases here are mostly about the ways a day can get
// lost: a command that moves every date of a route, a feed that collapses two
// days into one row, an in-flight flag that disables a journey nobody touched.
//
// Each of those looks like working code. The Tuesday that quietly says
// `in_progress` because Monday was started is indistinguishable from a correct
// screen until somebody reads it.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/api/rm_error_code.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/journeys/journey.dart';
import 'package:ridemate/core/routes/departure.dart';
import 'package:ridemate/core/trips/trip_lifecycle.dart';
import 'package:ridemate/features/journeys/application/journeys_providers.dart';
import 'package:ridemate/features/journeys/data/journeys_repository.dart';
import 'package:ridemate/features/journeys/domain/journey_detail.dart';
import 'package:ridemate/features/journeys/domain/my_journeys_page.dart';

import '../../support/fakes.dart';

/// A journeys backend a test can steer, recording exactly what it was asked.
class _FakeJourneys implements JourneysRepository {
  _FakeJourneys({this.pages = const <MyJourneysResult>[]});

  List<MyJourneysResult> pages;

  /// What the dated read answers with, when a test needs a particular journey
  /// rather than the default one for the day it asked about.
  Journey? reads;

  /// What every call named, in order. A null service date would mean this
  /// client asked the server to guess which journey it meant.
  final List<({String verb, String routeId, DepartureDate serviceDate})> calls =
      <({String verb, String routeId, DepartureDate serviceDate})>[];

  final List<String?> cursors = <String?>[];

  /// Which call number fails, and with what.
  int? failAt;
  RmFailure failure = const RmFailure.transport();

  int _pageCalls = 0;

  @override
  Future<MyJourneysResult> page({String? cursor, int limit = 20}) async {
    cursors.add(cursor);

    // No page left to serve is how a test says the next read fails.
    if (pages.isEmpty) throw failure;

    final MyJourneysResult result =
        pages[_pageCalls.clamp(0, pages.length - 1)];
    _pageCalls++;

    return result;
  }

  @override
  Future<Journey> journey({
    required String routeId,
    required DepartureDate serviceDate,
  }) async {
    calls.add((verb: 'read', routeId: routeId, serviceDate: serviceDate));

    return reads ?? fakeJourney(routeId: routeId, serviceDate: serviceDate.iso);
  }

  @override
  Future<TripLifecycle> startTrip({
    required String routeId,
    required DepartureDate serviceDate,
  }) => _command('start', routeId, serviceDate, TripState.inProgress);

  @override
  Future<TripLifecycle> completeTrip({
    required String routeId,
    required DepartureDate serviceDate,
  }) => _command('complete', routeId, serviceDate, TripState.completed);

  @override
  Future<TripLifecycle> abortTrip({
    required String routeId,
    required DepartureDate serviceDate,
  }) => _command('abort', routeId, serviceDate, TripState.aborted);

  Future<TripLifecycle> _command(
    String verb,
    String routeId,
    DepartureDate serviceDate,
    TripState reached,
  ) async {
    calls.add((verb: verb, routeId: routeId, serviceDate: serviceDate));

    if (failAt == calls.length) throw failure;

    return fakeTrip(state: reached, startedAt: '2026-09-16T05:05:00Z');
  }
}

void main() {
  const String routeId = '01991b00-0000-7000-8000-0000000000a1';
  const String otherRoute = '01991b00-0000-7000-8000-0000000000b2';
  const DepartureDate monday = DepartureDate(year: 2026, month: 9, day: 14);
  const DepartureDate tuesday = DepartureDate(year: 2026, month: 9, day: 15);

  JourneyRef refFor(DepartureDate day, [String id = routeId]) =>
      (routeId: id, serviceDate: day);

  ProviderContainer containerWith(_FakeJourneys repo) {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[journeysRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    return container;
  }

  MyJourneysResult onePage(List<Journey> journeys, {String? nextCursor}) =>
      MyJourneysResult(journeys: journeys, nextCursor: nextCursor);

  group('The feed', () {
    test('holds the first page in the order the server sent it', () async {
      final _FakeJourneys repo = _FakeJourneys(
        pages: <MyJourneysResult>[
          onePage(<Journey>[
            fakeJourney(serviceDate: '2026-09-16'),
            fakeJourney(routeId: otherRoute, serviceDate: '2026-09-14'),
          ]),
        ],
      );
      final ProviderContainer container = containerWith(repo);

      final MyJourneysPage page = await container.read(
        myJourneysProvider.future,
      );

      expect(page.journeys.map((Journey j) => j.serviceDate.iso), <String>[
        '2026-09-16',
        '2026-09-14',
      ]);
      expect(page.hasMore, isFalse);
      // The first page asks for no cursor at all.
      expect(repo.cursors, <String?>[null]);
    });

    test('load more sends the cursor back exactly as it arrived', () async {
      const String opaque = 'eyJpdiI6ImFiYy9kZWY=+ghi';
      final _FakeJourneys repo = _FakeJourneys(
        pages: <MyJourneysResult>[
          onePage(<Journey>[
            fakeJourney(serviceDate: '2026-09-16'),
          ], nextCursor: opaque),
          onePage(<Journey>[fakeJourney(serviceDate: '2026-09-15')]),
        ],
      );
      final ProviderContainer container = containerWith(repo);

      await container.read(myJourneysProvider.future);
      await container.read(myJourneysProvider.notifier).loadMore();

      expect(repo.cursors, <String?>[null, opaque]);
      expect(container.read(myJourneysProvider).value!.journeys, hasLength(2));
      expect(container.read(myJourneysProvider).value!.hasMore, isFalse);
    });

    /// CARRIES WEIGHT. Two days of one plan are two journeys.
    ///
    /// The defect this prevents is a feed keyed by route: page two's Monday
    /// would replace page one's Tuesday, and the driver would lose a journey
    /// they can act on with nothing to explain where it went.
    test('two dates of one route both survive paging', () async {
      final _FakeJourneys repo = _FakeJourneys(
        pages: <MyJourneysResult>[
          onePage(<Journey>[
            fakeJourney(serviceDate: '2026-09-15'),
          ], nextCursor: 'c1'),
          onePage(<Journey>[fakeJourney(serviceDate: '2026-09-14')]),
        ],
      );
      final ProviderContainer container = containerWith(repo);

      await container.read(myJourneysProvider.future);
      await container.read(myJourneysProvider.notifier).loadMore();

      expect(
        container
            .read(myJourneysProvider)
            .value!
            .journeys
            .map((Journey j) => j.serviceDate.iso),
        <String>['2026-09-15', '2026-09-14'],
      );
    });

    /// The same journey arriving twice is one row, not two.
    ///
    /// A keyset read concurrent with a command can hand back a row that was
    /// already above. Appended blindly it would be one journey with two Start
    /// controls addressing the same day.
    test('a repeated journey is not appended twice', () async {
      final _FakeJourneys repo = _FakeJourneys(
        pages: <MyJourneysResult>[
          onePage(<Journey>[
            fakeJourney(serviceDate: '2026-09-15'),
          ], nextCursor: 'c1'),
          onePage(<Journey>[
            fakeJourney(serviceDate: '2026-09-15'),
            fakeJourney(serviceDate: '2026-09-14'),
          ]),
        ],
      );
      final ProviderContainer container = containerWith(repo);

      await container.read(myJourneysProvider.future);
      await container.read(myJourneysProvider.notifier).loadMore();

      expect(container.read(myJourneysProvider).value!.journeys, hasLength(2));
    });

    test('a failed second page keeps the first on screen', () async {
      final _FakeJourneys repo = _FakeJourneys(
        pages: <MyJourneysResult>[
          onePage(<Journey>[
            fakeJourney(serviceDate: '2026-09-16'),
          ], nextCursor: 'c1'),
        ],
      );
      final ProviderContainer container = containerWith(repo);
      await container.read(myJourneysProvider.future);

      repo.pages = <MyJourneysResult>[];
      await container.read(myJourneysProvider.notifier).loadMore();

      final MyJourneysPage page = container.read(myJourneysProvider).value!;
      expect(page.journeys, hasLength(1));
      expect(page.loadMoreFailure, isNotNull);
    });
  });

  group('One journey, read by its own identity', () {
    test('the read names the route and the exact day', () async {
      final _FakeJourneys repo = _FakeJourneys();
      final ProviderContainer container = containerWith(repo);

      await container.read(journeyProvider(refFor(tuesday)).future);

      expect(repo.calls.single.verb, 'read');
      expect(repo.calls.single.routeId, routeId);
      expect(repo.calls.single.serviceDate, tuesday);
    });

    /// CARRIES WEIGHT. Two days of one plan are two pieces of state.
    test('two dates of one route are separate provider instances', () async {
      final _FakeJourneys repo = _FakeJourneys();
      final ProviderContainer container = containerWith(repo);

      await container.read(journeyProvider(refFor(monday)).future);
      await container.read(journeyProvider(refFor(tuesday)).future);

      expect(repo.calls.map((_) => true), hasLength(2));
      expect(
        repo.calls.map(
          (({String verb, String routeId, DepartureDate serviceDate}) c) =>
              c.serviceDate,
        ),
        <DepartureDate>[monday, tuesday],
      );
    });
  });

  group('Lifecycle commands name one day', () {
    for (final (String verb, TripState reached) in <(String, TripState)>[
      ('start', TripState.inProgress),
      ('complete', TripState.completed),
      ('abort', TripState.aborted),
    ]) {
      test(
        '$verb addresses the exact journey and records what came back',
        () async {
          final _FakeJourneys repo = _FakeJourneys();
          final ProviderContainer container = containerWith(repo);
          final JourneyRef target = refFor(tuesday);

          await container.read(journeyProvider(target).future);
          final JourneyController controller = container.read(
            journeyProvider(target).notifier,
          );

          final RmFailure? failure = switch (verb) {
            'start' => await controller.start(),
            'complete' => await controller.complete(),
            _ => await controller.abort(),
          };

          expect(failure, isNull);
          expect(repo.calls.last.verb, verb);
          expect(repo.calls.last.routeId, routeId);
          expect(repo.calls.last.serviceDate, tuesday);

          final JourneyDetail detail = container
              .read(journeyProvider(target))
              .value!;
          expect(detail.journey.trip.state, reached);
          expect(detail.isChangingTrip, isFalse);
        },
      );
    }

    /// CARRIES WEIGHT. Starting Monday says nothing about Tuesday.
    test('a command moves its own day and no other', () async {
      final _FakeJourneys repo = _FakeJourneys(
        pages: <MyJourneysResult>[
          onePage(<Journey>[
            fakeJourney(serviceDate: '2026-09-15'),
            fakeJourney(serviceDate: '2026-09-14'),
          ]),
        ],
      );
      final ProviderContainer container = containerWith(repo);

      await container.read(myJourneysProvider.future);
      await container.read(journeyProvider(refFor(monday)).future);
      await container.read(journeyProvider(refFor(monday)).notifier).start();

      final MyJourneysPage page = container.read(myJourneysProvider).value!;

      expect(
        page.journeys
            .firstWhere((Journey j) => j.serviceDate == monday)
            .trip
            .state,
        TripState.inProgress,
      );
      expect(
        page.journeys
            .firstWhere((Journey j) => j.serviceDate == tuesday)
            .trip
            .state,
        TripState.notStarted,
        reason: 'starting Monday moved Tuesday',
      );
    });

    /// And nothing is written for a route that merely shares an id.
    test('a command does not touch another route on the same day', () async {
      final _FakeJourneys repo = _FakeJourneys(
        pages: <MyJourneysResult>[
          onePage(<Journey>[
            fakeJourney(serviceDate: '2026-09-14'),
            fakeJourney(routeId: otherRoute, serviceDate: '2026-09-14'),
          ]),
        ],
      );
      final ProviderContainer container = containerWith(repo);

      await container.read(myJourneysProvider.future);
      await container.read(journeyProvider(refFor(monday)).future);
      await container.read(journeyProvider(refFor(monday)).notifier).start();

      final MyJourneysPage page = container.read(myJourneysProvider).value!;

      expect(
        page.journeys
            .firstWhere((Journey j) => j.routeId == otherRoute)
            .trip
            .state,
        TripState.notStarted,
      );
    });

    /// CARRIES WEIGHT. A refusal leaves the journey exactly as it was.
    ///
    /// A journey the backend would not start is not a journey that started.
    test('a refusal changes nothing and is handed back', () async {
      final _FakeJourneys repo = _FakeJourneys()
        ..failAt = 2
        ..failure = const RmFailure.fromBackend(
          status: 409,
          code: RmErrorCode.conflict,
          reason: 'departure_not_reached',
        );
      final ProviderContainer container = containerWith(repo);
      final JourneyRef target = refFor(tuesday);

      await container.read(journeyProvider(target).future);
      final RmFailure? failure = await container
          .read(journeyProvider(target).notifier)
          .start();

      expect(failure, isNotNull);

      final JourneyDetail detail = container
          .read(journeyProvider(target))
          .value!;
      expect(detail.journey.trip.state, TripState.notStarted);
      expect(detail.isChangingTrip, isFalse);
    });

    /// A journey the feed does not hold is not invented into it.
    test('a command on a day outside the feed adds no row', () async {
      final _FakeJourneys repo = _FakeJourneys(
        pages: <MyJourneysResult>[
          onePage(<Journey>[fakeJourney(serviceDate: '2026-09-14')]),
        ],
      );
      final ProviderContainer container = containerWith(repo);

      await container.read(myJourneysProvider.future);
      await container.read(journeyProvider(refFor(tuesday)).future);
      await container.read(journeyProvider(refFor(tuesday)).notifier).start();

      expect(container.read(myJourneysProvider).value!.journeys, hasLength(1));
    });
  });
}
