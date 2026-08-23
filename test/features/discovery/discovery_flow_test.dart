// ─────────────────────────────────────────────────────────────
// RideMate — Discovery navigation
//
// The whole passenger slice through the real router: Home → Search → Match
// Results → Route Details, and back again.
//
// Back behaviour is as much a product decision as the pixels, so it is
// asserted rather than assumed: Matches and Details push OVER the shell (no
// tab bar), popping Matches returns to the Search tab with its draft intact,
// and a system back on any secondary tab returns to Home instead of leaving
// the app.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/app/providers/app_preferences_provider.dart';
import 'package:ridemate/app/providers/session_provider.dart';
import 'package:ridemate/app/ride_mate_app.dart';
import 'package:ridemate/core/places/mock_places.dart';
import 'package:ridemate/core/widgets/rm_nav_bar.dart';
import 'package:ridemate/features/discovery/application/discovery_providers.dart';
import 'package:ridemate/features/discovery/domain/mock_discovery_fixtures.dart';
import 'package:ridemate/features/discovery/domain/search_draft.dart';
import 'package:ridemate/features/discovery/presentation/match_results_screen.dart';
import 'package:ridemate/features/discovery/presentation/route_details_screen.dart';
import 'package:ridemate/features/discovery/presentation/search_screen.dart';
import 'package:ridemate/features/home/presentation/home_screen.dart';
import 'package:ridemate/features/onboarding/application/onboarding_controller.dart';

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
    testWidgets('runs from Search all the way to Route Details and back', (
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

      await tester.tap(find.text('Eşleşmeleri gör · 3 sonuç'));
      await tester.pumpAndSettle();
      expect(find.byType(MatchResultsScreen), findsOneWidget);
      // Pushed over the shell: the design draws no tab bar here.
      expect(find.byType(RmNavBar), findsNothing);

      await tester.tap(find.text('İncele').first);
      await tester.pumpAndSettle();
      expect(find.byType(RouteDetailsScreen), findsOneWidget);
      expect(find.text('Selin K.'), findsOneWidget);
      expect(find.text('Güven Puanı'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Geri').first);
      await tester.pumpAndSettle();
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

      // Edit the journey, then leave the tab entirely.
      await tester.tap(find.text('Levent, Metro İstasyonu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ataşehir, Palladium').last);
      await tester.pumpAndSettle();

      await tester.tap(_navTab('Profil'));
      await tester.pumpAndSettle();
      await tester.tap(_navTab('Ara'));
      await tester.pumpAndSettle();

      expect(find.text('Ataşehir, Palladium'), findsOneWidget);
      expect(
        container.read(searchDraftProvider).destination,
        MockPlaces.atasehir,
      );
    });

    testWidgets('the results screen echoes the edited draft', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await _pumpApp(tester);
      container
          .read(searchDraftProvider.notifier)
          .setSort(MatchSortOption.cheapest);

      await tester.tap(_navTab('Ara'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.bySemanticsLabel('Kalkış ve varış noktalarını değiştir'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eşleşmeleri gör · 3 sonuç'));
      await tester.pumpAndSettle();

      expect(find.text('Levent → Kadıköy · Yarın 08:30'), findsOneWidget);
      // The sort chosen before navigating is still the one in effect.
      expect(find.text('₺14'), findsOneWidget);
      expect(container.read(routeOffersProvider).first, MockRouteOffers.emre);
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
