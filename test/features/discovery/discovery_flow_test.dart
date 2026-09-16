// ─────────────────────────────────────────────────────────────
// RideMate — Discovery navigation
//
// The passenger slice through the real router: Home → Search → Match Results,
// and back again.
//
// IT NOW STOPS AT THE RESULTS
//
// Match Results is server-backed and Route Details is still a fixture, so a
// real result deliberately leads nowhere: opening those details would put a
// real member's name above an invented vehicle, plate and cost. Route Details
// is still reachable from Home, which is still openly a fixture, and that path
// is asserted below so the screen does not quietly become unreachable.
//
// Back behaviour is as much a product decision as the pixels: Matches pushes
// OVER the shell (no tab bar), popping it returns to the Search tab with its
// draft intact, and a system back on any secondary tab returns to Home rather
// than leaving the app.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/app/providers/app_preferences_provider.dart';
import 'package:ridemate/app/providers/session_provider.dart';
import 'package:ridemate/app/ride_mate_app.dart';
import 'package:ridemate/core/routes/departure.dart';
import 'package:ridemate/core/routes/discovered_route.dart';
import 'package:ridemate/core/routes/published_route.dart';
import 'package:ridemate/core/routes/ride_rule.dart';
import 'package:ridemate/core/seat_requests/seat_request.dart';
import 'package:ridemate/core/widgets/rm_nav_bar.dart';
import 'package:ridemate/features/create_route/application/place_catalogue_providers.dart';
import 'package:ridemate/features/discovery/application/discovery_providers.dart';
import 'package:ridemate/features/discovery/application/discovery_search_providers.dart';
import 'package:ridemate/features/discovery/data/discovery_repository.dart';
import 'package:ridemate/features/discovery/domain/mock_discovery_fixtures.dart';
import 'package:ridemate/features/discovery/presentation/match_results_screen.dart';
import 'package:ridemate/features/discovery/presentation/route_details_screen.dart';
import 'package:ridemate/features/discovery/presentation/search_screen.dart';
import 'package:ridemate/features/home/presentation/home_screen.dart';
import 'package:ridemate/features/onboarding/application/onboarding_controller.dart';
import 'package:ridemate/features/profile/application/my_profile_providers.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';

/// Sends the platform message the engine sends on an Android system back.
Future<void> _simulateSystemBack() {
  return TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        'flutter/navigation',
        const JSONMessageCodec().encodeMessage(<String, dynamic>{
          'method': 'popRoute',
        }),
        (ByteData? _) {},
      );
}

Future<ProviderContainer> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  // The shell is reachable once the intro has been completed. That says
  // nothing about accounts or authentication, which do not exist.
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        onboardingRepositoryProvider.overrideWithValue(
          InMemoryOnboardingRepository(seen: true),
        ),
        rmSessionProvider.overrideWithValue(FakeSession()),
        profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
        placeRepositoryProvider.overrideWithValue(FakePlaceRepository()),
        discoveryRepositoryProvider.overrideWithValue(
          FakeDiscoveryRepository(
            pages: <DiscoveryResult>[
              DiscoveryResult(
                routes: <DiscoveredRoute>[
                  DiscoveredRoute(
                    id: 'r1',
                    origin: kFakePlaces[0],
                    destination: kFakePlaces[1],
                    recurrence: Recurrence.weekdays,
                    departureDate: null,
                    departureTime: const DepartureTime(hour: 8, minute: 25),
                    timezone: 'Europe/Istanbul',
                    departureState: DepartureState.upcoming,
                    seatsOffered: 3,
                    rules: const <RideRuleId>{RideRuleId.noSmoking},
                    driver: const DiscoveredDriver(
                      displayName: 'İrem Yılmaz',
                      initials: 'İY',
                    ),
                    requestableServiceDates: const <DepartureDate>[
                      DepartureDate(year: 2026, month: 9, day: 14),
                    ],
                    mySeatRequests: const <MySeatRequestSummary>[],
                  ),
                ],
                nextCursor: null,
              ),
            ],
          ),
        ),
      ],
      child: const RideMateApp(),
    ),
  );
  await tester.pumpAndSettle();

  final ProviderContainer container = ProviderScope.containerOf(
    tester.element(find.byType(RideMateApp)),
  );
  // Turkish is the source product language, so the flow is walked in it. The
  // host's locale must not decide what this test asserts.
  container.read(localeProvider.notifier).set(const Locale('tr'));
  await tester.pumpAndSettle();
  return container;
}

