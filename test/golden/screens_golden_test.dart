@Tags(<String>['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/theme/rm_theme.dart';
import 'package:ridemate/features/home/presentation/home_screen.dart';
import 'package:ridemate/features/onboarding/application/onboarding_controller.dart';
import 'package:ridemate/features/onboarding/presentation/onboarding_screen.dart';
import 'package:ridemate/features/verification/presentation/verification_screen.dart';
import 'package:ridemate/l10n/app_localizations.dart';

import '../support/fakes.dart';
import '../support/fonts.dart';

/// Golden coverage for the Phase 2 product screens.
///
/// Each screen is captured in light and dark, and Home additionally in RTL
/// because it is the most layout-dense of the three. Dark is covered for every
/// screen deliberately: dark-mode drift is otherwise invisible until someone
/// opens the app at night.
///
/// HOST-DEPENDENT. Baselines were generated on Linux; font rasterization
/// differs across platforms. Excluded from the default run — see
/// dart_test.yaml and tool/goldens.sh.
void main() {
  setUpAll(loadRideMateFonts);

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    required Brightness brightness,
    TextDirection textDirection = TextDirection.ltr,
  }) async {
    // A representative modern phone.
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          // Seed the intro as complete so nothing redirects mid-capture.
          onboardingRepositoryProvider.overrideWithValue(
            InMemoryOnboardingRepository(seen: true),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: RmTheme.of(brightness),
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Directionality(textDirection: textDirection, child: screen),
        ),
      ),
    );

    // Fixed frames rather than pumpAndSettle: some surfaces animate forever
    // by design, and a fixed point also keeps the baselines stable.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('Onboarding', () {
    for (final Brightness brightness in Brightness.values) {
      testWidgets(brightness.name, (WidgetTester tester) async {
        await pump(tester, const OnboardingScreen(), brightness: brightness);
        await expectLater(
          find.byType(OnboardingScreen),
          matchesGoldenFile('goldens/onboarding_${brightness.name}.png'),
        );
      });
    }
  });

  group('Verification', () {
    for (final Brightness brightness in Brightness.values) {
      testWidgets(brightness.name, (WidgetTester tester) async {
        await pump(tester, const VerificationScreen(), brightness: brightness);
        await expectLater(
          find.byType(VerificationScreen),
          matchesGoldenFile('goldens/verification_${brightness.name}.png'),
        );
      });
    }
  });

  group('Home', () {
    for (final Brightness brightness in Brightness.values) {
      testWidgets(brightness.name, (WidgetTester tester) async {
        await pump(
          tester,
          const Scaffold(body: HomeScreen()),
          brightness: brightness,
        );
        await expectLater(
          find.byType(HomeScreen),
          matchesGoldenFile('goldens/home_${brightness.name}.png'),
        );
      });
    }

    testWidgets('right-to-left', (WidgetTester tester) async {
      // Arabic is a declared future locale; this proves the densest screen is
      // already mirror-safe before any Arabic strings exist.
      await pump(
        tester,
        const Scaffold(body: HomeScreen()),
        brightness: Brightness.light,
        textDirection: TextDirection.rtl,
      );
      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('goldens/home_rtl.png'),
      );
    });
  });
}
