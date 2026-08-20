// ─────────────────────────────────────────────────────────────
// RideMate — Safety presentation model
//
// Source: docs/claude-designs/RideMate App.dc.html, "SAFETY · SOS"
// (immutable).
//
// SAFETY AFFORDANCE != EMERGENCY ACTION.
//
// The smallest model in the app, and deliberately so. Everything else the
// Safety Center shows is static copy, and the one field here is display data
// with nothing behind it: no trusted-contact store, no emergency dispatch, no
// telephony, no location, no notification channel and no backend.
//
// There is NO SosState enum, and adding one is not a small step. The design
// draws exactly one SOS state — idle — and a one-member enum is the seed of a
// machine whose other ten states nobody has designed. The written
// specification for them lives in docs/architecture.md; nothing may be
// implemented against it until it is approved.
//
// Nothing here may grow a `sosTriggered`, `emergencyActive`, `blockedUsers` or
// `reportSubmitted` field. A prototype that remembers a block is the most
// dangerous state this app could hold: it would let a member believe they are
// protected from someone when nothing of the kind happened.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

/// Everything the Safety Center renders.
@immutable
final class SafetySnapshot {
  const SafetySnapshot({required this.trustedContactCount});

  /// The figure in `2 kişi eklendi`.
  ///
  /// DISPLAY ONLY, and untrue: nothing stores a contact, so the subtitle
  /// asserts something that does not exist. It is one of the reasons this
  /// screen is kept out of release builds, and the first string that has to
  /// change if it ever becomes reachable.
  final int trustedContactCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SafetySnapshot &&
          other.trustedContactCount == trustedContactCount;

  @override
  int get hashCode => trustedContactCount.hashCode;
}
