// ─────────────────────────────────────────────────────────────
// RideMate — Reviews summary card
//
// Source: "REVIEWS · İTİBAR" (immutable). The headline rating and star row on
// the left, the histogram on the right.
//
// The headline is a declared figure. It is not an average of the histogram
// beside it, nor of the cards below it, however exactly those happen to agree
// — see review_entry.dart.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/format/rm_formatters.dart';
import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/review_entry.dart';
import 'rating_distribution.dart';
import 'star_row.dart';

/// How much of the card the headline block may take.
///
/// The comp gives it a little under half; the rest belongs to the histogram,
/// which stops meaning anything once it is narrow.
const double kSummaryHeadlineShare = 0.45;

/// The summary card.
class ReviewsSummaryCard extends StatelessWidget {
  const ReviewsSummaryCard({required this.snapshot, super.key});

  final ReviewsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmFormatters f = RmFormatters.of(context);

    return RmCard(
      padding: const EdgeInsets.all(RmSpacing.screenGutter),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) => Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Capped so the headline block cannot starve the histogram. The
            // comp gives the left column a little under half the card, and
            // `73 değerlendirme` is long enough — longer still in English and
            // at large text scales — to take the rest if left unbounded.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * kSummaryHeadlineShare,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  FittedBox(
                    child: Text(
                      f.rating(snapshot.averageRating),
                      style: RmTypography.numericXl.copyWith(color: c.ink),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: RmSpacing.xxs),
                  FittedBox(child: StarRow(rating: snapshot.averageRating)),
                  const SizedBox(height: RmSpacing.xxs),
                  Text(
                    l10n.reviewsCount(snapshot.reviewCount),
                    style: RmTypography.micro.copyWith(color: c.muted),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: RmSpacing.lg),
            Expanded(child: RatingDistribution(buckets: snapshot.distribution)),
          ],
        ),
      ),
    );
  }
}
