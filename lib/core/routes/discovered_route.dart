// ─────────────────────────────────────────────────────────────
// RideMate — A journey somebody else published
//
// Neutral, beside PublishedRoute, because it is the other projection of the
// same rows — and because keeping it here is what lets RouteDecoder stay the
// single place a DepartureState is ever built from a response.
//
// The server's discovery projection, and only that.
//
// WHY THIS IS NOT RouteOffer WITH FEWER FIELDS
//
// RouteOffer carries a rating, a verified badge, a trip count, a trust score,
// an approval rate, a compatibility percentage, walking minutes and a cost —
// twenty-odd values transcribed from the design, none of which any endpoint
// knows. Narrowing that class would leave every one of those semantics alive in
// the type, waiting for a screen to read them again.
//
// So this is a different model, built from the wire and nothing else. What the
// product cannot say has nowhere to live rather than somewhere to hide.
//
// INITIALS ARE THE SERVER'S
//
// A field, not a getter. `RmTextConventions.initials` is right there and
// correct, which is exactly what makes it worth refusing: a second
// implementation of a deterministic rule drifts, and Turkish casing is where
// the two would part company. A guard asserts nothing here computes them.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

import '../places/place.dart';
import '../seat_requests/seat_request.dart';
import 'departure.dart';
import 'published_route.dart';
import 'ride_rule.dart';

/// Who published a journey, in the two fields a profile has.
@immutable
final class DiscoveredDriver {
  const DiscoveredDriver({required this.displayName, required this.initials});

  final String displayName;

  /// Rendered, never recomputed. See the file header.
  final String initials;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredDriver &&
          other.displayName == displayName &&
          other.initials == initials;

  @override
  int get hashCode => Object.hash(displayName, initials);
}

/// A published journey as a member who did not publish it sees it.
///
/// Narrower than [PublishedRoute] on purpose. That one is what an owner sees of
/// their own route and carries `status`, `publishedAt` and `cancelledAt`;
/// everything here is published and upcoming by construction, so a status would
/// be a constant and the timestamps say when a row was written.
@immutable
final class DiscoveredRoute {
  const DiscoveredRoute({
    required this.id,
    required this.origin,
    required this.destination,
    required this.recurrence,
    required this.departureDate,
    required this.departureTime,
    required this.timezone,
    required this.departureState,
    required this.seatsOffered,
    required this.rules,
    required this.driver,
    required this.mySeatRequests,
  });

  final String id;
  final Place origin;
  final Place destination;
  final Recurrence recurrence;

  /// The day of a one-off journey. Null for a recurring one, which has none.
  final DepartureDate? departureDate;

  final DepartureTime departureTime;

  /// Decoded because the contract publishes it; the client computes nothing
  /// with it. Past and future are the server's to decide.
  final String timezone;

  final DepartureState departureState;

  /// What the driver OFFERED. Never what remains — nothing tracks that.
  final int seatsOffered;

  /// Only the rules the driver turned on. A rule that is false says the driver
  /// did not choose it, and guarantees nothing about the opposite.
  final Set<RideRuleId> rules;

  final DiscoveredDriver driver;

  /// The caller's own askings about this route's journeys, earliest first.
  ///
  /// The one per-viewer field on an otherwise identical projection, and never
  /// anybody else's. It is here so a card reloaded after a restart knows which
  /// journeys it cannot ask about again — without it the screen would offer an
  /// action the server has already ruled out, and the member would find out by
  /// tapping.
  ///
  /// A LIST, BECAUSE A ROUTE IS A PLAN
  ///
  /// A journey is a route on a date, so a member may hold one asking for Monday
  /// and another for Tuesday on the same route. A one-off route carries at most
  /// one entry. Nothing may collapse this to a single value: the service date
  /// is what says which journey a status belongs to, and taking the first would
  /// be picking a day nobody named.
  ///
  /// PRESENT IS NOT THE SAME AS ACTIONABLE
  ///
  /// The days are bounded: the server lists only service dates it would still
  /// offer, dropping departed days and days outside the request horizon. The
  /// askings are not. A declined or withdrawn asking stays here while its day
  /// is still offerable, and that entry is the point — a member gets one asking
  /// per journey for its lifetime, so its presence says the asking for that day
  /// is spent, not that there is something left to do. Empty is the ordinary
  /// case, and only empty means the day is free to ask about.
  final List<MySeatRequestSummary> mySeatRequests;

  /// This route's asking for one day, or null if the caller has not asked.
  ///
  /// The only way to read [mySeatRequests] for a single journey: a screen that
  /// wants "the" asking must say which day it means, because a plan has one per
  /// day it runs.
  MySeatRequestSummary? seatRequestOn(DepartureDate? serviceDate) {
    if (serviceDate == null) return null;

    for (final MySeatRequestSummary summary in mySeatRequests) {
      if (summary.serviceDate == serviceDate) return summary;
    }

    return null;
  }

  /// The same journey, carrying the asking the server has just confirmed.
  ///
  /// Everything else is copied unchanged: this exists to record one answer,
  /// not to let a screen edit a journey it does not own.
  ///
  /// The summary REPLACES any entry for the same day and is otherwise inserted
  /// in service-date order. That order is the server's, and this keeps it true
  /// for the one row inserted locally rather than leaving the list sorted
  /// everywhere except after a tap.
  DiscoveredRoute withSeatRequest(MySeatRequestSummary summary) {
    final List<MySeatRequestSummary> merged =
        <MySeatRequestSummary>[
          for (final MySeatRequestSummary existing in mySeatRequests)
            if (existing.serviceDate != summary.serviceDate) existing,
          summary,
        ]..sort(
          (MySeatRequestSummary a, MySeatRequestSummary b) =>
              a.serviceDate.iso.compareTo(b.serviceDate.iso),
        );

    return DiscoveredRoute(
      id: id,
      origin: origin,
      destination: destination,
      recurrence: recurrence,
      departureDate: departureDate,
      departureTime: departureTime,
      timezone: timezone,
      departureState: departureState,
      seatsOffered: seatsOffered,
      rules: rules,
      driver: driver,
      mySeatRequests: merged,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredRoute &&
          other.id == id &&
          other.origin == origin &&
          other.destination == destination &&
          other.recurrence == recurrence &&
          other.departureDate == departureDate &&
          other.departureTime == departureTime &&
          other.timezone == timezone &&
          other.departureState == departureState &&
          other.seatsOffered == seatsOffered &&
          setEquals(other.rules, rules) &&
          other.driver == driver &&
          listEquals(other.mySeatRequests, mySeatRequests);

  @override
  int get hashCode => Object.hash(
    id,
    origin,
    destination,
    recurrence,
    departureDate,
    departureTime,
    timezone,
    departureState,
    seatsOffered,
    Object.hashAllUnordered(rules),
    driver,
    Object.hashAll(mySeatRequests),
  );
}
