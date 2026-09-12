// ─────────────────────────────────────────────────────────────
// RideMate — Paging through what was said about me
//
// The feed is read-only, so almost everything here is about two things: the
// cursor going back exactly as it arrived, and a page that failed not taking
// away the page that worked.
//
// AND ONE THING THAT IS NOT ABOUT PAGING AT ALL
//
// Nothing in this controller may recompute release. There is no deadline, no
// counterpart check and no filter — a client that worked out which reviews it
// should be seeing would have to know about ones it may not see. The tests
// below pin the absence of that as firmly as they pin the cursor.
// ─────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/reviews/review.dart';
import 'package:ridemate/features/reviews/application/received_reviews_providers.dart';
import 'package:ridemate/features/reviews/application/review_action_providers.dart';
import 'package:ridemate/features/reviews/data/review_repository.dart';
import 'package:ridemate/features/reviews/domain/received_reviews_page.dart';

import '../../support/fakes.dart';

void main() {
  late FakeReviewRepository reviews;

  ProviderContainer container(
    List<MyReviewsResult> pages, {
    RmFailure? failure,
  }) {
    reviews = FakeReviewRepository(pages: pages, failure: failure);

    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        reviewRepositoryProvider.overrideWithValue(reviews),
      ],
    );
    addTearDown(c.dispose);

    // A live listener, the way the screen holds one: the provider auto-disposes
    // and would otherwise be torn down between reads.
    c.listen<AsyncValue<ReceivedReviewsPage>>(
      receivedReviewsProvider,
      (
        AsyncValue<ReceivedReviewsPage>? _,
        AsyncValue<ReceivedReviewsPage> _,
      ) {},
      fireImmediately: true,
    );

    return c;
  }

  MyReviewsResult page(List<String> ids, {String? next}) => MyReviewsResult(
    reviews: <ReceivedReview>[
      for (final String id in ids) fakeReceivedReview(id: id),
    ],
    nextCursor: next,
  );

  Future<ReceivedReviewsPage> loaded(ProviderContainer c) async {
    await c.read(receivedReviewsProvider.future);

    return c.read(receivedReviewsProvider).value!;
  }

  List<String> idsOf(ReceivedReviewsPage page) => <String>[
    for (final ReceivedReview r in page.reviews) r.id,
  ];

  group('The first page', () {
    test('is requested with no cursor and the contract limit', () async {
      final ProviderContainer c = container(<MyReviewsResult>[
        page(<String>['a', 'b']),
      ]);

      final ReceivedReviewsPage first = await loaded(c);

      expect(reviews.cursors, <String?>[null]);
      expect(reviews.limits, <int>[kMyReviewsPageSize]);
      expect(idsOf(first), <String>['a', 'b']);
    });

    /// CARRIES WEIGHT. Nothing sorts, filters or drops a row.
    ///
    /// The backend decides which reviews are released and in what order. A
    /// client that reordered them would be publishing a ranking; one that
    /// dropped a row would be second-guessing the release rule.
    test('holds exactly what the server sent, in that order', () async {
      final ProviderContainer c = container(<MyReviewsResult>[
        page(<String>['c', 'a', 'b']),
      ]);

      expect(idsOf(await loaded(c)), <String>['c', 'a', 'b']);
    });

    test('an empty page is not a failure', () async {
      final ProviderContainer c = container(<MyReviewsResult>[
        page(<String>[]),
      ]);

      final ReceivedReviewsPage first = await loaded(c);

      expect(first.isEmpty, isTrue);
      expect(c.read(receivedReviewsProvider).hasError, isFalse);
    });

    /// An empty page still carries its cursor forward.
    ///
    /// The backend filters unreleased reviews in SQL, so a page can arrive
    /// holding nothing and still offer a position. Treating empty as the end
    /// would silently truncate the list.
    test('an empty page that carries a cursor is not the end', () async {
      final ProviderContainer c = container(<MyReviewsResult>[
        page(<String>[], next: 'one'),
        page(<String>['a'], next: null),
      ]);

      final ReceivedReviewsPage first = await loaded(c);

      expect(first.isEmpty, isTrue);
      expect(first.hasMore, isTrue);

      await c.read(receivedReviewsProvider.notifier).loadMore();

      expect(idsOf(c.read(receivedReviewsProvider).value!), <String>['a']);
    });

    test('a failure is not an empty page', () async {
      final ProviderContainer c = container(
        <MyReviewsResult>[],
        failure: const RmFailure.transport(),
      );

      await expectLater(
        c.read(receivedReviewsProvider.future),
        throwsA(isA<RmFailure>()),
      );
      expect(c.read(receivedReviewsProvider).hasError, isTrue);
    });

    /// See `noAutomaticRetry`: a failed read is asked once, not eleven times.
    test('a failed read is asked exactly once', () async {
      final ProviderContainer c = container(
        <MyReviewsResult>[],
        failure: const RmFailure.transport(),
      );

      await expectLater(
        c.read(receivedReviewsProvider.future),
        throwsA(isA<RmFailure>()),
      );

      expect(reviews.callCount, 1);
    });
  });

  group('Loading more', () {
    /// CARRIES WEIGHT. The cursor is the server's, byte for byte.
    ///
    /// The fake throws on a cursor it never issued, so a value this client
    /// built, trimmed, decoded or re-encoded fails here rather than in
    /// production.
    test('sends exactly the cursor the server returned', () async {
      final ProviderContainer c = container(<MyReviewsResult>[
        page(<String>['a'], next: 'opaque-one'),
        page(<String>['b'], next: null),
      ]);

      await loaded(c);
      await c.read(receivedReviewsProvider.notifier).loadMore();

      expect(reviews.cursors, <String?>[null, 'opaque-one']);
      expect(idsOf(c.read(receivedReviewsProvider).value!), <String>['a', 'b']);
    });

    test('appends in server order and keeps what was there', () async {
      final ProviderContainer c = container(<MyReviewsResult>[
        page(<String>['a', 'b'], next: 'one'),
        page(<String>['c', 'd'], next: null),
      ]);

      await loaded(c);
      await c.read(receivedReviewsProvider.notifier).loadMore();

      expect(idsOf(c.read(receivedReviewsProvider).value!), <String>[
        'a',
        'b',
        'c',
        'd',
      ]);
    });

    /// CARRIES WEIGHT. A review released between two reads can land twice.
    test('a review seen twice is held once', () async {
      final ProviderContainer c = container(<MyReviewsResult>[
        page(<String>['a', 'b'], next: 'one'),
        page(<String>['b', 'c'], next: null),
      ]);

      await loaded(c);
      await c.read(receivedReviewsProvider.notifier).loadMore();

      expect(idsOf(c.read(receivedReviewsProvider).value!), <String>[
        'a',
        'b',
        'c',
      ]);
    });

    /// CARRIES WEIGHT. Page two failing does not take page one away.
    test('a failure keeps every review already loaded', () async {
      final ProviderContainer c = container(<MyReviewsResult>[
        page(<String>['a', 'b'], next: 'one'),
      ]);

      await loaded(c);
      reviews.failure = const RmFailure.transport();
      await c.read(receivedReviewsProvider.notifier).loadMore();

      final ReceivedReviewsPage after = c.read(receivedReviewsProvider).value!;

      expect(idsOf(after), <String>['a', 'b']);
      expect(after.loadMoreFailure, isNotNull);
      expect(after.isLoadingMore, isFalse);
      // Still offered, because the cursor was not consumed.
      expect(after.hasMore, isTrue);
      expect(c.read(receivedReviewsProvider).hasError, isFalse);
    });

    test('retrying after a failure re-sends the same cursor', () async {
      final ProviderContainer c = container(<MyReviewsResult>[
        page(<String>['a'], next: 'one'),
        page(<String>['b'], next: null),
      ]);

      await loaded(c);
      reviews.failure = const RmFailure.transport();
      await c.read(receivedReviewsProvider.notifier).loadMore();
      reviews.failure = null;
      await c.read(receivedReviewsProvider.notifier).loadMore();

      expect(reviews.cursors, <String?>[null, 'one', 'one']);
      expect(idsOf(c.read(receivedReviewsProvider).value!), <String>['a', 'b']);
      expect(
        c.read(receivedReviewsProvider).value!.loadMoreFailure,
        isNull,
        reason: 'a successful page clears the last failure',
      );
    });

    test('concurrent load-more makes one request', () async {
      final ProviderContainer c = container(<MyReviewsResult>[
        page(<String>['a'], next: 'one'),
        page(<String>['b'], next: null),
      ]);

      await loaded(c);
      reviews.hold();

      final Future<void> first = c
          .read(receivedReviewsProvider.notifier)
          .loadMore();
      final Future<void> second = c
          .read(receivedReviewsProvider.notifier)
          .loadMore();

      reviews.release();
      await Future.wait(<Future<void>>[first, second]);

      expect(reviews.cursors, <String?>[null, 'one']);
      expect(idsOf(c.read(receivedReviewsProvider).value!), <String>['a', 'b']);
    });

    test('there is nothing to load when the cursor is null', () async {
      final ProviderContainer c = container(<MyReviewsResult>[
        page(<String>['a'], next: null),
      ]);

      await loaded(c);
      await c.read(receivedReviewsProvider.notifier).loadMore();

      expect(reviews.cursors, <String?>[null]);
    });
  });

  group('Refreshing', () {
    test('discards the cursor and starts again', () async {
      final ProviderContainer c = container(<MyReviewsResult>[
        page(<String>['a'], next: 'one'),
        page(<String>['b'], next: null),
      ]);

      await loaded(c);
      await c.read(receivedReviewsProvider.notifier).loadMore();

      c.read(receivedReviewsProvider.notifier).refresh();
      await loaded(c);

      expect(reviews.cursors, <String?>[null, 'one', null]);
      expect(idsOf(c.read(receivedReviewsProvider).value!), <String>['a']);
    });
  });

  group('The page holds no figure', () {
    /// CARRIES WEIGHT. RideMate publishes no reputation, to anyone.
    ///
    /// A count or an average here would be one this client computed from a
    /// page of a list the backend deliberately withholds part of — so it would
    /// be both a reputation figure and a wrong one.
    test('there is no count, total or average to read', () {
      final String source = File(
        'lib/features/reviews/domain/received_reviews_page.dart',
      ).readAsStringSync();

      for (final String banned in <String>[
        'averageRating',
        'reviewCount',
        'get count',
        'get average',
        'fold',
        'reduce',
      ]) {
        expect(source.contains(banned), isFalse, reason: banned);
      }
    });

    /// CARRIES WEIGHT. Release is the server's, and stays there.
    test('nothing in the feed computes release', () {
      for (final String path in <String>[
        'lib/features/reviews/domain/received_reviews_page.dart',
        'lib/features/reviews/application/received_reviews_providers.dart',
      ]) {
        final String source = File(path)
            .readAsLinesSync()
            .map((String line) {
              final int slash = line.indexOf('//');
              return slash == -1 ? line : line.substring(0, slash);
            })
            .join('\n');

        for (final String banned in <String>[
          'DateTime.now',
          'Duration(',
          'days',
          'counterpart',
          'released',
          'where(',
        ]) {
          expect(source.contains(banned), isFalse, reason: '$path: $banned');
        }
      }
    });
  });
}
