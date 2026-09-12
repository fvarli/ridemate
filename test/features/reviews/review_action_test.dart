import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/api/rm_error_code.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/id/rm_uuid.dart';
import 'package:ridemate/core/reviews/review.dart';
import 'package:ridemate/core/reviews/review_decoder.dart';
import 'package:ridemate/features/create_route/application/publication_providers.dart'
    show uuidGeneratorProvider;
import 'package:ridemate/features/reviews/application/review_action_providers.dart';
import 'package:ridemate/features/reviews/data/review_repository.dart';

/// One attempt to rate one relationship.
///
/// The rule this file exists for: an unresolved intent is `{id, rating}` and
/// both halves are frozen. The id alone is not the identity — the backend
/// compares the whole payload, so the same id carrying a different rating is
/// `id_already_used`, a conflict this app would have created.
void main() {
  const String kRequest = '01991d00-0000-7000-8000-000000000001';

  late _Reviews backend;
  late _CountingUuid uuid;

  ProviderContainer container() {
    backend = _Reviews();
    uuid = _CountingUuid();

    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        reviewRepositoryProvider.overrideWithValue(backend),
        uuidGeneratorProvider.overrideWithValue(uuid),
      ],
    );
    addTearDown(c.dispose);

    c.listen<Map<String, ReviewAttempt>>(
      reviewActionProvider,
      (Map<String, ReviewAttempt>? _, Map<String, ReviewAttempt> _) {},
      fireImmediately: true,
    );

    return c;
  }

  ReviewActionController controllerOf(ProviderContainer c) =>
      c.read(reviewActionProvider.notifier);

  group('A submission that lands', () {
    test('sends one minted id with the chosen rating', () async {
      final ProviderContainer c = container();

      final RmFailure? failure = await controllerOf(c).submit(kRequest, 4);

      expect(failure, isNull);
      expect(backend.sent, <String>['review-1:4']);
      expect(uuid.minted, 1);
    });

    /// Resolved: the intent is over, and the server's review is the truth.
    test('clears the intent, so a later rating is a new one', () async {
      final ProviderContainer c = container();
      await controllerOf(c).submit(kRequest, 4);

      expect(controllerOf(c).lockedRating(kRequest), isNull);
      expect(controllerOf(c).attemptFor(kRequest), isNull);

      await controllerOf(c).submit(kRequest, 2);

      expect(backend.sent, <String>['review-1:4', 'review-2:2']);
    });
  });

  group('An attempt whose answer is unknown', () {
    /// CARRIES WEIGHT. Both halves are frozen, not just the id.
    ///
    /// A member who submitted four, lost the response, then chose five would
    /// be answered `id_already_used` — a conflict the client invented.
    test('keeps the id AND the rating, and retry resends both', () async {
      final ProviderContainer c = container();
      backend.failWith = const RmFailure.transport();

      await controllerOf(c).submit(kRequest, 4);

      expect(controllerOf(c).lockedRating(kRequest), 4);
      expect(uuid.minted, 1);

      // The member changes their mind and retries. The intent wins.
      await controllerOf(c).submit(kRequest, 5);

      expect(backend.sent, <String>['review-1:4', 'review-1:4']);
      expect(uuid.minted, 1, reason: 'a retry mints nothing');
    });

    test('a rebuild does not change either half', () async {
      final ProviderContainer c = container();
      backend.failWith = const RmFailure.transport();
      await controllerOf(c).submit(kRequest, 3);

      // Reading the notifier again is what a rebuild does.
      expect(controllerOf(c).lockedRating(kRequest), 3);
      expect(controllerOf(c).lockedRating(kRequest), 3);
      expect(uuid.minted, 1);
    });

    test('the failure it carries is the one that was sent', () async {
      final ProviderContainer c = container();
      backend.failWith = const RmFailure.transport();
      await controllerOf(c).submit(kRequest, 2);

      final ReviewAttempt? attempt = controllerOf(c).attemptFor(kRequest);

      expect(attempt, isA<ReviewFailed>());
      expect((attempt! as ReviewFailed).rating, 2);
      expect((attempt as ReviewFailed).isRetryable, isTrue);
    });

    /// CARRIES WEIGHT. Changing the rating is a deliberate act, not a retry.
    test('abandoning clears both, and the next one is genuinely new', () async {
      final ProviderContainer c = container();
      backend.failWith = const RmFailure.transport();
      await controllerOf(c).submit(kRequest, 4);

      controllerOf(c).abandon(kRequest);

      expect(controllerOf(c).lockedRating(kRequest), isNull);
      expect(controllerOf(c).attemptFor(kRequest), isNull);

      backend.failWith = null;
      await controllerOf(c).submit(kRequest, 5);

      expect(backend.sent, <String>['review-1:4', 'review-2:5']);
      expect(uuid.minted, 2);
    });

    /// And if the abandoned attempt had actually landed, the new one is told
    /// so — which is true, and not something to recover from by minting again.
    test(
      'a new intent after abandoning may be told it already exists',
      () async {
        final ProviderContainer c = container();
        backend.failWith = const RmFailure.transport();
        await controllerOf(c).submit(kRequest, 4);
        controllerOf(c).abandon(kRequest);

        backend.failWith = _conflict('already_reviewed');
        final RmFailure? failure = await controllerOf(c).submit(kRequest, 5);

        expect(failure?.reviewRefusal, ReviewRefusal.alreadyReviewed);
        expect(uuid.minted, 2, reason: 'no third id was invented');
      },
    );
  });

  group('What a refusal does to the intent', () {
    /// CARRIES WEIGHT. An identity conflict is never answered by a new id.
    test('id_already_used does not mint a replacement', () async {
      final ProviderContainer c = container();
      backend.failWith = _conflict('id_already_used');

      await controllerOf(c).submit(kRequest, 4);
      await controllerOf(c).submit(kRequest, 4);

      expect(uuid.minted, 1);
      expect(backend.sent, <String>['review-1:4', 'review-1:4']);
      expect(
        controllerOf(c).attemptFor(kRequest),
        isA<ReviewFailed>().having(
          (ReviewFailed f) => f.refusal,
          'refusal',
          ReviewRefusal.idAlreadyUsed,
        ),
      );
    });

    test('a settled refusal is not offered as retryable', () async {
      for (final String reason in <String>[
        'seat_request_not_accepted',
        'trip_not_completed',
        'review_window_closed',
        'already_reviewed',
        'id_already_used',
      ]) {
        final ProviderContainer c = container();
        backend.failWith = _conflict(reason);

        await controllerOf(c).submit(kRequest, 4);

        final ReviewFailed attempt =
            controllerOf(c).attemptFor(kRequest)! as ReviewFailed;

        expect(attempt.refusal, ReviewRefusal.fromWire(reason), reason: reason);
        expect(attempt.isRetryable, isFalse, reason: reason);
      }
    });

    /// CARRIES WEIGHT. A 404 is not a refusal and never reads as one.
    test('a not-found names no refusal at all', () async {
      final ProviderContainer c = container();
      backend.failWith = const RmFailure.fromBackend(
        status: 404,
        code: RmErrorCode.notFound,
      );

      final RmFailure? failure = await controllerOf(c).submit(kRequest, 4);

      expect(failure?.code, RmErrorCode.notFound);
      expect(failure?.reviewRefusal, isNull);
      expect(
        (controllerOf(c).attemptFor(kRequest)! as ReviewFailed).refusal,
        isNull,
      );
    });
  });

  group('Two relationships at once', () {
    test('each carries its own id and rating', () async {
      const String other = '01991d00-0000-7000-8000-000000000002';
      final ProviderContainer c = container();
      backend.failWith = const RmFailure.transport();

      await controllerOf(c).submit(kRequest, 4);
      await controllerOf(c).submit(other, 2);

      expect(controllerOf(c).lockedRating(kRequest), 4);
      expect(controllerOf(c).lockedRating(other), 2);
      expect(backend.sent, <String>['review-1:4', 'review-2:2']);
    });

    test('a second tap while one is in flight sends nothing more', () async {
      final ProviderContainer c = container();
      backend.hold();

      final Future<RmFailure?> first = controllerOf(c).submit(kRequest, 4);
      final RmFailure? second = await controllerOf(c).submit(kRequest, 4);

      expect(second, isNull);
      expect(backend.sent, <String>['review-1:4']);

      backend.release();
      await first;
    });
  });
}

