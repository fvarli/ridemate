// ─────────────────────────────────────────────────────────────
// RideMate — Active trip providers
//
// A single Provider returning a constant, exactly as Home does. Deliberately
// NOT a Notifier: a mutable trip state is the first brick of a trip lifecycle
// (requested, accepted, started, completed) that does not exist and must not be
// invented to make a screen reachable.
//
// No repository, no service, no stream, no timer.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/active_trip_fixtures.dart';
import '../domain/active_trip_snapshot.dart';

/// What the Active Trip screen renders.
final Provider<ActiveTripSnapshot> activeTripSnapshotProvider =
    Provider<ActiveTripSnapshot>((Ref ref) => kMockActiveTrip);
