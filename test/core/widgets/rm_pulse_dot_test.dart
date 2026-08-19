// ─────────────────────────────────────────────────────────────
// RideMate — Pulsing status dot
//
// The behaviour that matters is the one a member can be harmed by: an
// animation that repeats forever must stop when they have asked for reduced
// motion. WCAG 2.2.2.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/theme/tokens/rm_motion.dart';
import 'package:ridemate/core/widgets/rm_pulse_dot.dart';
import 'package:ridemate/core/widgets/rm_status_pill.dart';

import '../../support/pump.dart';

void main() {
  /// Scoped to the dot: a route transition contributes FadeTransitions of its
  /// own, so a bare byType finder would never be empty.
  final Finder fade = find.descendant(
    of: find.byType(RmPulseDot),
    matching: find.byType(FadeTransition),
  );

  /// The opacity the dot is currently rendered at.
  double opacityOf(WidgetTester tester) =>
      tester.widget<FadeTransition>(fade).opacity.value;

  group('RmPulseDot', () {
    testWidgets('is a still dot when not pulsing', (WidgetTester tester) async {
      await tester.pumpRm(const RmPulseDot(color: Color(0xFF18A957)));

      expect(fade, findsNothing);
      expect(
        find.descendant(
          of: find.byType(RmPulseDot),
          matching: find.byType(ScaleTransition),
        ),
        findsNothing,
      );
    });

    testWidgets('animates across its cycle when pulsing', (
      WidgetTester tester,
    ) async {
      await tester.pumpRm(
        const RmPulseDot(color: Color(0xFF18A957), pulsing: true),
      );

      final double start = opacityOf(tester);
      await tester.pump(RmMotion.pulse ~/ 2);
      expect(opacityOf(tester), isNot(start));
      // Never fully transparent: the source's rm-pulse floors at 0.35.
      expect(opacityOf(tester), greaterThanOrEqualTo(RmMotion.pulseMinOpacity));
    });

    testWidgets('stills itself under reduced motion', (
      WidgetTester tester,
    ) async {
      // The screens that use this animate indefinitely. A member who has asked
      // the system to remove animations must not be given one anyway.
      await tester.pumpRmScreen(
        const Scaffold(
          body: Center(
            child: RmPulseDot(color: Color(0xFF18A957), pulsing: true),
          ),
        ),
        disableAnimations: true,
      );

      expect(find.byType(RmPulseDot), findsOneWidget);
      expect(
        fade,
        findsNothing,
        reason: 'reduced motion must render a still dot',
      );

      // And it stays still — a frame later nothing has moved.
      await tester.pump(RmMotion.pulse);
      expect(fade, findsNothing);
    });

    testWidgets('starts and stops when the flag changes', (
      WidgetTester tester,
    ) async {
      await tester.pumpRm(const RmPulseDot(color: Color(0xFF18A957)));
      expect(fade, findsNothing);

      await tester.pumpRm(
        const RmPulseDot(color: Color(0xFF18A957), pulsing: true),
      );
      expect(fade, findsOneWidget);
    });
  });

  group('RmStatusPill delegates to it', () {
    testWidgets('renders a still dot under reduced motion', (
      WidgetTester tester,
    ) async {
      await tester.pumpRmScreen(
        const Scaffold(
          body: Center(
            child: RmStatusPill(
              label: 'CANLI YOLCULUK',
              tone: RmStatusPillTone.ink,
              pulsing: true,
            ),
          ),
        ),
        disableAnimations: true,
      );

      expect(find.byType(RmPulseDot), findsOneWidget);
      expect(fade, findsNothing);
      expect(find.text('CANLI YOLCULUK'), findsOneWidget);
    });
  });
}
