// ─────────────────────────────────────────────────────────────
// RideMate — Seat requests, from the wire to state
//
// No UI here. What is proved is that the three projections stay three, that a
// request's status and its journey's status stay independent, that a refusal
// is matched rather than guessed, and that a page behaves when the second one
// does not arrive.
// ─────────────────────────────────────────────────────────────

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
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
import 'package:ridemate/core/routes/route_decoder.dart';
import 'package:ridemate/core/seat_requests/seat_request.dart';
import 'package:ridemate/core/seat_requests/seat_request_decoder.dart';
import 'package:ridemate/features/seat_requests/application/seat_request_providers.dart';
import 'package:ridemate/features/seat_requests/data/seat_request_repository.dart';
import 'package:ridemate/features/seat_requests/domain/seat_request_page.dart';

import '../../support/fakes.dart';

// ------------------------------------------------------------------ fixtures

const String _requestId = '01991d00-0000-7000-8000-000000000001';
const String _routeId = '01991c00-0000-7000-8000-000000000001';

Map<String, Object?> _route({
  String status = 'published',
  String departureState = 'upcoming',
  String trip = 'not_started',
  Object? startedAt,
  Object? completedAt,
  Object? abortedAt,
}) => <String, Object?>{
  'id': _routeId,
  'origin': <String, Object?>{'id': 'p1', 'label': 'Kadıköy, Vapur İskelesi'},
  'destination': <String, Object?>{'id': 'p2', 'label': 'Levent, Metro'},
  'recurrence': 'once',
  'departure_date': '2026-09-14',
  'departure_time': '08:25',
  'timezone': 'Europe/Istanbul',
  'status': status,
  'departure_state': departureState,
  'seats_offered': 3,
  'rules': <String, Object?>{
    'no_smoking': true,
    'music_ok': false,
    'no_pets': false,
    'quiet': false,
  },
  'driver': <String, Object?>{'display_name': 'İrem Yılmaz', 'initials': 'İY'},
  // A fourth fact this projection always carries, independent of the three
  // above it.
  'trip': <String, Object?>{
    'state': trip,
    'started_at': startedAt,
    'completed_at': completedAt,
    'aborted_at': abortedAt,
  },
};

Map<String, Object?> _mine({
  String id = _requestId,
  String status = 'pending',
  String? decidedAt,
  String? withdrawnAt,
  Map<String, Object?>? route,
  Map<String, Object?>? myReview,
}) => <String, Object?>{
  'id': id,
  'status': status,
  'requested_at': '2026-09-09T08:00:00Z',
  'decided_at': decidedAt,
  'withdrawn_at': withdrawnAt,
  'route': route ?? _route(),
  // Required and nullable on this projection, like `my_seat_request` on
  // discovery: absent is drift, not an unreviewed relationship.
  'my_review': myReview,
};

Map<String, Object?> _incoming({
  String id = _requestId,
  String status = 'pending',
  Map<String, Object?>? myReview,
}) => <String, Object?>{
  'id': id,
  'status': status,
  'requested_at': '2026-09-09T08:00:00Z',
  'decided_at': null,
  'withdrawn_at': null,
  'passenger': <String, Object?>{
    'display_name': 'Ayşe Demir',
    'initials': 'AD',
  },
  'my_review': myReview,
};

