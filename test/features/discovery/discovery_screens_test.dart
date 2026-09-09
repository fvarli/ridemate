// ─────────────────────────────────────────────────────────────
// RideMate — Discovery screen tests
//
// Checked in both themes, both locales, RTL, at the maximum text scale the app
// allows, and at 360dp as well as 393dp — the narrow width is where Phase 2's
// overflows first appeared.
//
// WHAT THESE NOW GUARD
//
// Search and Match Results are server-backed. The honesty rules they carry are
// no longer "a filter changes no results" — the filters are gone — but that the
// screens claim nothing the backend does not provide, and that a failure never
// falls back to a fixture.
//
// Route Details is unchanged and still openly a fixture. Phase 12 does not
// migrate it, and nothing real navigates into it.
//
// The real fonts are loaded. Without them every glyph rasterizes as a square em
// box, far wider than Manrope, so a width assertion would measure Ahem rather
// than the product.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/a11y/rm_a11y.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/places/place.dart';
import 'package:ridemate/core/routes/departure.dart';
import 'package:ridemate/core/routes/discovered_route.dart';
import 'package:ridemate/core/routes/published_route.dart';
import 'package:ridemate/core/routes/ride_rule.dart';
import 'package:ridemate/core/widgets/rm_button.dart';
import 'package:ridemate/features/create_route/application/place_catalogue_providers.dart';
import 'package:ridemate/features/discovery/application/discovery_search_providers.dart';
import 'package:ridemate/features/discovery/data/discovery_repository.dart';
import 'package:ridemate/features/discovery/domain/mock_discovery_fixtures.dart';
import 'package:ridemate/features/discovery/domain/route_offer.dart';
import 'package:ridemate/features/discovery/presentation/match_results_screen.dart';
import 'package:ridemate/features/discovery/presentation/route_details_screen.dart';
import 'package:ridemate/features/discovery/presentation/search_screen.dart';
import 'package:ridemate/features/discovery/presentation/widgets/discovered_route_card.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/pump.dart';

/// The narrow phone width where Phase 2's overflows appeared.
const Size kNarrowPhone = Size(360, 800);

/// The reference device the design targets.
const Size kStandardPhone = Size(393, 852);

/// Every claim the old fixture card made that no endpoint can support. None of
/// these may appear on a server-backed discovery surface again.
const List<String> kRetiredClaims = <String>[
  '%94 uyum',
  '4,9',
  '128 yolculuk',
  '2 ortak rota',
  '₺18',
  '5 dk yürüme',
  'Doğrulanmış',
  'En iyi eşleşme',
  'En yakın',
  'En ucuz',
  '92',
];

DiscoveredRoute _route({
  String id = 'r1',
  String driver = 'İrem Yılmaz',
  String initials = 'İY',
  Recurrence recurrence = Recurrence.weekdays,
}) => DiscoveredRoute(
  id: id,
  origin: const Place(id: 'p1', label: 'Kadıköy, Vapur İskelesi'),
  destination: const Place(id: 'p2', label: 'Levent, Metro İstasyonu'),
  recurrence: recurrence,
  departureDate: recurrence == Recurrence.once
      ? const DepartureDate(year: 2026, month: 9, day: 14)
      : null,
  departureTime: const DepartureTime(hour: 8, minute: 25),
  timezone: 'Europe/Istanbul',
  departureState: DepartureState.upcoming,
  seatsOffered: 3,
  rules: const <RideRuleId>{RideRuleId.noSmoking},
  driver: DiscoveredDriver(displayName: driver, initials: initials),
  mySeatRequest: null,
);

