// ─────────────────────────────────────────────────────────────
// RideMate — Journey markers
//
// Source of truth: docs/claude-designs/RideMate App.dc.html (immutable).
//
// The design uses one consistent visual vocabulary for the two ends of a
// journey, across three different contexts:
//
//   origin       a hollow ring, 3px brand-blue border, transparent centre
//   destination  a solid ink teardrop — a square with three rounded corners,
//                rotated 45° so the sharp corner points at the place
//
// It appears on the Search from/to card, the Route Details timeline, and the
// Home map. Keeping one primitive means the two ends can never drift apart.
// ─────────────────────────────────────────────────────────────

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens/rm_colors.dart';

/// Which end of a journey a marker represents.
enum RmJourneyPoint {
  /// Where the journey starts. A hollow ring.
  origin,

  /// Where the journey ends. A solid teardrop.
  destination,
}

/// A single origin or destination marker.
class RmJourneyMarker extends StatelessWidget {
  const RmJourneyMarker(this.point, {super.key, this.size = defaultSize});

  /// 16 — the design's 11px marker at the 1.4239 scale, rounded.
  static const double defaultSize = 16;

  final RmJourneyPoint point;

  /// Outer diameter. The ring's border scales with it.
  final double size;

  /// Ring thickness as a fraction of the box, from the design's 3px on 11px.
  static const double _ringRatio = 0.27;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    // Decorative: the adjacent label already says which end this is.
    return ExcludeSemantics(
      child: switch (point) {
        RmJourneyPoint.origin => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: c.primary, width: size * _ringRatio),
          ),
        ),
        RmJourneyPoint.destination => Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: c.ink,
              // Three rounded corners; the fourth stays square and, once
              // rotated, becomes the point.
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(size),
                topRight: Radius.circular(size),
                bottomRight: Radius.circular(size),
              ),
            ),
          ),
        ),
      },
    );
  }
}