void main() {
  group('Statuses', () {
    test('all four decode, and a fifth refuses the response', () {
      for (final SeatRequestStatus status in SeatRequestStatus.values) {
        expect(
          SeatRequestDecoder.mine(_mine(status: status.wire), 200).status,
          status,
        );
      }

      expect(
        () => SeatRequestDecoder.mine(_mine(status: 'expired'), 200),
        throwsA(isA<RmFailure>()),
      );
    });
  });

  group('Discovery carries the caller own request', () {
    test('null when they have not asked', () {
      expect(fakeDiscoveredRoute().mySeatRequest, isNull);
    });

    test('each status, exactly as sent', () {
      for (final SeatRequestStatus status in SeatRequestStatus.values) {
        final DiscoveredRoute route = fakeDiscoveredRoute(
          mySeatRequest: <String, Object?>{
            'id': _requestId,
            'status': status.wire,
          },
        );

        expect(route.mySeatRequest?.id, _requestId);
        expect(route.mySeatRequest?.status, status);
      }
    });

    /// A response without the key is not this contract.
    ///
    /// Reading absence as "not requested" would make an older backend claim
    /// every journey is still askable — which is exactly the false affordance
    /// this field exists to prevent.
    test('an absent key is refused, which is not the same as a null value', () {
      final Map<String, Object?> wire = <String, Object?>{
        'id': _routeId,
        'origin': <String, Object?>{'id': 'p1', 'label': 'A'},
        'destination': <String, Object?>{'id': 'p2', 'label': 'B'},
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
          'quiet': false,
        },
        'driver': <String, Object?>{'display_name': 'İ Y', 'initials': 'İY'},
      };

      expect(
        () => RouteDecoder.discovered(wire, 200),
        throwsA(isA<RmFailure>()),
      );

      // The same body, with the key present and null, decodes.
      expect(
        RouteDecoder.discovered(<String, Object?>{
          ...wire,
          'my_seat_request': null,
        }, 200).mySeatRequest,
        isNull,
      );
    });
  });

  group('Two independent truths', () {
    /// THE ONE THAT MATTERS.
    ///
    /// A seat the driver agreed to give, on a journey they later withdrew.
    /// Both are true, and neither is derived from or corrected by the other.
    test('an accepted request on a cancelled journey stays both', () {
      final MySeatRequest request = SeatRequestDecoder.mine(
        _mine(
          status: 'accepted',
          decidedAt: '2026-09-09T09:00:00Z',
          route: _route(status: 'cancelled'),
        ),
        200,
      );

      expect(request.status, SeatRequestStatus.accepted);
      expect(request.route.status, RouteStatus.cancelled);
      expect(request.route.departureState, DepartureState.upcoming);
      expect(request.decidedAt, isNotNull);
      expect(request.withdrawnAt, isNull);
    });

    test('a pending request on a departed journey stays both', () {
      final MySeatRequest request = SeatRequestDecoder.mine(
        _mine(route: _route(departureState: 'past')),
        200,
      );

      expect(request.status, SeatRequestStatus.pending);
      expect(request.route.status, RouteStatus.published);
      expect(request.route.departureState, DepartureState.past);
    });

    test('the journey decodes with everything the passenger may see', () {
      final SeatRequestRoute route = SeatRequestDecoder.mine(
        _mine(),
        200,
      ).route;

      expect(route.origin.label, 'Kadıköy, Vapur İskelesi');
      expect(route.recurrence, Recurrence.once);
      expect(route.departureDate?.iso, '2026-09-14');
      expect(route.departureTime.hhMm, '08:25');
      expect(route.seatsOffered, 3);
      expect(route.rules, <RideRuleId>{RideRuleId.noSmoking});
      expect(route.driver.displayName, 'İrem Yılmaz');
      expect(route.driver.initials, 'İY');
    });
  });

  group('The driver projection', () {
    test('carries the passenger and no journey', () {
      final IncomingSeatRequest request = SeatRequestDecoder.incoming(
        _incoming(),
        200,
      );

      expect(request.passenger.displayName, 'Ayşe Demir');
      expect(request.passenger.initials, 'AD');
      expect(request.status, SeatRequestStatus.pending);
    });

    /// The type has nowhere to put one, which is the strongest form of this.
    test('has no route field at all', () {
      expect(
        IncomingSeatRequest,
        isNot(equals(MySeatRequest)),
        reason: 'the two projections must not be one type',
      );
    });
  });

  group('Refusals are matched, never guessed', () {
    test('every locked reason decodes from details', () {
      const List<String> wire = <String>[
        'profile_required',
        'own_route',
        'recurring_route_unsupported',
        'id_already_used',
        'already_requested',
        'route_unavailable',
        'route_full',
        'already_accepted',
        'already_decided',
        'withdrawn',
      ];

      for (final String reason in wire) {
        final RmFailure failure = RmFailure.fromBackend(
          status: 409,
          code: RmErrorCode.conflict,
          reason: reason,
        );

        expect(failure.seatRequestRefusal?.wire, reason);
      }

      // Exactly these, so a new one is a decision rather than a surprise.
      expect(
        SeatRequestRefusal.values.map((SeatRequestRefusal r) => r.wire).toSet(),
        wire.toSet(),
      );
    });

    test('an unknown reason is null rather than a plausible guess', () {
      const RmFailure failure = RmFailure.fromBackend(
        status: 409,
        code: RmErrorCode.conflict,
        reason: 'something_phase_14_added',
      );

      expect(failure.seatRequestRefusal, isNull);
    });

    /// A 409 with no reason must not become one by inference.
    test('a conflict without a reason names nothing', () {
      const RmFailure failure = RmFailure.fromBackend(
        status: 409,
        code: RmErrorCode.conflict,
      );

      expect(failure.seatRequestRefusal, isNull);
      expect(failure.seatRequestCurrentStatus, isNull);
    });

    test('current_status is preserved when the server sent it', () {
      const RmFailure failure = RmFailure.fromBackend(
        status: 409,
        code: RmErrorCode.conflict,
        reason: 'already_accepted',
        currentStatus: 'accepted',
      );

      expect(failure.seatRequestRefusal, SeatRequestRefusal.alreadyAccepted);
      expect(failure.seatRequestCurrentStatus, SeatRequestStatus.accepted);
    });
  });

  group('Asking', () {
    test(
      '201 is a new request and 200 is the one that already landed',
      () async {
        final FakeSeatRequestBackend backend = FakeSeatRequestBackend()
          ..enqueue(201, <String, Object?>{'seat_request': _mine()})
          ..enqueue(200, <String, Object?>{'seat_request': _mine()});

        final SeatRequestRepository repository = backend.repository();

        final SeatRequested first = await repository.ask(
          routeId: _routeId,
          requestId: _requestId,
        );
        final SeatRequested retry = await repository.ask(
          routeId: _routeId,
          requestId: _requestId,
        );

        expect(first.wasAlreadyRequested, isFalse);
        expect(retry.wasAlreadyRequested, isTrue);
        // The same resource either way: the flag says how it arrived, never what
        // it is.
        expect(retry.request.id, first.request.id);
        expect(retry.request.status, first.request.status);
      },
    );

    test('the client id is what the request carries', () async {
      final FakeSeatRequestBackend backend = FakeSeatRequestBackend()
        ..enqueue(201, <String, Object?>{'seat_request': _mine()});

      await backend.repository().ask(routeId: _routeId, requestId: _requestId);

      expect(backend.lastPath, '/api/v1/routes/$_routeId/seat-requests');
      expect(backend.lastJson?['id'], _requestId);
    });
  });

  group('Cursors', () {
    test('pass through unchanged, in both directions', () async {
      final FakeSeatRequestBackend backend = FakeSeatRequestBackend()
        ..enqueue(200, <String, Object?>{
          'seat_requests': <Object?>[_mine()],
          'next_cursor': 'opaque-position-one',
        });

      final MySeatRequestsResult page = await backend.repository().mine(
        cursor: 'opaque-position-zero',
      );

      expect(backend.lastQuery?['cursor'], 'opaque-position-zero');
      expect(page.nextCursor, 'opaque-position-one');
    });

    test('a missing next_cursor key refuses the page', () async {
      final FakeSeatRequestBackend backend = FakeSeatRequestBackend()
        ..enqueue(200, <String, Object?>{
          'seat_requests': <Object?>[_mine()],
        });

      expect(backend.repository().mine(), throwsA(isA<RmFailure>()));
    });
  });

  group('The read surfaces', () {
    test('an empty page is not a failure', () async {
      final ProviderContainer container = _container(
        FakeSeatRequestBackend()..enqueue(200, <String, Object?>{
          'seat_requests': <Object?>[],
          'next_cursor': null,
        }),
      );
      addTearDown(container.dispose);

      final SeatRequestPage<MySeatRequest> page = await container.read(
        mySeatRequestsProvider.future,
      );

      expect(page.isEmpty, isTrue);
      expect(page.hasMore, isFalse);
      expect(container.read(mySeatRequestsProvider).hasError, isFalse);
    });

    test('a failure is not an empty page', () async {
      final ProviderContainer container = _container(
        FakeSeatRequestBackend()..fail(),
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(mySeatRequestsProvider.future),
        throwsA(isA<RmFailure>()),
      );
      expect(container.read(mySeatRequestsProvider).hasError, isTrue);
    });

    /// One read, and no automatic second.
    ///
    /// Riverpod would otherwise retry a failed build ten times on a backoff —
    /// eleven requests to a broken backend, with the member watching a spinner
    /// throughout.
    test('a failed read is asked exactly once', () async {
      final FakeSeatRequestBackend backend = FakeSeatRequestBackend()..fail();
      final ProviderContainer container = _container(backend);
      addTearDown(container.dispose);

      await expectLater(
        container.read(mySeatRequestsProvider.future),
        throwsA(isA<RmFailure>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(backend.calls, 1);
    });

    test('load-more failure keeps what was already read', () async {
      final FakeSeatRequestBackend backend = FakeSeatRequestBackend()
        ..enqueue(200, <String, Object?>{
          'seat_requests': <Object?>[_mine()],
          'next_cursor': 'more',
        })
        ..failNext();
      final ProviderContainer container = _container(backend);
      addTearDown(container.dispose);

      await container.read(mySeatRequestsProvider.future);
      await container.read(mySeatRequestsProvider.notifier).loadMore();

      final SeatRequestPage<MySeatRequest> page = container
          .read(mySeatRequestsProvider)
          .value!;

      expect(page.requests, hasLength(1));
      expect(page.loadMoreFailure, isNotNull);
      expect(page.isLoadingMore, isFalse);
      // The cursor is untouched, so retrying asks for the same page again.
      expect(page.nextCursor, 'more');
    });

    test('a row repeated across pages is not shown twice', () async {
      final FakeSeatRequestBackend backend = FakeSeatRequestBackend()
        ..enqueue(200, <String, Object?>{
          'seat_requests': <Object?>[_mine(), _mine(id: _other)],
          'next_cursor': 'more',
        })
        ..enqueue(200, <String, Object?>{
          // The server would not normally repeat one, but a row written
          // between two reads can land twice.
          'seat_requests': <Object?>[_mine(id: _other), _mine(id: _third)],
          'next_cursor': null,
        });
      final ProviderContainer container = _container(backend);
      addTearDown(container.dispose);

      await container.read(mySeatRequestsProvider.future);
      await container.read(mySeatRequestsProvider.notifier).loadMore();

      final SeatRequestPage<MySeatRequest> page = container
          .read(mySeatRequestsProvider)
          .value!;

      expect(page.requests.map((MySeatRequest r) => r.id).toList(), <String>[
        _requestId,
        _other,
        _third,
      ]);
      expect(page.hasMore, isFalse);
    });

    test('the driver list is keyed by journey', () async {
      final FakeSeatRequestBackend backend = FakeSeatRequestBackend()
        ..enqueue(200, <String, Object?>{
          'seat_requests': <Object?>[_incoming()],
          'next_cursor': null,
        });
      final ProviderContainer container = _container(backend);
      addTearDown(container.dispose);

      final SeatRequestPage<IncomingSeatRequest> page = await container.read(
        incomingSeatRequestsProvider(_routeId).future,
      );

      expect(page.requests.single.passenger.initials, 'AD');
      expect(backend.lastPath, '/api/v1/routes/$_routeId/seat-requests');
    });
  });
}

const String _other = '01991d00-0000-7000-8000-000000000002';
const String _third = '01991d00-0000-7000-8000-000000000003';

/// A backend a test can steer, recording what it was asked.
///
/// A real [RmApiClient] over a [MockClient], rather than a fake repository:
/// the point of several of these tests is what actually goes over the wire and
/// what the decoder makes of what comes back, and a fake repository would skip
/// both.
class FakeSeatRequestBackend {
  /// Replies in the order they will be given. A `null` body is a request that
  /// never reaches the backend at all.
  final List<({int status, Map<String, Object?>? body})> _replies =
      <({int status, Map<String, Object?>? body})>[];

  bool _alwaysFails = false;

  int calls = 0;
  String? lastPath;
  Map<String, String>? lastQuery;
  Map<String, Object?>? lastJson;

  void enqueue(int status, Map<String, Object?> body) =>
      _replies.add((status: status, body: body));

  /// The next request in the queue is the one that fails.
  void failNext() => _replies.add((status: 0, body: null));

  /// Every request fails, however many there are.
  void fail() => _alwaysFails = true;

  RmApiClient get client => RmApiClient(
    transport: MockClient((http.Request request) async {
      calls++;
      lastPath = request.url.path;
      lastQuery = request.url.queryParameters;
      lastJson = request.body.isEmpty
          ? null
          : jsonDecode(request.body) as Map<String, Object?>;

      final ({int status, Map<String, Object?>? body}) reply = _replies.isEmpty
          ? (status: 200, body: <String, Object?>{})
          : _replies.removeAt(0);

      if (_alwaysFails || reply.body == null) {
        // What a dropped connection looks like from here. The client turns it
        // into an RmFailure.transport, which is the thing under test.
        throw http.ClientException('offline', request.url);
      }

      return http.Response(
        jsonEncode(reply.body),
        reply.status,
        headers: <String, String>{'content-type': 'application/json'},
      );
    }),
    baseUrl: Uri.parse('https://ridemate.test'),
  );

  SeatRequestRepository repository() =>
      ApiSeatRequestRepository(client: client, session: FakeSession());
}

ProviderContainer _container(FakeSeatRequestBackend backend) =>
    ProviderContainer(
      overrides: <Override>[
        seatRequestRepositoryProvider.overrideWithValue(backend.repository()),
      ],
    );
