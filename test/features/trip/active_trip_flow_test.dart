// ─────────────────────────────────────────────────────────────
// RideMate — Active trip navigation
//
// The debug-only screen, reached the only way it can be reached: a deep link.
// From there its chat button opens the same conversation Route Details does,
// and back returns here.
// ─────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/app/providers/app_preferences_provider.dart';
import 'package:ridemate/app/ride_mate_app.dart';
import 'package:ridemate/app/router/app_router.dart';
import 'package:ridemate/app/router/app_routes.dart';
import 'package:ridemate/core/widgets/rm_nav_bar.dart';
import 'package:ridemate/features/chat/presentation/chat_screen.dart';
import 'package:ridemate/features/home/presentation/home_screen.dart';
import 'package:ridemate/features/onboarding/application/onboarding_controller.dart';
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

/// Opens the debug-only screen the only way it can be opened.
Future<void> _deepLinkToTrip(
  WidgetTester tester,
  ProviderContainer container,
) async {
  unawaited(container.read(routerProvider).pushNamed(AppRoutes.activeTrip));
  await _settleTransition(tester);
}

/// Advances past a route transition without pumpAndSettle, which would hang:
/// the live dots and the SOS halo never stop.
Future<void> _settleTransition(WidgetTester tester) async {
  await tester.pump();
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  setUpAll(loadRideMateFonts);

  group('Active trip flow', () {
    testWidgets('a deep link opens it above the shell', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await _pumpApp(tester);
      expect(find.byType(HomeScreen), findsOneWidget);

      await _deepLinkToTrip(tester, container);

      expect(find.byType(ActiveTripScreen), findsOneWidget);
      // The comp draws no tab bar.
      expect(find.byType(RmNavBar), findsNothing);
      expect(find.text('CANLI YOLCULUK'), findsOneWidget);
    });

    testWidgets('its chat button opens the conversation and back returns', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await _pumpApp(tester);
      await _deepLinkToTrip(tester, container);

      await tester.tap(find.bySemanticsLabel('Sürücüye mesaj gönder'));
      await _settleTransition(tester);
      expect(find.byType(ChatScreen), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Geri').first);
      await _settleTransition(tester);

      expect(find.byType(ChatScreen), findsNothing);
      expect(
        find.byType(ActiveTripScreen),
        findsOneWidget,
        reason: 'back must return to where the conversation was opened from',
      );
    });

    testWidgets('nothing in the app links to it', (WidgetTester tester) async {
      // The screen is deliberately unreachable by product navigation: getting
      // to an active trip honestly needs a lifecycle that does not exist.
      await _pumpApp(tester);

      expect(find.byType(ActiveTripScreen), findsNothing);
      expect(find.textContaining('CANLI YOLCULUK'), findsNothing);
    });
  });
}
