// ─────────────────────────────────────────────────────────────
// RideMate — Home presentation model
//
// PRESENTATION DATA ONLY.
//
// Every value here is mock display data taken from the approved design. None
// of it implies a rule: not the fare share, not the compatibility percentage,
// not the rating, not the route. Matching, pricing and reputation are all
// backend-owned concerns that do not exist yet, and nothing in this file
// pre-empts any of them.
//
// The fare share is cost-sharing PRESENTATION only. RideMate implements no
// payment behaviour of any kind.
//
// No repository interface is introduced for this. There is no API to model
// yet, and inventing one would be the ceremony architecture.md forbids;
// overriding the provider is already the seam a real source would use.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

import '../../../core/widgets/rm_avatar.dart';

/// One nearby route match, as the design's Home card presents it.
@immutable
final class NearbyMatch {
  const NearbyMatch({
    required this.offerId,
    required this.initials,
    required this.displayName,
    required this.rating,
    required this.origin,
    required this.destination,
    required this.costSharePerPerson,
    required this.compatibility,
    required this.identity,
    required this.isVerified,
  });

  /// The route offer this match refers to, so tapping it opens the same
  /// screen the discovery flow reaches.
  final String offerId;

  /// Avatar initials. Built with `RmTextConventions.initials`.
  final String initials;

  /// Abbreviated name, per the design's privacy convention (`Selin K.`).
  final String displayName;

  final double rating;
  final String origin;
  final String destination;

  /// Suggested cost share, in lira. Display data — nothing charges anyone.
  final int costSharePerPerson;

  /// Route compatibility as a 0..1 ratio.
  final double compatibility;

  final RmIdentity identity;

  /// Whether to show the verified badge. Distinct from online presence.
  final bool isVerified;
}

/// Everything the Home screen renders.
@immutable
final class HomeSnapshot {
  const HomeSnapshot({
    required this.greetingName,
    required this.locationLabel,
    required this.matches,
    required this.matchCount,
  });

  final String greetingName;
  final String locationLabel;

  /// The matches shown inline on the map. The design shows one.
  final List<NearbyMatch> matches;

  /// Total matches available, which may exceed [matches].
  final int matchCount;
}
