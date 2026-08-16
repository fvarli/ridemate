import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/app/app_shell.dart';
import 'package:ridemate/app/providers/app_preferences_provider.dart';
import 'package:ridemate/app/ride_mate_app.dart';
import 'package:ridemate/app/startup_screen.dart';
import 'package:ridemate/features/onboarding/application/onboarding_controller.dart';
import 'package:ridemate/features/onboarding/presentation/onboarding_screen.dart';
import 'package:ridemate/features/verification/presentation/verification_screen.dart';

import '../support/fakes.dart';

Future<InMemoryOnboardingRepository> _pumpApp(
  WidgetTester tester, {
  bool introCompleted = false,
}) async {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final InMemoryOnboardingRepository repo = InMemoryOnboardingRepository(
    seen: introCompleted,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        onboardingRepositoryProvider.overrideWithValue(repo),
      ],
      child: const RideMateApp(),
    ),
  );
  await tester.pumpAndSettle();

  // Turkish is the source product language; the test device reports en_US, so
  // pin it here rather than asserting against translations.
  ProviderScope.containerOf(
    tester.element(find.byType(RideMateApp)),
  ).read(localeProvider.notifier).set(const Locale('tr'));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  group('Launch guard', () {
    testWidgets('a first-time launch lands on the intro', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester);

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
    });

    testWidgets('a returning launch lands straight on Home', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester, introCompleted: true);

      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
    });

    testWidgets('the wrong screen never flashes before persistence resolves', (
      WidgetTester tester,
    ) async {
      // The very first frame must show only the neutral launch surface.
      // Showing Home to a first-time user, or the intro to a returning one,
      // even for a frame, is a visible defect.
      final InMemoryOnboardingRepository repo = InMemoryOnboardingRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            onboardingRepositoryProvider.overrideWithValue(repo),
          ],
          child: const RideMateApp(),
        ),
      );

      expect(find.byType(StartupScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(AppShell), findsNothing);

      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('the launch surface is never left on screen', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester, introCompleted: true);
      expect(find.byType(StartupScreen), findsNothing);
    });
  });

  group('New-user flow', () {
    testWidgets('"Hesap oluştur" records the intro and opens verification', (
      WidgetTester tester,
    ) async {
      final InMemoryOnboardingRepository repo = await _pumpApp(tester);

      await tester.tap(find.text('Hesap oluştur'));
      await tester.pumpAndSettle();

      expect(repo.markCallCount, 1);
      expect(find.byType(VerificationScreen), findsOneWidget);
    });

    testWidgets('verification back goes to Home, not back to the intro', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester);

      await tester.tap(find.text('Hesap oluştur'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Geri'));
      await tester.pumpAndSettle();

      expect(find.byType(AppShell), findsOneWidget);
      expect(
        find.byType(OnboardingScreen),
        findsNothing,
        reason: 'the intro is complete and must not reappear',
      );
    });
  });

  group('Sign-in is not onboarding and not authentication', () {
    testWidgets(
      '"Zaten üyeyim" changes no persisted state and navigates nowhere',
      (WidgetTester tester) async {
        // "I'm already a member" means sign in to an existing account. Treating
        // it as "skip the intro" would encode the wrong product behaviour and
        // would have to be unpicked once real auth exists.
        final InMemoryOnboardingRepository repo = await _pumpApp(tester);

        await tester.tap(find.text('Zaten üyeyim'));
        await tester.pump();

        expect(repo.markCallCount, 0);
        expect(repo.seen, isFalse);
        expect(find.byType(OnboardingScreen), findsOneWidget);
        expect(find.byType(AppShell), findsNothing);
        expect(find.byType(VerificationScreen), findsNothing);
        expect(find.text('Giriş özelliği yakında eklenecek.'), findsOneWidget);
      },
    );

    testWidgets('after tapping sign-in, a relaunch still shows the intro', (
      WidgetTester tester,
    ) async {
      final InMemoryOnboardingRepository repo = await _pumpApp(tester);

      await tester.tap(find.text('Zaten üyeyim'));
      await tester.pumpAndSettle();

      // Relaunch against the same storage.
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            onboardingRepositoryProvider.overrideWithValue(repo),
          ],
          child: const RideMateApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
    });
  });
}
