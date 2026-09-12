// ─────────────────────────────────────────────────────────────
// RideMate — Reviews about me
//
// The member reading their own feedback. What this screen must never do is
// turn that into a reputation: no average, no total, no distribution, no
// score, no badge — and, the subtlest one, no claim about the reviews it was
// not sent.
//
// THE EMPTY STATE IS A PRIVACY TEST, NOT A COPY TEST
//
// A review is released when the other side writes one too or the fourteen days
// run out, and which of those happened is withheld. So an empty page means the
// server released nothing — NOT that nobody wrote anything. Saying "nobody has
// reviewed you" would report the absence of a review this client is not
// allowed to know about.
// ─────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/reviews/review.dart';
import 'package:ridemate/core/theme/rm_theme.dart';
import 'package:ridemate/core/widgets/rm_button.dart';
import 'package:ridemate/features/reviews/application/review_action_providers.dart';
import 'package:ridemate/features/reviews/data/review_repository.dart';
import 'package:ridemate/features/reviews/presentation/received_reviews_screen.dart';
import 'package:ridemate/features/reviews/presentation/widgets/received_review_card.dart';
import 'package:ridemate/l10n/app_localizations.dart';
import 'package:ridemate/l10n/app_localizations_en.dart';
import 'package:ridemate/l10n/app_localizations_tr.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';

