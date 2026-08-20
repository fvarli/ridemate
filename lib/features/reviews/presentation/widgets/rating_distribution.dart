// ─────────────────────────────────────────────────────────────
// RideMate — Rating histogram
//
// Source: "REVIEWS · İTİBAR" (immutable). Four rows: 5, 4, 3 and an empty 2.
//
// DISPLAY ONLY. Each bar draws a declared share; nothing counts reviews and
// nothing rolls these up into the headline rating beside them. That the two
// happen to agree is a coincidence of the fixture — see review_entry.dart.
//
// RmLinearMeter publishes its fill as a bare number, which here would be
// announced as `92` next to a `5` and read as ninety-two reviews. Every row
// is therefore relabelled as the share it is, including the empty one: a
// screen-reader user gets the same four rows a sighted one sees.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/format/rm_formatters.dart';
import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_meters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/review_entry.dart';

/// Bar height. Design 5px at RmScale.factor, rounded to the meter token.
const double kDistributionBarHeight = 7;

/// The four histogram rows.
class RatingDistribution extends StatelessWidget {
  const RatingDistribution({required this.buckets, super.key});

  final List<RatingBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmFormatters f = RmFormatters.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < buckets.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: RmSpacing.sm),
          Semantics(
            container: true,
            excludeSemantics: true,
            label: l10n.reviewsDistributionSemanticLabel(
              f.count(buckets[i].stars),
              f.percent(buckets[i].share),
            ),
            child: Row(
              children: <Widget>[
                Text(
                  f.count(buckets[i].stars),
                  style: RmTypography.numericMicro.copyWith(color: c.muted),
                  maxLines: 1,
                ),
                const SizedBox(width: RmSpacing.sm),
                Expanded(
                  child: RmLinearMeter(
                    progress: buckets[i].share,
                    height: kDistributionBarHeight,
                    color: c.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
