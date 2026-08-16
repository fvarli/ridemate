// ─────────────────────────────────────────────────────────────
// RideMate — Status pill
//
// Source of truth: docs/claude-designs/RideMate App.dc.html (immutable).
//
// A pill carrying a status dot and a label. The design uses it twice:
//   * Home        the current location chip (tinted surface, brand label)
//   * Active Trip the live-trip pill (ink fill, white label, pulsing dot)
//
// The pulsing variant reuses the source's `rm-pulse` keyframe. It is a purely
// visual "this is live" cue and carries no trip or SOS semantics.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../theme/tokens/rm_colors.dart';
import '../theme/tokens/rm_motion.dart';
import '../theme/tokens/rm_radius.dart';
import '../theme/tokens/rm_sizing.dart';
import '../theme/tokens/rm_spacing.dart';
import '../theme/tokens/rm_typography.dart';

/// Fill treatment of an [RmStatusPill].
enum RmStatusPillTone {
  /// Tinted brand surface with a brand label — the Home location chip.
  info,

  /// Solid ink with an inverse label — the live-trip pill.
  ink,
}

/// A dot-and-label status pill.
class RmStatusPill extends StatelessWidget {
  const RmStatusPill({
    required this.label,
    super.key,
    this.tone = RmStatusPillTone.info,
    this.dotColor,
    this.pulsing = false,
    this.semanticLabel,
  });

  final String label;
  final RmStatusPillTone tone;

  /// Defaults to the success green the design uses for both instances.
  final Color? dotColor;

  /// Animates the dot with the source's `rm-pulse` rhythm.
  final bool pulsing;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    final (Color background, Color foreground, Color? border) = switch (tone) {
      RmStatusPillTone.info => (
        c.primarySoft,
        c.primaryText,
        c.primarySoftBorder,
      ),
      RmStatusPillTone.ink => (c.ink, c.onInk, null),
    };

    return Semantics(
      container: true,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: RmSpacing.lg,
          vertical: RmSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: RmRadius.brPill,
          border: border == null
              ? null
              : Border.all(color: border, width: RmSizing.borderWidth),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _StatusDot(color: dotColor ?? c.success, pulsing: pulsing),
            const SizedBox(width: RmSpacing.sm),
            Flexible(
              child: Text(
                label,
                style: RmTypography.label.copyWith(color: foreground),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatefulWidget {
  const _StatusDot({required this.color, required this.pulsing});

  final Color color;
  final bool pulsing;

  static const double size = RmSpacing.md;

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.pulsing) _start();
  }

  @override
  void didUpdateWidget(_StatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulsing && _controller == null) {
      _start();
    } else if (!widget.pulsing && _controller != null) {
      _controller!.dispose();
      _controller = null;
    }
  }

  void _start() {
    _controller = AnimationController(vsync: this, duration: RmMotion.pulse)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget dot = Container(
      width: _StatusDot.size,
      height: _StatusDot.size,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    );

    final AnimationController? controller = _controller;
    if (controller == null) return dot;

    // The source's rm-pulse: opacity and scale drop together, then recover.
    final Animation<double> curved = CurvedAnimation(
      parent: controller,
      curve: RmMotion.ease,
    );
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
