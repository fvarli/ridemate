// ─────────────────────────────────────────────────────────────
// RideMate — Signing out, from the release app
//
// The control is on every face the Profile experience can show a signed-in
// member, including the two where the profile itself did not arrive. Pressing
// it navigates nowhere: the session ends and the router takes the member out,
// exactly as it does when a session ends any other way.
// ─────────────────────────────────────────────────────────────

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
import 'package:ridemate/core/places/place.dart';
import 'package:ridemate/core/session/rm_session.dart';
import 'package:ridemate/features/auth/presentation/phone_entry_screen.dart';
import 'package:ridemate/features/create_route/application/create_route_providers.dart';
import 'package:ridemate/features/create_route/domain/create_route_fixtures.dart';
import 'package:ridemate/features/onboarding/application/onboarding_controller.dart';
import 'package:ridemate/features/profile/application/my_profile_providers.dart';
import 'package:ridemate/features/profile/presentation/profile_screen.dart';
import 'package:ridemate/features/profile/presentation/profile_setup_screen.dart';
import 'package:ridemate/features/profile/presentation/widgets/sign_out_button.dart';

import '../../support/fakes.dart';
import '../../support/pump.dart';

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  required FakeSession session,
  required FakeProfileRepository profile,
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
        rmSessionProvider.overrideWithValue(session),
        profileRepositoryProvider.overrideWithValue(profile),
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

Future<void> _signOut(WidgetTester tester) async {
  final Finder button = find.byType(SignOutButton);
  expect(button, findsOneWidget);
  expect(find.text('Çıkış yap'), findsOneWidget);

  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void _expectSignedOut(FakeSession session) {
  expect(session.state.value, isA<RmSignedOut>());
  expect(find.byType(PhoneEntryScreen), findsOneWidget);
  expect(find.byType(AppShell), findsNothing);
  expect(find.byType(ProfileScreen), findsNothing);
  // A deliberate sign-out is not a session that ended.
  expect(session.consumeSignedOutReason(), isNull);
}

void main() {
  testWidgets('from the loaded profile, and what was left behind goes too', (
    WidgetTester tester,
  ) async {
    final FakeSession session = FakeSession();
    final ProviderContainer container = await _pumpApp(
      tester,
      session: session,
      profile: FakeProfileRepository(),
    );

    // Something this member was composing, which the next must not see.
    container
        .read(createRouteDraftProvider.notifier)
        .setOrigin(
          const Place(
            id: '01991a00-0000-7000-8000-00000000000a',
            label: 'Sunucu Yeri A',
          ),
        );

    container.read(routerProvider).goNamed(AppRoutes.profile);
    await tester.pumpAndSettle();
    expect(find.text('Ayşe Demir'), findsOneWidget);

    await _signOut(tester);

    _expectSignedOut(session);
    expect(container.read(createRouteDraftProvider), kInitialCreateRouteDraft);
  });

  /// Leaving must not depend on the read that failed.
  testWidgets('from a profile that could not be loaded', (
    WidgetTester tester,
  ) async {
    final FakeSession session = FakeSession();
    final ProviderContainer container = await _pumpApp(
      tester,
      session: session,
      profile: FakeProfileRepository.offline(),
    );

    container.read(routerProvider).goNamed(AppRoutes.profile);
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Yeniden dene'), findsOneWidget);

    await _signOut(tester);

    _expectSignedOut(session);
  });

  /// The no-profile branch of Profile itself. The router sends a missing
  /// profile to setup before this can be seen, so the screen is pumped on its
  /// own rather than bending routing to reach it.
  testWidgets('from a profile that does not exist yet', (
    WidgetTester tester,
  ) async {
    final FakeSession session = FakeSession();
    await tester.pumpRmScreen(
      const ProfileScreen(),
      overrides: <Override>[
        rmSessionProvider.overrideWithValue(session),
        profileRepositoryProvider.overrideWithValue(
          FakeProfileRepository.missing(),
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text('Henüz bir adın yok.'), findsOneWidget);

    await _signOut(tester);

    expect(session.state.value, isA<RmSignedOut>());
  });

  /// Setup is the only screen a member without a profile reaches, so it is
  /// the only way out for somebody who signed in with the wrong number.
  testWidgets('from profile setup', (WidgetTester tester) async {
    final FakeSession session = FakeSession();
    await _pumpApp(
      tester,
      session: session,
      profile: FakeProfileRepository.missing(),
    );

    expect(find.byType(ProfileSetupScreen), findsOneWidget);

    await _signOut(tester);

    _expectSignedOut(session);
    expect(find.byType(ProfileSetupScreen), findsNothing);
  });
}
