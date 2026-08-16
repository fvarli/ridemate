// ─────────────────────────────────────────────────────────────
// RideMate — Trust ring and linear meters
//
// Source of truth: docs/claude-designs/RideMate App.dc.html (immutable).
//
// The source draws the trust ring as an SVG donut whose stroke-dasharray is
// the FULL circumference (2*pi*r) and whose stroke-dashoffset encodes the
// value — 201/80 on a r=32 ring is 60%, 195/16 on r=31 is 92%. That is a
// progress arc, so it is painted rather than shipped as an asset.
//
// Both meters are display-only. They render a number someone else computed;
// no trust or matching logic lives here.
// ─────────────────────────────────────────────────────────────

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens/rm_colors.dart';
import '../theme/tokens/rm_sizing.dart';

/// A circular progress ring, used for the Trust Score.
///
/// The source shows two treatments: white-on-brand while the score is still
/// being built, and green-on-neutral once complete. Pass [color] accordingly.
class RmTrustRing extends StatelessWidget {
  const RmTrustRing({
    required this.progress,
    super.key,
    this.size = RmSizing.trustRingSize,
    this.strokeWidth = RmSizing.trustRingStroke,
    this.color,
    this.trackColor,
    this.child,
    this.semanticLabel,
  });

  /// 0..1. Values outside the range are clamped rather than overdrawn.
  final double progress;

  final double size;
  final double strokeWidth;

  /// Arc colour. Defaults to the success green of the completed treatment.
  final Color? color;

  /// Track colour. Defaults to the neutral meter track.
  final Color? trackColor;

  /// Centre content, normally the score and its caption.
  final Widget? child;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return Semantics(
      label: semanticLabel,
      value: '${(progress.clamp(0.0, 1.0) * 100).round()}',
      excludeSemantics: semanticLabel != null,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(
            progress: progress.clamp(0.0, 1.0),
            color: color ?? c.success,
            trackColor: trackColor ?? c.meterTrack,
            strokeWidth: strokeWidth,
          ),
          child: child == null ? null : Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Rect arcRect = rect.deflate(strokeWidth / 2);

    final Paint track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;

    canvas.drawArc(arcRect, 0, 2 * math.pi, false, track);

    if (progress <= 0) return;

    final Paint arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      // The source sets stroke-linecap="round" on the value arc.
      ..strokeCap = StrokeCap.round
      ..color = color;

    // The source rotates the arc -90deg so it starts at twelve o'clock.
    canvas.drawArc(arcRect, -math.pi / 2, 2 * math.pi * progress, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}

/// A horizontal progress bar.
///
/// Used for route-compatibility wells, trust-score breakdown rows and the
/// review histogram. The corner radius always equals the height, as in the
/// source.
class RmLinearMeter extends StatelessWidget {
  const RmLinearMeter({
    required this.progress,
    super.key,
    this.height = RmSizing.meterHeight,
    this.color,
    this.trackColor,
    this.gradient,
    this.semanticLabel,
  });

  /// 0..1, clamped.
  final double progress;

  final double height;

  /// Fill colour. Ignored when [gradient] is set.
  final Color? color;

  final Color? trackColor;

  /// Fill gradient — the source uses one on the highlighted compatibility bar.
  final Gradient? gradient;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final double value = progress.clamp(0.0, 1.0);

    return Semantics(
      label: semanticLabel,
      value: '${(value * 100).round()}',
      excludeSemantics: semanticLabel != null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              ColoredBox(color: trackColor ?? c.meterTrack),
              // A zero value must render as a bare track, matching the
              // source's empty histogram row.
              if (value > 0)
                FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: value,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: gradient == null ? (color ?? c.primary) : null,
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(height),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
