// ─────────────────────────────────────────────────────────────
// RideMate — Motion tokens
//
// Source of truth: docs/claude-designs/RideMate App.dc.html (immutable).
//
// The design source declares exactly two animations, in its only <style>
// block (lines 17-18):
//
//   @keyframes rm-pulse { 0%,100% { opacity:1; transform:scale(1); }
//                         50%     { opacity:.35; transform:scale(.82); } }
//   @keyframes rm-ring  { 0%   { box-shadow: 0 0 0 0    rgba(229,72,77,.45); }
//                         100% { box-shadow: 0 0 0 14px rgba(229,72,77,0); } }
//
// Durations come from the usages: `rm-pulse 1.4s infinite` on the live-trip
// status dot, `rm-ring 1.8s infinite` on the SOS surfaces.
//
// NOTE: `ring` is provided here purely as a visual primitive. It carries no
// SOS semantics. SOS behaviour (arming, countdown, trigger, escalation,
// cancellation) is Phase 6 and is gated behind a written specification.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/animation.dart';

import 'rm_spacing.dart';

/// Durations and curves.
abstract final class RmMotion {
  const RmMotion._();

  /// Press feedback, small state flips.
  static const Duration fast = Duration(milliseconds: 180);

  /// Standard transitions.
  static const Duration base = Duration(milliseconds: 260);

  /// Sheets and larger surfaces.
  static const Duration slow = Duration(milliseconds: 380);

  /// One full cycle of `rm-pulse` (live status dot).
  static const Duration pulse = Duration(milliseconds: 1400);

  /// One full cycle of `rm-ring` (expanding halo).
  static const Duration ring = Duration(milliseconds: 1800);

  /// Minimum opacity reached by `rm-pulse`.
  static const double pulseMinOpacity = 0.35;

  /// Minimum scale reached by `rm-pulse`.
  static const double pulseMinScale = 0.82;

  /// Peak halo radius of `rm-ring`, in logical pixels (design 14px).
  static final double ringMaxSpread = RmScale.of(14);

  /// Peak alpha of the `rm-ring` halo, fading to zero.
  static const double ringStartOpacity = 0.45;

  /// Decelerating curve for entrances and standard transitions.
  static const Cubic ease = Cubic(0.22, 0.61, 0.36, 1);

  /// Gentle overshoot for sheets and selection feedback.
  static const Cubic spring = Cubic(0.34, 1.3, 0.5, 1);
}
