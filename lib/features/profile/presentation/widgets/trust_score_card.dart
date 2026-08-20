// ─────────────────────────────────────────────────────────────
// RideMate — Trust Score card
//
// Source: "PROFILE · TRUST" (immutable). The ring, the tier badge, the
// next-step line and the four breakdown rows, in one card that rides up over
// the header.
//
// The ring is drawn from `trustScore / 100`. Putting a 0..100 figure on a
// 0..1 arc is geometry, and the app already does exactly this at
// verification_screen.dart; what is forbidden is producing the figure. See
// profile_snapshot.dart.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/format/rm_formatters.dart';
import '../../../../core/icons/rm_icons.dart';
import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_card.dart';
import '../../../../core/widgets/rm_chip.dart';
import '../../../../core/widgets/rm_meters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/profile_snapshot.dart';
import 'trust_factor_row.dart';

/// Ring diameter. Design 72px at RmScale.factor.
const double kTrustRingSize = 102;

/// Ring stroke. Design 7px at RmScale.factor.
const double kTrustRingStroke = 10;

/// The Trust Score card.
class TrustScoreCard extends StatelessWidget {
  const TrustScoreCard({required this.snapshot, super.key});

  final ProfileSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmFormatters f = RmFormatters.of(context);

    return RmCard(
      padding: const EdgeInsets.all(RmSpacing.screenGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Semantics(
                container: true,
                // The ring publishes its own numeric value, which would be
                // announced a second time and without its scale.
                excludeSemantics: true,
                label: l10n.profileTrustScoreSemanticLabel(
                  f.trustScore(snapshot.trustScore),
                ),
                child: RmTrustRing(
                  progress: snapshot.trustScore / 100,
                  size: kTrustRingSize,
                  strokeWidth: kTrustRingStroke,
                  color: c.success,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        f.trustScore(snapshot.trustScore),
                        style: RmTypography.numericMd.copyWith(color: c.ink),
                        maxLines: 1,
                      ),
                      Text(
                        l10n.profileTrustScoreOutOf,
                        style: RmTypography.micro.copyWith(color: c.muted),
                        maxLines: 1,
                      ),
                    ],
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
                      l10n.profileTrustScoreTitle,
                      style: RmTypography.labelSm.copyWith(color: c.ink),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: RmSpacing.xs),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: RmBadge(
                        // U+2605 is absent from both bundled families, so the
                        // comp's star ships as an icon (D-icon-4).
                        icon: RmIcons.starFilled,
                        label: l10n.profileTrustTier(
                          f.percentOf100(snapshot.tierPercentile),
                        ),
                      ),
                    ),
                    const SizedBox(height: RmSpacing.xs),
                    Text(
                      l10n.profileTrustNextStep,
                      style: RmTypography.overline.copyWith(color: c.muted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: RmSpacing.lg),
          TrustBreakdown(factors: snapshot.factors),
        ],
      ),
    );
  }
}
