// ─────────────────────────────────────────────────────────────
// RideMate — Safety providers
//
// One provider returning a fixed presentation fixture. No repository and no
// service: there is no contacts store, no emergency backend and no API to
// model, and inventing an interface for any of them would suggest otherwise.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/safety_fixtures.dart';
import '../domain/safety_snapshot.dart';

/// What the Safety Center renders.
final Provider<SafetySnapshot> safetySnapshotProvider =
    Provider<SafetySnapshot>((Ref ref) => kMockSafetySnapshot);
