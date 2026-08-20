// ─────────────────────────────────────────────────────────────
// RideMate — Card
//
// Source of truth: docs/claude-designs/RideMate App.dc.html (immutable).
//
// The source contains 11 distinct card containers, which collapse into the
// five variants below; the rest are radius and padding permutations.
//
// Note how `elevated` behaves across themes: in light it carries a shadow, in
// dark the source drops shadows entirely and relies on the 1px border. That is
// handled by RmShadows returning an empty list in dark, so no branching is
// needed here.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../a11y/rm_a11y.dart';
import '../theme/tokens/rm_colors.dart';
import '../theme/tokens/rm_radius.dart';
import '../theme/tokens/rm_shadows.dart';
import '../theme/tokens/rm_sizing.dart';
import '../theme/tokens/rm_spacing.dart';

/// Surface treatment of an [RmCard].
enum RmCardVariant {
  /// Surface fill with a hairline border. The default.
  outlined,

  /// Outlined plus an ambient shadow (light theme only — see the header).
  elevated,

  /// Tinted brand surface with a matching border. Informational panels.
  tinted,

  /// Emphasised border and a brand-tinted glow. The "best match" treatment.
  selected,

  /// Full-bleed gradient. Hero surfaces such as the trust card.
  gradient,
}

/// A RideMate surface.
class RmCard extends StatelessWidget {
  const RmCard({
    required this.child,
    super.key,
    this.variant = RmCardVariant.outlined,
    this.padding = const EdgeInsets.all(RmSpacing.xl),
    this.radius = RmRadius.lg,
    this.onTap,
    this.gradient,
    this.boxShadow,
    this.semanticLabel,
  });

  final Widget child;
  final RmCardVariant variant;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// When non-null the card becomes a button for assistive technology and
  /// grows to at least the minimum touch target.
  final VoidCallback? onTap;

  /// Overrides the gradient for [RmCardVariant.gradient]. Defaults to the
  /// brand hero gradient.
  final Gradient? gradient;

  /// Overrides the variant's shadow.
  ///
  /// The gradient variant assumes the brand hero, so its glow is brand blue.
  /// The design tints the glow to match whatever gradient it draws — the
  /// Safety Center's red SOS card gets a red one.
  final List<BoxShadow>? boxShadow;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final RmShadows s = context.rmShadows;
    final BorderRadius borderRadius = BorderRadius.circular(radius);

    final BoxDecoration decoration = switch (variant) {
      RmCardVariant.outlined => BoxDecoration(
        color: c.surface,
        borderRadius: borderRadius,
        border: Border.all(color: c.border, width: RmSizing.borderWidth),
      ),
      RmCardVariant.elevated => BoxDecoration(
        color: c.surface,
        borderRadius: borderRadius,
        border: Border.all(color: c.border, width: RmSizing.borderWidth),
        boxShadow: s.cardSoft,
      ),
      RmCardVariant.tinted => BoxDecoration(
        color: c.primarySoft,
        borderRadius: borderRadius,
        border: Border.all(
          color: c.primarySoftBorder,
          width: RmSizing.borderWidth,
        ),
      ),
      RmCardVariant.selected => BoxDecoration(
        color: c.surface,
        borderRadius: borderRadius,
        border: Border.all(
          color: c.primary,
          width: RmSizing.borderWidthEmphasis,
        ),
        boxShadow: s.selected,
      ),
      RmCardVariant.gradient => BoxDecoration(
        gradient: gradient ?? c.heroPrimary,
        borderRadius: borderRadius,
        boxShadow: boxShadow ?? s.primary,
      ),
    };

    if (onTap == null) {
      return Semantics(
        label: semanticLabel,
        container: semanticLabel != null,
        // Same reason as the tappable branch below: without this the children
        // merge into the labelled node and a row reads its own title twice.
        excludeSemantics: semanticLabel != null,
        child: Container(
          decoration: decoration,
          padding: padding,
          child: child,
        ),
      );
    }

    return Semantics(
      button: true,
      label: semanticLabel,
      // With an explicit label the children would otherwise be announced a
      // second time, so a row would read its title twice.
      excludeSemantics: semanticLabel != null,
      child: DecoratedBox(
        decoration: decoration,
        child: Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            splashColor: c.primarySoft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: RmA11y.minTouchTarget,
              ),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
