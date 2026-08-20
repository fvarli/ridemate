// ─────────────────────────────────────────────────────────────
// RideMate — Safety Center screen
//
// What it draws, and — far more of it — what pressing anything on it does
// not do.
//
// PUMP NOTE: the SOS halo repeats indefinitely, so pumpAndSettle would hang.
// Every test pumps fixed frames.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/widgets/rm_halo.dart';
import 'package:ridemate/core/widgets/rm_list_row.dart';
import 'package:ridemate/features/safety/presentation/safety_screen.dart';
import 'package:ridemate/features/safety/presentation/widgets/safety_links.dart';
import 'package:ridemate/features/safety/presentation/widgets/sos_card.dart';

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
      const SafetyScreen(),
      brightness: brightness,
      textDirection: textDirection,
      locale: locale,
      surfaceSize: size,
      textScaler: TextScaler.linear(textScale),
      disableAnimations: disableAnimations,
    );
    // Fixed frames: the SOS halo never settles.
    await tester.pump(const Duration(milliseconds: 200));
  }

  /// Taps [target] and expects exactly [message] to appear.
  Future<void> tapAndExpect(
    WidgetTester tester,
    Finder target,
    String message,
  ) async {
    await tester.ensureVisible(target);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(target);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(message), findsOneWidget);
  }

  group('SafetyScreen', () {
    testBothThemes('renders the approved copy', (
      WidgetTester tester,
      Brightness brightness,
    ) async {
      await pump(tester, brightness: brightness);

      expect(tester.takeException(), isNull);
      expect(find.text('Güvenlik Merkezi'), findsOneWidget);
      expect(find.text('Her yolculukta yanındayız'), findsOneWidget);
      expect(find.text('Acil yardım'), findsOneWidget);
      expect(
        find.text(
          'Bas, konumun ve yolculuk bilgin acil kişilere + ekibimize gider.',
        ),
        findsOneWidget,
      );
      expect(find.text("112'yi ara"), findsOneWidget);
      expect(find.text('Yolculuğu paylaş'), findsOneWidget);
      expect(find.text('Güvenilir kişiler'), findsOneWidget);
      expect(find.text('2 kişi eklendi'), findsOneWidget);
      expect(find.text('Yol arkadaşını doğrula'), findsOneWidget);
    });

    testBothThemes('keeps the block row the dark comp drops', (
      WidgetTester tester,
      Brightness brightness,
    ) async {
      // The dark artboard omits this row. A safety affordance that disappears
      // at night is a regression, not intent (D-safety-2).
      await pump(tester, brightness: brightness);

      expect(find.text('Kullanıcı engelle / bildir'), findsOneWidget);
      expect(find.text('Gizli inceleme'), findsOneWidget);
      expect(find.byType(RmListRow), findsNWidgets(3));
    });
  });

  group('Nothing on this screen does what it says', () {
    testWidgets('the SOS card notifies nobody and changes nothing', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      await tapAndExpect(
        tester,
        find.byType(SosCard),
        'Acil durum özelliği henüz aktif değil. Kimseye bildirim gönderilmedi.',
      );

      // No countdown, no confirmation, no armed or triggered state, no
      // success copy, and the card is exactly as it was.
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(SosCard), findsOneWidget);
      for (final String forbidden in <String>[
        'gönderildi',
        'İptal',
        'Yardım çağrıldı',
        'Bildirildi',
        'saniye',
      ]) {
        expect(find.textContaining(forbidden), findsNothing, reason: forbidden);
      }
      // The promise is untouched: pressing it corrects the claim rather than
      // rewriting it.
      expect(
        find.text(
          'Bas, konumun ve yolculuk bilgin acil kişilere + ekibimize gider.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('112 starts no call and says which capability is missing', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      // Not "the call failed" — the app cannot place one at all.
      await tapAndExpect(
        tester,
        find.text("112'yi ara"),
        'Uygulama henüz arama başlatamıyor.',
      );
      expect(find.byType(SafetyScreen), findsOneWidget);
    });

    testWidgets('sharing shares nothing', (WidgetTester tester) async {
      await pump(tester);
      await tapAndExpect(
        tester,
        find.text('Yolculuğu paylaş'),
        'Yolculuk paylaşma özelliği henüz aktif değil. Hiçbir şey paylaşılmadı.',
      );
    });

    testWidgets('each row names its own missing capability', (
      WidgetTester tester,
    ) async {
      // Three different gaps, three different sentences — a single generic
      // apology would tell a reviewer nothing about what is missing.
      const Map<String, String> expected = <String, String>{
        'Güvenilir kişiler': 'Güvenilir kişiler özelliği henüz eklenmedi.',
        'Yol arkadaşını doğrula': 'QR ile doğrulama özelliği henüz eklenmedi.',
        'Kullanıcı engelle / bildir':
            'Kullanıcı engelleme özelliği henüz eklenmedi.',
      };

      for (final MapEntry<String, String> entry in expected.entries) {
        await pump(tester);
        await tapAndExpect(tester, find.text(entry.key), entry.value);
        // No navigation, and no new state anywhere.
        expect(find.byType(SafetyScreen), findsOneWidget);
        expect(find.byType(RmListRow), findsNWidgets(3));
      }
    });

    testWidgets('the three messages are all different', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      final Iterable<String> messages = <String>{
        'Güvenilir kişiler özelliği henüz eklenmedi.',
        'QR ile doğrulama özelliği henüz eklenmedi.',
        'Kullanıcı engelleme özelliği henüz eklenmedi.',
        'Uygulama henüz arama başlatamıyor.',
      };
      expect(messages.length, 4);
    });
  });

  group('Accessibility', () {
    testWidgets('the SOS card is one button announcing what it draws', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      final SemanticsNode node = tester.getSemantics(find.byType(SosCard));
      expect(node.flagsCollection.isButton, isTrue);
      expect(
        node.label,
        'Acil yardım. Bas, konumun ve yolculuk bilgin acil kişilere + '
        'ekibimize gider.',
      );
    });

    testWidgets('each row announces its title and subtitle', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      expect(
        find.bySemanticsLabel('Güvenilir kişiler. 2 kişi eklendi'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel("112'yi ara. Acil servis"), findsOneWidget);
    });

    testWidgets('reduced motion stills the halo', (WidgetTester tester) async {
      await pump(tester, disableAnimations: true);

      // The halo repeats forever, so it stops entirely rather than slowing
      // down (WCAG 2.2.2).
      expect(find.byType(RmHalo), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(RmHalo),
          matching: find.byType(AnimatedBuilder),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Layout', () {
    for (final Size size in <Size>[kNarrowPhone, kStandardPhone]) {
      for (final double scale in <double>[1, 1.6]) {
        testWidgets('${size.width}dp at ${scale}x', (
          WidgetTester tester,
        ) async {
          await pump(tester, size: size, textScale: scale);
          expect(tester.takeException(), isNull);
          expect(find.byType(SafetyLinks), findsOneWidget);
        });
      }
    }

    testWidgets('lays out under RTL without overflow', (
      WidgetTester tester,
    ) async {
      await pump(tester, textDirection: TextDirection.rtl);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in English without overflow', (
      WidgetTester tester,
    ) async {
      await pump(tester, locale: const Locale('en'), size: kNarrowPhone);
      expect(find.text('Safety Center'), findsOneWidget);
      expect(find.text('Call 112'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
