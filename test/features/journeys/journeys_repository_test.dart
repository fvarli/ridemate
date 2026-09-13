// ─────────────────────────────────────────────────────────────
// RideMate — The driver's dated journeys, at the wire
//
// WHAT CARRIES THE WEIGHT HERE IS THE PATH
//
// A journey is `(routeId, serviceDate)` and has no id, so the address IS the
// identity. A command that dropped the day, or spelled it differently from the
// read beside it, would act on a journey nobody named — and would look exactly
// like a correct call, because a route id and a plausible answer are
// indistinguishable from the right ones until somebody notices the wrong day
// was started.
//
// So every method's exact path is pinned, and the three commands are pinned
// against each other.
// ─────────────────────────────────────────────────────────────

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ridemate/core/api/rm_api_client.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/journeys/journey.dart';
import 'package:ridemate/core/routes/departure.dart';
import 'package:ridemate/core/routes/published_route.dart';
import 'package:ridemate/core/trips/trip_lifecycle.dart';
import 'package:ridemate/features/journeys/data/journeys_repository.dart';

import '../../support/fakes.dart';

void main() {
  const String routeId = '01991b00-0000-7000-8000-0000000000a1';
  const DepartureDate day = DepartureDate(year: 2026, month: 9, day: 16);

  late List<http.Request> sent;

  ApiJourneysRepository repositoryOver(
    Future<http.Response> Function(http.Request) handler,
  ) {
    sent = <http.Request>[];

    return ApiJourneysRepository(
      client: RmApiClient(
        transport: MockClient((http.Request request) {
          sent.add(request);

          return handler(request);
        }),
        baseUrl: Uri.parse('https://ridemate.test'),
      ),
      session: FakeSession(),
    );
  }

  http.Response json(Object? body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: <String, String>{'content-type': 'application/json'},
  );

  Map<String, Object?> journeyJson({
    String id = routeId,
    String serviceDate = '2026-09-16',
    String routeStatus = 'published',
    TripState trip = TripState.notStarted,
  }) => <String, Object?>{
    'route_id': id,
    'service_date': serviceDate,
    'origin': <String, Object?>{'id': 'p1', 'label': 'Kadıköy'},
    'destination': <String, Object?>{'id': 'p2', 'label': 'Levent'},
    'departure_time': '08:25',
    'timezone': 'Europe/Istanbul',
    'route_status': routeStatus,
    'trip': fakeTripJson(state: trip),
  };

  group('The feed', () {
    test('asks the documented path with the two paging parameters', () async {
      final ApiJourneysRepository repository = repositoryOver(
        (_) async => json(<String, Object?>{
          'journeys': <Object?>[],
          'next_cursor': null,
        }),
      );

      await repository.page(limit: 5);

      expect(sent.single.method, 'GET');
      expect(sent.single.url.path, '/api/v1/me/journeys');
      expect(sent.single.url.queryParameters, <String, String>{'limit': '5'});
    });

    /// The cursor goes back exactly as it arrived. Nothing decodes, trims or
    /// re-encodes one: what it holds is free to change, and a client that read
    /// it would depend on a query it cannot see.
    test('a cursor is echoed back verbatim', () async {
      const String cursor = 'eyJ2IjoxfQ==.opaque+/=';
      final ApiJourneysRepository repository = repositoryOver(
        (_) async => json(<String, Object?>{
          'journeys': <Object?>[],
          'next_cursor': null,
        }),
      );

      await repository.page(cursor: cursor);

      expect(sent.single.url.queryParameters['cursor'], cursor);
    });

    test('no cursor parameter is sent on the first page', () async {
      final ApiJourneysRepository repository = repositoryOver(
        (_) async => json(<String, Object?>{
          'journeys': <Object?>[],
          'next_cursor': null,
        }),
      );

      await repository.page();

      expect(sent.single.url.queryParameters.containsKey('cursor'), isFalse);
    });

    test('rows decode in the order the server sent them', () async {
      final ApiJourneysRepository repository = repositoryOver(
        (_) async => json(<String, Object?>{
          'journeys': <Object?>[
            journeyJson(serviceDate: '2026-09-16'),
            journeyJson(serviceDate: '2026-09-15', trip: TripState.inProgress),
          ],
          'next_cursor': 'next',
        }),
      );

      final MyJourneysResult result = await repository.page();

      expect(
        result.journeys.map((Journey j) => j.serviceDate.iso).toList(),
        <String>['2026-09-16', '2026-09-15'],
      );
      expect(result.journeys.last.trip.state, TripState.inProgress);
      expect(result.nextCursor, 'next');
    });

    /// Null is the end; an empty page is not. Stopping on an empty list would
    /// sometimes hide a driver's own journeys from them.
    test('an absent next_cursor fails, and a null one is the end', () async {
      final ApiJourneysRepository missing = repositoryOver(
        (_) async => json(<String, Object?>{'journeys': <Object?>[]}),
      );

      await expectLater(missing.page(), throwsA(isA<RmFailure>()));

      final ApiJourneysRepository ended = repositoryOver(
        (_) async => json(<String, Object?>{
          'journeys': <Object?>[],
          'next_cursor': null,
        }),
      );

      expect((await ended.page()).nextCursor, isNull);
    });

    /// A row that will not decode fails the page rather than being skipped: a
    /// list quietly short is one the driver cannot explain.
    test('one unreadable row fails the whole page', () async {
      final ApiJourneysRepository repository = repositoryOver(
        (_) async => json(<String, Object?>{
          'journeys': <Object?>[
            journeyJson(),
            journeyJson()..remove('service_date'),
          ],
          'next_cursor': null,
        }),
      );

      await expectLater(repository.page(), throwsA(isA<RmFailure>()));
    });
  });

  group('The dated read', () {
    /// CARRIES WEIGHT. The day is in the path, spelled as the contract does.
    test('addresses the journey by route and service date', () async {
      final ApiJourneysRepository repository = repositoryOver(
        (_) async => json(journeyJson()),
      );

      final Journey journey = await repository.journey(
        routeId: routeId,
        serviceDate: day,
      );

      expect(sent.single.method, 'GET');
      expect(
        sent.single.url.path,
        '/api/v1/routes/$routeId/journeys/2026-09-16',
      );
      expect(journey.routeId, routeId);
      expect(journey.serviceDate, day);
    });

    /// The day travels as `YYYY-MM-DD` and nothing else — never an instant,
    /// never a locale format, never zero-padded differently.
    test('a single-digit month and day are padded in the path', () async {
      final ApiJourneysRepository repository = repositoryOver(
        (_) async => json(journeyJson(serviceDate: '2026-01-05')),
      );

      await repository.journey(
        routeId: routeId,
        serviceDate: const DepartureDate(year: 2026, month: 1, day: 5),
      );

      expect(
        sent.single.url.path,
        '/api/v1/routes/$routeId/journeys/2026-01-05',
      );
    });

    test('the body is the journey itself, with no envelope', () async {
      final ApiJourneysRepository repository = repositoryOver(
        (_) async => json(journeyJson(routeStatus: 'cancelled')),
      );

      final Journey journey = await repository.journey(
        routeId: routeId,
        serviceDate: day,
      );

      expect(journey.routeStatus, RouteStatus.cancelled);
    });
  });

  group('The dated commands', () {
    /// CARRIES WEIGHT. Every command names the day, and names it the same way.
    ///
    /// The failure this pins is a command that dropped the date and fell back
    /// to the route-only endpoint — which exists, answers 200, and means
    /// something else entirely: a one-off route's single journey, or a refusal
    /// for a plan. Nothing in the response would say which happened.
    test('each verb posts to its own dated path', () async {
      for (final (
            String verb,
            Future<TripLifecycle> Function(ApiJourneysRepository) call,
          )
          in <(String, Future<TripLifecycle> Function(ApiJourneysRepository))>[
            (
              'start',
              (ApiJourneysRepository r) =>
                  r.startTrip(routeId: routeId, serviceDate: day),
            ),
            (
              'complete',
              (ApiJourneysRepository r) =>
                  r.completeTrip(routeId: routeId, serviceDate: day),
            ),
            (
              'abort',
              (ApiJourneysRepository r) =>
                  r.abortTrip(routeId: routeId, serviceDate: day),
            ),
          ]) {
        final ApiJourneysRepository repository = repositoryOver(
          (_) async => json(<String, Object?>{
            'trip': fakeTripJson(state: TripState.inProgress),
          }),
        );

        await call(repository);

        expect(sent.single.method, 'POST', reason: verb);
        expect(
          sent.single.url.path,
          '/api/v1/routes/$routeId/journeys/2026-09-16/trip/$verb',
          reason: verb,
        );
        // Bodyless: each names its own target state, so nothing is needed to
        // make a retry safe. No Idempotency-Key, no expected_status.
        expect(sent.single.body, isEmpty, reason: verb);
      }
    });

    /// Start is the only one that can create, so it is the only one that may
    /// answer 201. The lifecycle in the body is the truth either way.
    test('start accepts 201 and 200, and the others only 200', () async {
      for (final int status in <int>[201, 200]) {
        final ApiJourneysRepository repository = repositoryOver(
          (_) async => json(<String, Object?>{
            'trip': fakeTripJson(state: TripState.inProgress),
          }, status),
        );

        expect(
          (await repository.startTrip(
            routeId: routeId,
            serviceDate: day,
          )).state,
          TripState.inProgress,
          reason: '$status',
        );
      }

      final ApiJourneysRepository created = repositoryOver(
        (_) async => json(<String, Object?>{
          'trip': fakeTripJson(state: TripState.completed),
        }, 201),
      );

      // A 201 from Complete is not this contract: nothing was created.
      await expectLater(
        created.completeTrip(routeId: routeId, serviceDate: day),
        throwsA(isA<RmFailure>()),
      );
    });

    test('the lifecycle is read from the envelope', () async {
      final ApiJourneysRepository repository = repositoryOver(
        (_) async => json(<String, Object?>{
          'trip': fakeTripJson(
            state: TripState.aborted,
            startedAt: '2026-09-16T05:25:00Z',
            abortedAt: '2026-09-16T06:00:00Z',
          ),
        }),
      );

      final TripLifecycle trip = await repository.abortTrip(
        routeId: routeId,
        serviceDate: day,
      );

      expect(trip.state, TripState.aborted);
      expect(trip.startedAt, DateTime.utc(2026, 9, 16, 5, 25));
      expect(trip.abortedAt, DateTime.utc(2026, 9, 16, 6));
      expect(trip.completedAt, isNull);
    });
  });
}