RmFailure _conflict(String reason) => RmFailure.fromBackend(
  status: 409,
  code: RmErrorCode.conflict,
  reason: reason,
);

/// A backend a test can steer, recording exactly what it was sent.
class _Reviews implements ReviewRepository {
  final List<String> sent = <String>[];
  RmFailure? failWith;

  Completer<void>? _gate;

  void hold() => _gate ??= Completer<void>();

  void release() {
    _gate?.complete();
    _gate = null;
  }

  @override
  Future<MyReview> submitReview({
    required String requestId,
    required String reviewId,
    required int rating,
  }) async {
    // The whole payload, so a changed rating under a reused id is visible.
    sent.add('$reviewId:$rating');

    await _gate?.future;

    final RmFailure? failure = failWith;
    if (failure != null) throw failure;

    return MyReview(
      id: reviewId,
      rating: rating,
      submittedAt: DateTime.utc(2026, 9, 25, 9, 14),
    );
  }

  @override
  Future<MyReviewsResult> mine({String? cursor, int limit = 20}) async =>
      const MyReviewsResult(reviews: <ReceivedReview>[], nextCursor: null);
}

/// Ids a test can recognise on sight, and count.
class _CountingUuid implements RmUuidGenerator {
  int minted = 0;

  @override
  String v7() {
    minted++;

    return 'review-$minted';
  }
}
