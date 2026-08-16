@Tags(<String>['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/theme/rm_theme.dart';
import 'package:ridemate/features/gallery/presentation/gallery_screen.dart';
import 'package:ridemate/l10n/app_localizations.dart';

import '../support/fonts.dart';

/// Golden coverage for the design system.
///
/// These render the debug gallery, which is deliberately the single catalogue
/// of every token, primitive and state — so one baseline per theme guards the
/// whole system against silent visual drift, especially dark-mode drift, which
/// is otherwise invisible until someone opens the app at night.
///
/// HOST-DEPENDENT. Baselines were generated on Linux; font rasterization
/// differs across platforms. Excluded from the default test run — see
/// dart_test.yaml and tool/goldens.sh.
void main() {
  setUpAll(loadRideMateFonts);

  Future<void> pumpGallery(
    WidgetTester tester, {
    required Brightness brightness,
    TextDirection? textDirection,
    Locale locale = const Locale('tr'),
  }) async {
    // A tall surface so the whole catalogue renders in one image.
    await tester.binding.setSurfaceSize(const Size(420, 6400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: RmTheme.of(brightness),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GalleryScreen(forceTextDirection: textDirection),
        ),
      ),
    );

    // RmSkeleton animates forever, so pumpAndSettle would time out. Pump to a
    // fixed point in its cycle instead, which also keeps goldens stable.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('Design system gallery', () {
    testWidgets('light', (WidgetTester tester) async {
      await pumpGallery(tester, brightness: Brightness.light);
      await expectLater(
        find.byType(GalleryScreen),
        matchesGoldenFile('goldens/design_system_light.png'),
      );
    });

    testWidgets('dark', (WidgetTester tester) async {
      await pumpGallery(tester, brightness: Brightness.dark);
      await expectLater(
        find.byType(GalleryScreen),
        matchesGoldenFile('goldens/design_system_dark.png'),
      );
    });

    testWidgets('right-to-left', (WidgetTester tester) async {
      // Arabic is a declared future locale. This baseline proves the layout is
      // already mirror-safe before any Arabic strings exist.
      await pumpGallery(
        tester,
        brightness: Brightness.light,
        textDirection: TextDirection.rtl,
      );
      await expectLater(
        find.byType(GalleryScreen),
        matchesGoldenFile('goldens/design_system_rtl.png'),
      );
    });

    testWidgets('english', (WidgetTester tester) async {
      // Guards the locale-dependent formatting: 94% and 6.2 km here, versus
      // %94 and 6,2 km in the Turkish baselines.
      await pumpGallery(
        tester,
        brightness: Brightness.light,
        locale: const Locale('en'),
      );
      await expectLater(
        find.byType(GalleryScreen),
        matchesGoldenFile('goldens/design_system_en.png'),
      );
    });
  });
}