Finder _navTab(String label) =>
    find.descendant(of: find.byType(RmNavBar), matching: find.text(label));

void main() {
  setUpAll(loadRideMateFonts);

  group('Passenger discovery flow', () {
    testWidgets('runs from Search to the results and back', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester);
      expect(find.byType(HomeScreen), findsOneWidget);

      await tester.tap(_navTab('Ara'));
      await tester.pumpAndSettle();
      expect(find.byType(SearchScreen), findsOneWidget);
      // Search is a designed tab destination, so it keeps the bar — see
      // deviation D-search-1.
      expect(find.byType(RmNavBar), findsOneWidget);

      // Two endpoints from the server's catalogue, which is what the query
      // needs; there is nothing else to fill in.
      await tester.tap(find.text('Kalkış noktası seç'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(kFakePlaces[0].label).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Varış noktası seç'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(kFakePlaces[1].label).last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Yolculukları ara'));
      await tester.pumpAndSettle();
      expect(find.byType(MatchResultsScreen), findsOneWidget);
      // Pushed over the shell: the design draws no tab bar here.
      expect(find.byType(RmNavBar), findsNothing);
      expect(find.text('İrem Yılmaz'), findsOneWidget);

      /// CARRIES WEIGHT. A real result goes nowhere.
      ///
      /// Route Details is fixture-backed and Phase 12 does not migrate it, so
      /// tapping through would show a real name above invented details.
      await tester.tap(find.text('İrem Yılmaz'));
      await tester.pumpAndSettle();
      expect(find.byType(RouteDetailsScreen), findsNothing);
      expect(find.byType(MatchResultsScreen), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Geri').first);
      await tester.pumpAndSettle();
      expect(find.byType(SearchScreen), findsOneWidget);
      expect(find.byType(RmNavBar), findsOneWidget);
    });

    testWidgets('Home opens the same route details the results list does', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester);

      await tester.tap(find.text('Selin K.'));
      await tester.pumpAndSettle();

      expect(find.byType(RouteDetailsScreen), findsOneWidget);
      expect(
        tester
            .widget<RouteDetailsScreen>(find.byType(RouteDetailsScreen))
            .routeId,
        MockRouteOffers.selin.id,
      );

      await tester.tap(find.bySemanticsLabel('Geri').first);
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Home\'s match count still goes to the Search tab', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester);

      await tester.tap(find.text('3 eşleşme →'));
      await tester.pumpAndSettle();

      expect(find.byType(SearchScreen), findsOneWidget);
      expect(find.byType(RmNavBar), findsOneWidget);
    });

    testWidgets('the search draft survives leaving and returning to the tab', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await _pumpApp(tester);

      await tester.tap(_navTab('Ara'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Varış noktası seç'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(kFakePlaces[1].label).last);
      await tester.pumpAndSettle();

      await tester.tap(_navTab('Profil'));
      await tester.pumpAndSettle();
      await tester.tap(_navTab('Ara'));
      await tester.pumpAndSettle();

      expect(find.text(kFakePlaces[1].label), findsOneWidget);
      expect(container.read(searchDraftProvider).destination, kFakePlaces[1]);
    });

    /// The results reflect the query that was submitted, not the draft as it
    /// stands. Editing the draft afterwards changes nothing until the member
    /// searches again — the alternative is a list that silently disagrees with
    /// the request that produced it.
    testWidgets('the results reflect the submitted query', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await _pumpApp(tester);

      await tester.tap(_navTab('Ara'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kalkış noktası seç'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(kFakePlaces[0].label).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Varış noktası seç'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(kFakePlaces[1].label).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yolculukları ara'));
      await tester.pumpAndSettle();

      final DiscoveryQuery? query = container.read(discoveryQueryProvider);
      expect(query?.originPlaceId, kFakePlaces[0].id);
      expect(query?.destinationPlaceId, kFakePlaces[1].id);
    });
  });

  group('System back', () {
    testWidgets('returns to Home from a secondary tab instead of exiting', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester);

      await tester.tap(_navTab('Ara'));
      await tester.pumpAndSettle();
      expect(find.byType(SearchScreen), findsOneWidget);

      await _simulateSystemBack();
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(RmNavBar), findsOneWidget);
    });

    testWidgets('pops Route Details before it touches the tabs', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester);

      await tester.tap(find.text('Selin K.'));
      await tester.pumpAndSettle();
      expect(find.byType(RouteDetailsScreen), findsOneWidget);

      await _simulateSystemBack();
      await tester.pumpAndSettle();

      expect(find.byType(RouteDetailsScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
