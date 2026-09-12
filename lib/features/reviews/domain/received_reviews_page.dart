// ─────────────────────────────────────────────────────────────
// RideMate — A page of what was said about this member
//
// The shape My Routes and the seat-request feeds already use, minus the two
// parts a read-only feed has no use for: there is no `busy` set, because no row
// here has a command to run, and no `withRowReplaced`, because a review is
// never edited — the server sends one instant and that is the whole of it.
//
// FAILURE IS NOT EMPTY
//
// A page that arrived and held nothing, and a page that never arrived, are
// different facts and are never collapsed. `AsyncError` carries the second;
// `isEmpty` on loaded data is the first. That distinction matters more here
// than anywhere else in the app: an empty page is the server saying it has
// nothing to release, which is NOT the same as nobody having written anything.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

import '../../../core/api/rm_failure.dart';
import '../../../core/reviews/review.dart';

@immutable
final class ReceivedReviewsPage {
  const ReceivedReviewsPage({
    required this.reviews,
    required this.nextCursor,
    this.isLoadingMore = false,
    this.loadMoreFailure,
  });

  /// Released reviews, in the order the server returned them. Nothing sorts.
  final List<ReceivedReview> reviews;

  /// The server's position, opaque and passed back untouched. Null is the end.
  ///
  /// An empty page is not the end: the backend filters unreleased reviews in
  /// SQL, so a page can arrive holding nothing and still carry a cursor.
  final String? nextCursor;

  final bool isLoadingMore;

  /// Why the page after this one did not arrive, if it did not.
  ///
  /// Held beside the rows rather than replacing them: losing what the member
  /// could already read, to report that there was more, is the worse trade.
  final RmFailure? loadMoreFailure;

  bool get hasMore => nextCursor != null;

  bool get isEmpty => reviews.isEmpty;

  /// Deliberately no `count`, no `length` getter and no average.
  ///
  /// RideMate publishes no reputation, and the member's own screen is not an
  /// exception: a figure here is one the client would have computed from a
  /// page, over a list the server deliberately withholds part of.

  ReceivedReviewsPage copyWith({
    List<ReceivedReview>? reviews,
    bool? isLoadingMore,
    RmFailure? loadMoreFailure,
    bool clearLoadMoreFailure = false,
  }) => ReceivedReviewsPage(
    reviews: reviews ?? this.reviews,
    // The cursor is never changed here. Only `appended` moves it, and only to
    // the value the server just sent.
    nextCursor: nextCursor,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailure: clearLoadMoreFailure
        ? null
        : loadMoreFailure ?? this.loadMoreFailure,
  );

  /// The next page, with anything already held dropped.
  ///
  /// Keyset pagination should not overlap, but a review released between two
  /// reads can land twice, and a list that shows the same rating twice reads as
  /// two people having said it. Defensive, and cheap.
  ReceivedReviewsPage appended(List<ReceivedReview> next, String? cursor) {
    final Set<String> known = <String>{
      for (final ReceivedReview review in reviews) review.id,
    };

    return ReceivedReviewsPage(
      reviews: <ReceivedReview>[
        ...reviews,
        for (final ReceivedReview review in next)
          if (known.add(review.id)) review,
      ],
      nextCursor: cursor,
    );
  }
}
