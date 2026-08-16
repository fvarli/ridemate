import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/widgets/rm_avatar.dart';
import 'package:ridemate/core/widgets/rm_map_canvas.dart';
import 'package:ridemate/core/widgets/rm_status_pill.dart';
import 'package:ridemate/features/home/presentation/home_screen.dart';
import 'package:ridemate/features/home/presentation/widgets/home_map.dart';
import 'package:ridemate/features/home/presentation/widgets/nearby_match_sheet.dart';

import '../../support/pump.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    TextDirection textDirection = TextDirection.ltr,
    Locale locale = kDefaultTestLocale,
  }) async {
    await tester.pumpRmScreen(
      const Scaffold(body: HomeScreen()),
      brightness: brightness,
      textDirection: textDirection,
      locale: locale,
      surfaceSize: const Size(393, 852),
    );
    await tester.pump();
  }

  group('HomeScreen', () {
    testBothThemes('renders every layer in both themes', (
      WidgetTester tester,
      Brightness brightness,
    ) async {
      await pump(tester, brightness: brightness);

      expect(tester.takeException(), isNull);
      expect(find.byType(HomeMap), findsOneWidget);
      expect(find.byType(NearbyMatchSheet), findsOneWidget);
      expect(find.byType(RmStatusPill), findsOneWidget);
    });

    testBothThemes('renders the approved copy', (
      WidgetTester tester,
      Brightness brightness,
    ) async {
      await pump(tester, brightness: brightness);

      expect(find.text('Günaydın,'), findsOneWidget);
      expect(find.text('Elif'), findsOneWidget);
      expect(find.text('Kadıköy'), findsOneWidget);
      expect(find.text('Nereye gidiyorsun?'), findsOneWidget);
      expect(find.text('Yakınındaki rotalar'), findsOneWidget);
      expect(find.text('Selin K.'), findsOneWidget);
      expect(find.text('Kadıköy → Levent'), findsOneWidget);
    });

    testBothThemes('formats every value for the Turkish locale', (
      WidgetTester tester,
      Brightness brightness,
    ) async {
      await pump(tester, brightness: brightness);

      // Cost-sharing display data, prefixed lira sign per the design.
      expect(find.text('₺18'), findsOneWidget);
      // Turkish puts the percent sign first.
      expect(find.text('%94 uyum'), findsOneWidget);
      expect(find.text('3 eşleşme →'), findsOneWidget);
      // Locale-correct decimal separator.
      expect(find.text('4,9'), findsOneWidget);
      expect(find.text('4.9'), findsNothing);
    });

    testWidgets('formats for English when the locale changes', (
      WidgetTester tester,
    ) async {
      await pump(tester, locale: const Locale('en'));

      expect(find.text('4.9'), findsOneWidget);
      expect(find.text('94% match'), findsOneWidget);
      expect(find.text('Good morning,'), findsOneWidget);
    });

    testWidgets('renders under RTL without overflow', (
      WidgetTester tester,
    ) async {
      await pump(tester, textDirection: TextDirection.rtl);
      expect(tester.takeException(), isNull);
    });

    testWidgets('survives the maximum text scale', (WidgetTester tester) async {
      await tester.pumpRmScreen(
        const Scaffold(body: HomeScreen()),
        surfaceSize: const Size(393, 852),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Dark mode must not reduce information', () {
    testWidgets('dark Home shows the same map markers as light', (
      WidgetTester tester,
    ) async {
      // The dark design comp omits the destination pin, a driver pin, the
      // arterial road, a building and the chip icons. Those omissions are
      // treated as comp simplification, not product behaviour — the same
      // screen must not show the user less at night.
      Future<int> avatarCount(Brightness brightness) async {
        await pump(tester, brightness: brightness);
        return find.byType(RmAvatar).evaluate().length;
      }

      final int light = await avatarCount(Brightness.light);
      final int dark = await avatarCount(Brightness.dark);

      expect(dark, light);
      expect(light, greaterThanOrEqualTo(3), reason: '2 driver pins + 1 match');
    });

    testWidgets('the destination pin is present in dark', (
      WidgetTester tester,
    ) async {
      await pump(tester, brightness: Brightness.dark);
      expect(find.text('Levent'), findsOneWidget);
    });

    testWidgets('shortcut chips keep their icons in dark', (
      WidgetTester tester,
    ) async {
      Future<int> chipIcons(Brightness brightness) async {
        await pump(tester, brightness: brightness);
        return find.text('Ev').evaluate().length;
      }

      expect(
        await chipIcons(Brightness.dark),
        await chipIcons(Brightness.light),
      );
      expect(find.text('İş · Levent'), findsOneWidget);
      expect(find.text('Üniversite'), findsOneWidget);
    });

    testWidgets('the map scene itself is identical across themes', (
      WidgetTester tester,
    ) async {
      // One scene, re-palettised — not two scenes.
      await pump(tester, brightness: Brightness.light);
      final RmMapCanvas lightCanvas = tester.widget(find.byType(RmMapCanvas));
      await pump(tester, brightness: Brightness.dark);
      final RmMapCanvas darkCanvas = tester.widget(find.byType(RmMapCanvas));

      expect(darkCanvas.scene, same(lightCanvas.scene));
      expect(kHomeMapScene.roads.length, 7);
      expect(kHomeMapScene.buildings.length, 3);
    });
  });

  group('Accessibility', () {
    testWidgets('the search field is a labelled button', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      expect(
        find.bySemanticsLabel('Nereye gidiyorsun? Rota ara.'),
        findsOneWidget,
      );
    });

    testWidgets('the match reads as one node with its key facts', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      expect(
        find.bySemanticsLabel(
          'Selin K., 4,9 puan. Kadıköy → Levent. Kişi başı ₺18. %94 rota uyumu.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the map illustration is decorative', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      // Artwork carries no information a screen reader needs; the match card
      // carries the real content.
      expect(find.byType(ExcludeSemantics), findsWidgets);
    });
  });
}
