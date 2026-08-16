// ─────────────────────────────────────────────────────────────
// RideMate — Discovery screen tests
//
// The three screens are checked in both themes, both locales, RTL, at the
// maximum text scale the app allows, and at 360dp as well as 393dp — the
// narrow width is where Phase 2's overflows first appeared.
//
// The behavioural assertions guard the phase's honesty rules: filters change
// no results, sort follows the fixture's declared order, and requesting a seat
// creates no "sent" state.
//
// The real fonts are loaded. Without them every glyph rasterizes as a square
// em box, which is far wider than Manrope — so a width assertion would be
// measuring Ahem rather than the product, and would both fail spuriously and
// miss real overflows. Phase 2's truncated Home row proved that the hard way.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/a11y/rm_a11y.dart';
import 'package:ridemate/core/widgets/rm_button.dart';
import 'package:ridemate/core/widgets/rm_chip.dart';
import 'package:ridemate/core/widgets/rm_selector_tile.dart';
import 'package:ridemate/features/discovery/domain/mock_discovery_fixtures.dart';
import 'package:ridemate/features/discovery/domain/route_offer.dart';
import 'package:ridemate/features/discovery/domain/search_draft.dart';
import 'package:ridemate/features/discovery/presentation/match_results_screen.dart';
import 'package:ridemate/features/discovery/presentation/route_details_screen.dart';
import 'package:ridemate/features/discovery/presentation/search_screen.dart';
import 'package:ridemate/features/discovery/presentation/widgets/match_card.dart';

import '../../support/fonts.dart';
import '../../support/pump.dart';

/// The narrow phone width where Phase 2's overflows appeared.
const Size kNarrowPhone = Size(360, 800);

/// The reference device the design targets.
const Size kStandardPhone = Size(393, 852);

/// Re-scales text without discarding the ambient [MediaQueryData].
Widget _atTextScale(double scale, Widget child) {
  return Builder(
    builder: (BuildContext context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child,
    ),
  );
}

