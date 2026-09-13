import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/journeys/journey.dart';
import 'package:ridemate/core/journeys/journey_decoder.dart';
import 'package:ridemate/core/routes/published_route.dart';
import 'package:ridemate/core/trips/trip_lifecycle.dart';

/// One dated journey, read off the wire.
///
/// A journey is `(routeId, serviceDate)` and has no id of its own, so what this
/// file is really about is that the pair survives decoding intact and that a
/// body which cannot name one day is refused rather than half-read.
void main() {
  Map<String, Object?> wire({
    String routeId = '01991b00-0000-7000-8000-0000000000a1',
    Object? serviceDate = '2026-09-16',
    String routeStatus = 'published',
    Map<String, Object?>? trip,
  }) => <String, Object?>{
    'route_id': routeId,
    'service_date': serviceDate,
    'origin': <String, Object?>{'id': 'p1', 'label': 'Kadıköy, Vapur İskelesi'},
    'destination': <String, Object?>{'id': 'p2', 'label': 'Levent, Metro'},
    'departure_time': '08:25',
    'timezone': 'Europe/Istanbul',
    'route_status': routeStatus,
    'trip':
        trip ??
        <String, Object?>{
          'state': 'not_started',
          'started_at': null,
          'completed_at': null,
          'aborted_at': null,
        },
  };

  group('The projection', () {
    test('every documented field decodes, and the identity survives', () {
      final Journey journey = JourneyDecoder.journey(wire(), 200);

      expect(journey.routeId, '01991b00-0000-7000-8000-0000000000a1');
      expect(journey.serviceDate.iso, '2026-09-16');
      expect(journey.origin.label, 'Kadıköy, Vapur İskelesi');
      expect(journey.destination.label, 'Levent, Metro');
      expect(journey.departureTime.hhMm, '08:25');
      expect(journey.timezone, 'Europe/Istanbul');
      expect(journey.routeStatus, RouteStatus.published);
      expect(journey.trip.state, TripState.notStarted);
    });

    /// CARRIES WEIGHT. A day with no trip is `notStarted`, not absent.
    ///
    /// The server sends the lifecycle for every journey, started or not, so
    /// this projection never has to read absence — and a client that did would
    /// be inventing the one fact the type exists to stop it inventing.
    test('a journey nobody started says so rather than omitting it', () {
      final Journey journey = JourneyDecoder.journey(wire(), 200);

      expect(journey.trip.state, TripState.notStarted);
      expect(journey.trip.startedAt, isNull);
      expect(journey.trip.completedAt, isNull);
      expect(journey.trip.abortedAt, isNull);
    });

    /// CARRIES WEIGHT. A cancelled plan can still hold a running journey.
    ///
    /// The two facts are independent, and a decoder that coupled them would
    /// hide the state a driver most needs to act on.
    test('a withdrawn plan and a journey under way are both kept', () {
      final Journey journey = JourneyDecoder.journey(
        wire(
          routeStatus: 'cancelled',
          trip: <String, Object?>{
            'state': 'in_progress',
            'started_at': '2026-09-15T05:25:00Z',
            'completed_at': null,
            'aborted_at': null,
          },
        ),
        200,
      );

      expect(journey.routeStatus, RouteStatus.cancelled);
      expect(journey.trip.state, TripState.inProgress);
    });

    test('every lifecycle state decodes', () {
      for (final TripState state in TripState.values) {
        final Journey journey = JourneyDecoder.journey(
          wire(
            trip: <String, Object?>{
              'state': state.wire,
              'started_at': null,
              'completed_at': null,
              'aborted_at': null,
            },
          ),
          200,
        );

        expect(journey.trip.state, state, reason: state.wire);
      }
    });
  });

  group('What it refuses', () {
    /// CARRIES WEIGHT. A journey is one day, so the day is never null.
    ///
    /// Unlike a route's `departure_date`, which is null for a plan. Reading a
    /// null here as "a recurring journey" would produce a Journey that cannot
    /// be addressed — and every command this client sends is addressed by it.
    test('a null or absent service date is refused', () {
      expect(
        () => JourneyDecoder.journey(wire(serviceDate: null), 200),
        throwsA(isA<RmFailure>()),
      );

      final Map<String, Object?> without = wire()..remove('service_date');
      expect(
        () => JourneyDecoder.journey(without, 200),
        throwsA(isA<RmFailure>()),
      );
    });

    /// CARRIES WEIGHT. A day this client cannot address is refused outright.
    ///
    /// `16-09-2026` parses part-by-part as the year 16 and would travel back
    /// out in a path; `2026-02-30` is not a day at all and would silently
    /// become the 2nd of March. Both would address a journey the server has no
    /// row for, and the 404 would arrive with nothing to explain it.
    test('a service date that is not a date is refused', () {
      for (final Object? bad in <Object?>[
        '16-09-2026',
        '2026-02-30',
        '2026-13-01',
        '2026-9-14',
        '2026-09',
        42,
        '',
      ]) {
        expect(
          () => JourneyDecoder.journey(wire(serviceDate: bad), 200),
          throwsA(isA<RmFailure>()),
          reason: '$bad',
        );
      }
    });

    test('a missing field fails the whole projection', () {
      for (final String field in <String>[
        'route_id',
        'service_date',
        'origin',
        'destination',
        'departure_time',
        'timezone',
        'route_status',
        'trip',
      ]) {
        final Map<String, Object?> row = wire()..remove(field);

        expect(
          () => JourneyDecoder.journey(row, 200),
          throwsA(isA<RmFailure>()),
          reason: field,
        );
      }
    });

    /// A null lifecycle is `MyRoute`'s answer for a plan, and is not this
    /// projection's: a journey is a concrete day, so the question always has
    /// one.
    test('a null trip is refused on this surface', () {
      expect(
        () => JourneyDecoder.journey(<String, Object?>{
          ...wire(),
          'trip': null,
        }, 200),
        throwsA(isA<RmFailure>()),
      );
    });

    test('a route status this build has never heard of is refused', () {
      expect(
        () => JourneyDecoder.journey(wire(routeStatus: 'archived'), 200),
        throwsA(isA<RmFailure>()),
      );
    });
  });
}
