// ─────────────────────────────────────────────────────────────
// RideMate — An asking belongs to a journey, not to a plan
//
// The controller holds two things per intent: what the attempt is doing, and
// the id it is carrying. Both used to be filed under the route id alone, which
// is the same key for every day a plan runs.
//
// WHY THAT WOULD HAVE BEEN A BUG RATHER THAN AN INEFFICIENCY
//
// The minted id is the idempotency key, and reusing it for a different journey
// is not a retry — it is the same id describing something else, which the
// backend answers `id_already_used`, or worse replays and hands back the wrong
// asking. Phase 16a fixed the server's half of that identity; this is the
// client's.
//
// WHY THE TESTS LOOK SYNTHETIC
//
// Nothing in the shipped UI can produce two dates for one plan yet: the
// recurring gate still stands in front of the control, and a one-off route has
// one day. So the controller is driven directly. No guard is weakened to reach
// these states, and none of this is reachable by a member until 16b.
// ─────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/id/rm_uuid.dart';
import 'package:ridemate/core/places/place.dart';
import 'package:ridemate/core/routes/departure.dart';
import 'package:ridemate/core/routes/published_route.dart';
import 'package:ridemate/core/routes/ride_rule.dart';
import 'package:ridemate/core/seat_requests/seat_request.dart';
import 'package:ridemate/features/create_route/application/publication_providers.dart';
import 'package:ridemate/features/seat_requests/application/seat_request_action_providers.dart';
import 'package:ridemate/features/seat_requests/application/seat_request_providers.dart';
import 'package:ridemate/features/seat_requests/data/seat_request_repository.dart';

import '../../support/fakes.dart';

/// Records every asking, and can be held open mid-flight.
class _Backend implements SeatRequestRepository {
  final List<String> requestIds = <String>[];
  RmFailure? failure;
  Completer<void>? gate;

  @override
  Future<SeatRequested> ask({
    required String routeId,
    required String requestId,
  }) async {
    requestIds.add(requestId);

    final Completer<void>? held = gate;
    if (held != null) await held.future;

    final RmFailure? refusal = failure;
    if (refusal != null) throw refusal;

    return SeatRequested(
      request: _pending(requestId, routeId),
      wasAlreadyRequested: false,
    );
  }

  @override
  Future<MySeatRequestsResult> mine({String? cursor, int limit = 20}) async =>
      const MySeatRequestsResult(requests: <MySeatRequest>[], nextCursor: null);

  @override
  Future<IncomingSeatRequestsResult> forRoute(
    String routeId, {
    String? cursor,
    int limit = 20,
  }) async => throw UnimplementedError();

  @override
  Future<MySeatRequest> withdraw(String requestId) =>
      throw UnimplementedError();

  @override
  Future<IncomingSeatRequest> accept(String requestId) =>
      throw UnimplementedError();

  @override
  Future<IncomingSeatRequest> decline(String requestId) =>
      throw UnimplementedError();
}

/// The server's answer, in the shape the projection has.
MySeatRequest _pending(String id, String routeId) => MySeatRequest(
  id: id,
  status: SeatRequestStatus.pending,
  requestedAt: DateTime.utc(2026, 9, 13, 8),
  decidedAt: null,
  withdrawnAt: null,
  myReview: null,
  route: SeatRequestRoute(
    id: routeId,
    origin: const Place(id: 'p1', label: 'Kadıköy'),
    destination: const Place(id: 'p2', label: 'Levent'),
    recurrence: Recurrence.once,
    departureDate: const DepartureDate(year: 2026, month: 9, day: 14),
    departureTime: const DepartureTime(hour: 8, minute: 25),
    timezone: 'Europe/Istanbul',
    status: RouteStatus.published,
    departureState: DepartureState.upcoming,
    seatsOffered: 3,
    rules: const <RideRuleId>{},
    driver: const SeatRequestMember(displayName: 'İrem Yılmaz', initials: 'İY'),
    trip: fakeTrip(),
  ),
);

/// Ids in order, so a test can say which intent minted which.
class _CountingUuid implements RmUuidGenerator {
  int _next = 0;

  @override
  String v7() =>
      '01991d00-0000-7000-8000-${(++_next).toString().padLeft(12, '0')}';
}

