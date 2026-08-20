// ─────────────────────────────────────────────────────────────
// RideMate — Reviews
//
// Source: docs/claude-designs/RideMate App.dc.html, "REVIEWS · İTİBAR"
// (immutable).
//
// Four stacked pieces, as drawn: a back control and title, the summary card,
// the attribute tags, and the review cards.
//
// PHASE 6 SCOPE. There is no reviews backend and no way to write one. The
// comp draws no compose affordance, no sort, no filter, no pagination and no
// "see more", so none of those is invented here — the screen is exactly as
// read-only as the design makes it.
//
// It also draws no moderation state of any kind. Reporting a review, hiding
// one, or marking one as coming from a completed journey are all product and
// policy decisions nobody has made; see docs/design-system.md §8.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/icons/rm_icons.dart';
import '../../../core/theme/tokens/rm_colors.dart';
import '../../../core/theme/tokens/rm_spacing.dart';
import '../../../core/theme/tokens/rm_typography.dart';
import '../../../core/widgets/rm_icon_button.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/review_entry.dart';
import '../domain/review_fixtures.dart';
import 'widgets/review_card.dart';
import 'widgets/review_tags.dart';
import 'widgets/reviews_summary_card.dart';

/// A member's reputation, in full.
class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ReviewsSnapshot snapshot = mockReviews(l10n);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                RmSpacing.screenGutter,
                RmSpacing.md,
                RmSpacing.screenGutter,
                0,
              ),
              child: Row(
                children: <Widget>[
                  RmIconButton(
                    icon: RmIcons.chevronLeft,
                    semanticLabel: l10n.commonBack,
                    onPressed: () => _back(context),
                  ),
                  const SizedBox(width: RmSpacing.md),
                  Expanded(
                    child: Text(
                      l10n.reviewsTitle,
                      style: RmTypography.label.copyWith(color: c.ink),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  RmSpacing.screenGutter,
                  RmSpacing.lg,
                  RmSpacing.screenGutter,
                  RmSpacing.xl,
                ),
                children: <Widget>[
                  ReviewsSummaryCard(snapshot: snapshot),
                  const SizedBox(height: RmSpacing.lg),
                  ReviewTags(tags: snapshot.tags),
                  const SizedBox(height: RmSpacing.lg),
                  for (int i = 0; i < snapshot.entries.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(height: RmSpacing.md),
                    ReviewCard(entry: snapshot.entries[i]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Deep links land here with nothing beneath them, so falling back to Home
  /// keeps the control from being a dead end.
  static void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoutes.home);
    }
  }
}
