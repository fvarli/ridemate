import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/a11y/rm_a11y.dart';
import '../core/theme/rm_theme.dart';
import '../l10n/app_localizations.dart';
import 'providers/app_preferences_provider.dart';

/// Root widget of the RideMate application.
///
/// Supplies the light and dark themes and lets Flutter resolve brightness via
/// [ThemeMode], rather than resolving it manually — RideMate renders light
/// surfaces over dark ones, so every widget must read the palette of its own
/// subtree.
///
/// Routing and the application shell attach here in the remaining Phase 1
/// steps. There are still no product screens.
class RideMateApp extends ConsumerWidget {
  const RideMateApp({super.key});

  /// Shown in the OS task switcher. Not localized — it is the product name.
  static const String appTitle = 'RideMate';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    final Locale? locale = ref.watch(localeProvider);

    return MaterialApp(
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
      home: const _BootstrapPlaceholder(),
    );
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

/// Temporary placeholder proving the app boots, the theme resolves and
/// localization is wired.
///
/// Replaced by the application shell later in Phase 1.
class _BootstrapPlaceholder extends StatelessWidget {
  const _BootstrapPlaceholder();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Text(
          AppLocalizations.of(context).appTitle,
          style: theme.textTheme.displaySmall,
        ),
      ),
    );
  }
}
