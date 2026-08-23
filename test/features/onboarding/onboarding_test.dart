import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ridemate/app/providers/session_provider.dart';
import 'package:ridemate/app/router/app_routes.dart';
import 'package:ridemate/core/theme/rm_theme.dart';
import 'package:ridemate/core/widgets/rm_button.dart';
import 'package:ridemate/features/auth/presentation/phone_entry_screen.dart';
import 'package:ridemate/features/onboarding/application/onboarding_controller.dart';
import 'package:ridemate/features/onboarding/data/onboarding_repository.dart';
import 'package:ridemate/features/onboarding/presentation/onboarding_screen.dart';
import 'package:ridemate/l10n/app_localizations.dart';

import '../../support/fakes.dart';
import '../../support/pump.dart';

void main() {
  group('OnboardingController', () {
    test('reports the stored value on first run', () async {
      final InMemoryOnboardingRepository repo = InMemoryOnboardingRepository();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          onboardingRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      expect(
        await container.read(onboardingControllerProvider.future),
        isFalse,
      );
    });

    test('reports true when the intro was completed previously', () async {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          onboardingRepositoryProvider.overrideWithValue(
            InMemoryOnboardingRepository(seen: true),
          ),
          rmSessionProvider.overrideWithValue(FakeSession()),
        ],
      );
      addTearDown(container.dispose);

      expect(await container.read(onboardingControllerProvider.future), isTrue);
    });

    test('markSeen persists and publishes the new state', () async {
      final InMemoryOnboardingRepository repo = InMemoryOnboardingRepository();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          onboardingRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(onboardingControllerProvider.future);
      await container.read(onboardingControllerProvider.notifier).markSeen();

      expect(repo.seen, isTrue);
      expect(container.read(onboardingControllerProvider).requireValue, isTrue);
    });
  });

  group('Onboarding persistence semantics', () {
    test('the stored key is namespaced and named around the intro only', () {
      // The flag must never read as an account, session or identity claim, or
      // a future auth integration will inherit the wrong assumption.
      const String key = SharedPreferencesOnboardingRepository.storageKey;

      expect(key, 'ridemate.onboarding.hasSeenOnboarding');
      for (final String forbidden in <String>[
        'auth',
        'registered',
        'account',
        'session',
        'user',
        'verified',
      ]) {
        expect(
          key.toLowerCase(),
          isNot(contains(forbidden)),
          reason: 'the onboarding flag must not imply "$forbidden"',
        );
      }
    });

    test('the repository exposes nothing beyond the intro flag', () {
      // Guards against the interface quietly growing into an auth surface.
      final InMemoryOnboardingRepository repo = InMemoryOnboardingRepository();
      expect(repo, isA<OnboardingRepository>());
    });
  });

  group('OnboardingScreen', () {
    Future<InMemoryOnboardingRepository> pumpScreen(
      WidgetTester tester, {
      Brightness brightness = Brightness.light,
      TextDirection textDirection = TextDirection.ltr,
      Locale locale = kDefaultTestLocale,
    }) async {
      final InMemoryOnboardingRepository repo = InMemoryOnboardingRepository();
      await tester.pumpRmScreen(
        const OnboardingScreen(),
        brightness: brightness,
        textDirection: textDirection,
        locale: locale,
        surfaceSize: const Size(393, 852),
        overrides: <Override>[
          onboardingRepositoryProvider.overrideWithValue(repo),
        ],
      );
      await tester.pump();
      return repo;
    }

    /// Both CTAs navigate now, so the tapping tests need a real router. Only
    /// the two routes involved are registered: this is testing the screen, not
    /// the application's route table.
    Future<InMemoryOnboardingRepository> pumpInRouter(
      WidgetTester tester,
    ) async {
      final InMemoryOnboardingRepository repo = InMemoryOnboardingRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            onboardingRepositoryProvider.overrideWithValue(repo),
            rmSessionProvider.overrideWithValue(FakeSession.signedOut()),
          ],
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: RmTheme.of(Brightness.light),
            locale: kDefaultTestLocale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: GoRouter(
              initialLocation: AppRoutes.onboardingPath,
              routes: <RouteBase>[
                GoRoute(
                  path: AppRoutes.onboardingPath,
                  name: AppRoutes.onboarding,
                  builder: (BuildContext context, GoRouterState state) =>
                      const OnboardingScreen(),
                ),
                GoRoute(
                  path: AppRoutes.authPhonePath,
                  name: AppRoutes.authPhone,
                  builder: (BuildContext context, GoRouterState state) =>
                      const PhoneEntryScreen(),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      return repo;
    }

    testBothThemes('renders the approved copy', (
      WidgetTester tester,
      Brightness brightness,
    ) async {
      await pumpScreen(tester, brightness: brightness);

      expect(tester.takeException(), isNull);
      // Verbatim from the design source.
      expect(find.text('Hesap oluştur'), findsOneWidget);
      expect(find.text('Zaten üyeyim'), findsOneWidget);
      expect(find.textContaining('Taksi değil — topluluk.'), findsOneWidget);
      // The member count is data, so it is formatted for the locale.
      expect(find.textContaining('12.480'), findsOneWidget);
    });

    testWidgets('renders under RTL without overflow', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, textDirection: TextDirection.rtl);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in English without overflow', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, locale: const Locale('en'));
      expect(tester.takeException(), isNull);
      expect(find.text('Create account'), findsOneWidget);
      expect(find.text("I'm already a member"), findsOneWidget);
    });

    /// Both buttons now record the intro as seen.
    ///
    /// That is not "sign-in became onboarding". The flag records a deliberate
    /// departure from the intro, and choosing either button is one. The router
    /// gives onboarding precedence over authentication, so a CTA that left the
    /// flag false would be redirected straight back here and the member would
    /// tap and watch nothing happen.
    for (final String cta in <String>['Hesap oluştur', 'Zaten üyeyim']) {
      testWidgets('"$cta" records the intro as seen, exactly once', (
        WidgetTester tester,
      ) async {
        final InMemoryOnboardingRepository repo = await pumpInRouter(tester);

        await tester.tap(find.text(cta));
        await tester.pumpAndSettle();

        expect(repo.markCallCount, 1);
        expect(repo.seen, isTrue);
        expect(find.byType(PhoneEntryScreen), findsOneWidget);
      });
    }

    /// The message that stood in for authentication is gone, along with its
    /// copy. Sign-in exists now.
    testWidgets('no "coming soon" message survives', (
      WidgetTester tester,
    ) async {
      await pumpInRouter(tester);

      await tester.tap(find.text('Zaten üyeyim'));
      await tester.pumpAndSettle();

      expect(find.textContaining('yakında'), findsNothing);
    });

    testWidgets('both actions meet the touch target and expose semantics', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      expect(find.byType(RmButton), findsNWidgets(2));
      expect(find.bySemanticsLabel('Hesap oluştur'), findsOneWidget);
      expect(find.bySemanticsLabel('Zaten üyeyim'), findsOneWidget);
    });
  });
}