void main() {
  setUpAll(loadRideMateFonts);

  group('SearchScreen', () {
    Future<void> pump(
      WidgetTester tester, {
      Brightness brightness = Brightness.light,
      TextDirection textDirection = TextDirection.ltr,
      Locale locale = kDefaultTestLocale,
      Size size = kStandardPhone,
      double textScale = 1,
    }) async {
      await tester.pumpRmScreen(
        _atTextScale(textScale, const SearchScreen()),
        brightness: brightness,
        textDirection: textDirection,
        locale: locale,
        surfaceSize: size,
      );
      await tester.pump();
    }

    testBothThemes('renders the approved copy', (
      WidgetTester tester,
      Brightness brightness,
    ) async {
      await pump(tester, brightness: brightness);

      expect(tester.takeException(), isNull);
      expect(find.text('Rota ara'), findsOneWidget);
      expect(find.text('NEREDEN'), findsOneWidget);
      expect(find.text('NEREYE'), findsOneWidget);
      expect(find.text('Kadıköy, İskele Meydanı'), findsOneWidget);
      expect(find.text('Levent, Metro İstasyonu'), findsOneWidget);
      expect(find.text('GÜVEN FİLTRELERİ'), findsOneWidget);
      expect(find.text('SON ARAMALAR'), findsOneWidget);
      expect(find.text('Eşleşmeleri gör · 3 sonuç'), findsOneWidget);
    });

    testBothThemes('renders every designed filter', (
      WidgetTester tester,
      Brightness brightness,
    ) async {
      await pump(tester, brightness: brightness);

      for (final String label in <String>[
        'Sadece doğrulanmış',
        '4.5+ puan',
        'Kadın sürücü',
        'Sigara yok',
        'Ortak bağlantı',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.byType(RmChip), findsNWidgets(5));
      // The design selects exactly one.
      expect(
        tester
            .widgetList<RmChip>(find.byType(RmChip))
            .where((RmChip chip) => chip.selected)
            .length,
        1,
      );
    });

    testWidgets('shows the when and seats selectors', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      expect(find.byType(RmSelectorTile), findsNWidgets(2));
      expect(find.text('NE ZAMAN'), findsOneWidget);
      expect(find.text('Yarın · 08:30'), findsOneWidget);
      expect(find.text('KOLTUK'), findsOneWidget);
      expect(find.text('1 kişi'), findsOneWidget);
    });

    testWidgets('tapping an endpoint opens the place picker', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('Kadıköy, İskele Meydanı'));
      await tester.pumpAndSettle();

      expect(find.text('Nereden yola çıkıyorsun?'), findsOneWidget);
      // The deterministic fixture list, not a search result.
      expect(find.text('Maslak, 42 Maslak'), findsOneWidget);
      expect(find.text('Üniversite'), findsOneWidget);
    });

    testWidgets('selecting a place updates the draft', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('Levent, Metro İstasyonu'));
      await tester.pumpAndSettle();
      expect(find.text('Nereye gidiyorsun?'), findsOneWidget);

      await tester.tap(find.text('Maslak, 42 Maslak').last);
      await tester.pumpAndSettle();

      expect(find.text('Maslak, 42 Maslak'), findsOneWidget);
      expect(find.text('Levent, Metro İstasyonu'), findsNothing);
    });

    testWidgets('swapping exchanges the endpoints', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      await tester.tap(
        find.bySemanticsLabel('Kalkış ve varış noktalarını değiştir'),
      );
      await tester.pump();

      // Both are still shown, but under the opposite eyebrow.
      expect(
        find.bySemanticsLabel('NEREDEN: Levent, Metro İstasyonu'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('NEREYE: Kadıköy, İskele Meydanı'),
        findsOneWidget,
      );
    });

    testWidgets('toggling a filter changes only the chip', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      final Finder chip = find.ancestor(
        of: find.text('Kadın sürücü'),
        matching: find.byType(RmChip),
      );
      expect(tester.widget<RmChip>(chip).selected, isFalse);

      await tester.tap(find.text('Kadın sürücü'));
      await tester.pump();

      expect(tester.widget<RmChip>(chip).selected, isTrue);
      // The result count in the CTA is untouched: filters narrow nothing.
      // discovery_domain_test.dart carries the full guarantee.
      expect(find.text('Eşleşmeleri gör · 3 sonuç'), findsOneWidget);
    });

    testWidgets('the recent search fills the draft', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      expect(find.text('Kadıköy → Maslak'), findsOneWidget);
      expect(find.text('Dün'), findsOneWidget);

      await tester.tap(find.text('Kadıköy → Maslak'));
      await tester.pump();

      expect(
        find.bySemanticsLabel('NEREYE: Maslak, 42 Maslak'),
        findsOneWidget,
      );
    });

    testWidgets('renders in English, RTL and at the narrow width', (
      WidgetTester tester,
    ) async {
      await pump(tester, textDirection: TextDirection.rtl);
      expect(tester.takeException(), isNull, reason: 'TR RTL');

      await pump(tester, locale: const Locale('en'));
      expect(tester.takeException(), isNull, reason: 'EN');
      expect(find.text('Search routes'), findsOneWidget);
      expect(find.text('See matches · 3 results'), findsOneWidget);

      await pump(tester, locale: const Locale('en'), size: kNarrowPhone);
      expect(tester.takeException(), isNull, reason: 'EN at 360dp');

      await pump(tester, size: kNarrowPhone);
      expect(tester.takeException(), isNull, reason: 'TR at 360dp');
    });

    testWidgets('survives the maximum text scale at the narrow width', (
      WidgetTester tester,
    ) async {
      await pump(tester, size: kNarrowPhone, textScale: RmA11y.maxTextScale);

      expect(tester.takeException(), isNull);
      expect(find.text('Rota ara'), findsOneWidget);
    });
  });

  group('MatchResultsScreen', () {
    Future<void> pump(
      WidgetTester tester, {
      Brightness brightness = Brightness.light,
      TextDirection textDirection = TextDirection.ltr,
      Locale locale = kDefaultTestLocale,
      Size size = kStandardPhone,
      double textScale = 1,
    }) async {
      await tester.pumpRmScreen(
        _atTextScale(textScale, const MatchResultsScreen()),
        brightness: brightness,
        textDirection: textDirection,
        locale: locale,
        surfaceSize: size,
      );
      await tester.pump();
    }

    testBothThemes('renders the three matches', (
      WidgetTester tester,
      Brightness brightness,
    ) async {
      await pump(tester, brightness: brightness);

      expect(tester.takeException(), isNull);
      expect(find.byType(MatchCard), findsNWidgets(3));
      expect(find.text('3 eşleşme'), findsOneWidget);
      // The header echoes the draft that produced them.
      expect(find.text('Kadıköy → Levent · Yarın 08:30'), findsOneWidget);
      expect(find.text('Selin K.'), findsOneWidget);
      expect(find.text('Mert A.'), findsOneWidget);
      expect(find.text('Emre Y.'), findsOneWidget);
    });

    testWidgets('the three tiers are visually distinct', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      final List<MatchCard> cards = tester
          .widgetList<MatchCard>(find.byType(MatchCard))
          .toList();

      expect(cards[0].tier, MatchCardTier.highlighted);
      expect(cards[1].tier, MatchCardTier.standard);
      expect(cards[2].tier, MatchCardTier.condensed);
      // The condensed tier has no CTA and no meter, so there are exactly two.
      expect(find.text('İncele'), findsNWidgets(2));
      expect(find.text('Rota uyumu'), findsNWidgets(2));
    });

    testBothThemes('formats every figure for the Turkish locale', (
      WidgetTester tester,
      Brightness brightness,
    ) async {
      await pump(tester, brightness: brightness);

      expect(find.text('₺18'), findsOneWidget);
      expect(find.text('₺16'), findsOneWidget);
      expect(find.text('₺14'), findsOneWidget);
      expect(find.text('%94'), findsOneWidget);
      expect(find.text('%88'), findsOneWidget);
      expect(find.text('4,9'), findsOneWidget);
      expect(find.text('4.9'), findsNothing);
    });

    testWidgets('changing sort reorders per the fixture', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      List<String> ids() => tester
          .widgetList<MatchCard>(find.byType(MatchCard))
          .map((MatchCard card) => card.offer.id)
          .toList();

      expect(ids(), MockRouteOffers.orderBySort[MatchSortOption.bestMatch]);

      await tester.tap(find.text('En ucuz'));
      await tester.pump();

      // The declared order, verbatim — nothing was compared to produce it.
      expect(ids(), MockRouteOffers.orderBySort[MatchSortOption.cheapest]);
    });

    testWidgets('each card reads as one node carrying its key facts', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      expect(
        find.bySemanticsLabel(
          'Selin K., 4,9 puan. %94 rota uyumu. Kalkış 08:25. Kişi başı ₺18.',
        ),
        findsOneWidget,
      );
      // The CTA stays a separate, actionable node.
      expect(find.bySemanticsLabel('İncele'), findsWidgets);
    });

    testWidgets('the list scrolls, as the design implies', (
      WidgetTester tester,
    ) async {
      // The comp clips its third card on purpose.
      await pump(tester, size: kNarrowPhone);

      await tester.drag(find.byType(MatchCard).first, const Offset(0, -240));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(MatchCard), findsNWidgets(3));
    });

    testWidgets('renders in English, RTL and at the narrow width', (
      WidgetTester tester,
    ) async {
      await pump(tester, textDirection: TextDirection.rtl);
      expect(tester.takeException(), isNull, reason: 'TR RTL');

      await pump(tester, size: kNarrowPhone);
      expect(tester.takeException(), isNull, reason: 'TR at 360dp');

      await pump(tester, locale: const Locale('en'), size: kNarrowPhone);
      expect(tester.takeException(), isNull, reason: 'EN at 360dp');
      expect(find.text('Best match'), findsOneWidget);
      expect(find.text('3 matches'), findsOneWidget);
    });

    testWidgets('survives the maximum text scale at the narrow width', (
      WidgetTester tester,
    ) async {
      await pump(tester, size: kNarrowPhone, textScale: RmA11y.maxTextScale);

      expect(tester.takeException(), isNull);
      // Fewer cards are built: the list is lazy and the rows are taller. What
      // matters is that the ones on screen laid out without overflowing.
      expect(find.byType(MatchCard), findsWidgets);
      expect(find.text('3 eşleşme'), findsOneWidget);
    });
  });

  group('RouteDetailsScreen', () {
    Future<void> pump(
      WidgetTester tester, {
      String routeId = 'offer-selin-kadikoy-levent',
      Brightness brightness = Brightness.light,
      TextDirection textDirection = TextDirection.ltr,
      Locale locale = kDefaultTestLocale,
      Size size = kStandardPhone,
      double textScale = 1,
    }) async {
      await tester.pumpRmScreen(
        _atTextScale(textScale, RouteDetailsScreen(routeId: routeId)),
        brightness: brightness,
        textDirection: textDirection,
        locale: locale,
        surfaceSize: size,
      );
      await tester.pump();
    }

    testBothThemes('renders every figure the offer carries', (
      WidgetTester tester,
      Brightness brightness,
    ) async {
      await pump(tester, brightness: brightness);

      expect(tester.takeException(), isNull);
      expect(find.text('Selin K.'), findsOneWidget);
      expect(find.text('4,9 · 128 yolculuk'), findsOneWidget);
      expect(find.text("2023'ten beri üye · Kadıköy"), findsOneWidget);
      // The three trust tiles.
      expect(find.text('92'), findsOneWidget);
      expect(find.text('Güven Puanı'), findsOneWidget);
      expect(find.text('%98'), findsOneWidget);
      expect(find.text('Onay oranı'), findsOneWidget);
      expect(find.text('3.4k'), findsOneWidget);
      expect(find.text('km paylaşıldı'), findsOneWidget);
      // The timeline.
      expect(find.text('Kadıköy İskele'), findsOneWidget);
      expect(find.text('Alış noktası'), findsOneWidget);
      expect(find.text('08:25'), findsOneWidget);
      expect(find.text('Levent Metro'), findsOneWidget);
      expect(find.text('Varış · 32 dk'), findsOneWidget);
      expect(find.text('08:57'), findsOneWidget);
      // The action dock.
      expect(find.text('Senin payın'), findsOneWidget);
      expect(find.text('₺18'), findsOneWidget);
      expect(find.text('İstek gönder'), findsOneWidget);
    });

    testWidgets('shows the vehicle and the mutual connection', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      expect(find.text('VW Passat · Gri'), findsOneWidget);
      expect(find.text('34 ABC 128'), findsOneWidget);
      expect(find.text('Ortak bağlantı'), findsOneWidget);
      expect(find.text('2 ortak rota'), findsOneWidget);
      expect(find.text('Müzik · Sessiz yolculuk'), findsOneWidget);
    });

    testWidgets('all three trust tiles stay on screen despite the overlap', (
      WidgetTester tester,
    ) async {
      // The tiles are pulled up over the hero by a negative offset, which is
      // exactly the arrangement that silently clips them.
      await pump(tester);

      for (final String caption in <String>[
        'Güven Puanı',
        'Onay oranı',
        'km paylaşıldı',
      ]) {
        final Rect rect = tester.getRect(find.text(caption));
        expect(rect.height, greaterThan(0), reason: caption);
        expect(rect.top, greaterThan(0), reason: '$caption is below the top');
        expect(
          rect.bottom,
          lessThan(kStandardPhone.height),
          reason: '$caption is above the fold',
        );
      }
    });

    testWidgets('requesting a seat shows a message and creates no sent state', (
      WidgetTester tester,
    ) async {
      // Nothing was sent anywhere. Telling a member otherwise would be a claim
      // no backend ever made.
      await pump(tester);

      await tester.tap(find.text('İstek gönder'));
      await tester.pump();

      expect(
        find.text('Yolculuk isteği özelliği yakında eklenecek.'),
        findsOneWidget,
      );
      // The button is unchanged: no "sent", no pending, no disabled flip.
      expect(find.text('İstek gönder'), findsOneWidget);
      final RmButton button = tester.widget<RmButton>(
        find.ancestor(
          of: find.text('İstek gönder'),
          matching: find.byType(RmButton),
        ),
      );
      expect(button.onPressed, isNotNull);
      expect(button.loading, isFalse);
    });

    testWidgets('messaging is honest about not existing yet', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      await tester.tap(find.bySemanticsLabel('Sürücüye mesaj gönder'));
      await tester.pump();

      expect(
        find.text('Mesajlaşma özelliği yakında eklenecek.'),
        findsOneWidget,
      );
    });

    testWidgets('an unknown id shows a message rather than crashing', (
      WidgetTester tester,
    ) async {
      await pump(tester, routeId: 'no-such-offer');

      expect(tester.takeException(), isNull);
      expect(find.text('Bu rota artık görüntülenemiyor.'), findsOneWidget);
      expect(find.text('İstek gönder'), findsNothing);
    });

    testWidgets('renders every offer in the fixture', (
      WidgetTester tester,
    ) async {
      for (final RouteOffer offer in MockRouteOffers.all) {
        await pump(tester, routeId: offer.id);
        expect(tester.takeException(), isNull, reason: offer.id);
        expect(find.text(offer.driverName), findsOneWidget, reason: offer.id);
      }
    });

    testWidgets('renders in English, RTL and at the narrow width', (
      WidgetTester tester,
    ) async {
      await pump(tester, textDirection: TextDirection.rtl);
      expect(tester.takeException(), isNull, reason: 'TR RTL');

      await pump(tester, size: kNarrowPhone);
      expect(tester.takeException(), isNull, reason: 'TR at 360dp');

      await pump(tester, locale: const Locale('en'), size: kNarrowPhone);
      expect(tester.takeException(), isNull, reason: 'EN at 360dp');
      expect(find.text('Send request'), findsOneWidget);
      expect(find.text('Trust Score'), findsOneWidget);
    });

    testWidgets('survives the maximum text scale at the narrow width', (
      WidgetTester tester,
    ) async {
      await pump(tester, size: kNarrowPhone, textScale: RmA11y.maxTextScale);

      expect(tester.takeException(), isNull);
      expect(find.text('İstek gönder'), findsOneWidget);
    });
  });
}
