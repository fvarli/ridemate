// ─────────────────────────────────────────────────────────────
// RideMate — Chat navigation
//
// Route Details → Chat → back, through the real router.
//
// The assertion behind the assertions: opening a conversation must not create a
// request, a match, a booking or a trip. Messaging someone about a route is not
// agreeing to travel with them.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/app/providers/app_preferences_provider.dart';
import 'package:ridemate/app/ride_mate_app.dart';
import 'package:ridemate/features/chat/presentation/chat_screen.dart';
import 'package:ridemate/features/discovery/application/discovery_providers.dart';
import 'package:ridemate/features/discovery/domain/mock_discovery_fixtures.dart';
import 'package:ridemate/features/discovery/domain/search_draft.dart';
import 'package:ridemate/features/discovery/presentation/route_details_screen.dart';
import 'package:ridemate/features/onboarding/application/onboarding_controller.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';

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

Future<void> _openRouteDetails(WidgetTester tester) async {
  await tester.tap(find.text('Selin K.'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadRideMateFonts);

  group('Chat flow', () {
    testWidgets('Route Details opens the conversation and back returns', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester);
      await _openRouteDetails(tester);
      expect(find.byType(RouteDetailsScreen), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Sürücüye mesaj gönder'));
      await tester.pumpAndSettle();
      expect(find.byType(ChatScreen), findsOneWidget);
      expect(find.text('Çevrimiçi'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Geri').first);
      await tester.pumpAndSettle();
      expect(find.byType(ChatScreen), findsNothing);
      expect(find.byType(RouteDetailsScreen), findsOneWidget);
    });

    testWidgets('opening it creates no trip, request or match state', (
      WidgetTester tester,
    ) async {
      // Messaging a driver about a route is not agreeing to travel with them.
      final ProviderContainer container = await _pumpApp(tester);
      final SearchDraft before = container.read(searchDraftProvider);

      await _openRouteDetails(tester);
      await tester.tap(find.bySemanticsLabel('Sürücüye mesaj gönder'));
      await tester.pumpAndSettle();

      expect(find.byType(ChatScreen), findsOneWidget);
      expect(container.read(searchDraftProvider), before);
      expect(
        container.read(routeOffersProvider),
        MockRouteOffers.orderedFor(before.sort),
      );
      // Nothing anywhere claims a journey is under way.
      expect(find.textContaining('CANLI'), findsNothing);
    });

    testWidgets('android system back closes it', (WidgetTester tester) async {
      await _pumpApp(tester);
      await _openRouteDetails(tester);
      await tester.tap(find.bySemanticsLabel('Sürücüye mesaj gönder'));
      await tester.pumpAndSettle();

      await _simulateSystemBack();
      await tester.pumpAndSettle();

      expect(find.byType(ChatScreen), findsNothing);
      expect(find.byType(RouteDetailsScreen), findsOneWidget);
    });

    testWidgets('sending changes nothing and stays on the screen', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester);
      await _openRouteDetails(tester);
      await tester.tap(find.bySemanticsLabel('Sürücüye mesaj gönder'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Merhaba');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Gönder'));
      await tester.pump();

      expect(
        find.text('Mesaj gönderilmedi. Mesajlaşma özelliği henüz eklenmedi.'),
        findsOneWidget,
      );
      expect(find.byType(ChatScreen), findsOneWidget);
      expect(find.text('Merhaba'), findsOneWidget);
    });
  });
}
