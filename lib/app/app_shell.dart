// ─────────────────────────────────────────────────────────────
// RideMate — Application shell
//
// Hosts the four bottom-navigation branches and the centre action button.
//
// Three of the four branches are real screens. Messages is still a
// PlaceholderScreen, and stays one until a conversation list is designed:
// wiring the tab to the single fixture thread would present a hard-coded
// conversation as the member's whole inbox. See docs/design-system.md §8.
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

    return PopScope(
      // System back on a secondary tab should return to Home, not leave the
      // app. Without this every tab exits on the first back press.
      canPop: navigationShell.currentIndex == _homeBranchIndex,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        navigationShell.goBranch(_homeBranchIndex);
      },
      child: _buildScaffold(context, l10n),
    );
  }

  /// The Home branch, which system back falls through to.
  static const int _homeBranchIndex = 0;

  Widget _buildScaffold(BuildContext context, AppLocalizations l10n) {
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
