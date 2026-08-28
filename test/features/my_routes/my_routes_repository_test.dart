import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ridemate/core/api/rm_api_client.dart';
import 'package:ridemate/core/api/rm_error_code.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/routes/departure.dart';
import 'package:ridemate/core/routes/published_route.dart';
import 'package:ridemate/core/routes/ride_rule.dart';
import 'package:ridemate/features/my_routes/data/my_routes_repository.dart';

import '../../support/fakes.dart';

/// Reading and withdrawing the member's own journeys, over the wire.
void main() {
  late List<http.Request> sent;

  ApiMyRoutesRepository repositoryOver(
    Future<http.Response> Function(http.Request) handler,
  ) {
    sent = <http.Request>[];

    return ApiMyRoutesRepository(
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

  Map<String, Object?> route({
    String id = '01991b00-0000-7000-8000-000000000001',
    String recurrence = 'weekdays',
    Object? departureDate,
    String status = 'published',
    String departureState = 'upcoming',
    Object? cancelledAt,
  }) => <String, Object?>{
    'id': id,
    'origin': <String, Object?>{
      'id': '01991a00-0000-7000-8000-00000000000a',
      'label': 'Kadıköy, Vapur İskelesi',
    },
    'destination': <String, Object?>{
      'id': '01991a00-0000-7000-8000-00000000000b',
      'label': 'Levent, Metro İstasyonu',
    },
    'recurrence': recurrence,
    'departure_date': departureDate,
    'departure_time': '08:25',
    'timezone': 'Europe/Istanbul',
    'departure_state': departureState,
    'seats_offered': 3,
    'rules': <String, Object?>{
      'no_smoking': true,
      'music_ok': false,
      'no_pets': false,
      'quiet': true,
    },
    'status': status,
    'published_at': '2026-08-28T09:41:00+00:00',
    'cancelled_at': cancelledAt,
  };

  http.Response ok(Object? body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: <String, String>{'content-type': 'application/json'},
  );

  http.Response refusal(int status, String code) => http.Response(
    jsonEncode(<String, Object?>{
      'error': <String, Object?>{
        'code': code,
        'message': 'developer facing',
        'request_id': '00000000-0000-7000-8000-000000000009',
      },
    }),
    status,
    headers: <String, String>{'content-type': 'application/json'},
  );

  group('Asking for a page', () {
    test('uses the documented path and the contract default', () async {
      final ApiMyRoutesRepository repository = repositoryOver(
        (_) async =>
            ok(<String, Object?>{'routes': <Object?>[], 'next_cursor': null}),
      );

      await repository.page();

      expect(sent, hasLength(1));
      expect(sent.single.method, 'GET');
      expect(sent.single.url.path, '/api/v1/me/routes');
      expect(sent.single.url.queryParameters['limit'], '20');
      expect(kMyRoutesPageSize, 20);
    });

    /// The first page names no position, because there is not one yet.
    test('the first page carries no cursor at all', () async {
      final ApiMyRoutesRepository repository = repositoryOver(
        (_) async =>
            ok(<String, Object?>{'routes': <Object?>[], 'next_cursor': null}),
      );

      await repository.page();

      expect(sent.single.url.queryParameters.containsKey('cursor'), isFalse);
    });

    /// CARRIES WEIGHT. The cursor goes back exactly as it arrived.
    ///
    /// It is the server's own token over its own ordering. Trimming, decoding,
    /// re-encoding or "normalising" it would be this client having an opinion
    /// about a format it is explicitly told not to read.
    test('the next page sends the token back byte for byte', () async {
      // Deliberately full of things a client might be tempted to tidy: base64
      // padding, a plus, a slash, and mixed case.
      const String token = 'eyJ2IjoxfQ==+slash/AND==';

      final ApiMyRoutesRepository repository = repositoryOver(
        (_) async =>
            ok(<String, Object?>{'routes': <Object?>[], 'next_cursor': null}),
      );

      await repository.page(cursor: token);

      expect(sent.single.url.queryParameters['cursor'], token);
    });

    test('travels through the authenticated seam', () async {
      final ApiMyRoutesRepository repository = repositoryOver(
        (_) async =>
            ok(<String, Object?>{'routes': <Object?>[], 'next_cursor': null}),
      );

      await repository.page();

      expect(sent.single.headers['Authorization'], startsWith('Bearer '));
    });
  });

  group('Reading a page', () {
    test('decodes routes in the order the server sent them', () async {
      final ApiMyRoutesRepository repository = repositoryOver(
        (_) async => ok(<String, Object?>{
          'routes': <Object?>[
            route(id: '01991b00-0000-7000-8000-000000000001'),
            route(id: '01991b00-0000-7000-8000-000000000002'),
            route(id: '01991b00-0000-7000-8000-000000000003'),
          ],
          'next_cursor': 'more',
        }),
      );

      final MyRoutesResult result = await repository.page();

      expect(
        <String>[for (final PublishedRoute r in result.routes) r.id],
        <String>[
          '01991b00-0000-7000-8000-000000000001',
          '01991b00-0000-7000-8000-000000000002',
          '01991b00-0000-7000-8000-000000000003',
        ],
      );
      expect(result.nextCursor, 'more');
    });

    test('decodes the projection completely', () async {
      final ApiMyRoutesRepository repository = repositoryOver(
        (_) async => ok(<String, Object?>{
          'routes': <Object?>[
            route(recurrence: 'once', departureDate: '2099-04-01'),
          ],
          'next_cursor': null,
        }),
      );

      final PublishedRoute r = (await repository.page()).routes.single;

      expect(r.origin.label, 'Kadıköy, Vapur İskelesi');
      expect(r.destination.label, 'Levent, Metro İstasyonu');
      expect(r.recurrence, Recurrence.once);
      expect(
        r.departureDate,
        const DepartureDate(year: 2099, month: 4, day: 1),
      );
      expect(r.departureTime, const DepartureTime(hour: 8, minute: 25));
      expect(r.timezone, 'Europe/Istanbul');
      expect(r.departureState, DepartureState.upcoming);
      expect(r.seatsOffered, 3);
      expect(r.rules, <RideRuleId>{RideRuleId.noSmoking, RideRuleId.quiet});
      expect(r.status, RouteStatus.published);
      expect(r.cancelledAt, isNull);
    });

    /// CARRIES WEIGHT. Only a null cursor ends the list.
    ///
    /// The contract says so explicitly. A page can come back empty with more
    /// behind it, and a client that stopped there would hide a member's own
    /// routes from them with no error and nothing to notice.
    test('an empty page is not the end unless the cursor says so', () async {
      final ApiMyRoutesRepository repository = repositoryOver(
        (_) async => ok(<String, Object?>{
          'routes': <Object?>[],
          'next_cursor': 'keep going',
        }),
      );

      final MyRoutesResult result = await repository.page();

      expect(result.routes, isEmpty);
      expect(result.nextCursor, 'keep going');
    });

    test('a null cursor is the end', () async {
      final ApiMyRoutesRepository repository = repositoryOver(
        (_) async => ok(<String, Object?>{
          'routes': <Object?>[route()],
          'next_cursor': null,
        }),
      );

      expect((await repository.page()).nextCursor, isNull);
    });
  });

  group('What a page refuses', () {
    /// CARRIES WEIGHT. One bad row fails the page.
    ///
    /// Skipping it would leave the list quietly short, and the member is the
    /// one person who would notice a journey missing and have no way to
    /// explain it.
    test('a malformed route fails the whole page', () async {
      for (final Object? broken in <Object?>[
        'not an object',
        <String, Object?>{'id': 'x'},
        route()..remove('rules'),
        <String, Object?>{...route(), 'seats_offered': '3'},
        <String, Object?>{...route(), 'status': 'expired'},
        <String, Object?>{...route(), 'departure_state': 'imminent'},
        <String, Object?>{
          ...route(),
          'rules': <String, Object?>{'no_smoking': true},
        },
      ]) {
        final ApiMyRoutesRepository repository = repositoryOver(
          (_) async => ok(<String, Object?>{
            'routes': <Object?>[route(), broken],
            'next_cursor': null,
          }),
        );

        await expectLater(
          repository.page(),
          throwsA(isA<RmFailure>()),
          reason: '$broken',
        );
      }
    });

    test('an envelope that is not a page fails', () async {
      for (final Object? body in <Object?>[
        <String, Object?>{'routes': 'lots', 'next_cursor': null},
        // Absent is not null: a response missing the key is not this contract,
        // and reading it as "the end" would silently truncate the list.
        <String, Object?>{'routes': <Object?>[]},
        <String, Object?>{'next_cursor': null},
        <String, Object?>{'routes': <Object?>[], 'next_cursor': 7},
      ]) {
        final ApiMyRoutesRepository repository = repositoryOver(
          (_) async => ok(body),
        );

        await expectLater(
          repository.page(),
          throwsA(isA<RmFailure>()),
          reason: jsonEncode(body),
        );
      }
    });

    test('the documented refusals surface with their codes', () async {
      for (final (int status, String code, RmErrorCode expected)
          in <(int, String, RmErrorCode)>[
            (401, 'unauthenticated', RmErrorCode.unauthenticated),
            (403, 'forbidden', RmErrorCode.forbidden),
            (422, 'validation_failed', RmErrorCode.validationFailed),
          ]) {
        final ApiMyRoutesRepository repository = repositoryOver(
          (_) async => refusal(status, code),
        );

        await expectLater(
          repository.page(),
          throwsA(
            isA<RmFailure>().having((RmFailure f) => f.code, 'code', expected),
          ),
          reason: '$status',
        );
      }
    });

    test('an unreachable backend is a transport failure', () async {
      final ApiMyRoutesRepository repository = repositoryOver(
        (_) async => throw const SocketException('no route to host'),
      );

      await expectLater(
        repository.page(),
        throwsA(
          isA<RmFailure>().having(
            (RmFailure f) => f.isTransport,
            'isTransport',
            isTrue,
          ),
        ),
      );
    });
  });

  group('Cancelling', () {
    test('posts to exactly the documented path', () async {
      final ApiMyRoutesRepository repository = repositoryOver(
        (_) async => ok(<String, Object?>{
          'route': route(
            status: 'cancelled',
            cancelledAt: '2026-08-28T10:00:00+00:00',
          ),
        }),
      );

      await repository.cancel('01991b00-0000-7000-8000-000000000001');

      expect(sent.single.method, 'POST');
      expect(
        sent.single.url.path,
        '/api/v1/routes/01991b00-0000-7000-8000-000000000001/cancel',
      );
      expect(sent.single.url.queryParameters, isEmpty);
    });

    /// CARRIES WEIGHT. The transition names its own target state, so it needs
    /// nothing to make it safe — no body, no expected status, no key.
    test('sends no body and no idempotency header', () async {
      final ApiMyRoutesRepository repository = repositoryOver(
        (_) async => ok(<String, Object?>{'route': route(status: 'cancelled')}),
      );

      await repository.cancel('01991b00-0000-7000-8000-000000000001');

      expect(sent.single.body, isEmpty);

      final Set<String> headers = sent.single.headers.keys
          .map((String k) => k.toLowerCase())
          .toSet();

      expect(headers, isNot(contains('idempotency-key')));
      expect(sent.single.headers['Authorization'], startsWith('Bearer '));
    });

    test('returns the route as the server now holds it', () async {
      final ApiMyRoutesRepository repository = repositoryOver(
        (_) async => ok(<String, Object?>{
          'route': route(
            status: 'cancelled',
            cancelledAt: '2026-08-28T10:00:00+00:00',
          ),
        }),
      );

      final PublishedRoute cancelled = await repository.cancel(
        '01991b00-0000-7000-8000-000000000001',
      );

      expect(cancelled.status, RouteStatus.cancelled);
      expect(cancelled.cancelledAt, '2026-08-28T10:00:00+00:00');
    });

    /// Cancelling something already cancelled is the same cancellation seen
    /// again. The server answers 200 and the client accepts it as authoritative
    /// — deliberately WITHOUT requiring the body to be byte-identical to the
    /// first one, because `departure_state` is read at the moment of asking and
    /// may legitimately have moved on.
    test('a repeat is a success, not a special case', () async {
      final ApiMyRoutesRepository repository = repositoryOver(
        (_) async => ok(<String, Object?>{
          'route': route(
            status: 'cancelled',
            departureState: 'past',
            cancelledAt: '2026-08-28T10:00:00+00:00',
          ),
        }),
      );

      final PublishedRoute again = await repository.cancel(
        '01991b00-0000-7000-8000-000000000001',
      );

      expect(again.status, RouteStatus.cancelled);
      expect(again.departureState, DepartureState.past);
      expect(again.cancelledAt, '2026-08-28T10:00:00+00:00');
    });

    test('the documented refusals surface with their codes', () async {
      for (final (int status, String code, RmErrorCode expected)
          in <(int, String, RmErrorCode)>[
            (401, 'unauthenticated', RmErrorCode.unauthenticated),
            (403, 'forbidden', RmErrorCode.forbidden),
            (404, 'not_found', RmErrorCode.notFound),
            (409, 'conflict', RmErrorCode.conflict),
          ]) {
        final ApiMyRoutesRepository repository = repositoryOver(
          (_) async => refusal(status, code),
        );

        await expectLater(
          repository.cancel('01991b00-0000-7000-8000-000000000001'),
          throwsA(
            isA<RmFailure>().having((RmFailure f) => f.code, 'code', expected),
          ),
          reason: '$status',
        );
      }
    });

    test('a malformed success fails rather than filling in blanks', () async {
      final ApiMyRoutesRepository repository = repositoryOver(
        (_) async => ok(<String, Object?>{'route': 'gone'}),
      );

      await expectLater(
        repository.cancel('01991b00-0000-7000-8000-000000000001'),
        throwsA(isA<RmFailure>()),
      );
    });
  });
}
