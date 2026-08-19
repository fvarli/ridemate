// ─────────────────────────────────────────────────────────────
// RideMate — Active trip screen
//
// Both themes, both locales, RTL, 360dp and 393dp, and the maximum text scale.
//
// PUMP NOTE: three animations repeat indefinitely here, so pumpAndSettle would
// hang. Every test pumps fixed frames, and the reduced-motion cases pump with
// disableAnimations so there is nothing running at all.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/a11y/rm_a11y.dart';
import 'package:ridemate/core/widgets/rm_avatar.dart';
import 'package:ridemate/core/widgets/rm_map_canvas.dart';
import 'package:ridemate/core/widgets/rm_pulse_dot.dart';
import 'package:ridemate/features/trip/presentation/active_trip_screen.dart';
import 'package:ridemate/features/trip/presentation/widgets/active_trip_map.dart';

import '../../support/fonts.dart';
import '../../support/pump.dart';

const Size kNarrowPhone = Size(360, 800);
const Size kStandardPhone = Size(393, 852);

void main() {
  setUpAll(loadRideMateFonts);

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    TextDirection textDirection = TextDirection.ltr,
    Locale locale = kDefaultTestLocale,
    Size size = kStandardPhone,
    double textScale = 1,
    bool disableAnimations = false,
  }) async {
    await tester.pumpRmScreen(
      const ActiveTripScreen(),
      brightness: brightness,
      textDirection: textDirection,
      locale: locale,
      surfaceSize: size,
      textScaler: TextScaler.linear(textScale),
      disableAnimations: disableAnimations,
    );
    // Fixed frames: the pulses and the SOS halo never settle.
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('ActiveTripScreen', () {
    testBothThemes('renders the approved copy', (
      WidgetTester tester,
      Brightness brightness,
    ) async {
      await pump(tester, brightness: brightness);

      expect(tester.takeException(), isNull);
      expect(find.text('CANLI YOLCULUK'), findsOneWidget);
      expect(find.text("Levent'e varış"), findsOneWidget);
      expect(find.text('Zamanında'), findsOneWidget);
      expect(find.text('Selin K. · 4,9'), findsOneWidget);
      // The plate's own spaces are non-breaking, so a wrap falls at the
      // separator rather than splitting "34 ABC 128" across two lines.
      expect(find.text('VW Passat · 34\u00A0ABC\u00A0128'), findsOneWidget);
      expect(find.text('Yolculuğu paylaş'), findsOneWidget);
      expect(find.text('SOS'), findsOneWidget);
      expect(
        find.text('Canlı konumun 2 acil kişiyle paylaşılıyor'),
        findsOneWidget,
      );
    });

    testBothThemes('shows the same map information in both themes', (
      WidgetTester tester,
      Brightness brightness,
    ) async {
      // Dark re-palettes the scene; it never shows less. The dark comp omits
      // the buildings and the destination pin, and both are kept — see
      // D-home-1.
      await pump(tester, brightness: brightness);

      expect(find.byType(RmMapCanvas), findsOneWidget);
      expect(kActiveTripMapScene.buildings, hasLength(2));
      expect(kActiveTripMapScene.roads, hasLength(4));
    });

    testWidgets('formats the figures for the Turkish locale', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      expect(find.textContaining('18 dk'), findsOneWidget);
      // Locale-correct decimal separator, per the locked formatting decision.
      expect(find.textContaining('6,2 km'), findsOneWidget);
      expect(find.textContaining('6.2 km'), findsNothing);
    });
  });

  group('Presence, not verification', () {
    testWidgets('the driver avatar shows a presence dot and no check', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      final RmAvatar avatar = tester.widget<RmAvatar>(find.byType(RmAvatar));
      expect(avatar.presence, RmPresence.online);
      expect(avatar.verification, RmVerification.none);
      expect(find.byType(RmVerifiedBadge), findsNothing);
    });

    testWidgets('the row announces presence itself', (
      WidgetTester tester,
    ) async {
      // There is no visible "Çevrimiçi" text on this screen, so the dot is
      // load-bearing and the merged label has to carry it.
      await pump(tester);

      expect(
        find.bySemanticsLabel(
          'Selin K., 4,9 puan, çevrimiçi. VW Passat, 34 ABC 128.',
        ),
        findsOneWidget,
      );
    });
  });

  group('Every action is honest', () {
    Future<void> tapAndExpect(
      WidgetTester tester,
      Finder target,
      String message,
    ) async {
      await tester.tap(target);
      await tester.pump();
      expect(find.text(message), findsOneWidget);
    }

    testWidgets('SOS notifies nobody and creates no state', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      await tapAndExpect(
        tester,
        find.text('SOS'),
        'Acil durum özelliği henüz aktif değil. Kimseye bildirim gönderilmedi.',
      );

      // No countdown, no confirmation, no armed state, no success copy.
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(ActiveTripScreen), findsOneWidget);
      for (final String forbidden in <String>[
        'gönderildi',
        'İptal',
        'Yardım çağrıldı',
        '112',
      ]) {
        expect(find.textContaining(forbidden), findsNothing, reason: forbidden);
      }
      // And the button is unchanged.
      expect(find.text('SOS'), findsOneWidget);
    });

    testWidgets('sharing shares nothing', (WidgetTester tester) async {
      await pump(tester);
      await tapAndExpect(
        tester,
        find.text('Yolculuğu paylaş'),
        'Yolculuk paylaşma özelliği henüz aktif değil. Hiçbir şey paylaşılmadı.',
      );
    });

    testWidgets('calling calls nobody', (WidgetTester tester) async {
      await pump(tester);
      await tapAndExpect(
        tester,
        find.bySemanticsLabel('Sürücüyü ara'),
        'Arama özelliği henüz aktif değil. Hiçbir arama başlatılmadı.',
      );
    });

    testWidgets('the clock tile is inert and silent', (
      WidgetTester tester,
    ) async {
      // It has no defined behaviour anywhere in the design, so no purpose is
      // invented for it. Recorded as D-trip-2.
      await pump(tester);
      expect(find.bySemanticsLabel(RegExp('saat|clock')), findsNothing);
    });
  });

  group('Reduced motion', () {
    testWidgets('stops every infinite animation', (WidgetTester tester) async {
      await pump(tester, disableAnimations: true);

      expect(find.byType(RmPulseDot), findsNWidgets(2));
      expect(
        find.descendant(
          of: find.byType(RmPulseDot),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
        reason: 'both dots must be still',
      );
      // And the screen keeps rendering with nothing running.
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
      expect(find.text('CANLI YOLCULUK'), findsOneWidget);
    });
  });

  group('Responsiveness', () {
    testWidgets('renders in English, RTL and at the narrow width', (
      WidgetTester tester,
    ) async {
      await pump(tester, textDirection: TextDirection.rtl);
      expect(tester.takeException(), isNull, reason: 'TR RTL');

      await pump(tester, size: kNarrowPhone);
      expect(tester.takeException(), isNull, reason: 'TR at 360dp');

      await pump(tester, locale: const Locale('en'));
      expect(tester.takeException(), isNull, reason: 'EN');
      expect(find.text('LIVE TRIP'), findsOneWidget);
      expect(find.text('Arriving in Levent'), findsOneWidget);
      expect(find.text('Share trip'), findsOneWidget);

      await pump(tester, locale: const Locale('en'), size: kNarrowPhone);
      expect(tester.takeException(), isNull, reason: 'EN at 360dp');
    });

    testWidgets('survives the maximum text scale at the narrow width', (
      WidgetTester tester,
    ) async {
      // The sheet is the tallest thing in the app and the actions row is the
      // first thing to break; it stacks rather than squeezing SOS.
      await pump(
        tester,
        size: kNarrowPhone,
        textScale: RmA11y.maxTextScale,
        disableAnimations: true,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('SOS'), findsOneWidget);
      expect(find.text('Yolculuğu paylaş'), findsOneWidget);
    });
  });
}
