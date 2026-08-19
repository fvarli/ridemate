import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/theme/tokens/rm_colors.dart';
import 'package:ridemate/core/widgets/rm_map_canvas.dart';
import 'package:ridemate/core/widgets/rm_status_pill.dart';

import '../../support/pump.dart';

const RmMapScene _scene = RmMapScene(
  roads: <RmMapRoad>[
    RmMapRoad(start: Offset(-10, 120), end: Offset(286, 120), width: 10),
    RmMapRoad(
      start: Offset(-10, 210),
      end: Offset(286, 380),
      width: 14,
      arterial: true,
    ),
  ],
  buildings: <RmMapBuilding>[
    RmMapBuilding(rect: Rect.fromLTWH(80, 135, 60, 50)),
  ],
  route: <Offset>[Offset(70, 470), Offset(138, 320), Offset(210, 150)],
);

void main() {
  group('RmStatusPill', () {
    testBothThemes('renders its label in both themes', (
      WidgetTester tester,
      Brightness brightness,
    ) async {
      await tester.pumpRm(
        const RmStatusPill(label: 'Kadıköy'),
        brightness: brightness,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Kadıköy'), findsOneWidget);
    });

    testWidgets('exposes one semantics node', (WidgetTester tester) async {
      await tester.pumpRm(const RmStatusPill(label: 'Kadıköy'));
      expect(find.bySemanticsLabel('Kadıköy'), findsOneWidget);
    });

    testWidgets('the ink tone inverts its label in light', (
      WidgetTester tester,
    ) async {
      await tester.pumpRm(
        const RmStatusPill(label: 'CANLI', tone: RmStatusPillTone.ink),
      );
      expect(
        tester.widget<Text>(find.text('CANLI')).style!.color,
        RmColors.light.onInk,
      );
    });

    testWidgets('the ink tone follows the dark comp rather than inverting', (
      WidgetTester tester,
    ) async {
      // The source does NOT turn this into a white slab over a near-black map.
      // Its dark comp draws a surface-coloured pill with a light label.
      await tester.pumpRm(
        const RmStatusPill(label: 'CANLI', tone: RmStatusPillTone.ink),
        brightness: Brightness.dark,
      );
      expect(
        tester.widget<Text>(find.text('CANLI')).style!.color,
        RmColors.dark.ink,
      );
    });

    testWidgets('the pulsing dot animates and is disposed cleanly', (
      WidgetTester tester,
    ) async {
      await tester.pumpRm(const RmStatusPill(label: 'CANLI', pulsing: true));
      // Never pumpAndSettle: the pulse repeats forever by design.
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);

      await tester.pumpRm(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });

    testWidgets('a long label ellipsizes rather than overflowing', (
      WidgetTester tester,
    ) async {
      await tester.pumpRm(
        const SizedBox(
          width: 120,
          child: RmStatusPill(label: 'Kadıköy İskele Meydanı yakını'),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('RmMapCanvas', () {
    testBothThemes('paints a scene in both themes', (
      WidgetTester tester,
      Brightness brightness,
    ) async {
      await tester.pumpRm(
        const SizedBox(
          width: 393,
          height: 600,
          child: RmMapCanvas(scene: _scene),
        ),
        brightness: brightness,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(RmMapCanvas), findsOneWidget);
    });

    testWidgets('is decorative unless given a label', (
      WidgetTester tester,
    ) async {
      await tester.pumpRm(
        const SizedBox(
          width: 393,
          height: 600,
          child: RmMapCanvas(scene: _scene),
        ),
      );
      expect(find.byType(ExcludeSemantics), findsWidgets);
    });

    testWidgets('survives a degenerate scene rather than throwing', (
      WidgetTester tester,
    ) async {
      const RmMapScene empty = RmMapScene(
        roads: <RmMapRoad>[],
        buildings: <RmMapBuilding>[],
        route: <Offset>[],
      );
      await tester.pumpRm(
        const SizedBox(
          width: 200,
          height: 200,
          child: RmMapCanvas(scene: empty),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders at any box size, keeping the design proportions', (
      WidgetTester tester,
    ) async {
      for (final Size box in <Size>[
        const Size(320, 500),
        const Size(393, 852),
        const Size(600, 400),
      ]) {
        await tester.pumpRm(
          SizedBox(
            width: box.width,
            height: box.height,
            child: const RmMapCanvas(scene: _scene),
          ),
        );
        expect(tester.takeException(), isNull, reason: '$box');
      }
    });

    test('the design artboard is the coordinate space', () {
      // The scene is authored in the design's own 276x598 space and scaled to
      // fit, exactly as an SVG viewBox behaves.
      expect(kRmMapDesignSize, const Size(276, 598));
    });
  });
}
