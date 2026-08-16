import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/a11y/rm_a11y.dart';
import 'package:ridemate/core/theme/tokens/rm_colors.dart';
import 'package:ridemate/core/widgets/rm_button.dart';
import 'package:ridemate/core/widgets/rm_cta_dock.dart';
import 'package:ridemate/core/widgets/rm_journey_marker.dart';
import 'package:ridemate/core/widgets/rm_selector_tile.dart';

import '../../support/pump.dart';

void main() {
  group('RmJourneyMarker', () {
    testBothThemes('renders both ends in both themes', (
      WidgetTester tester,
      Brightness brightness,
    ) async {
      for (final RmJourneyPoint point in RmJourneyPoint.values) {
        await tester.pumpRm(RmJourneyMarker(point), brightness: brightness);
        expect(tester.takeException(), isNull, reason: '$point $brightness');
      }
    });

    testWidgets('origin is a hollow ring, destination a solid teardrop', (
      WidgetTester tester,
    ) async {
      // The two ends must stay visually distinguishable: they are the only
      // thing telling a member which way the journey runs.
      await tester.pumpRm(const RmJourneyMarker(RmJourneyPoint.origin));
      final BoxDecoration origin =
          tester.widget<Container>(find.byType(Container)).decoration!
              as BoxDecoration;
      expect(origin.color, isNull, reason: 'origin has no fill');
      expect(origin.border, isNotNull);
      expect(origin.shape, BoxShape.circle);

      await tester.pumpRm(const RmJourneyMarker(RmJourneyPoint.destination));
      final BoxDecoration destination =
          tester.widget<Container>(find.byType(Container)).decoration!
              as BoxDecoration;
      expect(destination.color, RmColors.light.ink);
      expect(destination.border, isNull);
    });

    testWidgets('the teardrop keeps one square corner', (
      WidgetTester tester,
    ) async {
      // Three rounded corners plus one square one is what makes it a pin
      // rather than a circle once rotated.
      await tester.pumpRm(const RmJourneyMarker(RmJourneyPoint.destination));
      final BoxDecoration d =
          tester.widget<Container>(find.byType(Container)).decoration!
              as BoxDecoration;
      final BorderRadius radius = d.borderRadius! as BorderRadius;

      expect(radius.bottomLeft, Radius.zero);
      expect(radius.topLeft.x, greaterThan(0));
      expect(radius.topRight.x, greaterThan(0));
      expect(radius.bottomRight.x, greaterThan(0));
    });

    testWidgets('is decorative', (WidgetTester tester) async {
      await tester.pumpRm(const RmJourneyMarker(RmJourneyPoint.origin));
      expect(find.byType(ExcludeSemantics), findsWidgets);
    });

    testWidgets('scales its ring with its size', (WidgetTester tester) async {
      await tester.pumpRm(
        const RmJourneyMarker(RmJourneyPoint.origin, size: 32),
      );
      expect(tester.getSize(find.byType(RmJourneyMarker)), const Size(32, 32));
    });
  });

  group('RmSelectorTile', () {
    testBothThemes('renders label and value', (
      WidgetTester tester,
      Brightness brightness,
    ) async {
      await tester.pumpRm(
        const RmSelectorTile(label: 'NE ZAMAN', value: 'Yarın · 08:30'),
        brightness: brightness,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('NE ZAMAN'), findsOneWidget);
      expect(find.text('Yarın · 08:30'), findsOneWidget);
    });

    testWidgets('is display-only without a callback', (
      WidgetTester tester,
    ) async {
      await tester.pumpRm(
        const RmSelectorTile(label: 'KOLTUK', value: '1 kişi'),
      );
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('becomes a labelled button when tappable', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpRm(
        RmSelectorTile(
          label: 'NE ZAMAN',
          value: 'Yarın · 08:30',
          onTap: () => taps++,
        ),
      );

      expect(find.bySemanticsLabel('NE ZAMAN: Yarın · 08:30'), findsOneWidget);
      await tester.tap(find.byType(RmSelectorTile));
      expect(taps, 1);
    });

    testWidgets('a long value ellipsizes rather than overflowing', (
      WidgetTester tester,
    ) async {
      await tester.pumpRm(
        const SizedBox(
          width: 120,
          child: RmSelectorTile(
            label: 'NEREYE',
            value: 'Levent, Metro İstasyonu ve çevresi',
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('RmStatTile', () {
    testBothThemes('renders its figure and caption', (
      WidgetTester tester,
      Brightness brightness,
    ) async {
      await tester.pumpRm(
        const SizedBox(
          width: 110,
          child: RmStatTile(value: '92', caption: 'Güven Puanı'),
        ),
        brightness: brightness,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('92'), findsOneWidget);
      expect(find.text('Güven Puanı'), findsOneWidget);
    });

    testWidgets('reads as one node', (WidgetTester tester) async {
      await tester.pumpRm(
        const SizedBox(
          width: 110,
          child: RmStatTile(value: '%98', caption: 'Onay oranı'),
        ),
      );
      expect(find.bySemanticsLabel('%98 Onay oranı'), findsOneWidget);
    });

    testWidgets('renders whatever figure it is given', (
      WidgetTester tester,
    ) async {
      // The tile displays; it never derives. A pre-formatted fixture string
      // such as '3.4k' must pass through untouched.
      await tester.pumpRm(
        const SizedBox(
          width: 110,
          child: RmStatTile(value: '3.4k', caption: 'km paylaşıldı'),
        ),
      );
      expect(find.text('3.4k'), findsOneWidget);
    });

    testWidgets('survives a narrow tile without overflowing', (
      WidgetTester tester,
    ) async {
      // Three of these share a phone width, so each is genuinely tight.
      await tester.pumpRm(
        const SizedBox(
          width: 96,
          child: RmStatTile(value: '3.4k', caption: 'km paylaşıldı'),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('RmCtaDock', () {
    testBothThemes('renders its actions over a scrim', (
      WidgetTester tester,
      Brightness brightness,
    ) async {
      await tester.pumpRm(
        RmCtaDock(
          children: <Widget>[
            Expanded(
              child: RmButton(label: 'Devam', onPressed: () {}),
            ),
          ],
        ),
        brightness: brightness,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Devam'), findsOneWidget);
    });

    testWidgets('lays several actions out in a row', (
      WidgetTester tester,
    ) async {
      await tester.pumpRm(
        RmCtaDock(
          children: <Widget>[
            const Text('₺18'),
            Expanded(
              child: RmButton(label: 'İstek gönder', onPressed: () {}),
            ),
          ],
        ),
        surfaceSize: const Size(393, 400),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('₺18'), findsOneWidget);
      expect(find.text('İstek gönder'), findsOneWidget);
    });

    testWidgets('keeps its action above the touch floor', (
      WidgetTester tester,
    ) async {
      await tester.pumpRm(
        RmCtaDock(
          children: <Widget>[
            Expanded(
              child: RmButton(label: 'Devam', onPressed: () {}),
            ),
          ],
        ),
      );
      expect(
        tester.getSize(find.byType(RmButton)).height,
        greaterThanOrEqualTo(RmA11y.minTouchTarget),
      );
    });
  });
}
