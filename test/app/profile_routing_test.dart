// ─────────────────────────────────────────────────────────────
// RideMate — Mandatory profile completion, as a routing dimension
//
// THREE INDEPENDENT DIMENSIONS, IN A FIXED ORDER
//
//   "has this person seen the intro"   — a device-local flag
//   "is there a usable session"        — a credential the server accepts
//   "has this member chosen a name"    — a fact the server states
//
// None is derived from another. A member who reinstalls has a session and no
// flag; one who signed out has the flag and no session; one who just verified a
// phone number has both and no profile. Collapsing any pair gets a real case
// wrong.
//
// THE FAILURE THIS FILE EXISTS TO PREVENT
//
// Routing to setup because a profile READ failed. That asks somebody who
// already has a name to invent a second one, and the server would then answer
// 200 for a rename they never meant. So every failure shape is driven here, and
// each one must reach the app rather than the setup screen.
// ─────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/app/app_shell.dart';
import 'package:ridemate/app/providers/app_preferences_provider.dart';
import 'package:ridemate/app/providers/session_provider.dart';
import 'package:ridemate/app/ride_mate_app.dart';
import 'package:ridemate/app/router/app_router.dart';
import 'package:ridemate/app/startup_screen.dart';
import 'package:ridemate/core/api/rm_error_code.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/profile/profile.dart';
import 'package:ridemate/features/auth/presentation/phone_entry_screen.dart';
import 'package:ridemate/features/onboarding/application/onboarding_controller.dart';
import 'package:ridemate/features/onboarding/presentation/onboarding_screen.dart';
import 'package:ridemate/features/profile/application/my_profile_providers.dart';
import 'package:ridemate/features/profile/data/profile_repository.dart';
import 'package:ridemate/features/profile/presentation/profile_setup_screen.dart';

import '../support/fakes.dart';

