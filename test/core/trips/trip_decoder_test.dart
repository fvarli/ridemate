import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/api/rm_error_code.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/routes/departure.dart';
import 'package:ridemate/core/routes/discovered_route.dart';
import 'package:ridemate/core/routes/my_route.dart';
import 'package:ridemate/core/routes/published_route.dart';
import 'package:ridemate/core/routes/route_decoder.dart';
import 'package:ridemate/core/seat_requests/seat_request.dart';
import 'package:ridemate/core/seat_requests/seat_request_decoder.dart';
import 'package:ridemate/core/trips/trip_decoder.dart';
import 'package:ridemate/core/trips/trip_lifecycle.dart';

import '../../support/fakes.dart';

/// Reading whether a journey was made.
///
/// Mostly negative, for the reason the route decoder's tests are: a decoder
/// that accepts everything passes every positive test ever written against it.
/// The lifecycle is the difference between a journey that happened and one that
/// did not, and a plausible guess here is worse than a visible failure.
void main() {
  Map<String, Object?> wire({
    Object? state = 'not_started',
    Object? startedAt,
    Object? completedAt,
    Object? abortedAt,
  }) => <String, Object?>{
    'state': state,
    'started_at': startedAt,
    'completed_at': completedAt,
    'aborted_at': abortedAt,
  };

  group('The four states', () {
    test('a journey nobody started says so, with nothing else', () {
      final TripLifecycle trip = TripDecoder.lifecycle(wire(), 200);

      expect(trip.state, TripState.notStarted);
      expect(trip.startedAt, isNull);
      expect(trip.completedAt, isNull);
      expect(trip.abortedAt, isNull);
    });

    test('a running journey carries only its beginning', () {
      final TripLifecycle trip = TripDecoder.lifecycle(
        wire(state: 'in_progress', startedAt: '2026-09-11T07:05:00Z'),
        200,
      );

      expect(trip.state, TripState.inProgress);
      expect(trip.startedAt, DateTime.utc(2026, 9, 11, 7, 5));
      expect(trip.completedAt, isNull);
      expect(trip.abortedAt, isNull);
    });

    test('a finished journey carries its ending beside its beginning', () {
      final TripLifecycle trip = TripDecoder.lifecycle(
        wire(
          state: 'completed',
          startedAt: '2026-09-11T07:05:00Z',
          completedAt: '2026-09-11T07:45:00Z',
        ),
        200,
      );

      expect(trip.state, TripState.completed);
      expect(trip.startedAt, DateTime.utc(2026, 9, 11, 7, 5));
      expect(trip.completedAt, DateTime.utc(2026, 9, 11, 7, 45));
      expect(trip.abortedAt, isNull);
    });

    test('an abandoned journey carries its own ending', () {
      final TripLifecycle trip = TripDecoder.lifecycle(
        wire(
          state: 'aborted',
          startedAt: '2026-09-11T07:05:00Z',
          abortedAt: '2026-09-11T07:20:00Z',
        ),
        200,
      );

      expect(trip.state, TripState.aborted);
      expect(trip.abortedAt, DateTime.utc(2026, 9, 11, 7, 20));
      expect(trip.completedAt, isNull);
    });

    /// Every stored state is reachable from the wire, so none of the four is
    /// a case the client can hold and never be told about.
    test('every state this build knows can be decoded', () {
      for (final TripState state in TripState.values) {
        expect(
          TripDecoder.lifecycle(wire(state: state.wire), 200).state,
          state,
          reason: state.wire,
        );
      }
    });
  });

  group('What it refuses', () {
    void expectMalformed(Object? value, String why) {
      expect(
        () => TripDecoder.lifecycle(value, 409),
        throwsA(
          isA<RmFailure>()
              .having((RmFailure f) => f.code, 'code', RmErrorCode.unexpected)
              // The status the response arrived with is carried through, so a
              // caller can tell an unreadable success from a refusal.
              .having((RmFailure f) => f.status, 'status', 409),
        ),
        reason: why,
      );
    }

    test('anything that is not an object', () {
      expectMalformed('in_progress', 'a bare string');
      expectMalformed(<Object?>[], 'a list');
      expectMalformed(null, 'nothing at all');
    });

    /// CARRIES WEIGHT. A fifth state is not rendered as something plausible.
    test('a state this build has never heard of', () {
      expectMalformed(wire(state: 'parked'), 'an invented state');
      expectMalformed(wire(state: 'notStarted'), 'the camelCase spelling');
      expectMalformed(wire(state: 42), 'a state that is not a string');
      expectMalformed(wire(state: null), 'no state at all');
    });

    /// CARRIES WEIGHT. Absent and null are different things.
    ///
    /// The server always sends all three keys. Reading a missing one as null
    /// would let an older backend quietly claim every journey is unstarted —
    /// which is exactly the fact this type exists to stop the client inventing.
    test('a timestamp key that is absent rather than null', () {
      for (final String key in <String>[
        'started_at',
        'completed_at',
        'aborted_at',
      ]) {
        expectMalformed(
          Map<String, Object?>.from(wire(state: 'in_progress'))..remove(key),
          'missing $key',
        );
      }
    });

    test('a timestamp that is not a readable instant', () {
      expectMalformed(wire(startedAt: 'yesterday'), 'unparseable');
      expectMalformed(wire(startedAt: 17), 'not a string');
    });
  });

  group('Where it appears', () {
    /// The owner's own list carries it; the plain route projection does not.
    test('a My Routes row is a route plus the lifecycle', () {
      final MyRoute row = fakeMyRoute(
        trip: TripState.inProgress,
        startedAt: '2026-09-11T07:05:00Z',
      );

      expect(row.trip.state, TripState.inProgress);
      expect(row.route.status, RouteStatus.published);
      expect(row.id, row.route.id);
    });

    test('a row without a trip is refused rather than read as unstarted', () {
      expect(
        () => RouteDecoder.myRoute(fakeRouteJson(), 200),
        throwsA(isA<RmFailure>()),
      );
    });

    /// And the plain route still decodes without one, which is what keeps
    /// publication and cancellation working.
    test('the plain route projection neither carries nor needs it', () {
      expect(RouteDecoder.route(fakeRouteJson(), 200).id, isNotEmpty);
      expect(
        RouteDecoder.route(<String, Object?>{
          ...fakeRouteJson(),
          'trip': fakeTripJson(state: TripState.completed),
        }, 200).id,
        isNotEmpty,
        reason: 'an extra key is not a reason to fail a route',
      );
    });

    test('the journey nested in a seat request carries it', () {
      final MySeatRequest request = SeatRequestDecoder.mine(<String, Object?>{
        'id': '01991d00-0000-7000-8000-000000000001',
        'status': 'accepted',
        'requested_at': '2026-09-10T08:00:00Z',
        'decided_at': '2026-09-10T09:00:00Z',
        'withdrawn_at': null,
        // Required on this projection since Phase 15; absent is drift.
        'my_review': null,
        'route': <String, Object?>{
          ...fakeRouteJson(
            recurrence: Recurrence.once,
            departureDate: '2099-04-01',
          ),
          'driver': <String, Object?>{
            'display_name': 'İrem Yılmaz',
            'initials': 'İY',
          },
          'trip': fakeTripJson(
            state: TripState.aborted,
            startedAt: '2026-09-11T07:05:00Z',
            abortedAt: '2026-09-11T07:20:00Z',
          ),
        },
      }, 200);

      // Four separate facts, none derived from another: the asking was
      // accepted, the journey still stands, it has not departed, and it was
      // abandoned. Nothing reconciles them.
      expect(request.status, SeatRequestStatus.accepted);
      expect(request.route.status, RouteStatus.published);
      expect(request.route.departureState, DepartureState.upcoming);
      expect(request.route.trip.state, TripState.aborted);
      expect(request.route.trip.abortedAt, DateTime.utc(2026, 9, 11, 7, 20));
    });

    test('a nested journey without a trip is refused', () {
      expect(
        () => SeatRequestDecoder.mine(<String, Object?>{
          'id': '01991d00-0000-7000-8000-000000000001',
          'status': 'pending',
          'requested_at': '2026-09-10T08:00:00Z',
          'decided_at': null,
          'withdrawn_at': null,
          // Required on this projection since Phase 15; absent is drift.
          'my_review': null,
          'route': <String, Object?>{
            ...fakeRouteJson(
              recurrence: Recurrence.once,
              departureDate: '2099-04-01',
            ),
            'driver': <String, Object?>{
              'display_name': 'İrem Yılmaz',
              'initials': 'İY',
            },
          },
        }, 200),
        throwsA(isA<RmFailure>()),
      );
    });

    /// CARRIES WEIGHT. Discovery publishes no lifecycle and must not need one.
    ///
    /// The fixture is decoder-backed and carries no `trip`, so this failing
    /// would mean the public feed had grown a dependency on a fact the server
    /// does not send it — the leak B4 narrowed the backend surface to prevent.
    test('a discovered journey decodes with no trip anywhere in it', () {
      final DiscoveredRoute discovered = fakeDiscoveredRoute();

      expect(discovered.id, isNotEmpty);
      expect(discovered.driver.displayName, isNotEmpty);
    });
  });

  group('What a failure names', () {
    /// Read from `details.reason`, never from the message and never from the
    /// status — all six refusals share one.
    test('each documented reason, and nothing else', () {
      for (final TripRefusal refusal in TripRefusal.values) {
        expect(
          RmFailure.fromBackend(
            status: 409,
            code: RmErrorCode.conflict,
            reason: refusal.wire,
          ).tripRefusal,
          refusal,
          reason: refusal.wire,
        );
      }
    });

    test('a reason nobody documented stays unknown', () {
      for (final String? reason in <String?>[
        null,
        '',
        'trip_already_started',
        'already_started',
        'route_cancelled',
        'no_passengers',
        // A seat-request reason is not a trip reason, even though the two
        // vocabularies deliberately share two strings.
        'already_requested',
        'profile_required',
      ]) {
        expect(
          RmFailure.fromBackend(
            status: 409,
            code: RmErrorCode.conflict,
            reason: reason,
          ).tripRefusal,
          isNull,
          reason: '$reason',
        );
      }
    });

    /// The two strings both domains use mean the same thing in both, which is
    /// why they are spelled the same — and why neither enum owns the other.
    test('the shared strings resolve in both vocabularies', () {
      for (final (String wire, TripRefusal trip, SeatRequestRefusal seat)
          in <(String, TripRefusal, SeatRequestRefusal)>[
            (
              'recurring_route_unsupported',
              TripRefusal.recurringRouteUnsupported,
              SeatRequestRefusal.recurringRouteUnsupported,
            ),
            (
              'route_unavailable',
              TripRefusal.routeUnavailable,
              SeatRequestRefusal.routeUnavailable,
            ),
          ]) {
        final RmFailure failure = RmFailure.fromBackend(
          status: 409,
          code: RmErrorCode.conflict,
          reason: wire,
        );

        expect(failure.tripRefusal, trip, reason: wire);
        expect(failure.seatRequestRefusal, seat, reason: wire);
      }
    });
  });
}
