// ─────────────────────────────────────────────────────────────
// RideMate — Whether a journey was actually made
//
// A FOURTH INDEPENDENT TRUTH
//
// Beside the route's `status`, its `departureState` and a seat request's own
// status. None of them implies this one: a published journey may never be
// started, a departed one may never be reported, and a cancelled one was never
// begun. The server decides which, and this carries what it said.
//
// NOTHING HERE IS DERIVED
//
// Not from the departure, not from the clock, not from a request. The backend
// publishes the lifecycle on every surface that may say so, precisely so no
// client has to guess — and a guess would eventually disagree with the service
// about a journey the member is looking at.
//
// WHAT `inProgress` DOES NOT MEAN
//
// That the driver is at the origin, that anything is moving, that anybody
// boarded, or that any location is known. There are no coordinates in this
// contract. It means one thing: the driver pressed Start and the server
// accepted it.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

/// The four things a route can say about its journey.
///
/// `notStarted` is the absence of a trip rather than a stored state — the
/// server sends it for a journey nobody has begun, so absence never has to be
/// read. The wire strings are snake_case, which is why each case carries one
/// explicitly: `Enum.name` would never match them.
enum TripState {
  notStarted('not_started'),
  inProgress('in_progress'),
  completed('completed'),
  aborted('aborted');

  const TripState(this.wire);

  final String wire;
}

/// Why a trip lifecycle command was refused.
///
/// The stable machine strings the backend publishes at `error.details.reason`.
/// Matched, never parsed out of a message and never guessed from a status code
/// — all of them arrive as `409 conflict`, so the status alone says nothing.
///
/// DELIBERATELY NOT `SeatRequestRefusal`
///
/// `route_unavailable` and `service_date_passed` are also seat-request reasons,
/// and that is intentional: the same wire string for the same meaning is what
/// keeps the mapping simple. Sharing one enum across two domains would be a
/// different thing and a worse one — every later addition to either would have
/// to be argued in both. `recurring_route_unsupported` is the other way round:
/// it is a trip reason and no longer a seat-request one, which two separate
/// enums express and one shared enum could not.
///
/// `recurring_route_unsupported` no longer means recurring journeys cannot be
/// made. They can, by date. It means the ROUTE-ONLY command form, which names
/// no day, was aimed at a plan that has many.
///
/// `service_date_passed` bounds Start alone: a plan's journey may be started
/// only while its own calendar day is still current where the route is.
/// Completing or abandoning one that already exists has no such bound.
enum TripRefusal {
  recurringRouteUnsupported('recurring_route_unsupported'),
  departureNotReached('departure_not_reached'),
  serviceDatePassed('service_date_passed'),
  routeUnavailable('route_unavailable'),
  tripNotStarted('trip_not_started'),
  alreadyCompleted('already_completed'),
  alreadyAborted('already_aborted');

  const TripRefusal(this.wire);

  final String wire;

  /// The refusal a failure names, or null when it names none of them.
  ///
  /// Null covers a failure that carried no reason and one naming a value this
  /// build has never heard of. A future backend may add another, and a client
  /// that coerced it into one of these would act on a state nobody described.
  static TripRefusal? fromWire(String? value) {
    for (final TripRefusal refusal in values) {
      if (refusal.wire == value) return refusal;
    }

    return null;
  }
}

/// What a route says about whether its journey was made.
///
/// NO IDENTIFIER
///
/// A route has at most one trip and every command is route-scoped, so there is
/// nothing to address. The server publishes no id, and inventing one here would
/// be a field somebody eventually depends on.
///
/// NO POLICY FIELDS
///
/// No `canStart`, `canComplete`, `canAbort`, `isActive` or `canReview`. This
/// says what has happened; whether a control is offered is a decision a screen
/// makes from that plus what the server answers when it tries. Encoding it here
/// would fork the rule across two repositories — and `canReview` would be a
/// later phase arriving early by implication.
@immutable
final class TripLifecycle {
  const TripLifecycle({
    required this.state,
    required this.startedAt,
    required this.completedAt,
    required this.abortedAt,
  });

  final TripState state;

  /// When the driver started it — not when it was scheduled to leave.
  final DateTime? startedAt;

  final DateTime? completedAt;
  final DateTime? abortedAt;

  @override
  bool operator ==(Object other) =>
      other is TripLifecycle &&
      other.state == state &&
      other.startedAt == startedAt &&
      other.completedAt == completedAt &&
      other.abortedAt == abortedAt;

  @override
  int get hashCode => Object.hash(state, startedAt, completedAt, abortedAt);

  @override
  String toString() => 'TripLifecycle(${state.wire})';
}
