import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/a11y/rm_a11y.dart';
import '../core/theme/rm_theme.dart';
import '../core/theme/tokens/rm_colors.dart';
import '../l10n/app_localizations.dart';
import 'providers/app_preferences_provider.dart';
import 'router/app_router.dart';

/// Root widget of the RideMate application.
///
/// Supplies the light and dark themes and lets Flutter resolve brightness via
/// [ThemeMode], rather than resolving it manually — RideMate renders light
/// surfaces over dark ones, so every widget must read the palette of its own
/// subtree.
///
/// Also the one place the release error widget is installed. In debug and
/// under test the framework's red error box stays exactly as it is, because
/// that box is how a broken build announces itself to a developer.
class RideMateApp extends ConsumerWidget {
  const RideMateApp({super.key});

  /// Shown in the OS task switcher. Not localized — it is the product name.
  static const String appTitle = 'RideMate';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _installReleaseErrorWidget();

    final ThemeMode themeMode = ref.watch(themeModeProvider);
    final Locale? locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: RmTheme.light,
      darkTheme: RmTheme.dark,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveLocale,
      builder: _applyTextScaleCeiling,
      routerConfig: ref.watch(routerProvider),
    );
  }

  /// Replaces the framework's error box in release builds only.
  ///
  /// The default box prints the exception onto the screen. In debug that is
  /// exactly right; shipped, it shows a member a stack frame they cannot act
  /// on. The error itself is already recorded by [installRmErrorHandlers] —
  /// this only changes what is drawn in its place.
  static void _installReleaseErrorWidget() {
    if (!kReleaseMode) return;
    ErrorWidget.builder = (FlutterErrorDetails details) =>
        const _ReleaseErrorBox();
  }

  /// Resolves the device locale against what RideMate actually ships.
  ///
  /// Turkish is the default because it is the source product language and
  /// Istanbul is the pilot market; anything we do not translate falls back to
  /// English rather than to a half-translated Turkish UI.
  @visibleForTesting
  static Locale resolveLocale(Locale? device, Iterable<Locale> supported) {
    if (device == null) return const Locale('tr');
    for (final Locale candidate in supported) {
      if (candidate.languageCode == device.languageCode) return candidate;
    }
    return const Locale('en');
  }

  /// Honours the user's text-size preference but caps the extreme end.
  ///
  /// The floor is never raised — scaling down stays fully available. The
  /// ceiling exists so a very large system setting cannot push a safety
  /// control off screen. See [RmA11y.maxTextScale].
  static Widget _applyTextScaleCeiling(BuildContext context, Widget? child) {
    final MediaQueryData mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(
        textScaler: mq.textScaler.clamp(maxScaleFactor: RmA11y.maxTextScale),
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }
}

/// The neutral surface a failed subtree renders as in a release build.
///
/// Deliberately text-free: it sits wherever the failure happened, which may be
/// a 20dp row, and a sentence there would be clipped nonsense. Its job is to
/// not be a stack trace.
class _ReleaseErrorBox extends StatelessWidget {
  const _ReleaseErrorBox();

  @override
  Widget build(BuildContext context) {
    final RmColors? colors = Theme.of(context).extension<RmColors>();
    return ColoredBox(color: colors?.surfaceMuted ?? const Color(0x11000000));
  }
}
