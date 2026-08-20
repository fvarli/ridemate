// ─────────────────────────────────────────────────────────────
// RideMate — Profile providers
//
// One provider returning a fixed presentation fixture. Overriding it is the
// whole seam a real source would use, so no repository is invented for data
// that has no API — and, in this case, no service behind it either.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/profile_fixtures.dart';
import '../domain/profile_snapshot.dart';

/// What the Profile screen renders.
final Provider<ProfileSnapshot> profileSnapshotProvider =
    Provider<ProfileSnapshot>((Ref ref) => kMockProfileSnapshot);
