// ─────────────────────────────────────────────────────────────
// RideMate — Bottom navigation bar
//
// Source of truth: docs/claude-designs/RideMate App.dc.html (immutable).
//
// The source's tab bar is 5 slots: 4 labelled destinations with a centre
// action button between them. Active and inactive differ only by colour and
// weight (700 vs 600) — there is no indicator pill and no ripple.
//
// Height is clamped to 64 plus the safe-area inset (a literal scale of the
// source's 72px would be 102). The FAB protrudes above the bar, as it does in
// the design.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../theme/tokens/rm_colors.dart';
import '../theme/tokens/rm_sizing.dart';
import '../theme/tokens/rm_spacing.dart';
import '../theme/tokens/rm_typography.dart';
import 'rm_icon.dart';
import 'rm_icon_button.dart';

/// One bottom-navigation destination.
@immutable
class RmNavDestination {
  const RmNavDestination({required this.icon, required this.label});

  /// Icon asset from [RmIcons].
  final String icon;

  /// Localized label.
  final String label;
}

/// The bottom navigation bar, with a centre action button.
class RmNavBar extends StatelessWidget {
  const RmNavBar({
    required this.destinations,
    required this.currentIndex,
    required this.onSelected,
    super.key,
    this.actionIcon,
    this.actionLabel,
    this.onAction,
  });

  /// Exactly four destinations, matching the design.
  final List<RmNavDestination> destinations;

  final int currentIndex;
  final ValueChanged<int> onSelected;

  /// The centre action button. Omitted when null.
  final String? actionIcon;
  final String? actionLabel;
  final VoidCallback? onAction;

  bool get _hasAction =>
      actionIcon != null && actionLabel != null && onAction != null;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    // The action button sits between the second and third destination, as the
    // design's five-slot bar does.
    final int splitAt = destinations.length ~/ 2;

    return Container(
      decoration: BoxDecoration(
        color: c.navBar,
        border: Border(
          top: BorderSide(color: c.hairline, width: RmSizing.borderWidth),
        ),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: RmSizing.navBarHeight,
        child: Row(
          children: <Widget>[
            for (int i = 0; i < destinations.length; i++) ...<Widget>[
              if (_hasAction && i == splitAt)
                _ActionSlot(
                  icon: actionIcon!,
                  label: actionLabel!,
                  onPressed: onAction!,
                ),
              Expanded(
                child: _NavItem(
                  destination: destinations[i],
                  selected: i == currentIndex,
                  onTap: () => onSelected(i),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final RmNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    // The design signals the active tab with colour and weight only.
    final Color color = selected ? c.primaryText : c.faint;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: RmSizing.iconButtonSm,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RmIcon(destination.icon, size: RmIconSize.lg, color: color),
            const SizedBox(height: RmSpacing.xs),
            Text(
              destination.label,
              style: RmTypography.micro.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Reserves the centre slot and lets the FAB protrude above the bar.
class _ActionSlot extends StatelessWidget {
  const _ActionSlot({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final String icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: RmSizing.fab + RmSpacing.xl,
      child: OverflowBox(
        maxHeight: RmSizing.fab,
        child: RmFab(icon: icon, semanticLabel: label, onPressed: onPressed),
      ),
    );
  }
}
