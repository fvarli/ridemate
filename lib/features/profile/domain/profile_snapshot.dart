// ─────────────────────────────────────────────────────────────
// RideMate — Profile presentation model
//
// Source: docs/claude-designs/RideMate App.dc.html, "PROFILE · TRUST"
// (immutable).
//
// PRESENTATION DATA ONLY, and here that matters more than anywhere else in
// the app. This screen renders a Trust Score, a four-factor breakdown of it,
// a percentile tier and a verification count. RideMate has no Trust Score
// service, no reputation store, no identity provider and no backend of any
// kind, so every number below is a figure copied out of the design.
//
// TRUST SCORE DISPLAY != TRUST SCORE ALGORITHM.
//
// Nothing here computes, weights, thresholds or ranks anything:
//
//   * the four factors do NOT add up to the score, and must not be made to.
//     Their mean is 91.5 and the displayed score is 92 — a near miss that
//     invites exactly the wrong fix. Both are declared; neither produces the
//     other. profile_domain_test.dart pins the inequality so nobody
//     "corrects" it into a formula;
//   * [TrustFactorTone] is DECLARED per factor, never derived from [value].
//     The comp shows 82 amber and 90 blue, which would let anyone infer a
//     cut-off somewhere in 83..89. There is no such threshold, because there
//     is no policy that could define one;
//   * [TrustFactor.meter] and [TrustFactor.value] happen to agree in the comp
//     (a 94 factor draws a 94% bar). That agreement is the comp's, not a
//     rule. They stay independent so a real breakdown is free to draw a bar
//     that is not simply the number over one hundred.
//
// See docs/design-system.md §7 and the D-verify-1 deviation.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

import '../../../core/widgets/rm_avatar.dart';

/// The four rows of the Trust Score breakdown, in the order the design draws
/// them.
enum TrustFactorId { identity, community, reliability, activity }

/// The colour treatment a breakdown row is drawn in.
///
/// A declared presentation choice, NOT a severity computed from a value. The
/// design uses three, and what would qualify a factor for each is a product
/// and policy question nobody has answered.
enum TrustFactorTone {
  /// Green. The comp's `Kimlik`.
  complete,

  /// Blue. The comp's `Topluluk` and `Güvenilirlik`.
  standard,

  /// Amber. The comp's `Aktiflik`.
  attention,
}

/// One row of the Trust Score breakdown.
@immutable
final class TrustFactor {
  const TrustFactor({
    required this.id,
    required this.value,
    required this.meter,
    required this.tone,
  });

  final TrustFactorId id;

  /// The figure printed at the end of the row. Display data.
  final int value;

  /// The bar's fill, 0..1. Declared alongside [value] rather than derived
  /// from it — see the file header.
  final double meter;

  /// Declared, never thresholded.
  final TrustFactorTone tone;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrustFactor &&
          other.id == id &&
          other.value == value &&
          other.meter == meter &&
          other.tone == tone;

  @override
  int get hashCode => Object.hash(id, value, meter, tone);
}

/// Everything the Profile screen renders.
@immutable
final class ProfileSnapshot {
  const ProfileSnapshot({
    required this.name,
    required this.initials,
    required this.identity,
    required this.verification,
    required this.trustScore,
    required this.tierPercentile,
    required this.factors,
    required this.tripCount,
    required this.rating,
    required this.savingsLabel,
    required this.verifiedBadgeCount,
    required this.verifiedBadgeTotal,
  });

  final String name;

  /// Avatar initials. Built with `RmTextConventions.initials`.
  final String initials;

  final RmIdentity identity;

  /// Identity verification. Deliberately NOT presence: the design draws the
  /// check badge here, and the two claims are different. See RmAvatar.
  final RmVerification verification;

  /// The figure inside the ring, 0..100. Display data. Nothing computes it.
  final int trustScore;

  /// The percentile in the tier badge (`Üst %8`). A claim about a population
  /// of members that does not exist yet — presentation, like `%94 uyum`.
  final int tierPercentile;

  /// The breakdown rows. Not a decomposition of [trustScore]; see the header.
  final List<TrustFactor> factors;

  final int tripCount;

  final double rating;

  /// Pre-formatted, e.g. `₺2.1k`. Abbreviating a figure needs a rounding and
  /// unit policy nobody has set, so the design's own string ships as-is —
  /// the same treatment `sharedDistance: '3.4k'` already gets.
  final String savingsLabel;

  /// How many verification steps are complete, and out of how many. The total
  /// is the same five steps VerificationStepId declares; a test pins them
  /// together so the two features cannot drift apart.
  final int verifiedBadgeCount;
  final int verifiedBadgeTotal;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileSnapshot &&
          other.name == name &&
          other.initials == initials &&
          other.identity == identity &&
          other.verification == verification &&
          other.trustScore == trustScore &&
          other.tierPercentile == tierPercentile &&
          listEquals(other.factors, factors) &&
          other.tripCount == tripCount &&
          other.rating == rating &&
          other.savingsLabel == savingsLabel &&
          other.verifiedBadgeCount == verifiedBadgeCount &&
          other.verifiedBadgeTotal == verifiedBadgeTotal;

  @override
  int get hashCode => Object.hash(
    name,
    initials,
    identity,
    verification,
    trustScore,
    tierPercentile,
    Object.hashAll(factors),
    tripCount,
    rating,
    savingsLabel,
    verifiedBadgeCount,
    verifiedBadgeTotal,
  );
}
