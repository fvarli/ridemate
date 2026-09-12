// ─────────────────────────────────────────────────────────────
// RideMate — Rating a journey, as an action
//
// ONE CONTROLLER FOR BOTH SIDES, KEYED BY RELATIONSHIP
//
// A passenger rating a driver and a driver rating a passenger are the same
// command about the same seat request, so they are one controller keyed by its
// id. Two would be two places for the retry rule to drift apart.
//
// THE UNRESOLVED INTENT IS `{id, rating}`, FROZEN TOGETHER
//
// The client-generated id is the idempotency key, but it is not the whole
// identity: the backend compares the canonical payload, so the same id carrying
// a different rating answers `id_already_used`. That would be a conflict this
// app invented — a member who submitted four stars, lost the response, then
// chose five and tapped Retry.
//
// So an unresolved intent freezes both. Retry resends byte-for-byte what was
// sent, and the rating cannot be changed while the intent is in doubt.
// Changing it means abandoning the intent explicitly, which clears the id and
// the rating together; the next submission is a new intent with a new id. If
// the first attempt had in fact landed, that new intent correctly receives
// `already_reviewed` — which is the true answer, not something to recover from
// by minting again.
//
// NOTHING IS OPTIMISTIC
//
// A card says "rated" only after the server has said so, and it says it with
// the review the server returned.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/api_client_provider.dart';
import '../../../app/providers/session_provider.dart';
import '../../../core/api/rm_failure.dart';
import '../../../core/reviews/review.dart';
import '../../../core/reviews/review_decoder.dart';
import '../../create_route/application/publication_providers.dart'
    show uuidGeneratorProvider;
import '../data/review_repository.dart';

final Provider<ReviewRepository> reviewRepositoryProvider =
    Provider<ReviewRepository>(
      (Ref ref) => ApiReviewRepository(
        client: ref.watch(rmApiClientProvider),
        session: ref.watch(rmSessionProvider),
      ),
    );

/// Where one relationship's rating has got to, from this screen's view.
///
/// Deliberately not a copy of [MyReview]: that is what the server holds about a
/// review that exists, and this is what is happening to an attempt to create
/// one. Conflating them is how a card ends up claiming a rating the backend
/// never confirmed.
@immutable
sealed class ReviewAttempt {
  const ReviewAttempt();
}

/// In flight. The control is disabled and no second tap is sent.
final class ReviewSending extends ReviewAttempt {
  const ReviewSending();
}

/// It did not land, and trying again could still change the answer.
///
/// [rating] is the one that was sent, kept so a retry is the same submission
/// rather than a new one wearing a used id.
final class ReviewFailed extends ReviewAttempt {
  const ReviewFailed(this.failure, this.rating);

  final RmFailure failure;
  final int rating;

  /// The refusal the server named, when it named one this build knows.
  ReviewRefusal? get refusal => failure.reviewRefusal;

  /// Whether trying the identical submission again could still succeed.
  ///
  /// A refusal is the server's settled answer about the relationship, so
  /// repeating it changes nothing. A transport failure is the opposite: nobody
  /// knows whether it landed, which is exactly when the frozen id matters.
  bool get isRetryable => failure.isTransport;
}

/// What every relationship's attempt is doing right now.
final NotifierProvider<ReviewActionController, Map<String, ReviewAttempt>>
reviewActionProvider =
    NotifierProvider<ReviewActionController, Map<String, ReviewAttempt>>(
      ReviewActionController.new,
      isAutoDispose: true,
    );

class ReviewActionController extends Notifier<Map<String, ReviewAttempt>> {
  /// The `{id, rating}` each unresolved intent is carrying.
  ///
  /// Kept outside `state` because it is not something the UI renders: it is the
  /// identity of an attempt, and putting it on screen would invite a widget to
  /// show it.
  final Map<String, ({String id, int rating})> _intents =
      <String, ({String id, int rating})>{};

  @override
  Map<String, ReviewAttempt> build() => const <String, ReviewAttempt>{};

  ReviewAttempt? attemptFor(String requestId) => state[requestId];

  /// The rating an unresolved attempt is locked to, or null when free.
  ///
  /// A sheet reads this to show what was sent and to refuse a change: while the
  /// server's answer is unknown, the submission is what it was.
  int? lockedRating(String requestId) => _intents[requestId]?.rating;

  /// Rates one relationship.
  ///
  /// [rating] is used only when no intent is in flight for [requestId]. While
  /// one is unresolved the frozen rating wins, so a retry cannot quietly become
  /// a different submission.
  Future<RmFailure?> submit(String requestId, int rating) async {
    if (state[requestId] is ReviewSending) return null;

    final ({String id, int rating}) intent = _intents[requestId] ??= (
      id: ref.read(uuidGeneratorProvider).v7(),
      rating: rating,
    );

    state = <String, ReviewAttempt>{...state, requestId: const ReviewSending()};

    try {
      final MyReview review = await ref
          .read(reviewRepositoryProvider)
          .submitReview(
            requestId: requestId,
            reviewId: intent.id,
            rating: intent.rating,
          );

      // Resolved: the intent is over and the server's review is the truth.
      _intents.remove(requestId);
      _clear(requestId);

      _lastSubmitted[requestId] = review;

      return null;
    } on RmFailure catch (failure) {
      // The intent is KEPT. A transport failure leaves nobody knowing whether
      // it landed, and a refusal is the server's settled answer — neither is a
      // reason to start submitting something else under the same id.
      state = <String, ReviewAttempt>{
        ...state,
        requestId: ReviewFailed(failure, intent.rating),
      };

      return failure;
    }
  }

  /// The review the server returned, for a listing that has not re-read yet.
  final Map<String, MyReview> _lastSubmitted = <String, MyReview>{};

  /// What the server said about [requestId], if this session submitted it.
  MyReview? submitted(String requestId) => _lastSubmitted[requestId];

  /// Gives up on an unresolved intent.
  ///
  /// Clears the id AND the rating, because they are one thing. The next
  /// submission is a genuinely new intent — and if the abandoned one had
  /// actually landed, it will be told `already_reviewed`, which is true.
  void abandon(String requestId) {
    _intents.remove(requestId);
    _clear(requestId);
  }

  void _clear(String requestId) {
    if (!state.containsKey(requestId)) return;

    state = <String, ReviewAttempt>{...state}..remove(requestId);
  }
}
