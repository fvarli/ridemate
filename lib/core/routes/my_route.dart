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

  /// Whether the journey was made. Always present, `notStarted` included.
  final TripLifecycle trip;

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
  String toString() => 'MyRoute(${route.id}, ${trip.state.wire})';
}
