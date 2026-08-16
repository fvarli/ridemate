import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/app/providers/app_preferences_provider.dart';
import 'package:ridemate/app/ride_mate_app.dart';
import 'package:ridemate/core/theme/tokens/rm_colors.dart';
import 'package:ridemate/features/onboarding/application/onboarding_controller.dart';
import 'package:ridemate/l10n/app_localizations.dart';

import '../support/fakes.dart';

Future<void> _pumpApp(WidgetTester tester) async {
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
}

void main() {
  group('RideMateApp', () {
    testWidgets('boots and renders without exceptions', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('supplies both themes and follows the system by default', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester);

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.theme, isNotNull);
      expect(app.darkTheme, isNotNull);
      expect(app.themeMode, ThemeMode.system);
      expect(app.debugShowCheckedModeBanner, isFalse);
    });

    testWidgets('theme mode provider drives the rendered brightness', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester);
      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(RideMateApp)),
      );

      container.read(themeModeProvider.notifier).set(ThemeMode.dark);
      await tester.pumpAndSettle();

      final BuildContext ctx = tester.element(find.byType(Scaffold).first);
      expect(Theme.of(ctx).brightness, Brightness.dark);
      expect(ctx.rmColors, RmColors.dark);

      container.read(themeModeProvider.notifier).set(ThemeMode.light);
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
        Brightness.light,
      );
    });

    testWidgets('renders in both platform brightnesses', (
      WidgetTester tester,
    ) async {
      for (final Brightness brightness in Brightness.values) {
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(platformBrightness: brightness),
            child: ProviderScope(
              overrides: <Override>[
                onboardingRepositoryProvider.overrideWithValue(
                  InMemoryOnboardingRepository(seen: true),
                ),
              ],
              child: const RideMateApp(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'RideMateApp threw under $brightness',
        );
      }
    });
  });

  group('RideMateApp localization', () {
    testWidgets('ships Turkish and English', (WidgetTester tester) async {
      await _pumpApp(tester);
      final MaterialApp app = tester.widget(find.byType(MaterialApp));

      expect(
        app.supportedLocales.map((Locale l) => l.languageCode),
        containsAll(<String>['tr', 'en']),
      );
    });

    testWidgets('Turkish shell copy matches the approved design', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester);
      ProviderScope.containerOf(
        tester.element(find.byType(RideMateApp)),
      ).read(localeProvider.notifier).set(const Locale('tr'));
      await tester.pumpAndSettle();

      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(Scaffold).first),
      );

      // Verbatim from the design source's bottom navigation bar.
      expect(l10n.navHome, 'Anasayfa');
      expect(l10n.navSearch, 'Ara');
      expect(l10n.navMessages, 'Mesajlar');
      expect(l10n.navProfile, 'Profil');
      expect(l10n.navCreateRoute, 'Rota oluştur');
    });

    testWidgets('follows the device locale when no override is set', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester);

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(
        app.locale,
        isNull,
        reason: 'no override until the user picks one',
      );
    });

    testWidgets('locale provider switches the active translations', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester);
      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(RideMateApp)),
      );

      container.read(localeProvider.notifier).set(const Locale('en'));
      await tester.pumpAndSettle();
      expect(
        AppLocalizations.of(
          tester.element(find.byType(Scaffold).first),
        ).navHome,
        'Home',
      );

      container.read(localeProvider.notifier).set(const Locale('tr'));
      await tester.pumpAndSettle();
      expect(
        AppLocalizations.of(
          tester.element(find.byType(Scaffold).first),
        ).navHome,
        'Anasayfa',
      );
    });

    test('locale resolution prefers Turkish, falls back to English', () {
      const List<Locale> supported = <Locale>[Locale('tr'), Locale('en')];

      // No device locale at all -> the source product language.
      expect(RideMateApp.resolveLocale(null, supported), const Locale('tr'));
      // A supported language matches regardless of region.
      expect(
        RideMateApp.resolveLocale(const Locale('tr', 'TR'), supported),
        const Locale('tr'),
      );
      expect(
        RideMateApp.resolveLocale(const Locale('en', 'US'), supported),
        const Locale('en'),
      );
      // An untranslated language falls back to English rather than to a
      // half-translated Turkish UI.
      expect(
        RideMateApp.resolveLocale(const Locale('de'), supported),
        const Locale('en'),
      );
      expect(
        RideMateApp.resolveLocale(const Locale('ar'), supported),
        const Locale('en'),
      );
    });
  });
}
