// ─────────────────────────────────────────────────────────────
// RideMate — Selector tile and stat tile
//
// Source of truth: docs/claude-designs/RideMate App.dc.html (immutable).
//
// Two small bordered tiles the design reuses across screens:
//
//   RmSelectorTile  an uppercase eyebrow over a value — Search's "NE ZAMAN"
//                   and "KOLTUK", and Create Route's equivalents.
//   RmStatTile      a centred mono figure over a caption — Route Details'
//                   three-up trust row, and Profile's three-up.
//
// Both show numbers that came from somewhere else. Neither computes anything.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../theme/tokens/rm_colors.dart';
import '../theme/tokens/rm_radius.dart';
import '../theme/tokens/rm_shadows.dart';
import '../theme/tokens/rm_sizing.dart';
import '../theme/tokens/rm_spacing.dart';
import '../theme/tokens/rm_typography.dart';

/// An eyebrow label over a selected value, in a bordered tile.
class RmSelectorTile extends StatelessWidget {
  const RmSelectorTile({
    required this.label,
    required this.value,
    super.key,
    this.onTap,
    this.width,
  });

  /// Uppercase eyebrow, e.g. `NE ZAMAN`.
  final String label;

  /// The current selection, already localized and formatted.
  final String value;

  /// Null renders the tile as display-only.
  final VoidCallback? onTap;

  /// Fixed width. The design pins the seat tile and lets the date tile flex.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: RmTypography.overline.copyWith(color: c.faint),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: RmSpacing.xxs),
        Text(
          value,
          style: RmTypography.body.copyWith(color: c.ink),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    final Widget tile = Container(
      width: width,
      padding: const EdgeInsets.symmetric(
        horizontal: RmSpacing.lg,
        vertical: RmSpacing.md,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: RmRadius.brLg,
        border: Border.all(color: c.border, width: RmSizing.borderWidth),
      ),
      child: content,
    );

    if (onTap == null) return tile;

    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      label: '$label: $value',
      child: Material(
        color: Colors.transparent,
        borderRadius: RmRadius.brLg,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: RmRadius.brLg,
          splashColor: c.primarySoft,
          child: tile,
        ),
      ),
    );
  }
}

/// A centred figure over a caption — the design's trust/summary tile.
///
/// The value is rendered in the mono family because it is data, per the
/// design system's prose/data split. It is displayed, never derived.
class RmStatTile extends StatelessWidget {
  const RmStatTile({
    required this.value,
    required this.caption,
    super.key,
    this.valueColor,
    this.elevated = true,
  });

  /// Already-formatted figure, e.g. `92`, `%98`, `3.4k`.
  final String value;

  final String caption;

  /// Defaults to the palette ink; the design tints some values.
  final Color? valueColor;

  /// The design elevates the Route Details row and leaves Profile's flat.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return Semantics(
      container: true,
      label: '$value $caption',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: RmSpacing.sm,
          vertical: RmSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: RmRadius.brLg,
          border: Border.all(color: c.border, width: RmSizing.borderWidth),
          boxShadow: elevated ? context.rmShadows.cardRaised : RmShadows.none,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FittedBox(
              child: Text(
                value,
                style: RmTypography.numericMd.copyWith(
                  color: valueColor ?? c.ink,
                ),
                maxLines: 1,
              ),
            ),
            const SizedBox(height: RmSpacing.xs),
            Text(
              caption,
              style: RmTypography.micro.copyWith(color: c.muted),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
