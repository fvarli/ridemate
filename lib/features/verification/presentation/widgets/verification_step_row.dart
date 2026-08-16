// ─────────────────────────────────────────────────────────────
// RideMate — Verification step row
//
// Source: docs/claude-designs/RideMate App.dc.html, "VERIFICATION" (immutable).
//
// Four states, exactly as drawn:
//   verified    green filled indicator + check, green status text
//   inProgress  emphasised 2dp border, the only step shadow, a ring indicator
//               with one pale quadrant (static in the source — NOT animated),
//               and a trailing action
//   pending     hollow indicator, whole row at 62% opacity
//   optional    visually identical to pending; only the status text differs
//
// The pending/optional collision is the design's, not ours. It is flagged in
// docs/design-system.md. Their statuses stay distinct in the type system and
// in the accessibility tree so a future visual treatment is a local change.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/icons/rm_icons.dart';
import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_radius.dart';
import '../../../../core/theme/tokens/rm_shadows.dart';
import '../../../../core/theme/tokens/rm_sizing.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_button.dart';
import '../../../../core/widgets/rm_icon.dart';
import '../../domain/verification_state.dart';

/// The opacity the design applies to steps that have not started.
const double _kNotStartedOpacity = 0.62;

/// The 26px indicator from the design, scaled.
const double _kIndicatorSize = 36;

/// One row of the verification list.
class VerificationStepRow extends StatelessWidget {
  const VerificationStepRow({
    required this.title,
    required this.status,
    required this.statusLabel,
    super.key,
    this.titleQualifier,
    this.actionLabel,
    this.onAction,
  });

  final String title;

  /// A de-emphasised suffix, e.g. the licence step's "· if you drive".
  final String? titleQualifier;

  final VerificationStepStatus status;

  /// The already-localized status line.
  final String statusLabel;

  /// Trailing action, shown only for the in-progress step.
  final String? actionLabel;
  final VoidCallback? onAction;

  bool get _isNotStarted =>
      status == VerificationStepStatus.pending ||
      status == VerificationStepStatus.optional;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final bool emphasised = status == VerificationStepStatus.inProgress;

    final Widget row = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RmSpacing.lg,
        vertical: RmSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: RmRadius.brLg,
        border: Border.all(
          color: emphasised ? c.primary : c.border,
          width: emphasised
              ? RmSizing.borderWidthEmphasis
              : RmSizing.borderWidth,
        ),
        // The in-progress row is the only step the design elevates.
        boxShadow: emphasised ? context.rmShadows.selected : RmShadows.none,
      ),
      child: Row(
        children: <Widget>[
          // The informational part is one node: "{title}. {status}". The
          // status text is the ONLY thing distinguishing pending from
          // optional, so it must be spoken.
          Expanded(
            child: Semantics(
              container: true,
              label: '$title. $statusLabel',
              excludeSemantics: true,
              child: Row(
                children: <Widget>[
                  _StepIndicator(status: status),
                  const SizedBox(width: RmSpacing.lg),
                  Expanded(
                    child: _StepText(
                      title: title,
                      titleQualifier: titleQualifier,
                      statusLabel: statusLabel,
                      statusColor: _statusColor(c),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(width: RmSpacing.md),
            // Outside the label above, so it stays a separate, actionable node.
            RmButton(
              label: actionLabel!,
              size: RmButtonSize.sm,
              fullWidth: false,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );

    return _isNotStarted
        ? Opacity(opacity: _kNotStartedOpacity, child: row)
        : row;
  }

  Color _statusColor(RmColors c) => switch (status) {
    VerificationStepStatus.verified => c.success,
    VerificationStepStatus.inProgress => c.sub,
    VerificationStepStatus.pending ||
    VerificationStepStatus.optional => c.faint,
  };
}

/// Title (with its optional de-emphasised suffix) over the status line.
class _StepText extends StatelessWidget {
  const _StepText({
    required this.title,
    required this.titleQualifier,
    required this.statusLabel,
    required this.statusColor,
  });

  final String title;
  final String? titleQualifier;
  final String statusLabel;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text.rich(
          TextSpan(
            style: RmTypography.body.copyWith(color: c.ink),
            children: <InlineSpan>[
              TextSpan(text: title),
              if (titleQualifier != null)
                TextSpan(
                  text: titleQualifier,
                  style: RmTypography.caption.copyWith(color: c.faint),
                ),
            ],
          ),
        ),
        const SizedBox(height: RmSpacing.xxs),
        Text(
          statusLabel,
          style: RmTypography.caption.copyWith(color: statusColor),
        ),
      ],
    );
  }
}

/// The leading state indicator.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.status});

  final VerificationStepStatus status;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return switch (status) {
      VerificationStepStatus.verified => Container(
        width: _kIndicatorSize,
        height: _kIndicatorSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: c.success, shape: BoxShape.circle),
        child: RmIcon(
          RmIcons.check,
          size: _kIndicatorSize * 0.55,
          color: c.onPrimary,
        ),
      ),
      // A ring with one pale quadrant. Static, exactly as the source draws it:
      // animating it would imply live progress we cannot actually report.
      VerificationStepStatus.inProgress => SizedBox(
        width: _kIndicatorSize,
        height: _kIndicatorSize,
        child: CustomPaint(
          painter: _InProgressRingPainter(
            color: c.primary,
            gapColor: c.primarySoftBorder,
          ),
        ),
      ),
      VerificationStepStatus.pending ||
      VerificationStepStatus.optional => Container(
        width: _kIndicatorSize,
        height: _kIndicatorSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: c.disabled,
            width: RmSizing.borderWidthEmphasis,
          ),
        ),
      ),
    };
  }
}

class _InProgressRingPainter extends CustomPainter {
  const _InProgressRingPainter({required this.color, required this.gapColor});

  final Color color;
  final Color gapColor;

  static const double _stroke = 3.5;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = (Offset.zero & size).deflate(_stroke / 2);
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;

    // Three quarters in the brand colour, the trailing quarter pale — the
    // "border-right-color" trick the source uses.
    canvas.drawArc(rect, -1.0472, 5.236, false, paint..color = color);
    canvas.drawArc(
      rect,
      -1.0472 + 5.236,
      1.0472,
      false,
      paint..color = gapColor,
    );
  }

  @override
  bool shouldRepaint(_InProgressRingPainter old) =>
      old.color != color || old.gapColor != gapColor;
}
