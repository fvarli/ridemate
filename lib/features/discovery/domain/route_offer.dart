// ─────────────────────────────────────────────────────────────
// RideMate — Route offer
//
// One shared journey, as the Match Results card and the Route Details screen
// present it. A single entity feeds both, so the two screens can never show
// different figures for the same offer.
//
// EVERY NUMBER HERE IS PRESENTATION DATA THE OFFER CARRIES.
//
// Nothing in this codebase derives any of them. There is deliberately no
// calculateCompatibility, no calculateFare, no calculateTrustScore and no
// rankMatches. In particular:
//
//   compatibility  a percentage the design shows. Not a matching algorithm.
//   fareShare      a suggested cost share. Not a price, not a fare, not
//                  earnings, and nothing charges anyone.
//   trustScore     a backend-owned, safety-sensitive concept. The client
//                  displays it and never computes it.
//   rating         a reputation figure produced elsewhere.
//
// RideMate facilitates shared journeys and legitimate journey-cost sharing.
// None of these fields carry commercial passenger-transport semantics.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

import '../../../core/widgets/rm_avatar.dart';

/// A shared journey another member has published.
@immutable
final class RouteOffer {
  const RouteOffer({
    required this.id,
    required this.driverName,
    required this.initials,
    required this.identity,
    required this.isVerified,
    required this.rating,
    required this.tripCount,
    required this.originLabel,
    required this.destinationLabel,
    required this.departureHour,
    required this.departureMinute,
    required this.arrivalHour,
    required this.arrivalMinute,
    required this.tripMinutes,
    required this.seatsAvailable,
    required this.walkMinutes,
    required this.fareShare,
    required this.compatibility,
    required this.trustScore,
    required this.approvalRate,
    required this.sharedDistance,
    required this.memberSince,
    required this.homeArea,
    required this.vehicleName,
    required this.plate,
    this.sharedRouteCount,
    this.ridePreferences,
  });

  final String id;

  // ── Identity ───────────────────────────────────────────────

  /// Abbreviated per the design's privacy convention, e.g. `Selin K.`.
  final String driverName;
  final String initials;
  final RmIdentity identity;

  /// Identity verification. Distinct from online presence — see RmAvatar.
  final bool isVerified;

  /// Reputation figure. Display only.
  final double rating;

  /// Completed shared journeys. Display only.
  final int tripCount;

  /// Routes this member shares with the viewer, when the design shows it.
  final int? sharedRouteCount;

  // ── Journey ────────────────────────────────────────────────

  final String originLabel;
  final String destinationLabel;
  final int departureHour;
  final int departureMinute;
  final int arrivalHour;
  final int arrivalMinute;

  /// Journey duration in minutes. Display only — no route engine exists.
  final int tripMinutes;

  final int seatsAvailable;

  /// Walking minutes to the pickup point. Display only.
  final int walkMinutes;

  // ── Figures the design shows ───────────────────────────────

  /// Suggested cost share in lira. Presentation only; nothing charges anyone.
  final int fareShare;

  /// Route compatibility, 0..1. Presentation only; not a matching rule.
  final double compatibility;

  /// Trust Score to display. Backend-owned; never computed here.
  final int trustScore;

  /// Request approval rate, 0..1. Presentation only.
  final double approvalRate;

  /// Distance shared, pre-formatted by the fixture, e.g. `3.4k`.
  ///
  /// Kept as a string on purpose: deriving `3.4k` from a number would invent
  /// an abbreviation rule no locale requirement covers.
  final String sharedDistance;

  // ── Details-only ───────────────────────────────────────────

  /// Membership year, e.g. `2023`.
  final String memberSince;

  /// Neighbourhood shown beside the membership year.
  final String homeArea;

  final String vehicleName;
  final String plate;

  /// Ride preferences, e.g. `Müzik · Sessiz yolculuk`.
  final String? ridePreferences;

  @override
  bool operator ==(Object other) => other is RouteOffer && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'RouteOffer($id)';
}
