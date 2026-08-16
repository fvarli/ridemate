// ─────────────────────────────────────────────────────────────
// RideMate — Home providers
//
// A single provider returning a fixed presentation fixture reproducing the
// approved design. Overriding it is the entire seam a real source would use,
// so no repository interface is invented for data that has no API yet.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/rm_avatar.dart';
import '../domain/home_snapshot.dart';

/// Mock presentation fixture — every value is taken from the design source.
const HomeSnapshot _kMockHomeSnapshot = HomeSnapshot(
  greetingName: 'Elif',
  locationLabel: 'Kadıköy',
  matchCount: 3,
  matches: <NearbyMatch>[
    NearbyMatch(
      initials: 'SK',
      displayName: 'Selin K.',
      rating: 4.9,
      origin: 'Kadıköy',
      destination: 'Levent',
      fareShare: 18,
      compatibility: 0.94,
      identity: RmIdentity.amber,
      isVerified: true,
    ),
  ],
);

/// What the Home screen renders.
final Provider<HomeSnapshot> homeSnapshotProvider = Provider<HomeSnapshot>(
  (Ref ref) => _kMockHomeSnapshot,
);
