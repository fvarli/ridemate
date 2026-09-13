// ─────────────────────────────────────────────────────────────
// RideMate — Asking for a seat, as the server describes it
//
// THREE PROJECTIONS, NOT ONE MODEL WITH OPTIONAL FIELDS
//
// The backend publishes a seat request three different ways, for three
// different readers, and collapsing them into one class with nullable halves
// would lose the thing that makes each honest. A discovery card gets an id and
// a status and nothing else. A passenger gets the whole journey alongside their
// asking. A driver gets the person who asked and no journey at all, because the
// journey is the one they already own.
//
// A single model would let a screen read a field the server never sends it.
//
// THREE INDEPENDENT TRUTHS
//
// A request's own status is history — what this member asked and what answer
// they got. The route's status and departure state are the journey as it stands
// now. Its trip lifecycle is whether it was actually made. `accepted` beside
// `cancelled`, or beside `aborted`, is not a contradiction to be reconciled; it
// is separate facts, and the client renders each. Nothing here synthesises a
// further state to explain them away.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

import '../places/place.dart';
import '../reviews/review.dart';
import '../routes/departure.dart';
import '../routes/published_route.dart';
import '../routes/ride_rule.dart';
import '../trips/trip_lifecycle.dart';

/// Where one asking stands.
///
/// Exactly the four the contract names. There is no `expired`, no
/// `cancelledByRoute`, no `rejected` and no `approved`: the server has four
/// states, and a fifth invented here would be a claim no response supports.
enum SeatRequestStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined'),
  withdrawn('withdrawn');

  const SeatRequestStatus(this.wire);

  final String wire;
}

/// Why a seat-request command was refused.
///
/// The stable machine strings the backend publishes at `error.details.reason`.
/// They are matched, never parsed out of a message and never guessed from a
/// status code — several of these share one.
///
/// `recurring_route_unsupported` is NOT here. A passenger can now ask for a
/// seat on a named day of a weekday plan, so no seat-request command can
/// produce it and the backend stopped publishing it on this surface — an enum
/// advertising an outcome its surface cannot reach is a stale contract, not a
/// compatibility guarantee. It remains a TRIP reason, where the route-only
/// endpoints can still produce it; see [TripRefusal].
///
/// `service_date_passed` arrived with it: a driver accepting an asking for a
/// day that has already departed is told so. The same wire string is also a
/// trip reason, and the two enums stay separate for the reason [TripRefusal]
/// gives.
enum SeatRequestRefusal {
  profileRequired('profile_required'),
  ownRoute('own_route'),
  idAlreadyUsed('id_already_used'),
  alreadyRequested('already_requested'),
  routeUnavailable('route_unavailable'),
  serviceDatePassed('service_date_passed'),
  routeFull('route_full'),
  alreadyAccepted('already_accepted'),
  alreadyDecided('already_decided'),
  withdrawn('withdrawn');

  const SeatRequestRefusal(this.wire);

  final String wire;

  /// The refusal a failure names, or null when it names none of them.
  ///
  /// Null covers a failure that carried no reason and one naming a value this
  /// build has never heard of — a future backend may add one, and a client that
  /// guessed would be worse than a client that says it does not know.
  static SeatRequestRefusal? fromWire(String? value) {
    for (final SeatRequestRefusal refusal in values) {
      if (refusal.wire == value) return refusal;
    }

    return null;
  }
}

/// What every seat-request row can say about itself.
///
/// Declared here rather than in the feature that pages them: an id is a fact
/// about the model, and a page holding rows should not have to reach into a
/// feature to learn what a row is.
abstract interface class SeatRequestRow {
  String get id;
}

/// The caller's own asking about one dated journey of a discovered route.
///
/// The whole of what discovery publishes about it: which journey, enough to
/// address it, and what state it is in. Never anybody else's, and never a count.
///
/// [serviceDate] IS WHAT MAKES THIS ADDRESSABLE
///
/// A route is a plan and a journey is that plan on a date, so a member may hold
/// one asking for Monday and another for Tuesday on the same route. Without the
/// day, two of these would be indistinguishable except by an id a screen has no
/// other use for — and a card would have no way to say which journey a status
/// belongs to.
@immutable
final class MySeatRequestSummary {
  const MySeatRequestSummary({
    required this.serviceDate,
    required this.id,
    required this.status,
  });

  /// Which of the route's journeys this asking is for.
  final DepartureDate serviceDate;

  final String id;
  final SeatRequestStatus status;

  @override
  bool operator ==(Object other) =>
      other is MySeatRequestSummary &&
      other.serviceDate == serviceDate &&
      other.id == id &&
      other.status == status;

  @override
  int get hashCode => Object.hash(serviceDate, id, status);

