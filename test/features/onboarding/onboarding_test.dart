import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ridemate/app/providers/session_provider.dart';
import 'package:ridemate/app/router/app_routes.dart';
import 'package:ridemate/core/theme/rm_theme.dart';
import 'package:ridemate/core/widgets/rm_avatar.dart';
import 'package:ridemate/core/widgets/rm_button.dart';
import 'package:ridemate/features/auth/presentation/phone_entry_screen.dart';
import 'package:ridemate/features/onboarding/application/onboarding_controller.dart';
import 'package:ridemate/features/onboarding/data/onboarding_repository.dart';
import 'package:ridemate/features/onboarding/presentation/onboarding_screen.dart';
import 'package:ridemate/features/profile/application/my_profile_providers.dart';
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
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
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
            profileRepositoryProvider.overrideWithValue(
              FakeProfileRepository(),
            ),
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

  /// CARRIES WEIGHT. The intro claims no membership it cannot count.
  ///
  /// The design's community-proof card read "12.480 doğrulanmış üye
  /// İstanbul'da" beside three stacked member avatars. No endpoint counts
  /// verified members, and those three people do not exist, so the unit was
  /// removed rather than restated: the guard is written against the CLASS of
  /// claim, not against the one number, because "binlerce" and a four-star
  /// average are the same assertion in a quieter voice.
  group('Onboarding asserts no adoption', () {
    Future<void> pumpIntro(
      WidgetTester tester, {
      Locale locale = kDefaultTestLocale,
    }) async {
      await tester.pumpRmScreen(
        const OnboardingScreen(),
        locale: locale,
        surfaceSize: const Size(393, 852),
        overrides: <Override>[
          onboardingRepositoryProvider.overrideWithValue(
            InMemoryOnboardingRepository(),
          ),
        ],
      );
      await tester.pump();
    }

    /// Every string the screen renders, including the spans of a `Text.rich`.
    List<String> renderedText(WidgetTester tester) {
      final List<String> out = <String>[];
      for (final Text text in tester.widgetList<Text>(find.byType(Text))) {
        final String? plain = text.data;
        if (plain != null) out.add(plain);
        out.add(text.textSpan?.toPlainText() ?? '');
      }
      return out;
    }

    for (final Locale locale in <Locale>[
      kDefaultTestLocale,
      const Locale('en'),
    ]) {
      testWidgets('no figure is quoted at all in ${locale.languageCode}', (
        WidgetTester tester,
      ) async {
        await pumpIntro(tester, locale: locale);

        // A count is the only thing a digit could be here: the intro shows no
        // price, no distance and no time. So the absence of digits is the
        // whole property, and it survives a reformatted number.
        for (final String line in renderedText(tester)) {
          expect(
            RegExp(r'[0-9]').hasMatch(line),
            isFalse,
            reason: 'the intro quotes a figure: "$line"',
          );
        }
      });

      testWidgets('no adoption or trust claim replaced it in '
          '${locale.languageCode}', (WidgetTester tester) async {
        await pumpIntro(tester, locale: locale);
        final String shown = renderedText(tester).join(' ').toLowerCase();

        for (final String banned in <String>[
          'doğrulanmış üye',
          'verified member',
          'binlerce',
          'thousands',
          'büyüyen topluluk',
          'growing community',
          'üyemiz',
          'our members',
          'katıldı',
          'joined',
          'puan ortalama',
          'average rating',
        ]) {
          expect(
            shown.contains(banned),
            isFalse,
            reason: 'an unsupported claim came back: "$banned"',
          );
        }
      });
    }

    /// The avatars were the other half of the claim: three faces standing in
    /// for members, inside the sheet where the count was. The hero behind the
    /// sheet is a decorative constellation and is not what this watches, so
    /// the assertion is scoped to the sheet's scroll view.
    testWidgets('the sheet shows no member avatars', (
      WidgetTester tester,
    ) async {
      await pumpIntro(tester);

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(RmAvatar),
        ),
        findsNothing,
      );
      // And no anonymous stand-in avatar anywhere: the stacked three carried
      // no initials precisely because they represented nobody.
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is RmAvatar && w.initials.trim().isEmpty,
        ),
        findsNothing,
      );
    });

    /// The copy can come back without the widget: a key is enough.
    test('neither locale carries a social-proof string', () {
      for (final String path in <String>[
        'lib/l10n/app_tr.arb',
        'lib/l10n/app_en.arb',
      ]) {
        final String source = File(path).readAsStringSync();

        expect(
          source.contains('"onboardingSocialProof"'),
          isFalse,
          reason: path,
        );
        for (final String banned in <String>[
          'doğrulanmış üye',
          'verified member',
          'binlerce',
          'thousands of',
        ]) {
          expect(
            source.toLowerCase().contains(banned),
            isFalse,
            reason: '$path: $banned',
          );
        }
      }
    });

    /// And without the copy: a literal in the widget would do it.
    ///
    /// The debug gallery is excluded for the reason it always is — it is a
    /// component specimen sheet, registered only under `kDebugMode`, and its
    /// sample figures are not reachable in a release build.
    test('no release-reachable file names the fabricated count', () {
      final List<String> offenders = <String>[];

      for (final FileSystemEntity entity in Directory(
        'lib',
      ).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.contains('/gallery/')) continue;

        final List<String> lines = entity.readAsLinesSync();
        for (int i = 0; i < lines.length; i++) {
          final String line = lines[i];
          // The prohibition is written down in the header that explains why it
          // is prohibited, so comments are not scanned.
          if (line.trimLeft().startsWith('//')) continue;

          for (final String banned in <String>[
            '12480',
            '12.480',
            '12,480',
            'VerifiedMemberCount',
            'onboardingSocialProof',
          ]) {
            if (line.contains(banned)) {
              offenders.add('${entity.path}:${i + 1} — $banned');
            }
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'the fabricated member count reappeared in the release tree',
      );
    });
  });
}
