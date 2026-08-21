// ─────────────────────────────────────────────────────────────
// RideMate — Routing error surface
//
// What go_router shows when it cannot resolve a location. Its own default is
// an unthemed, unlocalized page that prints the exception and the attempted
// path; this replaces it with a RideMate screen.
//
// NOTHING DIAGNOSTIC REACHES THE MEMBER. No exception text, no stack trace,
// no attempted route, no path, no error code. Those are the report's job, not
// the screen's — a member cannot act on any of them, and each one tells
// whoever is looking at a stranger's phone something about the app's insides.
//
// The screen offers one recovery action, and only because it genuinely works:
// Home always exists. An action that might not resolve would be a second
// failure presented as a fix.
//
// The design source contains no error state at all (design-system.md §8), so
// this is extrapolated from the token language and uses the same
// RmInlineMessage vocabulary the other non-designed states use.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/rm_theme.dart';
import '../../core/theme/tokens/rm_colors.dart';
import '../../core/theme/tokens/rm_spacing.dart';
import '../../core/theme/tokens/rm_typography.dart';
import '../../core/widgets/rm_button.dart';
import '../../core/widgets/rm_list_row.dart';
import '../../l10n/app_localizations.dart';
import '../router/app_routes.dart';

/// Shown when navigation fails.
class AppErrorScreen extends StatelessWidget {
  const AppErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: c.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: RmTheme.overlayStyleFor(Theme.of(context).brightness),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(RmSpacing.screenGutter),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  l10n.errorTitle,
                  style: RmTypography.titleSm.copyWith(color: c.ink),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: RmSpacing.md),
                RmInlineMessage(message: l10n.errorBody),
                const SizedBox(height: RmSpacing.xl),
                RmButton(
                  label: l10n.errorReturnHome,
                  onPressed: () => context.goNamed(AppRoutes.home),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
