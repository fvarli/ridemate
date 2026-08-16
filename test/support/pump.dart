// ─────────────────────────────────────────────────────────────
// RideMate — Shared widget-test harness
//
// Every widget test pumps through here so it exercises the REAL ThemeData,
// including the RmColors/RmShadows extensions and the component themes. A
// harness that skips `theme:` silently stops testing the theme layer, which
// is exactly the gap this avoids.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/theme/rm_theme.dart';
import 'package:ridemate/core/theme/tokens/rm_colors.dart';
import 'package:ridemate/l10n/app_localizations.dart';

/// A typical phone viewport (Pixel-class device at 3x).
const Size kPhoneSize = Size(1080, 2340);
const double kPhoneDpr = 3;

/// Turkish is the source product language, so it is the harness default.
const Locale kDefaultTestLocale = Locale('tr');

extension RmPumpExtension on WidgetTester {
  /// Pumps [child] inside a real RideMate [MaterialApp].
  ///
  /// [brightness] selects the theme under test; [textDirection] lets a test
  /// assert RTL safety without a separate harness. Localizations are always
  /// wired, so product widgets that read `AppLocalizations` work here.
  Future<void> pumpRm(
    Widget child, {
    Brightness brightness = Brightness.light,
    TextDirection textDirection = TextDirection.ltr,
    TextScaler textScaler = TextScaler.noScaling,
    Size? surfaceSize,
    Locale locale = kDefaultTestLocale,
    List<Override> overrides = const <Override>[],
  }) async {
    if (surfaceSize != null) {
      await binding.setSurfaceSize(surfaceSize);
      addTearDown(() => binding.setSurfaceSize(null));
    }

    await pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: RmTheme.of(brightness),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Directionality(
            textDirection: textDirection,
            child: MediaQuery(
              data: MediaQueryData(textScaler: textScaler),
              child: Scaffold(body: Center(child: child)),
            ),
          ),
        ),
      ),
    );
  }

  /// Pumps a full screen: same wiring as [pumpRm] but without the wrapping
  /// [Scaffold]/[Center], since a screen supplies its own.
  Future<void> pumpRmScreen(
    Widget screen, {
    Brightness brightness = Brightness.light,
    TextDirection textDirection = TextDirection.ltr,
    Locale locale = kDefaultTestLocale,
    List<Override> overrides = const <Override>[],
    Size? surfaceSize,
  }) async {
    if (surfaceSize != null) {
      await binding.setSurfaceSize(surfaceSize);
      addTearDown(() => binding.setSurfaceSize(null));
    }

    await pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: RmTheme.of(brightness),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Directionality(textDirection: textDirection, child: screen),
        ),
      ),
    );
  }

  /// Constrains the viewport to a phone-sized surface for the current test.
  void usefulPhoneViewport() {
    view.physicalSize = kPhoneSize;
    view.devicePixelRatio = kPhoneDpr;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);
  }

  /// The [RmColors] resolved from the pumped theme.
  ///
  /// Lets a test assert against tokens rather than restating hex values.
  RmColors get rmColors =>
      Theme.of(element(find.byType(Scaffold).first)).extension<RmColors>()!;
}

/// Runs [body] for both brightnesses, so a test cannot accidentally cover
/// only one theme.
void testBothThemes(
  String description,
  Future<void> Function(WidgetTester tester, Brightness brightness) body,
) {
  for (final Brightness brightness in Brightness.values) {
    testWidgets('$description (${brightness.name})', (WidgetTester tester) {
      return body(tester, brightness);
    });
  }
}
