// ─────────────────────────────────────────────────────────────
// RideMate — Application shell
//
// Hosts the four bottom-navigation branches and the centre action button.
//
// PHASE 1 SCOPE: the branches render bare placeholders. No product screen,
// no mock data, no product layout. Phases 2-6 replace each placeholder with
// the real screen; nothing else about the shell needs to change.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/icons/rm_icons.dart';
import '../core/theme/tokens/rm_colors.dart';
import '../core/theme/tokens/rm_spacing.dart';
import '../core/theme/tokens/rm_typography.dart';
import '../core/widgets/rm_nav_bar.dart';
import '../l10n/app_localizations.dart';
import 'router/app_routes.dart';

/// Scaffold wrapping the navigation branches.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: RmNavBar(
        currentIndex: navigationShell.currentIndex,
        onSelected: _goBranch,
        destinations: <RmNavDestination>[
          RmNavDestination(icon: RmIcons.home, label: l10n.navHome),
          RmNavDestination(icon: RmIcons.search, label: l10n.navSearch),
          RmNavDestination(icon: RmIcons.chatBubble, label: l10n.navMessages),
          RmNavDestination(icon: RmIcons.person, label: l10n.navProfile),
        ],
        actionIcon: RmIcons.plus,
        actionLabel: l10n.navCreateRoute,
        onAction: () => context.pushNamed(AppRoutes.createRoute),
      ),
    );
  }

  void _goBranch(int index) {
    // initialLocation:true on a re-tap pops that branch back to its root,
    // which is the behaviour users expect from a tab bar.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

/// A bare placeholder standing in for a screen that a later phase will build.
///
/// Deliberately minimal: a title and a note. It exists to prove navigation,
/// branch state preservation and deep links work — not to preview product UI.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.routeName,
    required this.phase,
    super.key,
    this.showBackButton = false,
  });

  /// The route this placeholder stands in for.
  final String routeName;

  /// Which phase will replace it.
  final String phase;

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return Scaffold(
      appBar: showBackButton
          ? AppBar(
              leading: BackButton(
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: Text(routeName),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(RmSpacing.screenGutter),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  routeName,
                  style: RmTypography.titleLg.copyWith(color: c.ink),
                ),
                const SizedBox(height: RmSpacing.sm),
                Text(
                  phase,
                  style: RmTypography.caption.copyWith(color: c.muted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
