import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/app/app_shell.dart';
import 'package:ridemate/app/providers/app_preferences_provider.dart';
import 'package:ridemate/app/ride_mate_app.dart';
import 'package:ridemate/app/router/app_router.dart';
import 'package:ridemate/app/router/app_routes.dart';
import 'package:ridemate/core/a11y/rm_a11y.dart';
import 'package:ridemate/core/theme/rm_theme.dart';
import 'package:ridemate/core/widgets/rm_icon_button.dart';
import 'package:ridemate/core/widgets/rm_nav_bar.dart';
import 'package:ridemate/features/create_route/presentation/create_route_screen.dart';
import 'package:ridemate/features/discovery/presentation/search_screen.dart';
import 'package:ridemate/features/gallery/presentation/gallery_screen.dart';
import 'package:ridemate/features/home/presentation/home_screen.dart';
import 'package:ridemate/features/onboarding/application/onboarding_controller.dart';
import 'package:ridemate/l10n/app_localizations.dart';

import '../support/fakes.dart';

Future<ProviderContainer> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  // The shell is only reachable once the intro has been completed, so seed
  // that. It says nothing about accounts or authentication.
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
  return ProviderScope.containerOf(tester.element(find.byType(RideMateApp)));
}

/// Finds a destination inside the navigation bar.
///
/// Scoped because Home renders its own "Ara" action, which would otherwise
/// make a bare text finder ambiguous.
/// The gallery's own scroll view.
///
/// Scoped because Home's shortcut row is also a ListView and stays mounted in
/// the shell's IndexedStack, which would make a bare ListView finder
/// ambiguous.
Finder get _galleryList => find
    .descendant(of: find.byType(GalleryScreen), matching: find.byType(ListView))
    .first;

Finder _navTab(String label) =>
    find.descendant(of: find.byType(RmNavBar), matching: find.text(label));

void main() {
  group('Application shell', () {
    testWidgets('opens on the home branch with the navigation bar', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester);

      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(RmNavBar), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('shows the four design destinations and the centre action', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await _pumpApp(tester);
      container.read(localeProvider.notifier).set(const Locale('tr'));
      await tester.pumpAndSettle();

      // Verbatim from the design's tab bar. Scoped to the bar because Home
      // also renders an "Ara" action inside its search field.
      for (final String label in <String>[
        'Anasayfa',
        'Ara',
        'Mesajlar',
        'Profil',
      ]) {
        expect(
          find.descendant(
            of: find.byType(RmNavBar),
            matching: find.text(label),
          ),
          findsOneWidget,
          reason: label,
        );
      }
      expect(find.byType(RmFab), findsOneWidget);
    });

    testWidgets('switches branches on tap', (WidgetTester tester) async {
      final ProviderContainer container = await _pumpApp(tester);
      container.read(localeProvider.notifier).set(const Locale('en'));
      await tester.pumpAndSettle();

      await tester.tap(_navTab('Search'));
      await tester.pumpAndSettle();
      expect(find.byType(SearchScreen), findsOneWidget);

      await tester.tap(_navTab('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Phase 6 — Profile / Trust'), findsOneWidget);
    });

    testWidgets('branch state is preserved across tab switches', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await _pumpApp(tester);
      container.read(localeProvider.notifier).set(const Locale('en'));
      await tester.pumpAndSettle();

      // Branches build lazily, then stay mounted. After visiting all four,
      // every one remains in the tree — that is what preserves scroll
      // position and in-progress input once the screens are real.
      for (final String label in <String>[
        'Search',
        'Messages',
        'Profile',
        'Home',
      ]) {
        await tester.tap(_navTab(label));
        await tester.pumpAndSettle();
      }

      // Home and Search are real screens now; Messages and Profile are still
      // placeholders.
      expect(
        find.byType(PlaceholderScreen, skipOffstage: false),
        findsNWidgets(2),
      );
      for (final Type screen in <Type>[HomeScreen, SearchScreen]) {
        expect(
          find.byType(screen, skipOffstage: false),
          findsOneWidget,
          reason: '$screen stays mounted once visited',
        );
      }
    });

    testWidgets('the centre action pushes over the shell and pops back', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await _pumpApp(tester);
      container.read(localeProvider.notifier).set(const Locale('en'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(RmFab));
      await tester.pumpAndSettle();
      expect(find.byType(CreateRouteScreen), findsOneWidget);
      // Pushed over the shell, so the navigation bar is gone.
      expect(find.byType(RmNavBar), findsNothing);

      await tester.tap(find.bySemanticsLabel('Back').first);
      await tester.pumpAndSettle();
      expect(find.byType(CreateRouteScreen), findsNothing);
      expect(find.byType(RmNavBar), findsOneWidget);
    });

    testWidgets('navigation items meet the touch floor', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester);

      final Iterable<Element> items = find
          .descendant(
            of: find.byType(RmNavBar),
            matching: find.byType(InkResponse),
          )
          .evaluate();
      expect(items, isNotEmpty);
      for (final Element e in items) {
        expect(
          e.size!.height,
          greaterThanOrEqualTo(RmA11y.minTouchTarget),
          reason: 'a navigation destination is too small to tap',
        );
      }
    });
  });

  group('Router', () {
    testWidgets('is provided through Riverpod, not a global', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await _pumpApp(tester);
      expect(container.read(routerProvider), isNotNull);
      // Reading twice returns the same instance rather than rebuilding.
      expect(
        container.read(routerProvider),
        same(container.read(routerProvider)),
      );
    });

    testWidgets('routes by name, and the gallery is reachable in debug', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await _pumpApp(tester);

      container.read(routerProvider).goNamed(AppRoutes.gallery);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(GalleryScreen), findsOneWidget);
    });

    testWidgets('deep links resolve to the right branch', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await _pumpApp(tester);
      container.read(localeProvider.notifier).set(const Locale('en'));
      await tester.pumpAndSettle();

      container.read(routerProvider).go(AppRoutes.messagesPath);
      await tester.pumpAndSettle();
      expect(find.text('Conversation list — not designed yet'), findsOneWidget);
    });
  });

  group('Gallery (debug-only developer tooling)', () {
    testWidgets('renders every section without exceptions in both themes', (
      WidgetTester tester,
    ) async {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final ProviderContainer container = await _pumpApp(tester);
        container.read(themeModeProvider.notifier).set(mode);
        container.read(routerProvider).goNamed(AppRoutes.gallery);
        // RmSkeleton animates indefinitely, so pumpAndSettle would time out
        // on this screen. Pump a fixed number of frames instead.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull, reason: '\$mode');
        expect(find.byType(GalleryScreen), findsOneWidget);

        // Scroll the whole catalogue so every specimen actually builds.
        for (int i = 0; i < 6; i++) {
          await tester.drag(_galleryList, const Offset(0, -1200));
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(tester.takeException(), isNull, reason: '\$mode after scroll');
      }
    });

    testWidgets('renders under RTL without overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: RmTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: const GalleryScreen(forceTextDirection: TextDirection.rtl),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      for (int i = 0; i < 6; i++) {
        await tester.drag(_galleryList, const Offset(0, -1200));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull, reason: 'RTL after scroll');
    });
  });
}
