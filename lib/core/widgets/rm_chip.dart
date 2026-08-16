// ─────────────────────────────────────────────────────────────
// RideMate — Chips, badges and status pills
//
// Source of truth: docs/claude-designs/RideMate App.dc.html (immutable).
//
// The source uses two different SELECTED fills, deliberately:
//   * brand blue  — trust filters and ride-rule chips (a chosen attribute)
//   * ink navy    — sort chips (a chosen ordering)
// [RmChipTone] preserves that distinction rather than flattening it.
//
// DEVIATION R4: in the source a selected chip has no border while an
// unselected one has a 1px border, so a chip changes size when toggled. Here
// the selected chip carries a transparent 1px border, keeping the geometry
// stable. Logged in docs/design-system.md.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../a11y/rm_a11y.dart';
import '../theme/tokens/rm_colors.dart';
import '../theme/tokens/rm_radius.dart';
import '../theme/tokens/rm_sizing.dart';
import '../theme/tokens/rm_spacing.dart';
import '../theme/tokens/rm_typography.dart';
import 'rm_icon.dart';

/// What a selected [RmChip] means, which drives its fill.
enum RmChipTone {
  /// Brand fill when selected. A chosen attribute: trust filters, ride rules.
  primary,

  /// Ink fill when selected. A chosen ordering: the sort row.
  ink,

  /// Always tinted, never toggled. Review attribute tags, quick replies.
  info,
}

/// A pill-shaped chip.
class RmChip extends StatelessWidget {
  const RmChip({
    required this.label,
    super.key,
    this.onTap,
    this.selected = false,
    this.tone = RmChipTone.primary,
    this.icon,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final RmChipTone tone;

  /// Optional leading icon from [RmIcons].
  final String? icon;

  /// Tighter padding and a smaller label — the sort-row treatment.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    final (Color background, Color foreground, Color borderColor) = switch ((
      tone,
      selected,
    )) {
      (RmChipTone.info, _) => (
        c.primarySoft,
        c.primaryText,
        c.primarySoftBorder,
      ),
      (RmChipTone.primary, true) => (c.primary, c.onPrimary, c.primary),
      (RmChipTone.ink, true) => (c.ink, c.onInk, c.ink),
      // Unselected is identical for both toggleable tones apart from the
      // label colour, which the source mutes on the sort row.
      (RmChipTone.primary, false) => (c.surface, c.ink, c.border),
      (RmChipTone.ink, false) => (c.surface, c.sub, c.border),
    };

    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          RmIcon(icon!, size: RmIconSize.sm, color: foreground),
          const SizedBox(width: RmSpacing.sm),
        ],
        Text(
          label,
          style: (compact ? RmTypography.labelSm : RmTypography.label).copyWith(
            color: foreground,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    final Widget chip = Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: compact ? RmSpacing.lg : RmSpacing.xl,
        vertical: RmSpacing.md,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: RmRadius.brPill,
        // Always bordered so selecting never changes the chip's size.
        border: Border.all(color: borderColor, width: RmSizing.borderWidth),
      ),
      child: content,
    );

    if (onTap == null) {
      return chip;
    }

    return Semantics(
      button: true,
      selected: tone == RmChipTone.info ? null : selected,
      label: label,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: RmA11y.minTouchTarget),
        child: Material(
          color: Colors.transparent,
          borderRadius: RmRadius.brPill,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: RmRadius.brPill,
            splashColor: c.primarySoft,
            child: chip,
          ),
        ),
      ),
    );
  }
}

/// Semantic meaning of an [RmBadge].
enum RmBadgeTone { success, info, warning, danger, neutral, onColor }

/// A small rectangular badge, e.g. a rating or a compatibility score.
///
/// Badges are display-only. Anything tappable is an [RmChip].
class RmBadge extends StatelessWidget {
  const RmBadge({
    required this.label,
    super.key,
    this.tone = RmBadgeTone.success,
    this.icon,
    this.numeric = false,
  });

  final String label;
  final RmBadgeTone tone;

  /// Optional leading icon. Use [RmIcons.starFilled] for ratings — the star
  /// glyph U+2605 is absent from the bundled fonts.
  final String? icon;

  /// Renders the label in the mono family, per the design's rule that all
  /// data is mono.
  final bool numeric;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    final (Color background, Color foreground) = switch (tone) {
      RmBadgeTone.success => (c.successSoft, c.successInk),
      RmBadgeTone.info => (c.primarySoft, c.primaryText),
      RmBadgeTone.warning => (c.warningSoft, c.warningInk),
      RmBadgeTone.danger => (c.dangerSoft, c.danger),
      RmBadgeTone.neutral => (c.surfaceMuted, c.sub),
      // On a coloured header the source uses a translucent white wash.
      RmBadgeTone.onColor => (c.onPrimary.withValues(alpha: 0.2), c.onPrimary),
    };

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: RmSpacing.sm,
        vertical: RmSpacing.xs,
      ),
      decoration: BoxDecoration(color: background, borderRadius: RmRadius.brXs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            RmIcon(icon!, size: RmIconSize.sm, color: foreground),
            const SizedBox(width: RmSpacing.xs),
          ],
          Text(
            label,
            style: (numeric ? RmTypography.numericMicro : RmTypography.micro)
                .copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