  @override
  String toString() =>
      'MySeatRequestSummary(${serviceDate.iso}, ${status.wire})';
}

/// The journey an asking is about, as its passenger may see it.
///
/// What discovery publishes plus [status] — which discovery has no vocabulary
/// for, because it only ever shows live journeys. Here it is load-bearing: a
/// member looking at their own history needs to know the journey was withdrawn.
@immutable
final class SeatRequestRoute {
  const SeatRequestRoute({
    required this.id,
    required this.origin,
    required this.destination,
    required this.recurrence,
    required this.departureDate,
    required this.departureTime,
    required this.timezone,
    required this.status,
    required this.departureState,
    required this.seatsOffered,
    required this.rules,
    required this.driver,
    required this.trip,
  });

  final String id;
  final Place origin;
  final Place destination;
  final Recurrence recurrence;

  /// Present for a one-off journey, absent for a recurring plan.
  final DepartureDate? departureDate;
  final DepartureTime departureTime;
  final String timezone;

  /// Whether the journey still stands, independent of the request's own status.
  final RouteStatus status;

  /// Whether it has departed, computed by the server against its own clock.
  final DepartureState departureState;

  /// What the driver offered. Never what remains — nothing publishes that.
  final int seatsOffered;
  final Set<RideRuleId> rules;
  final SeatRequestMember driver;

  /// Whether the journey was made — a fourth fact beside [status],
  /// [departureState] and the asking's own status.
  ///
  /// A passenger may hold an accepted request on a journey that is under way,
  /// on one that finished, and on one cancelled before it ever began. All three
  /// are said plainly; nothing here reconciles them into a single verdict.
  final TripLifecycle trip;
}

/// A member, in the two fields a profile has.
///
/// Initials arrive derived. Turkish casing makes them a rule rather than a
/// formatting detail, so the server owns them and this renders what it is
/// given — a guard asserts nothing under the feature computes one.
@immutable
final class SeatRequestMember {
  const SeatRequestMember({required this.displayName, required this.initials});

  final String displayName;
  final String initials;

  @override
  bool operator ==(Object other) =>
      other is SeatRequestMember &&
      other.displayName == displayName &&
      other.initials == initials;

  @override
  int get hashCode => Object.hash(displayName, initials);
}

/// One of the caller's own askings, with the journey it is about.
@immutable
final class MySeatRequest implements SeatRequestRow {
  const MySeatRequest({
    required this.id,
    required this.serviceDate,
    required this.status,
    required this.requestedAt,
    required this.decidedAt,
    required this.withdrawnAt,
    required this.route,
    required this.myReview,
  });

  @override
  final String id;

  /// Which of the route's journeys this asking is for.
  ///
  /// Always present, for a one-off route as much as for a plan: the journey is
  /// `(route, date)` either way, and a one-off route simply has one date.
  /// [SeatRequestRoute.departureDate] is the ROUTE's — null for a plan — and
  /// this is the asking's, which is never null. They agree for a one-off
  /// journey and only this one means anything for a recurring one.
  final DepartureDate serviceDate;

  final SeatRequestStatus status;
  final DateTime requestedAt;

  /// When it was accepted or declined; null until it is either.
  final DateTime? decidedAt;

  /// When the passenger took it back; null unless they did.
  final DateTime? withdrawnAt;

  final SeatRequestRoute route;

  /// What this member has already said about the journey, or null.
  ///
  /// Null when they have written nothing — and also when the driver has written
  /// something the server has not released yet. The two are identical here on
  /// purpose: knowing the other side had already rated you would bias the
  /// rating you are about to give.
  final MyReview? myReview;
}

/// One asking on a journey the caller published.
///
/// No route: it is the one the driver addressed, and repeating it on every row
/// would say nothing they do not already know.
@immutable
final class IncomingSeatRequest implements SeatRequestRow {
  const IncomingSeatRequest({
    required this.id,
    required this.serviceDate,
    required this.status,
    required this.requestedAt,
    required this.decidedAt,
    required this.withdrawnAt,
    required this.passenger,
    required this.myReview,
  });

  @override
  final String id;

  /// Which of this route's journeys the passenger asked about.
  ///
  /// The driver addressed the route, so the row carries no journey — but a plan
  /// has one per day it runs, and without this a driver could not tell Monday's
  /// asking from Tuesday's.
  final DepartureDate serviceDate;

  final SeatRequestStatus status;
  final DateTime requestedAt;
  final DateTime? decidedAt;
  final DateTime? withdrawnAt;
  final SeatRequestMember passenger;

  /// What this driver has already said about the passenger, or null. See
  /// [MySeatRequest.myReview] for why null means two things at once.
  final MyReview? myReview;
}
