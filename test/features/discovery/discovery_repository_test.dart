// ─────────────────────────────────────────────────────────────
// RideMate — Reading other members' journeys, at the wire
//
// Two things carry the weight. What the request SENDS, because the endpoint
// refuses unknown parameters and a client that sent a filter would be told so
// at the worst possible moment. And what the response is allowed to be, because
// this is the one surface where another member's identity arrives.
// ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ridemate/core/api/rm_api_client.dart';
import 'package:ridemate/core/api/rm_error_code.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/routes/departure.dart';
import 'package:ridemate/core/routes/discovered_route.dart';
import 'package:ridemate/core/routes/published_route.dart';
import 'package:ridemate/core/routes/ride_rule.dart';
import 'package:ridemate/features/discovery/data/discovery_repository.dart';

import '../../support/fakes.dart';

void main() {
  late List<http.Request> sent;
  late FakeSession session;

  ApiDiscoveryRepository repositoryOver(
    Future<http.Response> Function(http.Request) handler,
  ) {
    sent = <http.Request>[];
    session = FakeSession();

    return ApiDiscoveryRepository(
      client: RmApiClient(
        transport: MockClient((http.Request request) {
          sent.add(request);

          return handler(request);
        }),
        baseUrl: Uri.parse('https://ridemate.test'),
      ),
      session: session,
    );
  }

  http.Response json(Object? body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: <String, String>{'content-type': 'application/json'},
  );

  /// One result exactly as the committed contract publishes it.
  Map<String, Object?> result({
    String id = '01991b00-0000-7000-8000-0000000000a1',
    String recurrence = 'weekdays',
    Object? departureDate,
    List<Map<String, Object?>> mySeatRequests = const <Map<String, Object?>>[],
  }) => <String, Object?>{
    'id': id,
    'origin': <String, Object?>{'id': 'p1', 'label': 'Kadıköy'},
    'destination': <String, Object?>{'id': 'p2', 'label': 'Levent'},
    'recurrence': recurrence,
    'departure_date': departureDate,
    'departure_time': '08:25',
    'timezone': 'Europe/Istanbul',
    'departure_state': 'upcoming',
    'seats_offered': 3,
    'rules': <String, Object?>{
      'no_smoking': true,
      'music_ok': false,
      'no_pets': false,
      'quiet': false,
    },
    'driver': <String, Object?>{
      'display_name': 'İrem Yılmaz',
      'initials': 'İY',
    },
    // Required on the wire and possibly empty: the caller has asked about none
    // of this route's journeys. Absent is not the same as empty — the
    // missing-field loop below proves that.
    'my_seat_requests': mySeatRequests,
  };

  Map<String, Object?> page(List<Object?> routes, {String? nextCursor}) =>
      <String, Object?>{'routes': routes, 'next_cursor': nextCursor};

  group('The request', () {
    test(
      'asks the documented path with exactly the accepted parameters',
      () async {
        final ApiDiscoveryRepository repository = repositoryOver(
          (_) async => json(page(<Object?>[])),
        );

        await repository.between(originPlaceId: 'p1', destinationPlaceId: 'p2');

        expect(sent, hasLength(1));
        expect(sent.single.method, 'GET');
        expect(sent.single.url.path, '/api/v1/routes/discover');
        expect(sent.single.url.queryParameters, <String, String>{
          'origin_place_id': 'p1',
          'destination_place_id': 'p2',
          'limit': '20',
        });
      },
    );

    /// CARRIES WEIGHT. The endpoint refuses unknown parameters, so anything
    /// extra here would turn every search into a 422.
    test('sends nothing the endpoint would refuse', () async {
      final ApiDiscoveryRepository repository = repositoryOver(
        (_) async => json(page(<Object?>[])),
      );

      await repository.between(originPlaceId: 'p1', destinationPlaceId: 'p2');

      for (final String forbidden in <String>[
        'seats',
        'sort',
        'date',
        'departure_date',
        'radius',
        'distance',
        'latitude',
        'longitude',
        'lat',
        'lng',
        'recurrence',
        'filters',
        'compatibility',
        'preferences',
        'cost',
        'max_cost',
      ]) {
        expect(
          sent.single.url.queryParameters.containsKey(forbidden),
          isFalse,
          reason: forbidden,
        );
      }
    });

    test('sends the cursor only when there is one, and verbatim', () async {
      final ApiDiscoveryRepository repository = repositoryOver(
        (_) async => json(page(<Object?>[])),
      );

      // An opaque token with characters that must survive untouched.
      const String opaque = 'eyJpdiI6ImFiYy9kZWY=+ghi';

      await repository.between(
        originPlaceId: 'p1',
        destinationPlaceId: 'p2',
        cursor: opaque,
      );

      expect(sent.single.url.queryParameters['cursor'], opaque);
    });

    test('travels through the authenticated seam', () async {
      final ApiDiscoveryRepository repository = repositoryOver(
        (_) async => json(page(<Object?>[])),
      );

      await repository.between(originPlaceId: 'p1', destinationPlaceId: 'p2');

      expect(sent.single.headers['Authorization'], startsWith('Bearer '));
    });
  });

  group('The result', () {
    test('decodes exactly the documented projection', () async {
      final ApiDiscoveryRepository repository = repositoryOver(
        (_) async => json(page(<Object?>[result()])),
      );

      final DiscoveryResult found = await repository.between(
        originPlaceId: 'p1',
        destinationPlaceId: 'p2',
      );

      expect(found.routes, hasLength(1));
      final DiscoveredRoute route = found.routes.single;

      expect(route.id, '01991b00-0000-7000-8000-0000000000a1');
      expect(route.origin.label, 'Kadıköy');
      expect(route.destination.label, 'Levent');
      expect(route.recurrence, Recurrence.weekdays);
      expect(route.departureDate, isNull);
      expect(route.departureTime, const DepartureTime(hour: 8, minute: 25));
      expect(route.timezone, 'Europe/Istanbul');
      expect(route.departureState, DepartureState.upcoming);
      expect(route.seatsOffered, 3);
      expect(route.rules, <RideRuleId>{RideRuleId.noSmoking});
      expect(route.driver.displayName, 'İrem Yılmaz');
      // Read, never derived. `IY` would mean somebody recomputed it.
      expect(route.driver.initials, 'İY');
    });

    test('a one-off carries its date, a weekday route carries null', () async {
      final ApiDiscoveryRepository repository = repositoryOver(
        (_) async => json(
          page(<Object?>[
            result(recurrence: 'once', departureDate: '2026-09-14'),
            result(id: 'b'),
          ]),
        ),
      );

      final DiscoveryResult found = await repository.between(
        originPlaceId: 'p1',
        destinationPlaceId: 'p2',
      );

      expect(
        found.routes[0].departureDate,
        const DepartureDate(year: 2026, month: 9, day: 14),
      );
      expect(found.routes[1].departureDate, isNull);
    });

    test('the cursor is carried through opaquely', () async {
      const String opaque = 'eyJpdiI6IngveSt6In0=';
      final ApiDiscoveryRepository repository = repositoryOver(
        (_) async => json(page(<Object?>[result()], nextCursor: opaque)),
      );

      expect(
        (await repository.between(
          originPlaceId: 'p1',
          destinationPlaceId: 'p2',
        )).nextCursor,
        opaque,
      );
    });

    test('a null cursor is the end of the list', () async {
      final ApiDiscoveryRepository repository = repositoryOver(
        (_) async => json(page(<Object?>[result()])),
      );

      expect(
        (await repository.between(
          originPlaceId: 'p1',
          destinationPlaceId: 'p2',
        )).nextCursor,
        isNull,
      );
    });

    /// An empty page is a real answer: the server found nothing between those
    /// two places. It is not a failure and not a fallback.
    test('an empty page decodes to no routes', () async {
      final ApiDiscoveryRepository repository = repositoryOver(
        (_) async => json(page(<Object?>[])),
      );

      final DiscoveryResult found = await repository.between(
        originPlaceId: 'p1',
        destinationPlaceId: 'p2',
      );

      expect(found.routes, isEmpty);
      expect(found.nextCursor, isNull);
    });
  });

  group('Strict decoding', () {
    final Map<String, Object?> bad = <String, Object?>{
      'no routes key': <String, Object?>{'next_cursor': null},
      'routes is not a list': <String, Object?>{
        'routes': 'nope',
        'next_cursor': null,
      },
      'a row is not an object': <String, Object?>{
        'routes': <Object?>['nope'],
        'next_cursor': null,
      },
      'a cursor that is not a string': <String, Object?>{
        'routes': <Object?>[],
        'next_cursor': 7,
      },
    };

    bad.forEach((String label, Object? body) {
      test('$label fails the whole response', () async {
        final ApiDiscoveryRepository repository = repositoryOver(
          (_) async => json(body),
        );

        await expectLater(
          repository.between(originPlaceId: 'p1', destinationPlaceId: 'p2'),
          throwsA(isA<RmFailure>()),
        );
      });
    });

    /// CARRIES WEIGHT. `departure_date` is always present on the wire, null for
    /// a recurring journey. A MISSING key is drift, not a weekday route.
    test('a missing departure_date is refused, not read as weekdays', () async {
      final Map<String, Object?> row = result()..remove('departure_date');
      final ApiDiscoveryRepository repository = repositoryOver(
        (_) async => json(page(<Object?>[row])),
      );

      await expectLater(
        repository.between(originPlaceId: 'p1', destinationPlaceId: 'p2'),
        throwsA(isA<RmFailure>()),
      );
    });

    /// Each required field, removed one at a time, so a failure names which.
    for (final String field in <String>[
      'id',
      'origin',
      'destination',
      'recurrence',
      'departure_time',
      'timezone',
      'departure_state',
      'seats_offered',
      'rules',
      'driver',
      'my_seat_requests',
    ]) {
      test('a row missing $field fails the response', () async {
        final Map<String, Object?> row = result()..remove(field);
        final ApiDiscoveryRepository repository = repositoryOver(
          (_) async => json(page(<Object?>[row])),
        );

        await expectLater(
          repository.between(originPlaceId: 'p1', destinationPlaceId: 'p2'),
          throwsA(isA<RmFailure>()),
        );
      });
    }

    test('a driver missing either field fails the response', () async {
      for (final Map<String, Object?> driver in <Map<String, Object?>>[
        <String, Object?>{'display_name': 'İrem'},
        <String, Object?>{'initials': 'İY'},
        <String, Object?>{'display_name': '', 'initials': 'İY'},
        <String, Object?>{'display_name': 'İrem', 'initials': ''},
      ]) {
        final Map<String, Object?> row = result();
        row['driver'] = driver;

        final ApiDiscoveryRepository repository = repositoryOver(
          (_) async => json(page(<Object?>[row])),
        );

        await expectLater(
          repository.between(originPlaceId: 'p1', destinationPlaceId: 'p2'),
          throwsA(isA<RmFailure>()),
        );
      }
    });

    /// A malformed 2xx keeps its real status, which is what makes it
    /// distinguishable from a deterministic 4xx despite both being
    /// `unexpected`.
    test('a malformed 200 keeps its status', () async {
      final ApiDiscoveryRepository repository = repositoryOver(
        (_) async => json(<String, Object?>{'nope': true}),
      );

      await expectLater(
        repository.between(originPlaceId: 'p1', destinationPlaceId: 'p2'),
        throwsA(
          isA<RmFailure>()
              .having((RmFailure f) => f.status, 'status', 200)
              .having((RmFailure f) => f.code, 'code', RmErrorCode.unexpected),
        ),
      );
    });
  });

  group('Failures stay failures', () {
    /// CARRIES WEIGHT. A failed search must never look like "nothing found".
    for (final (String label, Future<http.Response> Function() respond)
        in <(String, Future<http.Response> Function())>[
          (
            'an unreachable backend',
            () async => throw const SocketException('x'),
          ),
          (
            'a server error',
            () async => json(<String, Object?>{
              'error': <String, Object?>{'code': 'internal_error'},
            }, 500),
          ),
          (
            'a validation failure',
            () async => json(<String, Object?>{
              'error': <String, Object?>{'code': 'validation_failed'},
            }, 422),
          ),
        ]) {
      test('$label throws rather than returning an empty page', () async {
        final ApiDiscoveryRepository repository = repositoryOver(
          (_) async => respond(),
        );

        await expectLater(
          repository.between(originPlaceId: 'p1', destinationPlaceId: 'p2'),
          throwsA(isA<RmFailure>()),
        );
      });

      /// And none of them is a sign-out. Phase 9 owns the credential.
      test('$label leaves the member signed in', () async {
        final ApiDiscoveryRepository repository = repositoryOver(
          (_) async => respond(),
        );

        await repository
            .between(originPlaceId: 'p1', destinationPlaceId: 'p2')
            .then<void>((_) {}, onError: (Object _) {});

        expect(session.isSignedIn, isTrue);
        expect(session.signedOutReason, isNull);
      });
    }
  });
}
