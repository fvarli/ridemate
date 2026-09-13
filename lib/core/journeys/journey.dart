// ─────────────────────────────────────────────────────────────
// RideMate — One dated journey, as its own driver sees it
//
// A JOURNEY IS A ROUTE ON A DATE
//
// Not a row with an id of its own. The backend stores no occurrence table and
// publishes no journey identifier: `(routeId, serviceDate)` IS the identity,
// and a second name for it would be a second thing to keep in agreement.
//
// WHY THIS IS NOT MyRoute WITH A DATE
//
// MyRoute is the PLAN — its recurrence, its seats, its rules, when it was
// published — which is what an owner edits and cancels. This is one occurrence
// of that plan, and a driver reading it is asking a different question: which
// journey, where, when, and has it happened. Repeating the plan's fields on
// every date would say nothing about the date, and would invite a screen to
// edit a plan from a page about one of its days.
//
// NOBODY ELSE IS IN IT
//
// No driver identity — the caller is the driver. No passenger names, no
// passenger count, no accepted-seat figure: who is aboard is not stored
// anywhere, no phase has designed it, and a number here would be answered from
// seat requests, which are a different question with a surface of their own.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

import '../places/place.dart';
import '../routes/departure.dart';
import '../routes/published_route.dart';
import '../trips/trip_lifecycle.dart';

@immutable
final class Journey {
  const Journey({
    required this.routeId,
    required this.serviceDate,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.timezone,
    required this.routeStatus,
    required this.trip,
  });

  /// The plan this journey belongs to. With [serviceDate] it is the whole
  /// identity; there is no journey id.
  final String routeId;

  /// The calendar day, in the route's own timezone.
  final DepartureDate serviceDate;

  final Place origin;
  final Place destination;
  final DepartureTime departureTime;

  /// The zone [serviceDate] and [departureTime] are read in. Decoded because
  /// the contract publishes it; the client computes nothing with it.
  final String timezone;

  /// The PLAN's status, never folded into [trip].
  ///
  /// A cancelled plan can still hold a journey that is under way, and a driver
  /// ending one needs both facts rather than one derived from the other.
  final RouteStatus routeStatus;

  /// Whether this journey was made.
  ///
  /// Always present and never null here, unlike [MyRoute.trip]: a journey is a
  /// concrete day, so the question always has an answer, and no stored trip
  /// means `notStarted`.
  final TripLifecycle trip;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Journey &&
          other.routeId == routeId &&
          other.serviceDate == serviceDate &&
          other.origin == origin &&
          other.destination == destination &&
          other.departureTime == departureTime &&
          other.timezone == timezone &&
          other.routeStatus == routeStatus &&
          other.trip == trip;

  @override
  int get hashCode => Object.hash(
    routeId,
    serviceDate,
    origin,
    destination,
    departureTime,
    timezone,
    routeStatus,
    trip,
  );

  /// Says nothing about where it runs. The identity, and what became of it.
  @override
  String toString() =>
      'Journey($routeId, ${serviceDate.iso}, ${trip.state.wire})';
}
