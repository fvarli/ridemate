// ─────────────────────────────────────────────────────────────
// RideMate — Where a My Routes card goes
//
// To the REAL trip status, and never to the Active Trip fixture. That screen
// is registered in debug builds and linked from nowhere on purpose: it draws a
// map, claims a live location and offers an SOS control, none of which exists.
// A card that reached it would put all three in front of a real member.
//
// Pumped through the real app and the real router, so a route that is declared
// but not registered, or registered to the wrong screen, fails here.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/app/providers/app_preferences_provider.dart';
import 'package:ridemate/app/providers/session_provider.dart';
import 'package:ridemate/app/ride_mate_app.dart';
import 'package:ridemate/app/router/app_router.dart';
import 'package:ridemate/app/router/app_routes.dart';
import 'package:ridemate/core/routes/my_route.dart';
import 'package:ridemate/features/my_routes/application/my_routes_providers.dart';
import 'package:ridemate/features/my_routes/data/my_routes_repository.dart';
import 'package:ridemate/features/my_routes/presentation/my_routes_screen.dart';
import 'package:ridemate/features/my_routes/presentation/trip_status_screen.dart';
import 'package:ridemate/features/my_routes/presentation/widgets/my_route_card.dart';
import 'package:ridemate/features/onboarding/application/onboarding_controller.dart';
import 'package:ridemate/features/profile/application/my_profile_providers.dart';
import 'package:ridemate/features/trip/presentation/active_trip_screen.dart';

import '../../support/fakes.dart';

const String _kId = '01991b00-0000-7000-8000-000000000001';

Future<ProviderContainer> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        onboardingRepositoryProvider.overrideWithValue(
          InMemoryOnboardingRepository(seen: true),
        ),
        rmSessionProvider.overrideWithValue(FakeSession()),
        profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
        myRoutesRepositoryProvider.overrideWithValue(
          FakeMyRoutesRepository(
            pages: <MyRoutesResult>[
              MyRoutesResult(
                routes: <MyRoute>[fakeMyRoute(id: _kId)],
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
  container.read(localeProvider.notifier).set(const Locale('tr'));
  await tester.pumpAndSettle();

  return container;
}

void main() {
  testWidgets('a real card opens the real trip status, and comes back', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await _pumpApp(tester);
    container.read(routerProvider).goNamed(AppRoutes.myRoutes);
    await tester.pumpAndSettle();
    expect(find.byType(MyRoutesScreen), findsOneWidget);

    await tester.tap(find.byType(MyRouteCard));
    await tester.pumpAndSettle();

    expect(find.byType(TripStatusScreen), findsOneWidget);
    // CARRIES WEIGHT. Not the fixture, in any build.
    expect(find.byType(ActiveTripScreen), findsNothing);

    container.read(routerProvider).pop();
    await tester.pumpAndSettle();
    expect(find.byType(MyRoutesScreen), findsOneWidget);
  });

  /// The screen it reaches is the one the route declares, and that route is
  /// the real one — not a debug fixture path.
  testWidgets('the trip status route is registered and is not the fixture', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await _pumpApp(tester);

    container
        .read(routerProvider)
        .goNamed(
          AppRoutes.tripStatus,
          pathParameters: <String, String>{'routeId': _kId},
        );
    await tester.pumpAndSettle();

    expect(find.byType(TripStatusScreen), findsOneWidget);
    expect(find.byType(ActiveTripScreen), findsNothing);
    expect(AppRoutes.tripStatusPath, isNot(AppRoutes.activeTripPath));
  });
}
