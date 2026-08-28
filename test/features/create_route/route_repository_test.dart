import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ridemate/core/api/rm_api_client.dart';
import 'package:ridemate/core/api/rm_error_code.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/places/place.dart';
import 'package:ridemate/core/routes/departure.dart';
import 'package:ridemate/core/routes/published_route.dart';
import 'package:ridemate/core/routes/ride_rule.dart';
import 'package:ridemate/features/create_route/data/route_repository.dart';
import 'package:ridemate/features/create_route/domain/create_route_draft.dart';

import '../../support/fakes.dart';

/// Publishing over the wire: the request, both successes, and every refusal.
void main() {
  const Place origin = Place(
    id: '01991a00-0000-7000-8000-00000000000a',
    label: 'Kadıköy, Vapur İskelesi',
  );
  const Place destination = Place(
    id: '01991a00-0000-7000-8000-00000000000b',
    label: 'Levent, Metro İstasyonu',
  );

  const String routeId = '01991b00-0000-7000-8000-000000000001';

  const CreateRouteDraft draft = CreateRouteDraft(
    origin: origin,
    destination: destination,
    recurrence: Recurrence.weekdays,
    departureDate: null,
    departureTime: DepartureTime(hour: 8, minute: 25),
    seats: 3,
    rules: <RideRuleId>{RideRuleId.noSmoking, RideRuleId.quiet},
  );

  const RoutePublicationCommand command = RoutePublicationCommand(
    id: routeId,
    draft: draft,
  );

  late List<http.Request> sent;

  ApiRouteRepository repositoryOver(
    Future<http.Response> Function(http.Request) handler,
  ) {
    sent = <http.Request>[];

    return ApiRouteRepository(
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

  /// The envelope the server returns, with fields overridable per test.
  Map<String, Object?> routeBody([Map<String, Object?> overrides = const {}]) =>
      <String, Object?>{
        'route': <String, Object?>{
          'id': routeId,
          'origin': <String, Object?>{'id': origin.id, 'label': origin.label},
          'destination': <String, Object?>{
            'id': destination.id,
            'label': destination.label,
          },
          'recurrence': 'weekdays',
          'departure_date': null,
          'departure_time': '08:25',
          'timezone': 'Europe/Istanbul',
          'departure_state': 'upcoming',
          'seats_offered': 3,
          'rules': <String, Object?>{
            'no_smoking': true,
            'music_ok': false,
            'no_pets': false,
            'quiet': true,
          },
          'status': 'published',
          'published_at': '2026-08-28T09:41:00+00:00',
          'cancelled_at': null,
          ...overrides,
        },
      };

  http.Response created(Object? body, [int status = 201]) => http.Response(
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

  group('The request', () {
    test('posts to exactly the documented path', () async {
      final ApiRouteRepository repository = repositoryOver(
        (_) async => created(routeBody()),
      );

      await repository.publish(command);

      expect(sent, hasLength(1));
      expect(sent.single.method, 'POST');
      expect(sent.single.url.path, '/api/v1/routes');
      expect(sent.single.url.queryParameters, isEmpty);
    });

    /// Phase 9 settled how a credential is attached and refreshed. Publishing
    /// reuses that seam rather than opening it again.
    test('travels through the authenticated seam', () async {
      final ApiRouteRepository repository = repositoryOver(
        (_) async => created(routeBody()),
      );

      await repository.publish(command);

      expect(sent.single.headers['Authorization'], startsWith('Bearer '));
    });

    /// CARRIES WEIGHT. The id on the wire is the one the caller minted.
    test('carries the caller’s id, unaltered', () async {
      final ApiRouteRepository repository = repositoryOver(
        (_) async => created(routeBody()),
      );

      await repository.publish(command);

      final Map<String, Object?> body =
          jsonDecode(sent.single.body) as Map<String, Object?>;

      expect(body['id'], routeId);
    });

    /// There is no Idempotency-Key here, and that is the decision, not an
    /// omission: the resource id identifies the intent completely.
    test('sends no idempotency header', () async {
      final ApiRouteRepository repository = repositoryOver(
        (_) async => created(routeBody()),
      );

      await repository.publish(command);

      final Set<String> headers = sent.single.headers.keys
          .map((String k) => k.toLowerCase())
          .toSet();

      expect(headers, isNot(contains('idempotency-key')));
    });

    test('a one-off journey states its date and a commute does not', () async {
      final ApiRouteRepository once = repositoryOver(
        (_) async => created(
          routeBody(<String, Object?>{
            'recurrence': 'once',
            'departure_date': '2099-04-01',
          }),
        ),
      );

      await once.publish(
        RoutePublicationCommand(
          id: routeId,
          draft: draft.copyWith(
            recurrence: Recurrence.once,
            departureDate: const DepartureDate(year: 2099, month: 4, day: 1),
          ),
        ),
      );

      Map<String, Object?> body =
          jsonDecode(sent.single.body) as Map<String, Object?>;
      expect(body['recurrence'], 'once');
      expect(body['departure_date'], '2099-04-01');

      final ApiRouteRepository weekdays = repositoryOver(
        (_) async => created(routeBody()),
      );

      await weekdays.publish(command);

      body = jsonDecode(sent.single.body) as Map<String, Object?>;
      expect(body['recurrence'], 'weekdays');
      // Absent, not null. `additionalProperties: false` plus the contract's
      // oneOf rejects a commute that carries a date at all.
      expect(body.containsKey('departure_date'), isFalse);
    });
  });

  group('Success', () {
    test('201 decodes the published route', () async {
      final ApiRouteRepository repository = repositoryOver(
        (_) async => created(routeBody()),
      );

      final PublishedRoute route = await repository.publish(command);

      expect(route.id, routeId);
      expect(route.origin, origin);
      expect(route.destination, destination);
      expect(route.recurrence, Recurrence.weekdays);
      expect(route.departureDate, isNull);
      expect(route.departureTime, const DepartureTime(hour: 8, minute: 25));
      expect(route.timezone, 'Europe/Istanbul');
      expect(route.departureState, DepartureState.upcoming);
      expect(route.seatsOffered, 3);
      expect(route.rules, <RideRuleId>{RideRuleId.noSmoking, RideRuleId.quiet});
      expect(route.status, RouteStatus.published);
      expect(route.publishedAt, '2026-08-28T09:41:00+00:00');
      expect(route.cancelledAt, isNull);
    });

    /// CARRIES WEIGHT. 200 is "already published under this id" — the answer a
    /// retry gets after a request that timed out on its way back. Treating it
    /// as anything but success would tell a driver their journey had failed
    /// while it sat published on the server.
    test('200 and 201 decode identically', () async {
      final ApiRouteRepository first = repositoryOver(
        (_) async => created(routeBody(), 201),
      );
      final ApiRouteRepository second = repositoryOver(
        (_) async => created(routeBody(), 200),
      );

      final PublishedRoute a = await first.publish(command);
      final PublishedRoute b = await second.publish(command);

      expect(a.id, b.id);
      expect(a.status, b.status);
      expect(a.publishedAt, b.publishedAt);
      expect(a.departureState, b.departureState);
      expect(a.rules, b.rules);
    });

    test('a one-off route reads its date back', () async {
      final ApiRouteRepository repository = repositoryOver(
        (_) async => created(
          routeBody(<String, Object?>{
            'recurrence': 'once',
            'departure_date': '2099-04-01',
          }),
        ),
      );

      final PublishedRoute route = await repository.publish(command);

      expect(route.recurrence, Recurrence.once);
      expect(
        route.departureDate,
        const DepartureDate(year: 2099, month: 4, day: 1),
      );
    });

    /// The state is read, never derived: whether a departure has passed is
    /// decided in a timezone the server owns.
    test('a past route is past because the server said so', () async {
      final ApiRouteRepository repository = repositoryOver(
        (_) async =>
            created(routeBody(<String, Object?>{'departure_state': 'past'})),
      );

      expect(
        (await repository.publish(command)).departureState,
        DepartureState.past,
      );
    });
  });

  group('What it refuses', () {
    test('a conflict surfaces as one', () async {
      final ApiRouteRepository repository = repositoryOver(
        (_) async => refusal(409, 'conflict'),
      );

      await expectLater(
        repository.publish(command),
        throwsA(
          isA<RmFailure>()
              .having((RmFailure f) => f.code, 'code', RmErrorCode.conflict)
              .having((RmFailure f) => f.status, 'status', 409),
        ),
      );
    });

    test('a validation failure surfaces as one', () async {
      final ApiRouteRepository repository = repositoryOver(
        (_) async => refusal(422, 'validation_failed'),
      );

      await expectLater(
        repository.publish(command),
        throwsA(
          isA<RmFailure>().having(
            (RmFailure f) => f.code,
            'code',
            RmErrorCode.validationFailed,
          ),
        ),
      );
    });

    test('the auth refusals arrive with their own codes', () async {
      for (final (int status, String code, RmErrorCode expected)
          in <(int, String, RmErrorCode)>[
            (401, 'unauthenticated', RmErrorCode.unauthenticated),
            (403, 'forbidden', RmErrorCode.forbidden),
          ]) {
        final ApiRouteRepository repository = repositoryOver(
          (_) async => refusal(status, code),
        );

        await expectLater(
          repository.publish(command),
          throwsA(
            isA<RmFailure>().having((RmFailure f) => f.code, 'code', expected),
          ),
          reason: '$status',
        );
      }
    });

    test('an unreachable backend is a transport failure', () async {
      final ApiRouteRepository repository = repositoryOver(
        (_) async => throw const SocketException('no route to host'),
      );

      await expectLater(
        repository.publish(command),
        throwsA(
          isA<RmFailure>().having(
            (RmFailure f) => f.isTransport,
            'isTransport',
            isTrue,
          ),
        ),
      );
    });

    /// CARRIES WEIGHT. The status of an unreadable success survives on the
    /// failure, and the publication controller classifies on it.
    ///
    /// A body that will not decode and a 404 both carry
    /// [RmErrorCode.unexpected], and they mean opposite things: the first may
    /// be a route that now exists, the second is the server saying no. Only
    /// the status separates them. If this failure were ever built with a
    /// hardcoded status, every indeterminate publication would be reclassified
    /// as a deterministic refusal — and the retry that would have confirmed
    /// the route would stop happening.
    test('an unreadable success carries the status the server sent', () async {
      for (final int status in <int>[200, 201]) {
        final ApiRouteRepository repository = repositoryOver(
          (_) async =>
              created(<String, Object?>{'route': 'not an object'}, status),
        );

        await expectLater(
          repository.publish(command),
          throwsA(
            isA<RmFailure>()
                .having((RmFailure f) => f.status, 'status', status)
                .having((RmFailure f) => f.code, 'code', RmErrorCode.unexpected)
                .having((RmFailure f) => f.isTransport, 'isTransport', isFalse),
          ),
          reason: '$status',
        );
      }
    });

    /// CARRIES WEIGHT. A success that will not decode is not a success. Half a
    /// route is worse than none: the driver would be told it worked and shown
    /// a journey the server does not agree with.
    test('a malformed success fails rather than filling in blanks', () async {
      final List<Map<String, Object?>> broken = <Map<String, Object?>>[
        <String, Object?>{'route': 'yes'},
        <String, Object?>{},
        routeBody(<String, Object?>{'id': null}),
        routeBody(<String, Object?>{'seats_offered': '3'}),
        routeBody(<String, Object?>{'departure_time': null}),
        routeBody(<String, Object?>{'departure_time': '0825'}),
        routeBody(<String, Object?>{'departure_date': '2099/04/01'}),
        routeBody(<String, Object?>{'timezone': null}),
        // A status this build has never heard of. Guessing would put a route
        // into a state the app cannot reason about.
        routeBody(<String, Object?>{'status': 'expired'}),
        routeBody(<String, Object?>{'departure_state': 'imminent'}),
        routeBody(<String, Object?>{'recurrence': 'daily'}),
        routeBody(<String, Object?>{'origin': null}),
        routeBody(<String, Object?>{
          'origin': <String, Object?>{'id': origin.id},
        }),
        // A rule the response left out is not the same as a rule set to false.
        routeBody(<String, Object?>{
          'rules': <String, Object?>{
            'no_smoking': true,
            'music_ok': false,
            'quiet': true,
          },
        }),
        routeBody(<String, Object?>{
          'rules': <String, Object?>{
            'no_smoking': 1,
            'music_ok': 0,
            'no_pets': 0,
            'quiet': 1,
          },
        }),
      ];

      for (final Map<String, Object?> body in broken) {
        final ApiRouteRepository repository = repositoryOver(
          (_) async => created(body),
        );

        await expectLater(
          repository.publish(command),
          throwsA(isA<RmFailure>()),
          reason: jsonEncode(body),
        );
      }
    });
  });

  group('What a route says about itself', () {
    /// A route's endpoints and times describe somebody's daily commute, and a
    /// toString is the easiest way for that to reach a log by accident.
    test('a published route names no place and no time', () async {
      final ApiRouteRepository repository = repositoryOver(
        (_) async => created(routeBody()),
      );

      final String description = (await repository.publish(command)).toString();

      expect(description, contains(routeId));
      expect(description, isNot(contains('Kadıköy')));
      expect(description, isNot(contains('Levent')));
      expect(description, isNot(contains('08:25')));
    });

    /// A failure carries a correlation id and nothing else. No token, no
    /// header, no body, no endpoint.
    test('a refusal names nothing about the journey', () async {
      final ApiRouteRepository repository = repositoryOver(
        (_) async => refusal(409, 'conflict'),
      );

      try {
        await repository.publish(command);
        fail('a conflict must not succeed');
      } on RmFailure catch (failure) {
        final String description = failure.toString();

        expect(description, isNot(contains('Bearer')));
        expect(description, isNot(contains('rma_')));
        expect(description, isNot(contains('Kadıköy')));
        expect(description, isNot(contains(origin.id)));
        expect(description, isNot(contains('/api/v1/routes')));
      }
    });
  });
}