void main() {
  const String routeId = '01991c00-0000-7000-8000-000000000001';
  const DepartureDate monday = DepartureDate(year: 2026, month: 9, day: 14);
  const DepartureDate tuesday = DepartureDate(year: 2026, month: 9, day: 15);

  const JourneyKey onMonday = (routeId: routeId, serviceDate: monday);
  const JourneyKey onTuesday = (routeId: routeId, serviceDate: tuesday);

  late _Backend backend;

  SeatRequestActionController controllerIn(ProviderContainer c) =>
      c.read(seatRequestActionProvider.notifier);

  ProviderContainer container() {
    backend = _Backend();

    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        seatRequestRepositoryProvider.overrideWithValue(backend),
        uuidGeneratorProvider.overrideWithValue(_CountingUuid()),
      ],
    );
    addTearDown(c.dispose);

    return c;
  }

  /// CARRIES WEIGHT. Two days of one plan do not share an id.
  ///
  /// The mutation this kills is the map going back to `Map<String, ...>`: with
  /// a route-only key the second ask reuses the first's id, and the recorder
  /// below sees one id twice.
  test('each journey mints its own id', () async {
    final ProviderContainer c = container();

    await controllerIn(c).request(onMonday);
    await controllerIn(c).request(onTuesday);

    expect(backend.requestIds, hasLength(2));
    expect(
      backend.requestIds.first,
      isNot(backend.requestIds.last),
      reason: 'Tuesday went out as a retry of Monday',
    );
  });

  /// And a genuine retry of the SAME journey is still the same asking.
  test('a retry of one journey reuses its id', () async {
    final ProviderContainer c = container();

    backend.failure = const RmFailure.transport();
    await controllerIn(c).request(onMonday);

    backend.failure = null;
    await controllerIn(c).request(onMonday);

    expect(backend.requestIds, hasLength(2));
    expect(backend.requestIds.first, backend.requestIds.last);
  });

  /// CARRIES WEIGHT. One day in flight does not make another look busy.
  test('an attempt in flight belongs to one journey', () async {
    final ProviderContainer c = container();

    backend.gate = Completer<void>();
    final Future<void> monday = controllerIn(c).request(onMonday);

    expect(controllerIn(c).attemptFor(onMonday), isA<SeatRequestSending>());
    expect(controllerIn(c).attemptFor(onTuesday), isNull);

    backend.gate!.complete();
    await monday;
  });

  /// A failure is filed against the journey that failed, and only that one.
  test('a failure belongs to one journey', () async {
    final ProviderContainer c = container();

    backend.failure = const RmFailure.transport();
    await controllerIn(c).request(onMonday);

    expect(controllerIn(c).attemptFor(onMonday), isA<SeatRequestFailed>());
    expect(controllerIn(c).attemptFor(onTuesday), isNull);
  });

  /// CARRIES WEIGHT. Dismissing one day leaves the other alone.
  test('clearing one journey does not clear another', () async {
    final ProviderContainer c = container();

    backend.failure = const RmFailure.transport();
    await controllerIn(c).request(onMonday);
    await controllerIn(c).request(onTuesday);

    expect(controllerIn(c).attemptFor(onMonday), isA<SeatRequestFailed>());
    expect(controllerIn(c).attemptFor(onTuesday), isA<SeatRequestFailed>());

    controllerIn(c).dismiss(onMonday);

    expect(controllerIn(c).attemptFor(onMonday), isNull);
    expect(
      controllerIn(c).attemptFor(onTuesday),
      isA<SeatRequestFailed>(),
      reason: 'dismissing Monday cleared Tuesday',
    );
  });

  /// Dismissing keeps the id, so a later retry is still the same asking — the
  /// Phase 13 rule, now per journey.
  test('dismissing one journey keeps its id for a later retry', () async {
    final ProviderContainer c = container();

    backend.failure = const RmFailure.transport();
    await controllerIn(c).request(onMonday);
    controllerIn(c).dismiss(onMonday);

    backend.failure = null;
    await controllerIn(c).request(onMonday);

    expect(backend.requestIds.first, backend.requestIds.last);
  });
}
