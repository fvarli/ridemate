// ─────────────────────────────────────────────────────────────
// RideMate — One thing somebody said about this member
//
// A rating, who gave it, which side they were on, and which journey it refers
// to. Every one of those is a field the server sent; none is worked out here.
//
// WHAT IS NOT ON THIS CARD, AND WHY
//
// No average, no total, no distribution, no trust score and no badge: RideMate
// publishes no reputation, and the member's own screen is not an exception —
// a figure here would be one this client computed from a page of a list the
// backend deliberately withholds part of.
//
// No identifier of any kind. [ReceivedReview] carries no route, trip, seat
// request or account id precisely so that no screen can address one, and this
// card adds nothing.
//
// Nothing about release. Whether the counterpart wrote a review, and whether
// this one appeared because they did or because the period ran out, is the
// fact the rule exists to withhold. The card knows only that the server sent
// it.
//
// A RATING IS AN OPINION, NOT A RECORD
//
// The journey line attributes the rating; it does not certify that anybody
// travelled. Nothing here says verified, confirmed, or completed.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/format/rm_formatters.dart';
import '../../../../core/format/rm_text_conventions.dart';
import '../../../../core/reviews/review.dart';
import '../../../../core/routes/departure.dart';
import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_avatar.dart';
import '../../../../core/widgets/rm_card.dart';
import '../../../../core/widgets/rm_rating_display.dart';
import '../../../../l10n/app_localizations.dart';

class ReceivedReviewCard extends StatelessWidget {
  const ReceivedReviewCard({required this.review, super.key});

  final ReceivedReview review;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmColors c = context.rmColors;
    final RmFormatters f = RmFormatters.of(context);

    final ReviewReviewer reviewer = review.reviewer;
    final ReviewJourney journey = review.journey;

    // The server's own role, never inferred from which screen this is. The
    // same account is a driver on journeys it published and a passenger on
    // journeys it asked to join, sometimes on the same day.
    final String role = switch (reviewer.role) {
      ReviewerRole.driver => l10n.receivedReviewsRoleDriver,
      ReviewerRole.passenger => l10n.receivedReviewsRolePassenger,
    };
    final String rating = l10n.receivedReviewRatingSemanticLabel(review.rating);
    final String trip = RmTextConventions.route(
      journey.origin,
      journey.destination,
    );
    final String departure = _departure(f, journey);

    return RmCard(
      // One node for the whole card, so a screen reader hears a rating about a
      // journey rather than six unrelated fragments — and so the arrow between
      // two places is not the only thing carrying the direction.
      child: Semantics(
        container: true,
        label: l10n.receivedReviewCardSemanticLabel(
          reviewer.displayName,
          role,
          rating,
          trip,
          departure,
        ),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  RmAvatar(
                    // The server's letters, as they arrived. Turkish casing
                    // makes those a rule the backend owns.
                    initials: reviewer.initials,
                    // Nothing verifies anybody.
                    verification: RmVerification.none,
                    identity: RmIdentity.purple,
                  ),
                  const SizedBox(width: RmSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          reviewer.displayName,
                          style: RmTypography.body.copyWith(color: c.ink),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          role,
                          style: RmTypography.caption.copyWith(color: c.sub),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: RmSpacing.sm),
                  RmRatingDisplay(rating: review.rating, semanticLabel: rating),
                ],
              ),
              const SizedBox(height: RmSpacing.sm),
              // Which journey this refers to, so several ratings from the same
              // person can be told apart. Attribution, not proof.
              Text(trip, style: RmTypography.body.copyWith(color: c.ink)),
              const SizedBox(height: RmSpacing.xs),
              Text(
                departure,
                style: RmTypography.caption.copyWith(color: c.sub),
              ),
              const SizedBox(height: RmSpacing.xs),
              Text(
                l10n.receivedReviewSubmittedAt(f.instant(review.submittedAt)),
                style: RmTypography.caption.copyWith(color: c.sub),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The day and wall-clock time the driver published.
  ///
  /// Not converted to the reader's zone, unlike [RmFormatters.instant]: a
  /// departure is a wall clock in the route's own timezone, and shifting it
  /// would be this client second-guessing the server about when a journey
  /// left.
  String _departure(RmFormatters f, ReviewJourney journey) {
    final DepartureDate date = journey.departureDate;
    final DepartureTime time = journey.departureTime;

    return '${f.calendarDate(date.year, date.month, date.day)}'
        '${RmFormatters.separator}'
        '${f.hourMinute(time.hour, time.minute)}';
  }
}
