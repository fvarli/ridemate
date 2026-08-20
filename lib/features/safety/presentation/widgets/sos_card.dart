// ─────────────────────────────────────────────────────────────
// RideMate — SOS card
//
// Source: "SAFETY · SOS" (immutable). The red gradient card, the haloed disc
// and the promise beneath the title.
//
// THE AFFORDANCE ONLY. THERE IS NO EMERGENCY BEHAVIOUR BEHIND IT.
//
// The whole card is the control. The design draws no separate button and its
// copy opens with `Bas` — an invitation — so a display-only card would both
// contradict the design and leave a safety control that looks actionable and
// silently is not. Pressing shows one message saying plainly that nobody was
// notified, and does nothing else. It shares that message with Active Trip's
// SOS button, because it is the same claim.
//
// Deliberately absent, every one of them:
//   no countdown            no confirmation dialog
//   no armed state          no triggered state
//   no cancelled state      no success copy
//   no phone call           no trusted-contact notification
//   no location sharing     no sosTriggered / emergencyActive field
//
// The design draws ONE of the eleven states this control would need. The other
// ten — pressed, confirming, countdown, armed, activated, cancelled,
// permission-denied, no-contacts, failed, expired — have no approved visual,
// and the two most likely real outcomes (permission denied, no contacts added)
// are among them. docs/architecture.md carries the written specification and
// the capabilities that must exist first. Nothing here is a head start on it.
//
// The promise renders verbatim. It is false — no location is sent, no contact
// is reached, there is no team — and it survives only because this screen is
// withheld from release builds and because pressing it says so immediately.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_radius.dart';
import '../../../../core/theme/tokens/rm_shadows.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_card.dart';
import '../../../../core/widgets/rm_halo.dart';
import '../../../../l10n/app_localizations.dart';

/// Outer disc diameter. Design 64px at RmScale.factor.
const double kSosDiscSize = 91;

/// Inner white disc. Design 48px at RmScale.factor.
const double kSosInnerDiscSize = 68;

/// The designed emergency affordance, with no emergency behaviour.
class SosCard extends StatelessWidget {
  const SosCard({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return RmCard(
      variant: RmCardVariant.gradient,
      gradient: c.heroDanger,
      // The design tints the glow to the card: `rgba(229,72,77,.3)`, not the
      // brand blue the gradient variant otherwise assumes.
      boxShadow: context.rmShadows.danger,
      onTap: onPressed,
      padding: const EdgeInsets.all(RmSpacing.xl),
      // Announced exactly as drawn, so a screen-reader user meets the same
      // claim a sighted one does — and the same correction on pressing it.
      semanticLabel: '${l10n.safetySosTitle}. ${l10n.safetySosPromise}',
      child: Row(
        children: <Widget>[
          // Decoration. The halo carries no emergency meaning and nothing
          // about it changes when the card is pressed.
          ExcludeSemantics(
            child: RmHalo(
              color: c.onPrimary.withValues(alpha: _kHaloOpacity),
              child: Container(
                width: kSosDiscSize,
                height: kSosDiscSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.onPrimary.withValues(alpha: _kDiscOpacity),
                  borderRadius: RmRadius.brPill,
                ),
                child: Container(
                  width: kSosInnerDiscSize,
                  height: kSosInnerDiscSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.onPrimary,
                    borderRadius: RmRadius.brPill,
                  ),
                  child: Text(
                    l10n.sosLabel,
                    // Design 14px at RmScale.factor is 20.
                    style: RmTypography.bodyLg.copyWith(
                      color: c.danger,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: RmSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  l10n.safetySosTitle,
                  style: RmTypography.label.copyWith(color: c.onPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: RmSpacing.xs),
                Text(
                  l10n.safetySosPromise,
                  style: RmTypography.captionSm.copyWith(
                    color: c.onPrimary.withValues(alpha: _kPromiseOpacity),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// `rgba(255,255,255,.18)` — the disc behind the white one.
  static const double _kDiscOpacity = 0.18;

  /// The halo is fainter still; RmMotion fades it out from there.
  static const double _kHaloOpacity = 0.35;

  /// `rgba(255,255,255,.85)` on the promise.
  static const double _kPromiseOpacity = 0.85;
}
