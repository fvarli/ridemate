// ─────────────────────────────────────────────────────────────
// RideMate — Reviews presentation model
//
// Source: docs/claude-designs/RideMate App.dc.html, "REVIEWS · İTİBAR"
// (immutable).
//
// PRESENTATION DATA ONLY. There is no reviews backend, no submission, no
// moderation, no abuse detection and no verified-trip policy. Every figure
// below is transcribed from the design.
//
// THREE ARITHMETIC COINCIDENCES, none of which is a rule:
//
//   * 0.92*5 + 0.06*4 + 0.02*3 = 4.90, which is exactly the headline rating.
//     The distribution does NOT produce the headline; both are declared;
//   * (5.0 + 4.8) / 2 = 4.9, the same number again from the two visible
//     cards. Two reviews out of a claimed 73 cannot average to anything;
//   * 0.92 * 73 = 67.16, which is not a count of anything.
//
// reviews_domain_test.dart pins all three as coincidences so nobody turns one
// into a derivation. A real reputation service will produce these figures
// together and they will stop agreeing; when that happens the fixtures are
// what changes, not the arithmetic, because there is no arithmetic.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

import '../../../core/widgets/rm_avatar.dart';

/// One bar of the rating histogram.
@immutable
final class RatingBucket {
  const RatingBucket({required this.stars, required this.share});

  /// 5, 4, 3, 2. The comp draws no 1-star row.
  final int stars;

  /// Bar fill, 0..1. Declared, not counted.
  final double share;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RatingBucket && other.stars == stars && other.share == share;

  @override
  int get hashCode => Object.hash(stars, share);
}

/// One attribute tag with the number of reviews that mention it.
@immutable
final class ReviewTag {
  const ReviewTag({required this.label, required this.count});

  /// Already localized.
  final String label;

  final int count;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewTag && other.label == label && other.count == count;

  @override
  int get hashCode => Object.hash(label, count);
}

/// One review card.
@immutable
final class ReviewEntry {
  const ReviewEntry({
    required this.authorName,
    required this.authorInitials,
    required this.authorIdentity,
    required this.rating,
    required this.age,
    required this.context,
    required this.body,
  });

  /// Abbreviated, per the design's privacy convention (`Mert A.`).
  final String authorName;

  final String authorInitials;
  final RmIdentity authorIdentity;

  final double rating;

  /// Already localized relative date, e.g. `2 gün önce`. There is no absolute
  /// timestamp anywhere in the design and none is invented.
  final String age;

  /// Free-form context. The comp prints `Kadıköy → Levent` on one card and
  /// `Düzenli rota` on the other, so this is NOT an origin/destination pair.
  final String context;

  /// Already localized prose.
  final String body;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewEntry &&
          other.authorName == authorName &&
          other.authorInitials == authorInitials &&
          other.authorIdentity == authorIdentity &&
          other.rating == rating &&
          other.age == age &&
          other.context == context &&
          other.body == body;

  @override
  int get hashCode => Object.hash(
    authorName,
    authorInitials,
    authorIdentity,
    rating,
    age,
    context,
    body,
  );
}

/// Everything the Reviews screen renders.
@immutable
final class ReviewsSnapshot {
  const ReviewsSnapshot({
    required this.subject,
    required this.averageRating,
    required this.reviewCount,
    required this.distribution,
    required this.tags,
    required this.entries,
  });

  /// Whose reputation this is.
  ///
  /// Modelled because the comp is ambiguous about it, not because anything
  /// reads it: Profile reaches this screen through `Değerlendirmelerim`, yet
  /// the first review's prose praises Selin, and both authors are drivers in
  /// the discovery fixtures. Raised in docs/design-system.md §8; the prose
  /// ships as approved rather than being quietly rewritten.
  final String subject;

  /// The headline figure. Declared — see the file header.
  final double averageRating;

  /// The claimed total. The comp shows two cards and no way to see more,
  /// which is recorded rather than resolved.
  final int reviewCount;

  /// Four buckets, 5 down to 2.
  final List<RatingBucket> distribution;

  /// Attribute tags. Their counts sum to more than [reviewCount] because a
  /// review carries several tags — see the fixture.
  final List<ReviewTag> tags;

  final List<ReviewEntry> entries;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewsSnapshot &&
          other.subject == subject &&
          other.averageRating == averageRating &&
          other.reviewCount == reviewCount &&
          listEquals(other.distribution, distribution) &&
          listEquals(other.tags, tags) &&
          listEquals(other.entries, entries);

  @override
  int get hashCode => Object.hash(
    subject,
    averageRating,
    reviewCount,
    Object.hashAll(distribution),
    Object.hashAll(tags),
    Object.hashAll(entries),
  );
}
