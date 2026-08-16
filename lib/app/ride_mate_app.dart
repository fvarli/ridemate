import 'package:flutter/material.dart';

/// Root widget of the RideMate application.
///
/// Phase 0 deliberately keeps this minimal: it exists so the project has a
/// real, testable entry point and a stable place for Phase 1 to attach the
/// router, the design-token themes and localization. It intentionally does
/// **not** define colors, typography, navigation or product screens — those
/// are Phase 1 concerns and adding them here early would spread design values
/// outside the token layer.
class RideMateApp extends StatelessWidget {
  const RideMateApp({super.key});

  /// Shown in the OS task switcher until localization lands in Phase 1.
  static const String appTitle = 'RideMate';

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      home: _BootstrapPlaceholder(),
    );
  }
}

/// Temporary placeholder screen proving the app boots.
///
/// Replaced in Phase 1 by the themed app shell.
class _BootstrapPlaceholder extends StatelessWidget {
  const _BootstrapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text(RideMateApp.appTitle)));
  }
}
