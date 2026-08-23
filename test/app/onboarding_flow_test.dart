import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/app/app_shell.dart';
import 'package:ridemate/app/providers/app_preferences_provider.dart';
import 'package:ridemate/app/providers/session_provider.dart';
import 'package:ridemate/app/ride_mate_app.dart';
import 'package:ridemate/app/startup_screen.dart';
import 'package:ridemate/core/session/rm_session.dart';
import 'package:ridemate/features/auth/presentation/phone_entry_screen.dart';
import 'package:ridemate/features/onboarding/application/onboarding_controller.dart';
import 'package:ridemate/features/onboarding/presentation/onboarding_screen.dart';

import '../support/fakes.dart';

Future<InMemoryOnboardingRepository> _pumpApp(
  WidgetTester tester, {
  bool introCompleted = false,
  FakeSession? session,
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
        // Signed out by default: this file is about the ONBOARDING dimension,
        // and the two are independent. Tests that need the other one say so.
        rmSessionProvider.overrideWithValue(session ?? FakeSession.signedOut()),
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

    testWidgets('a returning, signed-in launch lands straight on Home', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester, introCompleted: true, session: FakeSession());

      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
    });

    /// The two dimensions are independent, and this is the case that proves
    /// it: the intro is done and there is still no account, so the answer is
    /// the sign-in screen rather than the shell.
    testWidgets('a returning, signed-out launch lands on sign-in', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester, introCompleted: true);

      expect(find.byType(PhoneEntryScreen), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
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
            rmSessionProvider.overrideWithValue(FakeSession.signedOut()),
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

    /// The session resolves over the network, so it is the slower of the two
    /// and the one that would flash a sign-in screen at somebody who is
    /// already signed in.
    testWidgets('an unresolved session holds the launch surface', (
      WidgetTester tester,
    ) async {
      final FakeSession session = FakeSession.unresolved();
      await _pumpApp(tester, introCompleted: true, session: session);

      expect(find.byType(StartupScreen), findsOneWidget);
      expect(find.byType(PhoneEntryScreen), findsNothing);
      expect(find.byType(AppShell), findsNothing);

      session.become(const RmSignedIn('SESSION_TEST'));
      await tester.pumpAndSettle();

      expect(find.byType(AppShell), findsOneWidget);
    });

    testWidgets('the launch surface is never left on screen', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester, introCompleted: true, session: FakeSession());
      expect(find.byType(StartupScreen), findsNothing);
    });
  });

  group('Leaving the intro', () {
    /// Both buttons mark the intro seen and land on the SAME screen.
    ///
    /// The distinction between them is real to the member and deliberately
    /// invisible to the client: a verified number either belongs to an account
    /// or does not, and the server decides that on one endpoint so that asking
    /// cannot reveal who is already a member. Two client journeys would have to
    /// know the answer before asking.
    ///
    /// Marking it is not a convenience: the router gives onboarding precedence
    /// over authentication, so a CTA that navigated to /auth while the flag
    /// was still false would be redirected straight back here — the member
    /// would tap and watch nothing happen.
    for (final String cta in <String>['Hesap oluştur', 'Zaten üyeyim']) {
      testWidgets('"$cta" records the intro and opens sign-in', (
        WidgetTester tester,
      ) async {
        final InMemoryOnboardingRepository repo = await _pumpApp(tester);

        await tester.tap(find.text(cta));
        await tester.pumpAndSettle();

        expect(repo.markCallCount, 1);
        expect(repo.seen, isTrue);
        expect(find.byType(PhoneEntryScreen), findsOneWidget);
        expect(
          find.byType(OnboardingScreen),
          findsNothing,
          reason: 'a bounce back to the intro is the failure this guards',
        );
      });

      testWidgets('"$cta" settles rather than looping', (
        WidgetTester tester,
      ) async {
        await _pumpApp(tester);

        await tester.tap(find.text(cta));
        // pumpAndSettle would time out on a redirect loop; several explicit
        // frames prove it is stable rather than merely quiet.
        await tester.pumpAndSettle();
        await tester.pump();
        await tester.pump();

        expect(find.byType(PhoneEntryScreen), findsOneWidget);
      });

      testWidgets('after "$cta", a relaunch goes straight to sign-in', (
        WidgetTester tester,
      ) async {
        final InMemoryOnboardingRepository repo = await _pumpApp(tester);

        await tester.tap(find.text(cta));
        await tester.pumpAndSettle();

        expect(repo.seen, isTrue);
      });
    }
  });
}
