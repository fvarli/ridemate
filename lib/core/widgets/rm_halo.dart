// ─────────────────────────────────────────────────────────────
// RideMate — Expanding halo
//
// Source of truth: docs/claude-designs/RideMate App.dc.html (immutable).
//
// The source's `rm-ring` keyframe: a shape grows out of its element and fades.
// It is drawn on Active Trip's SOS button (a rounded rectangle) and on the
// Safety Center's SOS disc (a circle), which is why it lives here rather than
// in either feature.
//
// IT CARRIES NO MEANING. RmMotion's header already records that the ring token
// has no emergency semantics; neither does this. It is a decoration, it is
// excluded from the accessibility tree, and it says nothing about whether
// anything is happening.
//
// It repeats indefinitely, so it stops entirely for a member who has asked for
// reduced motion (WCAG 2.2.2) — and because it never settles, pumpAndSettle
// hangs on any screen that shows it.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../theme/tokens/rm_motion.dart';

/// Wraps [child] in the source's expanding, fading halo.
class RmHalo extends StatefulWidget {
  const RmHalo({
    required this.color,
    required this.child,
    super.key,
    this.borderRadius,
  });

  final Color color;

  /// Corner radius of the halo. Null draws a circle around [child].
  final double? borderRadius;

  final Widget child;

  @override
  State<RmHalo> createState() => _RmHaloState();
}

class _RmHaloState extends State<RmHalo> with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller?.dispose();
      _controller = null;
    } else {
      _controller ??= AnimationController(vsync: this, duration: RmMotion.ring)
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AnimationController? controller = _controller;
    if (controller == null) return widget.child;

    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) => CustomPaint(
        painter: _HaloPainter(
          progress: controller.value,
          color: widget.color,
          borderRadius: widget.borderRadius,
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _HaloPainter extends CustomPainter {
  const _HaloPainter({
    required this.progress,
    required this.color,
    required this.borderRadius,
  });

  final double progress;
  final Color color;
  final double? borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final double spread = RmMotion.ringMaxSpread * progress;
    final double alpha = RmMotion.ringStartOpacity * (1 - progress);
    if (alpha <= 0) return;

    final Rect rect = (Offset.zero & size).inflate(spread);
    // A null radius means the child is round, so the halo follows it.
    final double radius = (borderRadius ?? size.shortestSide / 2) + spread;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()..color = color.withValues(alpha: alpha),
    );
  }

  @override
  bool shouldRepaint(_HaloPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.borderRadius != borderRadius;
}
