// ─────────────────────────────────────────────────────────────
// RideMate — Reviews screen
//
// Covers what the screen shows, what it deliberately does not offer, and the
// accessibility work the histogram needs — a bar that announces its own fill
// reads as a review count.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/widgets/rm_chip.dart';
import 'package:ridemate/core/widgets/rm_icon.dart';
import 'package:ridemate/core/widgets/rm_meters.dart';
import 'package:ridemate/features/reviews/presentation/reviews_screen.dart';
import 'package:ridemate/features/reviews/presentation/widgets/rating_distribution.dart';
import 'package:ridemate/features/reviews/presentation/widgets/review_card.dart';
import 'package:ridemate/features/reviews/presentation/widgets/star_row.dart';

import '../../support/fonts.dart';
import '../../support/pump.dart';

/// The narrowest phone the project supports, and the widest.
const Size kNarrowPhone = Size(360, 780);
const Size kWidePhone = Size(393, 852);

void main() {
  setUpAll(loadRideMateFonts);

  testBothThemes('renders the summary, the tags and both reviews', (
    WidgetTester tester,
    Brightness brightness,
  ) async {
    await tester.pumpRmScreen(
      const ReviewsScreen(),
      brightness: brightness,
      surfaceSize: kWidePhone,
    );

    expect(find.text('Değerlendirmeler'), findsOneWidget);
    expect(find.text('4,9'), findsOneWidget);
    expect(find.text('73 değerlendirme'), findsOneWidget);
    expect(find.text('Dakik · 41'), findsOneWidget);
    expect(find.byType(RmChip), findsNWidgets(4));
    expect(find.byType(ReviewCard), findsNWidgets(2));
    expect(find.text('Mert A.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the rating is formatted for the locale', (
    WidgetTester tester,
  ) async {
    await tester.pumpRmScreen(
      const ReviewsScreen(),
      locale: const Locale('en'),
      surfaceSize: kWidePhone,
    );

    expect(find.text('4.9'), findsOneWidget, reason: 'a point in English');
    expect(find.text('73 reviews'), findsOneWidget);
  });

  testWidgets('draws four histogram rows, the last one empty', (
    WidgetTester tester,
  ) async {
    await tester.pumpRmScreen(const ReviewsScreen(), surfaceSize: kWidePhone);

    final Finder meters = find.descendant(
      of: find.byType(RatingDistribution),
      matching: find.byType(RmLinearMeter),
    );
    expect(meters, findsNWidgets(4));
    expect(
      tester
          .widgetList<RmLinearMeter>(meters)
          .map((RmLinearMeter m) => m.progress),
      <double>[0.92, 0.06, 0.02, 0],
    );
  });

  testWidgets('stars are icons, never the U+2605 glyph', (
    WidgetTester tester,
  ) async {
    await tester.pumpRmScreen(const ReviewsScreen(), surfaceSize: kWidePhone);

    // Neither bundled family carries U+2605, so a literal star renders tofu.
    expect(find.textContaining('★'), findsNothing);
    expect(
      find.descendant(of: find.byType(StarRow), matching: find.byType(RmIcon)),
      findsNWidgets(5),
    );
  });

  group('Accessibility', () {
    testWidgets('each histogram row announces a share, including the empty '
        'one', (WidgetTester tester) async {
      await tester.pumpRmScreen(const ReviewsScreen(), surfaceSize: kWidePhone);

      expect(
        find.bySemanticsLabel('5 yıldız: değerlendirmelerin %92 kadarı'),
        findsOneWidget,
      );
      // The empty bar still announces, so a screen-reader user gets the same
      // four rows a sighted user sees.
      expect(
        find.bySemanticsLabel('2 yıldız: değerlendirmelerin %0 kadarı'),
        findsOneWidget,
      );
      // And no bar announces a bare number that could read as a count.
      expect(find.bySemanticsLabel('92'), findsNothing);
    });

    testWidgets('the five stars are one node, not five', (
      WidgetTester tester,
    ) async {
      await tester.pumpRmScreen(const ReviewsScreen(), surfaceSize: kWidePhone);

      final SemanticsNode node = tester.getSemantics(
        find
            .descendant(
              of: find.byType(ReviewsScreen),
              matching: find.byType(StarRow),
            )
            .first,
      );
      expect(node.label, '5 üzerinden 4,9');
    });

    testWidgets('a review card announces as one sentence', (
      WidgetTester tester,
    ) async {
      await tester.pumpRmScreen(const ReviewsScreen(), surfaceSize: kWidePhone);

      final SemanticsNode node = tester.getSemantics(
        find.byType(ReviewCard).first,
      );
      expect(node.label, startsWith('Mert A., 2 gün önce, Kadıköy → Levent.'));
      expect(node.label, contains('5 üzerinden 5,0'));
      // The initials would otherwise be spelled out letter by letter.
      expect(node.label, isNot(contains('MA')));
    });
  });

  group('Layout', () {
    for (final Size size in <Size>[kNarrowPhone, kWidePhone]) {
      testWidgets('survives the maximum text scale at ${size.width}dp', (
        WidgetTester tester,
      ) async {
        await tester.pumpRmScreen(
          const ReviewsScreen(),
          surfaceSize: size,
          textScaler: const TextScaler.linear(1.6),
        );

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('lays out under RTL without overflow', (
      WidgetTester tester,
    ) async {
      await tester.pumpRmScreen(
        const ReviewsScreen(),
        textDirection: TextDirection.rtl,
        surfaceSize: kWidePhone,
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('The design offers nothing else, so neither does the screen', () {
    testWidgets('there is no way to write, sort, filter or page', (
      WidgetTester tester,
    ) async {
      await tester.pumpRmScreen(const ReviewsScreen(), surfaceSize: kWidePhone);

      // The comp draws no compose affordance and no controls of any kind
      // besides the back button, so the screen must not have grown any.
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
      for (final RmChip chip in tester.widgetList<RmChip>(
        find.byType(RmChip),
      )) {
        expect(chip.onTap, isNull, reason: 'tags are display only');
      }
    });
  });
}
