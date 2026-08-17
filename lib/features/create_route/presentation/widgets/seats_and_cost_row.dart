// ─────────────────────────────────────────────────────────────
// RideMate — Seats and cost share
//
// Source: docs/claude-designs/RideMate App.dc.html, "CREATE ROUTE" (immutable).
//
// Two tiles side by side. The left one is the only stepper in all fifteen
// approved screens, so — like the recurrence switch — it stays feature-local
// rather than being promoted to core.
//
// The right one has NO CONTROL OF ANY KIND in the design: no stepper, no
// input, no chevron, no tap affordance. That is not an oversight to fix. The
// amount is a fixture captioned `Önerilen · maliyet paylaşımı`, and making
// driver-set cost sharing editable may materially affect how RideMate is
// characterized for regulatory purposes — it needs legal and product review
// first. See create_route_fixtures.dart.
//
// There is deliberately no total: `seats × costShare` would be both a formula
// this layer may not author and a driver-earnings claim the product does not
// make.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/a11y/rm_a11y.dart';
import '../../../../core/a11y/rm_tap_target.dart';
import '../../../../core/format/rm_formatters.dart';
import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_radius.dart';
import '../../../../core/theme/tokens/rm_sizing.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/create_route_fixtures.dart';

/// The seats and cost-share pair.
class SeatsAndCostRow extends StatelessWidget {
  const SeatsAndCostRow({
    required this.seats,
    required this.canDecrement,
    required this.onIncrement,
    required this.onDecrement,
    super.key,
  });

  final int seats;
  final bool canDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    // The two tiles have different natural heights, and `stretch` inside a
    // scroll view demands an infinite one — the trap that bit Route Details.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: SeatsStepper(
              seats: seats,
              canDecrement: canDecrement,
              onIncrement: onIncrement,
              onDecrement: onDecrement,
            ),
          ),
          const SizedBox(width: RmSpacing.md),
          const Expanded(child: CostShareTile()),
        ],
      ),
    );
  }
}

/// A bordered tile with an uppercase eyebrow over its content.
///
/// Shared by both tiles so their padding, radius and border cannot drift apart.
class _FieldTile extends StatelessWidget {
  const _FieldTile({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return RmCard(
      radius: RmRadius.lg,
      padding: const EdgeInsets.all(RmSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: RmTypography.overline.copyWith(color: c.faint),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: RmSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// The free-seat count, with a decrement and an increment control.
class SeatsStepper extends StatelessWidget {
  const SeatsStepper({
    required this.seats,
    required this.canDecrement,
    required this.onIncrement,
    required this.onDecrement,
    super.key,
  });

  final int seats;
  final bool canDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmFormatters f = RmFormatters.of(context);

    // One adjustable node for the whole tile, with the buttons excluded below.
    // Two labelled buttons alone would never announce that the value changed,
    // and doing both patterns would announce it twice.
    return Semantics(
      container: true,
      label: l10n.createRouteSeatsSemanticLabel,
      value: l10n.createRouteSeatsValue(seats),
      increasedValue: l10n.createRouteSeatsValue(seats + 1),
      decreasedValue: canDecrement
          ? l10n.createRouteSeatsValue(seats - 1)
          : null,
      onIncrease: onIncrement,
      // Null at the floor, so assistive tech agrees with the muted control.
      onDecrease: canDecrement ? onDecrement : null,
      child: ExcludeSemantics(
        child: _FieldTile(
          label: l10n.createRouteSeatsLabel,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              // A plain Row, so minus and plus mirror in RTL.
              _StepperButton(
                glyph: '−',
                filled: false,
                onTap: canDecrement ? onDecrement : null,
              ),
              Flexible(
                child: FittedBox(
                  child: Text(
                    f.count(seats),
                    style: RmTypography.numericMd.copyWith(color: c.ink),
                  ),
                ),
              ),
              _StepperButton(glyph: '+', filled: true, onTap: onIncrement),
            ],
          ),
        ),
      ),
    );
  }
}

/// One increment or decrement control.
///
/// The glyphs are text, exactly as the design draws them — `−` is U+2212, and
/// both it and `+` are present in every bundled Manrope weight, so neither can
/// fall back to tofu the way U+2605 did.
///
/// DEVIATION D-create-4: the muted disabled treatment is invented. The source
/// draws only the enabled control, and a control that looks tappable but
/// silently does nothing is the worst of the available options.
class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.glyph,
    required this.filled,
    required this.onTap,
  });

  final String glyph;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final bool enabled = onTap != null;

    final Color background = filled
        ? (enabled ? c.primary : c.primarySoft)
        : c.surface;
    final Color foreground = filled
        ? (enabled ? c.onPrimary : c.disabled)
        : (enabled ? c.sub : c.disabled);

    // Visually 44 per RmSizing.stepperButton; the tap area reaches the 48dp
    // floor through RmTapTarget without changing how large it looks.
    return RmTapTarget(
      onTap: onTap,
      size: RmA11y.minTouchTarget,
      child: Container(
        width: RmSizing.stepperButton,
        height: RmSizing.stepperButton,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: RmRadius.brXs,
          border: filled
              ? null
              : Border.all(
                  color: enabled ? c.border : c.hairline,
                  width: RmSizing.borderWidth,
                ),
        ),
        child: Text(
          glyph,
          style: RmTypography.titleMd.copyWith(color: foreground),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// The suggested per-person cost share. Read-only, on purpose.
class CostShareTile extends StatelessWidget {
  const CostShareTile({super.key});

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmFormatters f = RmFormatters.of(context);

    final String amount = f.money(kSuggestedCostSharePerPerson);

    // One merged read-only node, with no `button` — so assistive tech agrees
    // with the visual that this is data, not an unfinished control. There is
    // no InkWell, no ripple and no chevron for the same reason; the green
    // `Önerilen` caption is what carries the meaning.
    return Semantics(
      container: true,
      readOnly: true,
      label: l10n.createRouteCostShareSemanticLabel(amount),
      excludeSemantics: true,
      child: _FieldTile(
        label: l10n.createRouteCostShareLabel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FittedBox(
              child: Text(
                amount,
                style: RmTypography.numericLg.copyWith(color: c.ink),
              ),
            ),
            const SizedBox(height: RmSpacing.xs),
            Text(
              l10n.createRouteCostShareCaption,
              style: RmTypography.micro.copyWith(color: c.success),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
