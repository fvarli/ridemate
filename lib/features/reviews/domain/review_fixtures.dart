// ─────────────────────────────────────────────────────────────
// RideMate — Reviews fixture
//
// Transcribed from the approved design. Read review_entry.dart first: three
// of these numbers reconstruct each other by coincidence, and none of those
// coincidences is a rule.
//
// The prose is localized, so this is a function of AppLocalizations rather
// than a const: a fixture that hardcodes Turkish stops being a fixture the
// moment the app is opened in English.
// ─────────────────────────────────────────────────────────────

import '../../../core/format/rm_formatters.dart';
import '../../../core/widgets/rm_avatar.dart';
import '../../../l10n/app_localizations.dart';
import 'review_entry.dart';

/// The rating histogram, exactly as drawn.
///
/// The comp has no 1-star row, so there are four bars and the last one is
/// empty. The empty bar is kept rather than dropped: a histogram that stops
/// where the data stops implies nobody ever rated below three.
const List<RatingBucket> kMockRatingDistribution = <RatingBucket>[
  RatingBucket(stars: 5, share: 0.92),
  RatingBucket(stars: 4, share: 0.06),
  RatingBucket(stars: 3, share: 0.02),
  RatingBucket(stars: 2, share: 0),
];

/// The Reviews screen exactly as the design draws it.
ReviewsSnapshot mockReviews(AppLocalizations l10n) {
  return ReviewsSnapshot(
    subject: 'Elif Çelik',
    averageRating: 4.9,
    reviewCount: 73,
    distribution: kMockRatingDistribution,
    // 41 + 38 + 33 + 24 = 136 across 73 reviews. That is not a mistake to be
    // tidied up: a review carries more than one tag. Nothing sums these.
    tags: <ReviewTag>[
      ReviewTag(label: l10n.reviewsTagPunctual, count: 41),
      ReviewTag(label: l10n.reviewsTagSafeDriving, count: 38),
      ReviewTag(label: l10n.reviewsTagFriendly, count: 33),
      ReviewTag(label: l10n.reviewsTagCleanCar, count: 24),
    ],
    entries: <ReviewEntry>[
      ReviewEntry(
        authorName: 'Mert A.',
        authorInitials: 'MA',
        authorIdentity: RmIdentity.green,
        rating: 5,
        age: l10n.dateDaysAgo(2),
        context: 'Kadıköy${RmFormatters.routeArrow}Levent',
        body: l10n.reviewsMockBodyFirst,
      ),
      ReviewEntry(
        authorName: 'Emre Y.',
        authorInitials: 'EY',
        authorIdentity: RmIdentity.purple,
        rating: 4.8,
        age: l10n.dateWeeksAgo(1),
        context: l10n.reviewsContextRegularRoute,
        body: l10n.reviewsMockBodySecond,
      ),
    ],
  );
}