void main() {
  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    required FakeSession session,
    required FakeProfileRepository profiles,
    bool introSeen = true,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          onboardingRepositoryProvider.overrideWithValue(
            InMemoryOnboardingRepository(seen: introSeen),
          ),
          rmSessionProvider.overrideWithValue(session),
          profileRepositoryProvider.overrideWithValue(profiles),
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

  /// Mounts the app and pumps frames without settling, for the cases where
  /// something deliberately never answers.
  Future<void> pumpUnsettled(
    WidgetTester tester, {
    required ProfileRepository profiles,
  }) async {
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
          profileRepositoryProvider.overrideWithValue(profiles),
        ],
        child: const RideMateApp(),
      ),
    );

    for (int i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  group('Where a signed-in member lands', () {
    /// CARRIES WEIGHT. The reason the whole dimension exists.
    testWidgets('no profile sends them to setup', (WidgetTester tester) async {
      await pumpApp(
        tester,
        session: FakeSession(),
        profiles: FakeProfileRepository.missing(),
      );

      expect(find.byType(ProfileSetupScreen), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
    });

    testWidgets('a profile sends them to the app', (WidgetTester tester) async {
      await pumpApp(
        tester,
        session: FakeSession(),
        profiles: FakeProfileRepository(),
      );

      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(ProfileSetupScreen), findsNothing);
    });
  });

  group('Auth wins, and the profile never overrides it', () {
    /// A signed-out member goes to sign-in whatever the profile would say —
    /// and, more importantly, no profile request is made at all: there is no
    /// credential to make one with.
    testWidgets('signed out never sees setup', (WidgetTester tester) async {
      final FakeProfileRepository profiles = FakeProfileRepository.missing();

      await pumpApp(
        tester,
        session: FakeSession.signedOut(),
        profiles: profiles,
      );

      expect(find.byType(PhoneEntryScreen), findsOneWidget);
      expect(find.byType(ProfileSetupScreen), findsNothing);
      expect(
        profiles.readCount,
        0,
        reason: 'a signed-out app has no credential to read a profile with',
      );
    });

    /// The intro still wins over both, unchanged.
    testWidgets('an unseen intro beats a missing profile', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        session: FakeSession(),
        profiles: FakeProfileRepository.missing(),
        introSeen: false,
      );

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(ProfileSetupScreen), findsNothing);
    });
  });

  group('Nothing is guessed', () {
    /// An unresolved session holds the launch surface, as before — and the
    /// profile must not push past it.
    testWidgets('an unresolved session flashes neither sign-in nor setup', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        session: FakeSession.unresolved(),
        profiles: FakeProfileRepository.missing(),
      );

      expect(find.byType(StartupScreen), findsOneWidget);
      expect(find.byType(ProfileSetupScreen), findsNothing);
      expect(find.byType(PhoneEntryScreen), findsNothing);
      expect(find.byType(AppShell), findsNothing);
    });

    /// CARRIES WEIGHT. While the read is in flight the app decides nothing.
    ///
    /// Pumped rather than settled, because the held read never answers and
    /// `pumpAndSettle` would wait for it. The pumping is long enough for the
    /// onboarding flag to resolve — proved by the control below, which reaches
    /// the app under exactly the same pumping — so the launch surface here is
    /// the PROFILE dimension holding it, not the intro one.
    testWidgets('a profile still loading holds the launch surface', (
      WidgetTester tester,
    ) async {
      final _HeldProfileRepository profiles = _HeldProfileRepository();

      await pumpUnsettled(tester, profiles: profiles);

      expect(find.byType(StartupScreen), findsOneWidget);
      expect(find.byType(ProfileSetupScreen), findsNothing);
      expect(find.byType(PhoneEntryScreen), findsNothing);
      expect(find.byType(AppShell), findsNothing);

      profiles.release();
      await tester.pumpAndSettle();

      expect(find.byType(AppShell), findsOneWidget);
    });

    /// The control. Without it the test above would pass for the wrong reason —
    /// an unresolved onboarding flag holds the same surface, and that is
    /// exactly how an earlier version of this test proved nothing.
    testWidgets('the same pumping reaches the app when the read answers', (
      WidgetTester tester,
    ) async {
      await pumpUnsettled(tester, profiles: FakeProfileRepository());

      expect(
        find.byType(AppShell),
        findsOneWidget,
        reason: 'the onboarding flag has resolved by this point',
      );
    });
  });

  group('A failed read is not a missing profile', () {
    /// CARRIES WEIGHT. Every failure shape, and none of them may reach setup.
    for (final (String label, Object failure) in <(String, Object)>[
      ('an unreachable backend', const RmFailure.transport()),
      (
        'a server error',
        const RmFailure.fromBackend(
          status: 500,
          code: RmErrorCode.internalError,
        ),
      ),
      (
        'a malformed response',
        const RmFailure.fromBackend(status: 200, code: RmErrorCode.unexpected),
      ),
      (
        'a forbidden account',
        const RmFailure.fromBackend(status: 403, code: RmErrorCode.forbidden),
      ),
    ]) {
      testWidgets('$label reaches the app, never setup', (
        WidgetTester tester,
      ) async {
        await pumpApp(
          tester,
          session: FakeSession(),
          profiles: FakeProfileRepository(readError: failure),
        );

        expect(find.byType(ProfileSetupScreen), findsNothing);
        expect(find.byType(AppShell), findsOneWidget);
      });

      /// And it is not a sign-out either. Phase 9 owns the credential.
      testWidgets('$label leaves the member signed in', (
        WidgetTester tester,
      ) async {
        final FakeSession session = FakeSession();

        await pumpApp(
          tester,
          session: session,
          profiles: FakeProfileRepository(readError: failure),
        );

        expect(session.isSignedIn, isTrue);
        expect(session.signedOutReason, isNull);
        expect(find.byType(PhoneEntryScreen), findsNothing);
      });
    }
  });

  group('Completing setup', () {
    Future<void> enterName(WidgetTester tester, String name) async {
      await tester.enterText(find.byType(TextField), name);
      await tester.pump();
      await tester.tap(find.text('Devam et'));
      await tester.pumpAndSettle();
    }

    /// CARRIES WEIGHT. The save is what moves the member, and only after the
    /// server has answered.
    testWidgets('a successful save leaves setup', (WidgetTester tester) async {
      final FakeProfileRepository profiles = FakeProfileRepository.missing();
      await pumpApp(tester, session: FakeSession(), profiles: profiles);

      expect(find.byType(ProfileSetupScreen), findsOneWidget);

      await enterName(tester, 'Ayşe Demir');

      expect(profiles.saveCount, 1);
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(ProfileSetupScreen), findsNothing);
    });

    testWidgets('a failed save stays, with an honest error', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository profiles = FakeProfileRepository.missing()
        ..saveError = const RmFailure.transport();
      await pumpApp(tester, session: FakeSession(), profiles: profiles);

      await enterName(tester, 'Ayşe Demir');

      expect(find.byType(ProfileSetupScreen), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
      // The transport copy, not a backend message and not a silent failure.
      expect(
        find.text('Bağlantı kurulamadı. İnternet bağlantını kontrol et.'),
        findsOneWidget,
      );
    });

    /// CARRIES WEIGHT. Setup is a dead end once it is done.
    testWidgets('a completed member cannot navigate back into setup', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository profiles = FakeProfileRepository.missing();
      final ProviderContainer container = await pumpApp(
        tester,
        session: FakeSession(),
        profiles: profiles,
      );

      await enterName(tester, 'Ayşe Demir');
      expect(find.byType(AppShell), findsOneWidget);

      container.read(routerProvider).go('/profile/setup');
      await tester.pumpAndSettle();

      expect(find.byType(ProfileSetupScreen), findsNothing);
      expect(find.byType(AppShell), findsOneWidget);
    });
  });

  group('No loop', () {
    /// CARRIES WEIGHT. The redirect runs on every navigation; if it read the
    /// provider directly, each run would create, request and dispose. One read
    /// per session is the proof that it does not.
    testWidgets('navigating repeatedly performs exactly one profile read', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository profiles = FakeProfileRepository();
      final ProviderContainer container = await pumpApp(
        tester,
        session: FakeSession(),
        profiles: profiles,
      );

      expect(profiles.readCount, 1);

      for (final String path in <String>[
        '/search',
        '/messages',
        '/profile',
        '/home',
        '/search',
      ]) {
        container.read(routerProvider).go(path);
        await tester.pumpAndSettle();
      }

      expect(
        profiles.readCount,
        1,
        reason: 'the redirect reacts to profile state; it never fetches it',
      );
    });

    /// A member who arrives without a profile and completes setup reads once
    /// and saves once — no re-read storm as the router re-evaluates.
    testWidgets('setup completes with one read and one save', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository profiles = FakeProfileRepository.missing();
      await pumpApp(tester, session: FakeSession(), profiles: profiles);

      await tester.enterText(find.byType(TextField), 'Ayşe Demir');
      await tester.pump();
      await tester.tap(find.text('Devam et'));
      await tester.pumpAndSettle();

      expect(profiles.readCount, 1);
      expect(profiles.saveCount, 1);
    });
  });
}

/// A repository whose read does not answer until a test says so.
class _HeldProfileRepository implements ProfileRepository {
  final Completer<Profile> _gate = Completer<Profile>();

  void release() =>
      _gate.complete(const Profile(displayName: 'Ayşe Demir', initials: 'AD'));

  @override
  Future<Profile> read() => _gate.future;

  @override
  Future<Profile> save(String displayName) async =>
      Profile(displayName: displayName.trim(), initials: 'SV');
}
