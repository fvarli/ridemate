// ─────────────────────────────────────────────────────────────
// RideMate — Startup surface
//
// Rendered only while the locally stored onboarding flag is being read.
//
// It exists so `main()` can stay synchronous — no I/O before the first frame —
// while still guaranteeing that neither Onboarding nor Home flashes before the
// stored value is known. Reading one boolean takes single-digit milliseconds,
// so this is normally invisible.
//
// It is launch scaffolding, deliberately NOT product UI: nothing but the
// themed background. No logo, no spinner, no copy — anything more would be
// inventing a splash screen that was never designed.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../core/theme/tokens/rm_colors.dart';
import '../l10n/app_localizations.dart';

/// A visually neutral surface shown while startup state resolves.
class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.rmColors.background,
      // Announced as loading so a screen reader is not left on a silent
      // screen, however briefly.
      child: Semantics(
        label: AppLocalizations.of(context).commonLoading,
        child: const SizedBox.expand(),
      ),
    );
  }
}