void main() {
  setUpAll(loadRideMateFonts);

  late FakeReviewRepository reviews;

  Future<void> pump(WidgetTester tester, FakeReviewRepository backend) async {
    reviews = backend;

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          reviewRepositoryProvider.overrideWithValue(backend),
        ],
        child: MaterialApp(
          theme: RmTheme.of(Brightness.light),
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ReceivedReviewsScreen(),
        ),
      ),
    );
  }

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ReceivedReviewsScreen)));

  MyReviewsResult page(List<ReceivedReview> rows, {String? next}) =>
      MyReviewsResult(reviews: rows, nextCursor: next);

  group('What the server sent, and only that', () {
    testWidgets('the first page renders the server rows', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        FakeReviewRepository(
          pages: <MyReviewsResult>[
            page(<ReceivedReview>[
              fakeReceivedReview(id: 'a', rating: 4),
              fakeReceivedReview(id: 'b', rating: 2, displayName: 'Mert Aydın'),
            ]),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ReceivedReviewCard), findsNWidgets(2));
      expect(find.text('İrem Yılmaz'), findsOneWidget);
      expect(find.text('Mert Aydın'), findsOneWidget);
    });

    /// CARRIES WEIGHT. The side is the server's, never the screen's.
    ///
    /// The same account is a driver on journeys it published and a passenger
    /// on journeys it asked to join. A screen that decided from context would
    /// label half its rows wrongly.
    testWidgets('a driver reviewer is labelled driver', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        FakeReviewRepository(
          pages: <MyReviewsResult>[
            page(<ReceivedReview>[fakeReceivedReview(role: 'driver')]),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final AppLocalizations l10n = l10nOf(tester);

      expect(find.text(l10n.receivedReviewsRoleDriver), findsOneWidget);
      expect(find.text(l10n.receivedReviewsRolePassenger), findsNothing);
    });

    testWidgets('a passenger reviewer is labelled passenger', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        FakeReviewRepository(
          pages: <MyReviewsResult>[
            page(<ReceivedReview>[fakeReceivedReview(role: 'passenger')]),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final AppLocalizations l10n = l10nOf(tester);

      expect(find.text(l10n.receivedReviewsRolePassenger), findsOneWidget);
      expect(find.text(l10n.receivedReviewsRoleDriver), findsNothing);
    });

    testWidgets('the journey comes from the backend model', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        FakeReviewRepository(
          pages: <MyReviewsResult>[
            page(<ReceivedReview>[
              fakeReceivedReview(
                origin: 'Üsküdar',
                destination: 'Maslak',
                departureDate: '2026-09-24',
                departureTime: '08:25',
              ),
            ]),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Üsküdar → Maslak'), findsOneWidget);
      expect(find.textContaining('24 Eylül 2026'), findsOneWidget);
      expect(find.textContaining('08:25'), findsOneWidget);
    });

    /// The rating is one member's, rendered as given — never folded into a
    /// figure with any other.
    testWidgets('the rating is announced as a number out of five', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        FakeReviewRepository(
          pages: <MyReviewsResult>[
            page(<ReceivedReview>[fakeReceivedReview(rating: 3)]),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp('5 üzerinden 3')), findsWidgets);
    });
  });

  group('Empty is not an accusation', () {
    testWidgets('an empty page is a server answer, not a failure', (
      WidgetTester tester,
    ) async {
      await pump(tester, FakeReviewRepository.empty());
      await tester.pumpAndSettle();

      final AppLocalizations l10n = l10nOf(tester);

      expect(find.text(l10n.receivedReviewsEmpty), findsOneWidget);
      expect(find.text(l10n.receivedReviewsEmptyBody), findsOneWidget);
      expect(find.byType(ReceivedReviewCard), findsNothing);
      expect(find.text(l10n.commonRetry), findsNothing);
    });

    /// CARRIES WEIGHT. This is the sentence the release rule protects.
    testWidgets('the empty copy claims nothing about who wrote', (
      WidgetTester tester,
    ) async {
      await pump(tester, FakeReviewRepository.empty());
      await tester.pumpAndSettle();

      for (final AppLocalizations l10n in <AppLocalizations>[
        AppLocalizationsTr(),
        AppLocalizationsEn(),
      ]) {
        final String copy =
            '${l10n.receivedReviewsEmpty} ${l10n.receivedReviewsEmptyBody}'
                .toLowerCase();

        for (final String banned in <String>[
          'kimse',
          'nobody',
          'no one',
          'değerlendirmedi',
          'henüz kimse',
          'reviewed you',
          'rated you',
        ]) {
          expect(copy.contains(banned), isFalse, reason: banned);
        }
      }
    });
  });

  group('Failure is not empty', () {
    testWidgets('a failed read says so and offers a retry', (
      WidgetTester tester,
    ) async {
      await pump(tester, FakeReviewRepository.offline());
      await tester.pumpAndSettle();

      final AppLocalizations l10n = l10nOf(tester);

      expect(find.text(l10n.receivedReviewsEmpty), findsNothing);
      expect(find.text(l10n.commonRetry), findsOneWidget);
    });

    /// CARRIES WEIGHT. `hasError` is matched before `isLoading`, and the
    /// order is not cosmetic.
    ///
    /// A provider being re-read carries its previous error while it reloads,
    /// so a screen that matched loading first would replace a stated failure
    /// with a spinner the moment the member pressed Retry — and if the second
    /// attempt never answers, that spinner is all they ever see. The failure
    /// and its Retry stay put until something replaces them.
    testWidgets('a retry that has not answered still shows the failure', (
      WidgetTester tester,
    ) async {
      await pump(tester, FakeReviewRepository.offline());
      await tester.pumpAndSettle();

      final AppLocalizations l10n = l10nOf(tester);

      reviews.hold();
      await tester.tap(find.text(l10n.commonRetry));
      await tester.pump();

      expect(find.text(l10n.commonRetry), findsOneWidget);
      expect(find.text(l10n.commonLoading), findsNothing);

      reviews.release();
      await tester.pumpAndSettle();
    });

    testWidgets('retry asks again', (WidgetTester tester) async {
      await pump(tester, FakeReviewRepository.offline());
      await tester.pumpAndSettle();

      final AppLocalizations l10n = l10nOf(tester);

      reviews.failure = null;
      reviews.chain(<MyReviewsResult>[
        page(<ReceivedReview>[fakeReceivedReview()]),
      ]);

      await tester.tap(find.text(l10n.commonRetry));
      await tester.pumpAndSettle();

      expect(find.byType(ReceivedReviewCard), findsOneWidget);
    });
  });

  group('Paging', () {
    testWidgets('load more appends without duplicating a review', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        FakeReviewRepository(
          pages: <MyReviewsResult>[
            page(<ReceivedReview>[
              fakeReceivedReview(id: 'a'),
              fakeReceivedReview(id: 'b'),
            ], next: 'one'),
            page(<ReceivedReview>[
              fakeReceivedReview(id: 'b'),
              fakeReceivedReview(id: 'c'),
            ]),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final AppLocalizations l10n = l10nOf(tester);

      await tester.tap(find.text(l10n.receivedReviewsLoadMore));
      await tester.pumpAndSettle();

      expect(find.byType(ReceivedReviewCard), findsNWidgets(3));
      expect(reviews.cursors, <String?>[null, 'one']);
    });

    testWidgets('no cursor means no load-more control', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        FakeReviewRepository(
          pages: <MyReviewsResult>[
            page(<ReceivedReview>[fakeReceivedReview()]),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final AppLocalizations l10n = l10nOf(tester);

      expect(find.text(l10n.receivedReviewsLoadMore), findsNothing);
      expect(find.byType(RmButton), findsNothing);
    });

    /// CARRIES WEIGHT. Page two failing does not take page one off the screen.
    testWidgets('a failed second page keeps the first on screen', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        FakeReviewRepository(
          pages: <MyReviewsResult>[
            page(<ReceivedReview>[fakeReceivedReview(id: 'a')], next: 'one'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final AppLocalizations l10n = l10nOf(tester);

      reviews.failure = const RmFailure.transport();
      await tester.tap(find.text(l10n.receivedReviewsLoadMore));
      await tester.pumpAndSettle();

      expect(find.byType(ReceivedReviewCard), findsOneWidget);
      expect(find.text(l10n.receivedReviewsLoadMoreFailed), findsOneWidget);
      // The control turns into a retry rather than disappearing.
      expect(find.text(l10n.commonRetry), findsOneWidget);
      expect(find.text(l10n.receivedReviewsEmpty), findsNothing);
    });

    testWidgets('retrying a page re-sends the same opaque cursor', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        FakeReviewRepository(
          pages: <MyReviewsResult>[
            page(<ReceivedReview>[fakeReceivedReview(id: 'a')], next: 'one'),
            page(<ReceivedReview>[fakeReceivedReview(id: 'b')]),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final AppLocalizations l10n = l10nOf(tester);

      reviews.failure = const RmFailure.transport();
      await tester.tap(find.text(l10n.receivedReviewsLoadMore));
      await tester.pumpAndSettle();

      reviews.failure = null;
      await tester.tap(find.text(l10n.commonRetry));
      await tester.pumpAndSettle();

      expect(reviews.cursors, <String?>[null, 'one', 'one']);
      expect(find.byType(ReceivedReviewCard), findsNWidgets(2));
    });
  });

  group('Nothing on this screen is a reputation', () {
    /// CARRIES WEIGHT. A figure here would be computed from a page of a list
    /// the backend deliberately withholds part of — a reputation, and a wrong
    /// one.
    testWidgets('no total, average or distribution is shown', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        FakeReviewRepository(
          pages: <MyReviewsResult>[
            page(<ReceivedReview>[
              fakeReceivedReview(id: 'a', rating: 5),
              fakeReceivedReview(id: 'b', rating: 3),
              fakeReceivedReview(id: 'c', rating: 4),
            ]),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Three rows, so a count would read `3` and an average `4`. Neither is
      // anywhere on the screen.
      expect(find.text('3'), findsNothing);
      expect(find.text('4'), findsNothing);
      expect(find.text('4,0'), findsNothing);
      expect(find.textContaining('ortalama'), findsNothing);
      expect(find.textContaining('değerlendirme sayısı'), findsNothing);
    });

    /// The source, not the rendering: a claim can hide in a string the fixture
    /// data never happens to produce.
    test('the screen and its card make no trust or verification claim', () {
      for (final String path in <String>[
        'lib/features/reviews/presentation/received_reviews_screen.dart',
        'lib/features/reviews/presentation/widgets/received_review_card.dart',
      ]) {
        final String source = File(path)
            .readAsLinesSync()
            .map((String line) {
              final int slash = line.indexOf('//');
              return slash == -1 ? line : line.substring(0, slash);
            })
            .join('\n');

        for (final String banned in <String>[
          'averageRating',
          'reviewCount',
          'trustScore',
          'RmVerification.verified',
          'ratingDistribution',
          'counterpart',
          'releasedAt',
          'seatRequestId',
          'routeId',
          'tripId',
          'accountId',
        ]) {
          expect(source.contains(banned), isFalse, reason: '$path: $banned');
        }
      }
    });

    /// CARRIES WEIGHT. The list's own size is not a fact about the member.
    ///
    /// It is the size of one page of a list the backend withholds part of, so
    /// rendering it would publish a reputation figure AND a wrong one. The
    /// loop bound is the only place the count may be read at all.
    test('the list length is never read except to walk the rows', () {
      for (final String path in <String>[
        'lib/features/reviews/presentation/received_reviews_screen.dart',
        'lib/features/reviews/presentation/widgets/received_review_card.dart',
      ]) {
        final List<String> lines = File(path).readAsLinesSync();

        for (int i = 0; i < lines.length; i++) {
          final String line = lines[i];
          if (line.trimLeft().startsWith('//')) continue;
          if (!line.contains('.length')) continue;

          expect(
            line.contains('for (int i = 0; i < page.reviews.length;'),
            isTrue,
            reason: '$path:${i + 1} reads the count for something else',
          );
        }
      }
    });
  });
}
