// ─────────────────────────────────────────────────────────────
// RideMate — Profile navigation
//
// The one edge the design draws out of Profile, and the one it deliberately
// does not.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/app/providers/app_preferences_provider.dart';
import 'package:ridemate/app/ride_mate_app.dart';
import 'package:ridemate/app/router/app_router.dart';
import 'package:ridemate/app/router/app_routes.dart';
import 'package:ridemate/core/widgets/rm_card.dart';
import 'package:ridemate/features/onboarding/application/onboarding_controller.dart';
import 'package:ridemate/features/profile/presentation/profile_screen.dart';
import 'package:ridemate/features/profile/presentation/widgets/profile_links.dart';
import 'package:ridemate/features/reviews/presentation/reviews_screen.dart';

import '../../support/fakes.dart';

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
      ],
      child: const RideMateApp(),
    ),
  );
  await tester.pumpAndSettle();

  final ProviderContainer container = ProviderScope.containerOf(
    tester.element(find.byType(RideMateApp)),
  );
  // Turkish is the product language and these tests assert its copy; the app
  // otherwise follows the host locale, which is English under test.
  container.read(localeProvider.notifier).set(const Locale('tr'));
  await tester.pumpAndSettle();
  return container;
}

/// The two Profile rows, in the order the design draws them.
Finder get _profileRows => find.descendant(
  of: find.byType(ProfileLinks),
  matching: find.byType(RmCard),
);

void main() {
  testWidgets('the profile tab opens reviews and comes back', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await _pumpApp(tester);
    container.read(routerProvider).goNamed(AppRoutes.profile);
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);

    await tester.ensureVisible(_profileRows.last);
    await tester.pumpAndSettle();
    await tester.tap(_profileRows.last);
    await tester.pumpAndSettle();
    expect(find.byType(ReviewsScreen), findsOneWidget);
    expect(find.text('Değerlendirmeler'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Geri'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('the verification row goes nowhere, as drawn', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await _pumpApp(tester);
    container.read(routerProvider).goNamed(AppRoutes.profile);
    await tester.pumpAndSettle();

    // The comp gives it a count and no chevron. It counts the five steps
    // /verification models but does not link to them — probably an oversight,
    // raised in docs/design-system.md §8 rather than invented here.
    await tester.ensureVisible(_profileRows.first);
    await tester.pumpAndSettle();
    await tester.tap(_profileRows.first);
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.byType(ReviewsScreen), findsNothing);
  });

  testWidgets('reviews is reachable in release builds', (
    WidgetTester tester,
  ) async {
    // Unlike Active Trip, nothing about this screen is withheld: it shows
    // presentation data and offers no action, so it carries no claim a real
    // member should not meet.
    final ProviderContainer container = await _pumpApp(tester);
    container.read(routerProvider).goNamed(AppRoutes.reviews);
    await tester.pumpAndSettle();

    expect(find.byType(ReviewsScreen), findsOneWidget);
  });

  testWidgets('reviews reached directly falls back to home', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await _pumpApp(tester);
    container.read(routerProvider).goNamed(AppRoutes.reviews);
    await tester.pumpAndSettle();

    // A deep link leaves nothing beneath it, and a back control that does
    // nothing is worse than no back control.
    await tester.tap(find.bySemanticsLabel('Geri'));
    await tester.pumpAndSettle();
    expect(find.byType(ReviewsScreen), findsNothing);
  });
}
