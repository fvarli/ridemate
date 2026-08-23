// ─────────────────────────────────────────────────────────────
// RideMate — Safety navigation
//
// The only path into the Safety Center, and the fact that it is the only one.
//
// PUMP NOTE: pumpAndSettle would hang on either screen — Active Trip's pulses
// and the SOS halo never stop — so transitions advance by fixed frames.
// ─────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/app/providers/app_preferences_provider.dart';
import 'package:ridemate/app/providers/session_provider.dart';
import 'package:ridemate/app/ride_mate_app.dart';
import 'package:ridemate/app/router/app_router.dart';
import 'package:ridemate/app/router/app_routes.dart';
import 'package:ridemate/features/onboarding/application/onboarding_controller.dart';
import 'package:ridemate/features/safety/presentation/safety_screen.dart';
import 'package:ridemate/features/safety/presentation/widgets/sos_card.dart';
import 'package:ridemate/features/trip/presentation/active_trip_screen.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';

Future<ProviderContainer> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1179, 2556);
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

/// Advances past a route transition without pumpAndSettle, which would hang.
Future<void> _settleTransition(WidgetTester tester) async {
  await tester.pump();
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  setUpAll(loadRideMateFonts);

  testWidgets('the SOS button opens the Safety Center and back returns', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await _pumpApp(tester);

    // Active Trip is itself debug-only and reachable only by deep link.
    unawaited(container.read(routerProvider).pushNamed(AppRoutes.activeTrip));
    await _settleTransition(tester);
    expect(find.byType(ActiveTripScreen), findsOneWidget);

    await tester.tap(find.text('SOS'));
    await _settleTransition(tester);

    // Pressing SOS opens the safety surface. It does not arm, count down,
    // trigger, call or notify anyone — there is nothing behind any of that.
    expect(find.byType(SafetyScreen), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.textContaining('gönderildi'), findsNothing);

    container.read(routerProvider).pop();
    await _settleTransition(tester);
    expect(find.byType(ActiveTripScreen), findsOneWidget);
  });

  testWidgets('the SOS card there says plainly that nobody was notified', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await _pumpApp(tester);
    unawaited(container.read(routerProvider).pushNamed(AppRoutes.safety));
    await _settleTransition(tester);

    await tester.tap(find.byType(SosCard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The same string Active Trip's control used, because it is the same
    // claim: one concept, one sentence.
    expect(
      find.text(
        'Acil durum özelliği henüz aktif değil. Kimseye bildirim gönderilmedi.',
      ),
      findsOneWidget,
    );
    expect(find.byType(SafetyScreen), findsOneWidget);
  });

  testWidgets('no product surface reaches it', (WidgetTester tester) async {
    final ProviderContainer container = await _pumpApp(tester);

    // Walk every release destination and confirm none of them exposes a path
    // to the Safety Center. The route exists in this debug test binary; what
    // must not exist is a way for a member to arrive at it.
    for (final String route in <String>[
      AppRoutes.home,
      AppRoutes.search,
      AppRoutes.messages,
      AppRoutes.profile,
      AppRoutes.matches,
      AppRoutes.createRoute,
      AppRoutes.reviews,
      AppRoutes.chat,
    ]) {
      container.read(routerProvider).goNamed(route);
      await _settleTransition(tester);
      expect(
        find.byType(SafetyScreen),
        findsNothing,
        reason: '$route must not land on the Safety Center',
      );
      expect(
        find.textContaining('Güvenlik Merkezi'),
        findsNothing,
        reason: '$route must not link to the Safety Center',
      );
    }
  });
}
