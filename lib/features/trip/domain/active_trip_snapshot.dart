// ─────────────────────────────────────────────────────────────
// RideMate — Active trip presentation model
//
// PRESENTATION DATA ONLY. NOTHING HERE IS LIVE.
//
// The screen this feeds looks like a journey in progress: a car on a map, a
// pulsing "live" badge, an ETA counting down to a destination. None of it is
// happening. There is no trip session, no location, no GPS, no permission, no
// map vendor, no realtime transport and no presence service. Every value below
// is a figure taken from the approved design and displayed unchanged.
//
// So there is deliberately no calculateEta, calculateRemainingDistance,
// calculateProgress, updateVehiclePosition, derivePresence or trackingTimer in
// this codebase, and no repository or service behind this type. The ETA does
// not tick down, the route progress does not advance and the car does not
// move — animating any of them would be a route-progress calculation wearing a
// different hat.
//
// [driverPresence] is an [RmPresence], never an [RmVerification] and never a
// bool. The two mean different things — "online now" and "identity verified" —
// and the design draws them with a confusingly similar green. Keeping them as
// distinct types is what stops one being read, or passed, as the other.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

import '../../../core/widgets/rm_avatar.dart';

/// Whether the trip is running to time.
///
/// The design draws exactly one state, `Zamanında`. A second member needs both
/// design approval and a source of truth — it must never become a status this
/// layer computes from an ETA.
enum TripPunctuality { onTime }

/// Everything the Active Trip screen renders.
@immutable
final class ActiveTripSnapshot {
  const ActiveTripSnapshot({
    required this.driverName,
    required this.driverInitials,
    required this.driverIdentity,
    required this.driverRating,
    required this.driverPresence,
    required this.vehicleName,
    required this.plate,
    required this.etaMinutes,
    required this.remainingKm,
    required this.punctuality,
    required this.emergencyContactCount,
  });

  /// Abbreviated name, per the design's privacy convention (`Selin K.`).
  final String driverName;

  /// Avatar initials. Built with `RmTextConventions.initials`.
  final String driverInitials;

  final RmIdentity driverIdentity;
  final double driverRating;

  /// Online presence — NOT verification. See the file header.
  final RmPresence driverPresence;

  final String vehicleName;
  final String plate;

  /// Minutes to arrival, as displayed. Not counted down, not computed.
  final int etaMinutes;

  /// Kilometres remaining, as displayed. Not computed.
  final double remainingKm;

  final TripPunctuality punctuality;

  /// How many emergency contacts the footer names.
  ///
  /// Display only: nothing is shared with anyone, and no contact exists.
  final int emergencyContactCount;
}
