// ─────────────────────────────────────────────────────────────
// RideMate — Profile fixture
//
// Every value is transcribed from the approved design, not calculated.
// Read profile_snapshot.dart before changing anything here.
// ─────────────────────────────────────────────────────────────

import '../../../core/widgets/rm_avatar.dart';
import 'profile_snapshot.dart';

/// The Profile screen exactly as the design draws it.
///
/// The four factors are 100 / 90 / 94 / 82 and the score is 92. Their mean is
/// 91.5. That is NOT a rounding error to be tidied up — the two are unrelated
/// declarations, and a test asserts they stay unequal.
const List<TrustFactor> kMockProfileFactors = <TrustFactor>[
  TrustFactor(
    id: TrustFactorId.identity,
    value: 100,
    meter: 1,
    tone: TrustFactorTone.complete,
  ),
  TrustFactor(
    id: TrustFactorId.community,
    value: 90,
    meter: 0.9,
    tone: TrustFactorTone.standard,
  ),
  TrustFactor(
    id: TrustFactorId.reliability,
    value: 94,
    meter: 0.94,
    tone: TrustFactorTone.standard,
  ),
  TrustFactor(
    id: TrustFactorId.activity,
    value: 82,
    meter: 0.82,
    tone: TrustFactorTone.attention,
  ),
];

const ProfileSnapshot kMockProfileSnapshot = ProfileSnapshot(
  name: 'Elif Çelik',
  initials: 'EÇ',
  identity: RmIdentity.purple,
  verification: RmVerification.verified,
  trustScore: 92,
  tierPercentile: 8,
  factors: kMockProfileFactors,
  tripCount: 73,
  rating: 4.9,
  savingsLabel: '₺2.1k',
  verifiedBadgeCount: 4,
  verifiedBadgeTotal: 5,
);
