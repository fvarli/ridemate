// ─────────────────────────────────────────────────────────────
// RideMate — One journey, and whether a command is in flight on it
//
// AsyncValue answers loading, loaded or failed for the READ. This adds the one
// thing a mutable detail screen needs beside it: whether this journey's own
// lifecycle command is under way.
//
// It cannot live in AsyncValue. Turning the screen into `AsyncLoading` to run a
// command would blank out the journey the driver is looking at, and a refusal
// would replace it with an error — losing the journey in order to report that
// it did not move.
//
// ONE JOURNEY, NOT A SET
//
// `MyRoutesPage` carries a set of route ids with a command in flight, because
// one screen holds many rows. This is one journey's own state, held by that
// journey's own provider, so the set would always have nought or one member in
// it — and the day it had two, one of them would belong to another journey.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

import '../../../core/journeys/journey.dart';
import '../../../core/trips/trip_lifecycle.dart';

@immutable
final class JourneyDetail {
  const JourneyDetail({required this.journey, this.isChangingTrip = false});

  /// The journey as the server last described it.
  ///
  /// Its lifecycle is only ever replaced by one the server returned — never
  /// computed here from a route status, a departure or a clock.
  final Journey journey;

  /// Whether a Start, Complete or Abort on THIS journey is in flight.
  final bool isChangingTrip;

  /// The same journey, with its command under way.
  JourneyDetail changing() =>
      JourneyDetail(journey: journey, isChangingTrip: true);

  /// The same journey, with nothing in flight and nothing changed.
  ///
  /// What a refusal leaves behind: a journey the backend would not start is not
  /// a journey that started.
  JourneyDetail settled() =>
      JourneyDetail(journey: journey, isChangingTrip: false);

  /// Settled, carrying the lifecycle the server returned.
  JourneyDetail withTrip(TripLifecycle lifecycle) =>
      JourneyDetail(journey: journey.withTrip(lifecycle));
}
