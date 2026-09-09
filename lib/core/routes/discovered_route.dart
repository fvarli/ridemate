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
    required this.mySeatRequest,
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

  /// The caller's own asking about this journey, or null if they have not.
  ///
  /// The one per-viewer field on an otherwise identical projection, and never
  /// anybody else's. It is here so a card reloaded after a restart knows it
  /// cannot ask again — without it the screen would offer an action the server
  /// has already ruled out, and the member would find out by tapping.
  ///
  /// At most one exists: a member may create one seat request per journey for
  /// that journey's lifetime, so a terminal status here never becomes
  /// requestable again.
  final MySeatRequestSummary? mySeatRequest;

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
          other.driver == driver;

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
  );
}
