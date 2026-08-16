import 'package:flutter/material.dart';

import '../core/a11y/rm_a11y.dart';
import '../core/theme/rm_theme.dart';

/// Root widget of the RideMate application.
///
/// Supplies the light and dark themes and lets Flutter resolve brightness via
/// [ThemeMode], rather than resolving it manually — RideMate renders light
/// surfaces over dark ones, so every widget must read the palette of its own
/// subtree.
///
/// Routing, localization and the application shell attach here in the
/// remaining Phase 1 steps. There are still no product screens.
class RideMateApp extends StatelessWidget {
  const RideMateApp({super.key, this.themeMode = ThemeMode.system});

  /// Shown in the OS task switcher until localization lands.
  static const String appTitle = 'RideMate';

  /// Which theme to apply. Driven by a provider once state is wired in.
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: RmTheme.light,
      darkTheme: RmTheme.dark,
      themeMode: themeMode,
      builder: _applyTextScaleCeiling,
      home: const _BootstrapPlaceholder(),
    );
  }

  /// Honours the user's text-size preference but caps the extreme end.
  ///
  /// The floor is never raised — scaling down stays fully available. The
  /// ceiling exists so a 200% system setting cannot push a safety control off
  /// screen. See [RmA11y.maxTextScale].
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

/// Temporary placeholder proving the app boots and the theme resolves.
///
/// Replaced by the application shell later in Phase 1.
class _BootstrapPlaceholder extends StatelessWidget {
  const _BootstrapPlaceholder();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Text(RideMateApp.appTitle, style: theme.textTheme.displaySmall),
      ),
    );
  }
}
