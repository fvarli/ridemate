// ─────────────────────────────────────────────────────────────
// RideMate — Create route navigation
//
// The driver flow through the real router: the centre action opens Create
// Route above the shell, back returns to the tab it was opened from, and the
// draft survives being closed and reopened within the session.
//
// Nothing is persisted. A new process starts from the designed defaults —
// that half of the contract is asserted in create_route_domain_test.dart.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/app/providers/app_preferences_provider.dart';
import 'package:ridemate/app/providers/session_provider.dart';
import 'package:ridemate/app/ride_mate_app.dart';
import 'package:ridemate/core/widgets/rm_icon_button.dart';
import 'package:ridemate/core/widgets/rm_nav_bar.dart';
import 'package:ridemate/features/create_route/application/create_route_providers.dart';
import 'package:ridemate/features/create_route/domain/create_route_draft.dart';
import 'package:ridemate/features/create_route/domain/departure.dart';
import 'package:ridemate/features/create_route/presentation/create_route_screen.dart';
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
  // Turkish is the source product language; the host's locale must not decide
  // what this test asserts.
  container.read(localeProvider.notifier).set(const Locale('tr'));
  await tester.pumpAndSettle();
  return container;
}

Finder _navTab(String label) =>
    find.descendant(of: find.byType(RmNavBar), matching: find.text(label));

Future<void> _openCreateRoute(WidgetTester tester) async {
  await tester.tap(find.byType(RmFab));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadRideMateFonts);

  group('Create route flow', () {
    testWidgets('the centre action opens it above the shell', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester);
      expect(find.byType(HomeScreen), findsOneWidget);

      await _openCreateRoute(tester);

      expect(find.byType(CreateRouteScreen), findsOneWidget);
      // The comp draws no tab bar here, so it is pushed over the shell.
      expect(find.byType(RmNavBar), findsNothing);
      expect(find.text('Rota oluştur'), findsWidgets);
    });

    testWidgets('back returns to the tab it was opened from', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester);

      await tester.tap(_navTab('Ara'));
      await tester.pumpAndSettle();
      await _openCreateRoute(tester);
      expect(find.byType(CreateRouteScreen), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Geri').first);
      await tester.pumpAndSettle();

      expect(find.byType(CreateRouteScreen), findsNothing);
      expect(find.byType(RmNavBar), findsOneWidget);
      // The Search tab, not Home.
      expect(find.text('Rota ara'), findsOneWidget);
    });

    testWidgets('android system back closes it', (WidgetTester tester) async {
      await _pumpApp(tester);
      await _openCreateRoute(tester);

      await _simulateSystemBack();
      await tester.pumpAndSettle();

      expect(find.byType(CreateRouteScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('the draft survives closing and reopening the screen', (
      WidgetTester tester,
    ) async {
      // Backing out by accident must not discard the driver's edits.
      final ProviderContainer container = await _pumpApp(tester);
      await _openCreateRoute(tester);

      await tester.tap(find.text('+'));
      await tester.tap(find.text('+'));
      await tester.pump();
      await tester.tap(find.text('Her hafta içi tekrarla'));
      await tester.pumpAndSettle();
      expect(container.read(createRouteDraftProvider).seats, 5);

      await tester.tap(find.bySemanticsLabel('Geri').first);
      await tester.pumpAndSettle();
      expect(find.byType(CreateRouteScreen), findsNothing);

      await _openCreateRoute(tester);

      expect(find.text('5'), findsOneWidget);
      expect(container.read(createRouteDraftProvider).seats, 5);
      expect(
        container.read(createRouteDraftProvider).recurrence ==
            Recurrence.weekdays,
        isFalse,
      );
      expect(find.text('Pzt–Cum · 08:00 kalkış'), findsNothing);
    });

    testWidgets('publishing changes nothing and stays on the screen', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await _pumpApp(tester);
      await _openCreateRoute(tester);

      // The form has to be finished before publishing can say anything about
      // publishing; an unfinished one is told what is missing instead.
      ProviderScope.containerOf(tester.element(find.byType(CreateRouteScreen)))
          .read(createRouteDraftProvider.notifier)
          .setDepartureTime(const DepartureTime(hour: 8, minute: 25));
      await tester.pump();

      // What publishing must not change is whatever the driver has entered —
      // not the screen's opening state, which they have already edited.
      final CreateRouteDraft before = container.read(createRouteDraftProvider);

      await tester.tap(find.text('Rotayı yayınla'));
      await tester.pump();

      expect(
        find.text(
          'Rota henüz yayınlanmadı. Yayınlama özelliği yakında eklenecek.',
        ),
        findsOneWidget,
      );
      expect(find.byType(CreateRouteScreen), findsOneWidget);
      expect(container.read(createRouteDraftProvider), before);
    });
  });
}
