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
import '../../../../core/theme/tokens/rm_radius.dart';
import '../../../../core/theme/tokens/rm_sizing.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_halo.dart';
import '../../../../core/widgets/rm_icon.dart';
import '../../../../l10n/app_localizations.dart';

/// The designed emergency affordance, with no emergency behaviour.
class SosButton extends StatelessWidget {
  const SosButton({required this.onPressed, super.key, this.expanded = false});

  final VoidCallback onPressed;

  /// Fills the row instead of holding the design's fixed width.
  ///
  /// Used when the actions stack vertically at a large text scale. SOS never
  /// shrinks below its designed size and never ellipsises its label.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);

    final Widget button = Semantics(
      container: true,
      button: true,
      label: l10n.sosLabel,
      excludeSemantics: true,
      child: Material(
        color: c.danger,
        borderRadius: RmRadius.brMd,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            height: RmSizing.ctaMd,
            width: expanded ? null : _designWidth,
            constraints: expanded
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
                  l10n.sosLabel,
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

    // The halo is the source's `rm-ring`. It is decoration and carries no
    // emergency meaning; see rm_halo.dart.
    return RmHalo(color: c.danger, borderRadius: RmRadius.md, child: button);
  }

  /// The design's fixed SOS width (104px scaled).
  static const double _designWidth = 148;
}
