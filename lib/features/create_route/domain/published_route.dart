// ─────────────────────────────────────────────────────────────
// RideMate — A journey the server has accepted
//
// Everything here came back from the API. Nothing is derived, and in
// particular `departureState` is READ, never computed: whether a departure has
// passed is decided in the pilot's timezone, which is the server's
// configuration, and a client that answered the question locally would
// eventually disagree with the service about it.
//
// The model deliberately carries no driver. The contract has no name, rating,
// verification, trust score or vehicle on a route, because RideMate does not
// have them — and a plausible field here would be the beginning of a screen
// that looks more real than it is.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

import '../../../core/places/place.dart';
import 'create_route_draft.dart';
import 'departure.dart';

/// Whether a route still stands.
enum RouteStatus { published, cancelled }

/// Whether the departure is still ahead, as the SERVER read it.
enum DepartureState { upcoming, past }

@immutable
final class PublishedRoute {
  const PublishedRoute({
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
    required this.status,
    required this.publishedAt,
    required this.cancelledAt,
  });

  final String id;
  final Place origin;
  final Place destination;
  final Recurrence recurrence;
  final DepartureDate? departureDate;
  final DepartureTime departureTime;

  /// The IANA zone the departure is read in, as recorded when it was
  /// published. Displayed or ignored; never used to compute anything here.
  final String timezone;

  final DepartureState departureState;
  final int seatsOffered;
  final Set<RideRuleId> rules;
  final RouteStatus status;
  final String publishedAt;
  final String? cancelledAt;

  @override
  bool operator ==(Object other) => other is PublishedRoute && other.id == id;

  @override
  int get hashCode => id.hashCode;

  /// Deliberately says nothing about where the journey runs or when.
  ///
  /// A route's endpoints and times describe somebody's daily commute, and a
  /// toString is the easiest way for that to reach a log by accident.
  @override
  String toString() => 'PublishedRoute($id, ${status.name})';
}
