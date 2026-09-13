// ─────────────────────────────────────────────────────────────
// RideMate — A journey the member published, with whether it was made
//
// WHY THIS IS NOT A FIELD ON PublishedRoute
//
// The backend publishes three different projections of a route and only one of
// them carries a lifecycle. Publication and cancellation answer the plain
// route; the owner's own list answers this. Putting `trip` on the shared model
// would make it either a lie on two surfaces or a nullable half — and a
// nullable half is read as `not_started` by the first screen that forgets the
// difference between "no trip" and "this projection does not say".
//
// The lifecycle here is ITSELF nullable since Phase 16b, and for the third
// meaning of the three: "this route is a plan, so the question does not apply".
// That is not "no trip" and not "this projection does not say" — it is a route
// whose journeys are addressed one date at a time. See the field.
//
// Composition rather than inheritance: a route is a route, and this is a route
// seen from the one place entitled to know more about it.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

import '../trips/trip_lifecycle.dart';
import 'published_route.dart';

@immutable
final class MyRoute {
  const MyRoute({required this.route, required this.trip});

  final PublishedRoute route;

  /// Whether the journey was made — and **null when the question does not
  /// apply**, which is every recurring plan.
  ///
  /// A one-off route is its own single journey, so the lifecycle is the route's
  /// and this carries it, `notStarted` included. A recurring plan is not a
  /// journey at all: it has as many as it has dates, each with its own state,
  /// and no one of them is the plan's.
  ///
  /// NULL IS NOT `notStarted`. Reading it as one would be a claim about a
  /// journey that does not exist, and it would stay wrong while the driver was
  /// mid-trip on Tuesday. The dated journey reads answer per date; nothing here
  /// picks one of a plan's trips to stand in.
  final TripLifecycle? trip;

  String get id => route.id;

  /// This row with the journey replaced and the lifecycle kept.
  ///
  /// Cancellation answers with a plain route and says nothing about a trip, so
  /// the lifecycle this row already holds is carried across rather than
  /// refetched or invented. Nothing about withdrawing a plan changes whether
  /// its journey was made.
  MyRoute withRoute(PublishedRoute replacement) =>
      MyRoute(route: replacement, trip: trip);

  @override
  bool operator ==(Object other) =>
      other is MyRoute && other.route == route && other.trip == trip;

  @override
  int get hashCode => Object.hash(route, trip);

  /// Says nothing about where the journey runs or when. See [PublishedRoute].
  @override
  String toString() => 'MyRoute(${route.id}, ${trip?.state.wire ?? 'n/a'})';
}