void main() {
  setUpAll(loadRideMateFonts);

  group('SearchScreen', () {
    Future<void> pump(
      WidgetTester tester, {
      FakePlaceRepository? places,
      Brightness brightness = Brightness.light,
      TextDirection textDirection = TextDirection.ltr,
      Locale locale = kDefaultTestLocale,
      Size size = kStandardPhone,
      double textScale = 1,
    }) async {
      await tester.pumpRmScreen(
        const SearchScreen(),
        brightness: brightness,
        textDirection: textDirection,
        locale: locale,
        surfaceSize: size,
        textScaler: TextScaler.linear(textScale),
        overrides: <Override>[
          placeRepositoryProvider.overrideWithValue(
            places ?? FakePlaceRepository(),
          ),
        ],
      );
      await tester.pumpAndSettle();
    }

    testBothThemes('renders the endpoints and the search action', (
      WidgetTester tester,
      Brightness brightness,
    ) async {
      await pump(tester, brightness: brightness);

      expect(find.text('Rota ara'), findsOneWidget);
      expect(find.text('Kalkış noktası seç'), findsOneWidget);
      expect(find.text('Varış noktası seç'), findsOneWidget);
      expect(find.text('Yolculukları ara'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    /// CARRIES WEIGHT. Every control that implied a server filter is gone.
    ///
    /// Not hidden behind a flag and not collected then ignored: absent, because
    /// the endpoint accepts two place ids and refuses everything else.
    testWidgets('offers no filter, sort, seat or date control', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      for (final String gone in <String>[
        'Filtreler',
        'Doğrulanmış',
        'Min. puan',
        'Kadın sürücü',
        'Sigara içilmez',
        'Ortak bağlantı',
        'Son aramalar',
        'NE ZAMAN',
        'KOLTUK',
        'Bugün',
      ]) {
        expect(find.text(gone), findsNothing, reason: gone);
      }
    });

    testWidgets('the search action is disabled until two places are chosen', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      final RmButton cta = tester.widget<RmButton>(
        find.widgetWithText(RmButton, 'Yolculukları ara'),
      );
      expect(cta.onPressed, isNull, reason: 'nothing to ask about yet');
      expect(find.text('İki farklı yer seç.'), findsOneWidget);
    });

    testWidgets('choosing both endpoints enables the search', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('Kalkış noktası seç'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(kFakePlaces[0].label).last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Varış noktası seç'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(kFakePlaces[1].label).last);
      await tester.pumpAndSettle();

      final RmButton cta = tester.widget<RmButton>(
        find.widgetWithText(RmButton, 'Yolculukları ara'),
      );
      expect(cta.onPressed, isNotNull);
    });

    /// CARRIES WEIGHT. No fixture list stands in for the catalogue.
    testWidgets('an unreachable catalogue says so and offers nothing', (
      WidgetTester tester,
    ) async {
      await pump(tester, places: FakePlaceRepository.offline());

      expect(find.text('Yer listesi alınamadı.'), findsOneWidget);
      expect(find.text('Yeniden dene'), findsOneWidget);

      // And the picker offers nothing rather than something invented.
      await tester.tap(find.text('Kalkış noktası seç'));
      await tester.pumpAndSettle();
      expect(find.text('Nereden yola çıkıyorsun?'), findsNothing);
    });

    testWidgets('renders in English, RTL and at the narrow width', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        locale: const Locale('en'),
        textDirection: TextDirection.rtl,
        size: kNarrowPhone,
      );

      expect(find.text('Search journeys'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('survives the maximum text scale at the narrow width', (
      WidgetTester tester,
    ) async {
      await pump(tester, size: kNarrowPhone, textScale: 1.3);

      expect(tester.takeException(), isNull);
    });
  });

  group('MatchResultsScreen', () {
    Future<void> pump(
      WidgetTester tester, {
      required FakeDiscoveryRepository discovery,
      bool searched = true,
      Brightness brightness = Brightness.light,
      TextDirection textDirection = TextDirection.ltr,
      Locale locale = kDefaultTestLocale,
      Size size = kStandardPhone,
      double textScale = 1,
    }) async {
      await tester.pumpRmScreen(
        const MatchResultsScreen(),
        brightness: brightness,
        textDirection: textDirection,
        locale: locale,
        surfaceSize: size,
        textScaler: TextScaler.linear(textScale),
        overrides: <Override>[
          discoveryRepositoryProvider.overrideWithValue(discovery),
          if (searched)
            discoveryQueryProvider.overrideWith(
              () => SearchedQueryController(),
            ),
        ],
      );
      await tester.pumpAndSettle();
    }

    testBothThemes('renders the server identity and the journey', (
      WidgetTester tester,
      Brightness brightness,
    ) async {
      await pump(
        tester,
        brightness: brightness,
        discovery: FakeDiscoveryRepository(
          pages: <DiscoveryResult>[
            DiscoveryResult(
              routes: <DiscoveredRoute>[_route()],
              nextCursor: null,
            ),
          ],
        ),
      );

      expect(find.text('İrem Yılmaz'), findsOneWidget);
      // The server's letters, rendered as received.
      expect(find.text('İY'), findsOneWidget);
      expect(find.textContaining('Kadıköy'), findsWidgets);
      expect(find.text('3 koltuk sunuluyor'), findsOneWidget);
      expect(find.text('En son yayınlananlar önce'), findsOneWidget);
    });

    /// CARRIES WEIGHT. Not one retired claim survives.
    testWidgets('no unsupported claim appears on a real result', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        discovery: FakeDiscoveryRepository(
          pages: <DiscoveryResult>[
            DiscoveryResult(
              routes: <DiscoveredRoute>[_route()],
              nextCursor: null,
            ),
          ],
        ),
      );

      for (final String gone in kRetiredClaims) {
        expect(find.textContaining(gone), findsNothing, reason: gone);
      }
    });

    /// CARRIES WEIGHT. A real result leads nowhere, because Route Details is
    /// still a fixture.
    testWidgets('a result is not tappable and offers no seat request', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        discovery: FakeDiscoveryRepository(
          pages: <DiscoveryResult>[
            DiscoveryResult(
              routes: <DiscoveredRoute>[_route()],
              nextCursor: null,
            ),
          ],
        ),
      );

      expect(find.byType(DiscoveredRouteCard), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DiscoveredRouteCard),
          matching: find.byType(InkWell),
        ),
        findsNothing,
        reason: 'tapping would open a fixture-backed Route Details',
      );
      expect(find.byType(RouteDetailsScreen), findsNothing);
      // Asking for a seat is Phase 13.
      for (final String cta in <String>['Koltuk iste', 'Katıl', 'Rezerve et']) {
        expect(find.text(cta), findsNothing, reason: cta);
      }
    });

    /// Nothing asked is a different sentence from nothing found.
    ///
    /// Two tests rather than two pumps: Riverpod refuses a changing number of
    /// overrides within one scope, and collapsing them would need a controller
    /// that pretends to be both.
    testWidgets('idle says nobody has searched', (WidgetTester tester) async {
      await pump(tester, searched: false, discovery: FakeDiscoveryRepository());

      expect(find.text('Nereden nereye gittiğini seç.'), findsOneWidget);
      expect(find.textContaining('yayınlanmış yolculuk yok'), findsNothing);
    });

    testWidgets('an empty result says the server found none', (
      WidgetTester tester,
    ) async {
      await pump(tester, discovery: FakeDiscoveryRepository());

      expect(
        find.text('Bu iki yer arasında yayınlanmış yolculuk yok.'),
        findsOneWidget,
      );
      expect(
        find.text('Nereden nereye gittiğini seç.'),
        findsNothing,
        reason: 'the question was asked and answered',
      );
    });

    /// CARRIES WEIGHT. A failure is a failure, never an empty list and never a
    /// fixture.
    testWidgets('a failure shows an honest retry and no fixture', (
      WidgetTester tester,
    ) async {
      await pump(tester, discovery: FakeDiscoveryRepository.offline());

      expect(
        find.text('Bağlantı kurulamadı. İnternet bağlantını kontrol et.'),
        findsOneWidget,
      );
      expect(find.text('Yeniden dene'), findsOneWidget);
      expect(find.byType(DiscoveredRouteCard), findsNothing);
      for (final RouteOffer offer in MockRouteOffers.all) {
        expect(find.text(offer.driverName), findsNothing);
      }
      expect(
        find.text('Bu iki yer arasında yayınlanmış yolculuk yok.'),
        findsNothing,
        reason: 'a failure is not an empty result',
      );
    });

    testWidgets('retry performs exactly one more read', (
      WidgetTester tester,
    ) async {
      final FakeDiscoveryRepository discovery =
          FakeDiscoveryRepository.offline();
      await pump(tester, discovery: discovery);

      expect(discovery.callCount, 1);

      discovery
        ..failure = null
        ..pages = <DiscoveryResult>[
          DiscoveryResult(
            routes: <DiscoveredRoute>[_route()],
            nextCursor: null,
          ),
        ];

      await tester.tap(find.text('Yeniden dene'));
      await tester.pumpAndSettle();

      expect(discovery.callCount, 2);
      expect(find.text('İrem Yılmaz'), findsOneWidget);
    });

    testWidgets('load more appends the next page', (WidgetTester tester) async {
      final FakeDiscoveryRepository discovery = FakeDiscoveryRepository(
        pages: <DiscoveryResult>[
          DiscoveryResult(
            routes: <DiscoveredRoute>[_route(driver: 'Ayşe Demir')],
            nextCursor: 'opaque',
          ),
          DiscoveryResult(
            routes: <DiscoveredRoute>[_route(id: 'r2', driver: 'Ali Can')],
            nextCursor: null,
          ),
        ],
      );
      await pump(tester, discovery: discovery);

      expect(find.text('Daha fazla göster'), findsOneWidget);

      await tester.tap(find.text('Daha fazla göster'));
      await tester.pumpAndSettle();

      expect(find.text('Ayşe Demir'), findsOneWidget);
      expect(find.text('Ali Can'), findsOneWidget);
      expect(discovery.cursors, <String?>[null, 'opaque']);
      expect(find.text('Daha fazla göster'), findsNothing);
    });

    /// Page two failing does not take page one off the screen.
    testWidgets('a failed load more keeps the results and offers a retry', (
      WidgetTester tester,
    ) async {
      final FakeDiscoveryRepository discovery = FakeDiscoveryRepository(
        pages: <DiscoveryResult>[
          DiscoveryResult(
            routes: <DiscoveredRoute>[_route(driver: 'Ayşe Demir')],
            nextCursor: 'opaque',
          ),
        ],
      );
      await pump(tester, discovery: discovery);

      discovery.failure = const RmFailure.transport();
      await tester.tap(find.text('Daha fazla göster'));
      await tester.pumpAndSettle();

      expect(find.text('Ayşe Demir'), findsOneWidget);
      expect(find.text('Daha fazlası alınamadı.'), findsOneWidget);
      expect(find.text('Yeniden dene'), findsOneWidget);
    });

    testWidgets('renders in English, RTL and at the narrow width', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        locale: const Locale('en'),
        textDirection: TextDirection.rtl,
        size: kNarrowPhone,
        discovery: FakeDiscoveryRepository(
          pages: <DiscoveryResult>[
            DiscoveryResult(
              routes: <DiscoveredRoute>[_route()],
              nextCursor: null,
            ),
          ],
        ),
      );

      expect(find.text('Most recently published first'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('survives the maximum text scale at the narrow width', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        size: kNarrowPhone,
        textScale: 1.3,
        discovery: FakeDiscoveryRepository(
          pages: <DiscoveryResult>[
            DiscoveryResult(
              routes: <DiscoveredRoute>[_route()],
              nextCursor: null,
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
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
        RouteDetailsScreen(routeId: routeId),
        brightness: brightness,
        textDirection: textDirection,
        locale: locale,
        surfaceSize: size,
        textScaler: TextScaler.linear(textScale),
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

    testWidgets('the message button opens the conversation', (
      WidgetTester tester,
    ) async {
      // Chat shipped in Phase 5, so this no longer apologises for itself. The
      // navigation is asserted in chat_flow_test.dart, which has a real router;
      // here the point is only that the temporary message is gone.
      await pump(tester);

      expect(find.bySemanticsLabel('Sürücüye mesaj gönder'), findsOneWidget);
      expect(find.textContaining('yakında eklenecek'), findsNothing);
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
