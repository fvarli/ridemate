import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/app/app_shell.dart';
import 'package:ridemate/app/providers/app_preferences_provider.dart';
import 'package:ridemate/app/providers/session_provider.dart';
import 'package:ridemate/app/ride_mate_app.dart';
import 'package:ridemate/app/router/app_router.dart';
import 'package:ridemate/app/router/app_routes.dart';
import 'package:ridemate/app/startup_screen.dart';
import 'package:ridemate/core/session/rm_session.dart';
import 'package:ridemate/features/auth/presentation/passcode_entry_screen.dart';
import 'package:ridemate/features/auth/presentation/phone_entry_screen.dart';
import 'package:ridemate/features/onboarding/application/onboarding_controller.dart';
import 'package:ridemate/features/onboarding/presentation/onboarding_screen.dart';
import 'package:ridemate/l10n/app_localizations.dart';

import '../support/fakes.dart';

/// Navigation policy: two independent dimensions, in a fixed order.
///
///   "has this person seen the intro"  — a device-local flag
///   "is there a usable session"       — a credential the server accepts
///
/// Neither is derived from the other, and the combinations below are why: a
/// member who reinstalls has a session and no flag, and one who signed out has
/// the flag and no session. Collapsing them into a single boolean gets both
/// wrong.
void main() {
  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    required bool introSeen,
    required FakeSession session,
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

  // -------------------------------------------------------------- precedence

  group('Precedence', () {
    testWidgets('an unresolved session holds the startup surface', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, introSeen: true, session: FakeSession.unresolved());

      expect(find.byType(StartupScreen), findsOneWidget);
      expect(find.byType(PhoneEntryScreen), findsNothing);
      expect(find.byType(AppShell), findsNothing);
    });

    /// The intro wins. Somebody who has never seen it should not meet a
    /// sign-in form first, whatever their credential says.
    testWidgets('an unseen intro beats a valid session', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, introSeen: false, session: FakeSession());

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
    });

    testWidgets('an unseen intro also beats no session', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, introSeen: false, session: FakeSession.signedOut());

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(PhoneEntryScreen), findsNothing);
    });

    testWidgets('intro seen and signed out lands on sign-in', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, introSeen: true, session: FakeSession.signedOut());

      expect(find.byType(PhoneEntryScreen), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
    });

    testWidgets('intro seen and signed in lands on the shell', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, introSeen: true, session: FakeSession());

      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(PhoneEntryScreen), findsNothing);
      expect(find.byType(StartupScreen), findsNothing);
    });
  });

  // ------------------------------------------------------------ no loops

  group('Auth routes do not loop', () {
    testWidgets('a signed-out member may sit on the phone screen', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await pumpApp(
        tester,
        introSeen: true,
        session: FakeSession.signedOut(),
      );

      container.read(routerProvider).goNamed(AppRoutes.authPhone);
      await tester.pumpAndSettle();
      await tester.pump();

      expect(find.byType(PhoneEntryScreen), findsOneWidget);
    });

    /// The redirect that would send /auth/passcode back to /auth is exactly
    /// the loop this excludes: a member entering six digits would be thrown
    /// off the screen mid-typing.
    testWidgets('a signed-out member may sit on the passcode screen', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await pumpApp(
        tester,
        introSeen: true,
        session: FakeSession.signedOut(),
      );

      container
          .read(routerProvider)
          .goNamed(AppRoutes.authPasscode, extra: '0532 123 45 67');
      await tester.pumpAndSettle();
      await tester.pump();
      await tester.pump();

      expect(find.byType(PasscodeEntryScreen), findsOneWidget);
    });

    /// Stale navigation history must not send a valid session back to a
    /// sign-in form.
    testWidgets('a signed-in member visiting auth is sent to the shell', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await pumpApp(
        tester,
        introSeen: true,
        session: FakeSession(),
      );

      container.read(routerProvider).goNamed(AppRoutes.authPhone);
      await tester.pumpAndSettle();

      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(PhoneEntryScreen), findsNothing);
    });

    testWidgets('a signed-in member visiting onboarding is sent to the shell', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await pumpApp(
        tester,
        introSeen: true,
        session: FakeSession(),
      );

      container.read(routerProvider).goNamed(AppRoutes.onboarding);
      await tester.pumpAndSettle();

      expect(find.byType(AppShell), findsOneWidget);
    });

    testWidgets('every combination settles rather than looping', (
      WidgetTester tester,
    ) async {
      for (final bool seen in <bool>[true, false]) {
        for (final FakeSession session in <FakeSession>[
          FakeSession(),
          FakeSession.signedOut(),
          FakeSession.unresolved(),
        ]) {
          await pumpApp(tester, introSeen: seen, session: session);
          // pumpAndSettle already timed out if anything looped; the extra
          // frames prove the result is stable rather than merely quiet.
          await tester.pump();
          await tester.pump();
          expect(tester.takeException(), isNull);
        }
      }
    });
  });

  // ------------------------------------------------------- ending a session

  group('A session ending mid-flight', () {
    testWidgets('a revoked session lands on sign-in with a notice', (
      WidgetTester tester,
    ) async {
      final FakeSession session = FakeSession();
      await pumpApp(tester, introSeen: true, session: session);
      expect(find.byType(AppShell), findsOneWidget);

      session.endSession(RmSignedOutReason.sessionEnded);
      await tester.pumpAndSettle();

      final AppLocalizations tr = await AppLocalizations.delegate.load(
        const Locale('tr'),
      );

      expect(find.byType(PhoneEntryScreen), findsOneWidget);
      expect(find.text(tr.errorUnauthenticated), findsOneWidget);
    });

    /// Suspension is not an expired session, and telling a suspended member to
    /// sign in again is advice that cannot work.
    testWidgets('a suspended account gets its own copy', (
      WidgetTester tester,
    ) async {
      final FakeSession session = FakeSession();
      await pumpApp(tester, introSeen: true, session: session);

      session.endSession(RmSignedOutReason.accountSuspended);
      await tester.pumpAndSettle();

      final AppLocalizations tr = await AppLocalizations.delegate.load(
        const Locale('tr'),
      );

      expect(find.text(tr.errorForbidden), findsOneWidget);
      expect(find.text(tr.errorUnauthenticated), findsNothing);
    });

    /// A member who signed out deliberately must not be told their session
    /// ended: the app would be explaining an event they caused.
    testWidgets('an explicit sign-out shows no notice', (
      WidgetTester tester,
    ) async {
      final FakeSession session = FakeSession();
      await pumpApp(tester, introSeen: true, session: session);

      await session.signOut();
      await tester.pumpAndSettle();

      final AppLocalizations tr = await AppLocalizations.delegate.load(
        const Locale('tr'),
      );

      expect(find.byType(PhoneEntryScreen), findsOneWidget);
      expect(find.text(tr.errorUnauthenticated), findsNothing);
      expect(find.text(tr.errorForbidden), findsNothing);
    });

    /// Nor should a first launch, which never had a session to lose.
    testWidgets('a first launch shows no notice', (WidgetTester tester) async {
      await pumpApp(tester, introSeen: true, session: FakeSession.signedOut());

      final AppLocalizations tr = await AppLocalizations.delegate.load(
        const Locale('tr'),
      );

      expect(find.byType(PhoneEntryScreen), findsOneWidget);
      expect(find.text(tr.errorUnauthenticated), findsNothing);
    });

    /// Read once. The router re-evaluates its redirect on every navigation, so
    /// a reason left in place would reappear each time the member moved.
    testWidgets('the notice does not follow the member around', (
      WidgetTester tester,
    ) async {
      final FakeSession session = FakeSession.signedOut(
        RmSignedOutReason.sessionEnded,
      );
      final ProviderContainer container = await pumpApp(
        tester,
        introSeen: true,
        session: session,
      );

      final AppLocalizations tr = await AppLocalizations.delegate.load(
        const Locale('tr'),
      );
      expect(find.text(tr.errorUnauthenticated), findsOneWidget);

      container
          .read(routerProvider)
          .goNamed(AppRoutes.authPasscode, extra: '0532 123 45 67');
      await tester.pumpAndSettle();
      container.read(routerProvider).goNamed(AppRoutes.authPhone);
      await tester.pumpAndSettle();

      expect(find.text(tr.errorUnauthenticated), findsNothing);
    });
  });

  // ------------------------------------------------------- withheld screens

  group('Verification is withheld from release', () {
    /// Its email step reads "verified" from a fixture, its progression is a
    /// scripted demo no backend drives, and its Trust Score has no engine.
    /// Harmless while every account was imaginary; false claims about a real
    /// member's account now.
    test('its route sits under the kDebugMode guard', () {
      final List<String> lines = File(
        'lib/app/router/app_router.dart',
      ).readAsLinesSync();

      final int route = lines.indexWhere(
        (String l) => l.contains('AppRoutes.verificationPath'),
      );
      expect(route, isNot(-1));

      final int guard = lines
          .sublist(0, route)
          .lastIndexWhere((String l) => l.contains('if (kDebugMode)'));
      expect(guard, isNot(-1));
      expect(
        route - guard,
        lessThan(6),
        reason: 'the verification route must sit under the kDebugMode guard',
      );
    });

    /// The screen, its fixtures, its tests and its goldens all stay. Only the
    /// release entry point goes.
    test('the screen and its fixtures are untouched', () {
      expect(
        File(
          'lib/features/verification/presentation/verification_screen.dart',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          'lib/features/verification/domain/mock_verification_scenarios.dart',
        ).existsSync(),
        isTrue,
      );
    });

    /// What has to be true before it comes back.
    test('the return conditions are recorded beside the guard', () {
      final String source = File(
        'lib/app/router/app_router.dart',
      ).readAsStringSync();

      for (final String condition in <String>[
        'served by the backend',
        'Trust Score',
        'submission path',
        'traceable to backend state',
        'one coherent change',
      ]) {
        expect(source, contains(condition), reason: condition);
      }
    });
  });

  group('No gate was introduced that the design does not have', () {
    /// NARROWED IN PHASE 11.
    ///
    /// This banned `profile` alongside `verification`, on the reasoning that
    /// gating on either would invent a product rule the design does not
    /// contain. That was right for verification and is still right: it gates
    /// nothing, has no backend behind it, and its screen is debug-only.
    ///
    /// Profile completion stopped being an invention when Phase 11 decided it:
    /// a member who has not chosen a name has nothing another member could be
    /// shown, so the app asks once and never again. The ban would now forbid
    /// the decided behaviour while permitting the undecided one.
    ///
    /// What survives is the part that still protects something, and it is now
    /// stricter than the old blanket ban — see the two tests below. The
    /// redirect may know WHETHER a profile exists; it may not know what is in
    /// one, and it may not go and find out.
    test('the redirect gates on no verification or trust condition', () {
      final String source = File('lib/app/router/app_router.dart')
          .readAsLinesSync()
          .map((String line) {
            final int comment = line.indexOf('//');

            return comment == -1 ? line : line.substring(0, comment);
          })
          .join('\n');

      // Bounded to the redirect's own body. Slicing to the end of the file
      // would sweep in the route table below, where the verification route
      // legitimately appears.
      final int start = source.indexOf('redirect:');
      final int end = source.indexOf('\n    },', start);
      expect(end, greaterThan(start));
      final String redirect = source.substring(start, end);

      for (final String banned in <String>[
        'verification',
        'Verification',
        'trustScore',
        'rating',
        'tripCount',
        // The redirect may know whether a profile EXISTS. What it says is none
        // of its business: a router that read a display name would be one
        // rename away from deciding where somebody lives.
        'displayName',
        'display_name',
        'initials',
      ]) {
        expect(redirect, isNot(contains(banned)), reason: banned);
      }
    });

    /// CARRIES WEIGHT. The redirect reacts to profile state; it never fetches
    /// it.
    ///
    /// `redirect` runs on every navigation, and `myProfileProvider` is
    /// auto-dispose — reading it here would create the provider, start a
    /// request, dispose it, and start another on the next redirect. A request
    /// storm and a redirect loop from one line. ProfileGate owns the
    /// subscription precisely so this stays impossible.
    test('the redirect performs no profile I/O', () {
      for (final String banned in <String>[
        'myProfileProvider',
        'profileRepositoryProvider',
        'ProfileRepository',
        'await',
        'ref.watch',
        'ref.read(myProfile',
      ]) {
        expect(redirectSource(), isNot(contains(banned)), reason: banned);
      }
    });

    /// And the gate is genuinely a separate dimension, not folded into the
    /// session — the mistake this file has warned about since the intro flag
    /// was the only condition.
    test('profile state is merged as its own refresh dimension', () {
      final String source = File(
        'lib/app/router/app_router.dart',
      ).readAsStringSync();

      expect(source, contains('ProfileGate('));
      expect(source, contains('refreshListenable'));
      // Three listenables, not two: onboarding, session, profile.
      expect(source, contains('session.state,'));
      expect(source, contains('profile,'));
    });
  });
}

/// The redirect's own body, comments stripped.
///
/// Bounded to the redirect rather than the whole file: the route table below it
/// legitimately names the verification and profile-setup routes.
String redirectSource() {
  final String source = File('lib/app/router/app_router.dart')
      .readAsLinesSync()
      .map((String line) {
        final int comment = line.indexOf('//');

        return comment == -1 ? line : line.substring(0, comment);
      })
      .join('\n');

  final int start = source.indexOf('redirect:');
  final int end = source.indexOf('\n    },', start);

  return source.substring(start, end);
}
