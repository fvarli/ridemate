// ─────────────────────────────────────────────────────────────
// RideMate — SOS button
//
// Source: docs/claude-designs/RideMate App.dc.html, "ACTIVE TRIP" (immutable).
//
// THE AFFORDANCE ONLY. THERE IS NO EMERGENCY BEHAVIOUR BEHIND IT.
//
// The red fill and the expanding `rm-ring` halo are reproduced because the
// design draws them; RmMotion's own header records that the ring token carries
// no SOS semantics. Tapping shows one message saying plainly that nobody was
// notified, and does nothing else.
//
// Deliberately absent, every one of them:
//   no countdown            no confirmation dialog
//   no armed state          no triggered state
//   no cancelled state      no success copy
//   no phone call           no trusted-contact notification
//   no location sharing     no sosTriggered / emergencyActive field
//
// No emergency number is offered either. None appears in the approved design,
// and hard-coding one country's would invent both safety guidance and a
// product behaviour for every market RideMate might later serve.
//
// The real SOS state machine — idle, armed, countdown, triggered, escalated,
// cancelled — is Phase 6, and architecture.md already gates it behind a written
// specification. Nothing here may be mistaken for a head start on it.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/icons/rm_icons.dart';
import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_motion.dart';
import '../../../../core/theme/tokens/rm_radius.dart';
import '../../../../core/theme/tokens/rm_sizing.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_icon.dart';
import '../../../../l10n/app_localizations.dart';

/// The designed emergency affordance, with no emergency behaviour.
class SosButton extends StatefulWidget {
  const SosButton({required this.onPressed, super.key, this.expanded = false});

  final VoidCallback onPressed;

  /// Fills the row instead of holding the design's fixed width.
  ///
  /// Used when the actions stack vertically at a large text scale. SOS never
  /// shrinks below its designed size and never ellipsises its label.
  final bool expanded;

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton>
    with SingleTickerProviderStateMixin {
  AnimationController? _halo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The halo repeats indefinitely, so a member who has asked for reduced
    // motion gets a still button (WCAG 2.2.2).
    if (MediaQuery.disableAnimationsOf(context)) {
      _halo?.dispose();
      _halo = null;
    } else {
      _halo ??= AnimationController(vsync: this, duration: RmMotion.ring)
        ..repeat();
    }
  }

  @override
  void dispose() {
    _halo?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AnimationController? halo = _halo;

    final Widget button = Semantics(
      container: true,
      button: true,
      label: l10n.activeTripSos,
      excludeSemantics: true,
      child: Material(
        color: c.danger,
        borderRadius: RmRadius.brMd,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onPressed,
          child: Container(
            height: RmSizing.ctaMd,
            width: widget.expanded ? null : _designWidth,
            constraints: widget.expanded
                ? null
                : const BoxConstraints(minWidth: _designWidth),
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: RmSpacing.lg,
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                RmIcon(
                  RmIcons.alertTriangle,
                  size: RmIconSize.sm,
                  color: c.onPrimary,
                ),
                const SizedBox(width: RmSpacing.sm),
                // Never ellipsised: a truncated safety label is worse than a
                // wrapped row.
                Text(
                  l10n.activeTripSos,
                  style: RmTypography.label.copyWith(
                    color: c.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  softWrap: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (halo == null) return button;

    return AnimatedBuilder(
      animation: halo,
      builder: (BuildContext context, Widget? child) => CustomPaint(
        painter: _HaloPainter(
          progress: halo.value,
          color: c.danger,
          radius: RmRadius.md,
        ),
        child: child,
      ),
      child: button,
    );
  }

  /// The design's fixed SOS width (104px scaled).
  static const double _designWidth = 148;
}

/// The source's `rm-ring`: a halo that expands out of the button and fades.
class _HaloPainter extends CustomPainter {
  const _HaloPainter({
    required this.progress,
    required this.color,
    required this.radius,
  });

  final double progress;
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final double spread = RmMotion.ringMaxSpread * progress;
    final double alpha = RmMotion.ringStartOpacity * (1 - progress);
    if (alpha <= 0) return;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        (Offset.zero & size).inflate(spread),
        Radius.circular(radius + spread),
      ),
      Paint()..color = color.withValues(alpha: alpha),
    );
  }

  @override
  bool shouldRepaint(_HaloPainter old) =>
      old.progress != progress || old.color != color || old.radius != radius;
}
