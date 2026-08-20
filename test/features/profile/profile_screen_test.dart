// ─────────────────────────────────────────────────────────────
// RideMate — Profile screen
//
// The trust card is the densest row set in the app: a ring, a badge, two
// lines of prose and four measured columns, inside a card that overlaps the
// header. Most of what follows is about it surviving 360dp at the maximum
// text scale, which the goldens at 1.0 would never catch.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/widgets/rm_card.dart';
import 'package:ridemate/core/widgets/rm_meters.dart';
import 'package:ridemate/features/profile/domain/profile_fixtures.dart';
import 'package:ridemate/features/profile/presentation/profile_screen.dart';
import 'package:ridemate/features/profile/presentation/widgets/profile_links.dart';
import 'package:ridemate/features/profile/presentation/widgets/profile_stats.dart';
import 'package:ridemate/features/profile/presentation/widgets/trust_factor_row.dart';
import 'package:ridemate/features/profile/presentation/widgets/trust_score_card.dart';

import '../../support/fonts.dart';
import '../../support/pump.dart';

const Size kNarrowPhone = Size(360, 780);
const Size kWidePhone = Size(393, 852);

void main() {
  setUpAll(loadRideMateFonts);

  testBothThemes('renders the header, the trust card, the stats and the rows', (
    WidgetTester tester,
    Brightness brightness,
  ) async {
    await tester.pumpRmScreen(
      const ProfileScreen(),
      brightness: brightness,
      surfaceSize: kWidePhone,
    );

    expect(find.text('Elif Çelik'), findsOneWidget);
    expect(find.text("Doğrulanmış üye · 2024'ten beri"), findsOneWidget);
    expect(find.text('Güven Puanı'), findsOneWidget);
    expect(find.text('92'), findsOneWidget);
    expect(find.text('/ 100'), findsOneWidget);
    expect(find.text('Üst %8 · Güvenilir'), findsOneWidget);
    expect(find.text("100'e ulaşmak için 1 yolculuk daha"), findsOneWidget);
    expect(find.text('Kimlik'), findsOneWidget);
    expect(find.text('Aktiflik'), findsOneWidget);
    expect(find.text('73'), findsOneWidget);
    expect(find.text('4,9'), findsOneWidget);
    expect(find.text('₺2.1k'), findsOneWidget);
    expect(find.text('4 / 5'), findsOneWidget);
    expect(find.text('Değerlendirmelerim'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the ring is drawn from the score, not from the factors', (
    WidgetTester tester,
  ) async {
    await tester.pumpRmScreen(const ProfileScreen(), surfaceSize: kWidePhone);

    final RmTrustRing ring = tester.widget<RmTrustRing>(
      find.descendant(
        of: find.byType(TrustScoreCard),
        matching: find.byType(RmTrustRing),
      ),
    );
    expect(ring.progress, 0.92);

    // The four bars carry their own declared fills.
    final Iterable<double> bars = tester
        .widgetList<RmLinearMeter>(
          find.descendant(
            of: find.byType(TrustBreakdown),
            matching: find.byType(RmLinearMeter),
          ),
        )
        .map((RmLinearMeter m) => m.progress);
    expect(bars, <double>[1, 0.9, 0.94, 0.82]);
  });

  testWidgets('the star in the tier badge is an icon, not a glyph', (
    WidgetTester tester,
  ) async {
    await tester.pumpRmScreen(const ProfileScreen(), surfaceSize: kWidePhone);

    // U+2605 is absent from both bundled families and renders as tofu.
    expect(find.textContaining('★'), findsNothing);
  });

  group('Accessibility', () {
    testWidgets('the ring announces a score out of 100 and nothing more', (
      WidgetTester tester,
    ) async {
      await tester.pumpRmScreen(const ProfileScreen(), surfaceSize: kWidePhone);

      expect(
        find.bySemanticsLabel('Güven Puanı: 92, 100 üzerinden'),
        findsOneWidget,
      );
      // Never a percentage: the score is not a proportion of anything.
      expect(find.bySemanticsLabel(RegExp('%92')), findsNothing);
    });

    testWidgets('each factor announces once, and the amber one says why', (
      WidgetTester tester,
    ) async {
      await tester.pumpRmScreen(const ProfileScreen(), surfaceSize: kWidePhone);

      expect(find.bySemanticsLabel('Kimlik: 100'), findsOneWidget);
      expect(find.bySemanticsLabel('Güvenilirlik: 94'), findsOneWidget);
      // Colour is otherwise the only thing marking this row (WCAG 1.4.1).
      expect(find.bySemanticsLabel('Aktiflik: 82, dikkat'), findsOneWidget);
      // And the meters do not announce their fills a second time.
      expect(find.bySemanticsLabel('82'), findsNothing);
    });

    testWidgets('the verification row announces its count', (
      WidgetTester tester,
    ) async {
      await tester.pumpRmScreen(const ProfileScreen(), surfaceSize: kWidePhone);

      // The count lives only in a trailing badge, which emits no semantics.
      expect(
        find.bySemanticsLabel(
          'Doğrulama rozetleri: 5 adımdan 4 tanesi tamamlandı',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the verification row is not a button, the reviews row is', (
      WidgetTester tester,
    ) async {
      await tester.pumpRmScreen(const ProfileScreen(), surfaceSize: kWidePhone);

      final Iterable<RmCard> rows = tester.widgetList<RmCard>(
        find.descendant(
          of: find.byType(ProfileLinks),
          matching: find.byType(RmCard),
        ),
      );
      expect(rows.length, 2);
      // The comp gives the first row no chevron, so it does nothing — and it
      // therefore must not announce itself as actionable.
      expect(rows.first.onTap, isNull);
      expect(rows.last.onTap, isNotNull);

      final SemanticsNode node = tester.getSemantics(
        find
            .descendant(
              of: find.byType(ProfileLinks),
              matching: find.byType(RmCard),
            )
            .first,
      );
      expect(node.flagsCollection.isButton, isFalse);
    });
  });

  group('Layout', () {
    for (final Size size in <Size>[kNarrowPhone, kWidePhone]) {
      testWidgets('the trust card survives 1.6x at ${size.width}dp', (
        WidgetTester tester,
      ) async {
        await tester.pumpRmScreen(
          const ProfileScreen(),
          surfaceSize: size,
          textScaler: const TextScaler.linear(1.6),
        );

        expect(tester.takeException(), isNull);
        // The rows must still be laid out, not merely not throwing.
        expect(find.byType(TrustFactorRow), findsNWidgets(4));
      });
    }

    testWidgets('the breakdown shares one label column across all four rows', (
      WidgetTester tester,
    ) async {
      await tester.pumpRmScreen(const ProfileScreen(), surfaceSize: kWidePhone);

      // The comp fixes the label column at 74px, which `Güvenilirlik` alone
      // outgrows once the text scales. The column is measured instead, and
      // every row must get the same one or the bars stop sharing an axis.
      final Iterable<TrustFactorRow> rows = tester.widgetList<TrustFactorRow>(
        find.byType(TrustFactorRow),
      );
      final Set<double?> widths = rows
          .map((TrustFactorRow r) => r.labelWidth)
          .toSet();
      expect(widths.length, 1);
      expect(widths.single, isNotNull);
    });

    testWidgets('the breakdown stacks rather than crushing the bar', (
      WidgetTester tester,
    ) async {
      // Squeezed past the point where a label, a usable bar and a figure fit
      // on one line. The bar is the only part of the row that has to be wide
      // — below a floor it stops reading as a proportion at all — so the row
      // breaks instead of shrinking it. Pumped in isolation because this is
      // narrower than any supported screen: it is the breakdown's own floor,
      // not a layout the app ships.
      await tester.pumpRm(
        const SizedBox(
          width: 160,
          child: TrustBreakdown(factors: kMockProfileFactors),
        ),
        textScaler: const TextScaler.linear(1.6),
      );

      expect(tester.takeException(), isNull);
      for (final TrustFactorRow row in tester.widgetList<TrustFactorRow>(
        find.byType(TrustFactorRow),
      )) {
        expect(row.labelWidth, isNull, reason: 'stacked');
      }
      // The label and its figure are still both present, just on their own
      // line above the bar.
      expect(find.text('Güvenilirlik'), findsOneWidget);
      expect(find.text('94'), findsOneWidget);
    });

    testWidgets('the stat tiles stack rather than shrink at 1.6x', (
      WidgetTester tester,
    ) async {
      await tester.pumpRmScreen(
        const ProfileScreen(),
        surfaceSize: kNarrowPhone,
        textScaler: const TextScaler.linear(1.6),
      );

      // `₺2.1k` is the whole content of its tile; three of them across a
      // 360dp screen would have to shrink the figure to nothing (D-profile-3).
      final Finder stats = find.byType(ProfileStats);
      expect(
        find.descendant(of: stats, matching: find.byType(Row)),
        findsNothing,
        reason: 'stacked into a column',
      );
    });

    testWidgets('lays out under RTL without overflow', (
      WidgetTester tester,
    ) async {
      await tester.pumpRmScreen(
        const ProfileScreen(),
        textDirection: TextDirection.rtl,
        surfaceSize: kWidePhone,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
