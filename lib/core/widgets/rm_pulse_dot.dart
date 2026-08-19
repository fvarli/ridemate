// ─────────────────────────────────────────────────────────────
// RideMate — Pulsing status dot
//
// Source of truth: docs/claude-designs/RideMate App.dc.html (immutable).
//
// The source's `rm-pulse` keyframe: opacity and scale drop together, then
// recover. It appears three times, in two different containers —
//
//   * inside the Home location chip and the Active Trip live pill (via
//     [RmStatusPill]), and
//   * bare, beside Active Trip's "Canlı konumun … paylaşılıyor" footer.
//
// The bare use is why this is a primitive rather than a private part of the
// pill.
//
// It is a purely visual "this is live" cue. It carries no trip, presence, SOS
// or connection semantics, and it is decorative to a screen reader — whatever
// the dot means, the text beside it has to say.
//
// REDUCED MOTION: this animation repeats indefinitely, which WCAG 2.2.2 says a
// member must be able to stop. It honours `MediaQuery.disableAnimationsOf` and
// renders a still dot instead.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../theme/tokens/rm_motion.dart';
import '../theme/tokens/rm_spacing.dart';

/// A small round status dot, optionally pulsing.
class RmPulseDot extends StatefulWidget {
  const RmPulseDot({
    required this.color,
    super.key,
    this.pulsing = false,
    this.size = defaultSize,
  });

  final Color color;

  /// Animates with the source's `rm-pulse` rhythm.
  ///
  /// Ignored when the member has asked for reduced motion.
  final bool pulsing;

  final double size;

  /// The size the source draws in both of its containers (design 7px).
  static const double defaultSize = RmSpacing.md;

  @override
  State<RmPulseDot> createState() => _RmPulseDotState();
}

class _RmPulseDotState extends State<RmPulseDot>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _curved;

  /// Whether the dot should actually animate right now.
  bool _wants(BuildContext context) =>
      widget.pulsing && !MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(RmPulseDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  /// Starts or stops the controller to match the current intent.
  ///
  /// The curve is built once alongside the controller rather than on every
  /// build — a CurvedAnimation allocated per frame is never disposed.
  void _sync() {
    final bool wanted = _wants(context);
    if (wanted && _controller == null) {
      _controller = AnimationController(vsync: this, duration: RmMotion.pulse)
        ..repeat(reverse: true);
      _curved = CurvedAnimation(parent: _controller!, curve: RmMotion.ease);
    } else if (!wanted && _controller != null) {
      _controller!.dispose();
      _controller = null;
      _curved = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget dot = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    );

    final Animation<double>? curved = _curved;
    if (curved == null) return dot;

    return FadeTransition(
      opacity: Tween<double>(
        begin: 1,
        end: RmMotion.pulseMinOpacity,
      ).animate(curved),
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 1,
          end: RmMotion.pulseMinScale,
        ).animate(curved),
        child: dot,
      ),
    );
  }
}
