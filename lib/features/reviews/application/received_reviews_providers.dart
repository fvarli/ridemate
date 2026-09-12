// ─────────────────────────────────────────────────────────────
// RideMate — Reading what was said about this member
//
// A paginated read the screen watches, in the shape My Routes and the
// seat-request feeds already have: one `AsyncNotifier`, the page held as its
// data, and load-more as a mutation of that page rather than a new load.
//
// RELEASE IS THE SERVER'S DECISION, AND THIS ASKS RATHER THAN WORKS IT OUT
//
// A review about this member becomes visible when the other side has written
// one too or the fourteen days have run out. Nothing here computes either: a
// client that decided for itself would have to know whether a review it is not
// allowed to see exists, which is the entire point of the rule. What the
// backend returned is what there is.
//
// So there is no deadline, no counterpart check, no local filter and no
// re-reading of seat-request state to guess what might have been released.
// Submitting a review in F2 does not make the counterpart's appear here — only
// a fresh response can say that, which is what `refresh` is for.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/rm_failure.dart';
import '../../../core/api/rm_retry.dart';
import '../data/review_repository.dart';
import '../domain/received_reviews_page.dart';
import 'review_action_providers.dart' show reviewRepositoryProvider;

/// Released reviews about the signed-in member, newest first.
///
/// Auto-disposing for the reason the other feeds are: a list held across
/// screens is a list that has gone stale by the time it is shown again, and
/// what goes stale here is whether the server has released anything since.
///
/// `retry` is stated rather than defaulted — see [noAutomaticRetry].
final AsyncNotifierProvider<ReceivedReviewsController, ReceivedReviewsPage>
receivedReviewsProvider =
    AsyncNotifierProvider<ReceivedReviewsController, ReceivedReviewsPage>(
      ReceivedReviewsController.new,
      isAutoDispose: true,
      retry: noAutomaticRetry,
    );

class ReceivedReviewsController extends AsyncNotifier<ReceivedReviewsPage> {
  @override
  Future<ReceivedReviewsPage> build() async {
    final MyReviewsResult result = await ref
        .watch(reviewRepositoryProvider)
        .mine(limit: kMyReviewsPageSize);

    return ReceivedReviewsPage(
      reviews: result.reviews,
      nextCursor: result.nextCursor,
    );
  }

  /// Starts again from the most recent review.
  ///
  /// `invalidateSelf` rather than assigning state by hand: re-running build is
  /// what produces the loading state, the request and the answer as one step,
  /// and it discards the old cursor by construction.
  void refresh() => ref.invalidateSelf();

  /// Fetches the page after the one already held.
  ///
  /// Existing rows stay on screen throughout, **including when this fails**:
  /// taking away what the member could already read, in order to report that
  /// there was more, is the worse trade. The cursor is untouched on failure, so
  /// retrying asks for the same page again with the same opaque value.
  Future<void> loadMore() async {
    final ReceivedReviewsPage? page = state.value;

    // Nothing to continue, no cursor to continue with, or a request already in
    // flight. A second tap joins the first rather than sending the cursor twice
    // and appending the same page to itself.
    if (page == null || !page.hasMore || page.isLoadingMore) return;

    final String cursor = page.nextCursor!;

    state = AsyncData<ReceivedReviewsPage>(
      page.copyWith(isLoadingMore: true, clearLoadMoreFailure: true),
    );

    try {
      final MyReviewsResult result = await ref
          .read(reviewRepositoryProvider)
          // Back exactly as it arrived. Nothing decodes, times, orders by or
          // rebuilds a cursor.
          .mine(cursor: cursor, limit: kMyReviewsPageSize);

      state = AsyncData<ReceivedReviewsPage>(
        page.appended(result.reviews, result.nextCursor),
      );
    } on RmFailure catch (failure) {
      state = AsyncData<ReceivedReviewsPage>(
        page.copyWith(isLoadingMore: false, loadMoreFailure: failure),
      );
    }
  }
}
