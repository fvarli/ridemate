// ─────────────────────────────────────────────────────────────
// RideMate — Trust Score breakdown
//
// Source: "PROFILE · TRUST" (immutable). Four rows of label, bar and figure.
//
// DISPLAY ONLY. The bar draws a fill somebody else declared and the figure
// prints a number somebody else declared; neither is derived from the other,
// and nothing here rolls the four rows up into the score above them. See
// profile_snapshot.dart.
//
// The comp fixes the label column at 74px and the value column at 30px. Those
// are artboard measurements of one Turkish string set at one text size, and
// `Güvenilirlik` alone outgrows 74px well before the maximum text scale. So
// the columns are measured instead: one shared width across all four rows, so
// the bars still start on a common axis, and the whole row set drops to a
// stacked layout once the bar can no longer keep a usable width.
// ─────────────────────────────────────────────────────────────

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/format/rm_formatters.dart';
import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_sizing.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_meters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/profile_snapshot.dart';

/// Narrowest a bar may become before the rows stack instead.
///
/// Below this the bar stops reading as a proportion at all, which is the only
/// thing it is there to do.
const double kTrustBarMinWidth = 64;

/// The four breakdown rows.
class TrustBreakdown extends StatelessWidget {
  const TrustBreakdown({required this.factors, super.key});

  final List<TrustFactor> factors;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmFormatters f = RmFormatters.of(context);
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final TextDirection direction = Directionality.of(context);

    final List<String> labels = factors
        .map((TrustFactor factor) => trustFactorLabel(l10n, factor.id))
        .toList(growable: false);
    final List<String> values = factors
        .map((TrustFactor factor) => f.count(factor.value))
        .toList(growable: false);

    final double labelWidth = _widest(
      labels,
      RmTypography.micro,
      scaler,
      direction,
    );
    final double valueWidth = _widest(
      values,
      RmTypography.numericMicro,
      scaler,
      direction,
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double needed =
            labelWidth + valueWidth + RmSpacing.md * 2 + kTrustBarMinWidth;
        final bool inline = needed <= constraints.maxWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < factors.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: RmSpacing.md),
              TrustFactorRow(
                factor: factors[i],
                label: labels[i],
                value: values[i],
                labelWidth: inline ? labelWidth : null,
                valueWidth: inline ? valueWidth : null,
              ),
            ],
          ],
        );
      },
    );
  }

  static double _widest(
    List<String> texts,
    TextStyle style,
    TextScaler scaler,
    TextDirection direction,
  ) {
    double widest = 0;
    for (final String text in texts) {
      final TextPainter painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      widest = math.max(widest, painter.width);
      painter.dispose();
    }
    // Sub-pixel widths make the shared column jitter between builds.
    return widest.ceilToDouble();
  }
}

/// One breakdown row.
///
/// Laid out inline when [labelWidth] and [valueWidth] are given, and stacked
/// — figure beside the label, bar on its own line — when they are not.
class TrustFactorRow extends StatelessWidget {
  const TrustFactorRow({
    required this.factor,
    required this.label,
    required this.value,
    super.key,
    this.labelWidth,
    this.valueWidth,
  });

  final TrustFactor factor;
  final String label;
  final String value;
  final double? labelWidth;
  final double? valueWidth;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);

    final Color fill = switch (factor.tone) {
      TrustFactorTone.complete => c.success,
      TrustFactorTone.standard => c.primary,
      TrustFactorTone.attention => c.warning,
    };

    final Widget labelText = Text(
      label,
      style: RmTypography.micro.copyWith(color: c.sub),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    final Widget valueText = Text(
      value,
      style: RmTypography.numericMicro.copyWith(color: c.ink),
      textAlign: TextAlign.end,
      maxLines: 1,
    );

    final Widget bar = RmLinearMeter(
      progress: factor.meter,
      height: RmSizing.meterHeight,
      color: fill,
    );

    final bool inline = labelWidth != null && valueWidth != null;

    return Semantics(
      container: true,
      // The meter would otherwise announce its fill as a bare number, which
      // reads as a second, different score.
      excludeSemantics: true,
      label: switch (factor.tone) {
        // Amber is the only thing marking this row as needing attention, and
        // colour alone is not an accessible signal.
        TrustFactorTone.attention =>
          l10n.profileTrustFactorAttentionSemanticLabel(label, value),
        _ => l10n.profileTrustFactorSemanticLabel(label, value),
      },
      child: inline
          ? Row(
              children: <Widget>[
                SizedBox(width: labelWidth, child: labelText),
                const SizedBox(width: RmSpacing.md),
                Expanded(child: bar),
                const SizedBox(width: RmSpacing.md),
                SizedBox(width: valueWidth, child: valueText),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(child: labelText),
                    const SizedBox(width: RmSpacing.sm),
                    valueText,
                  ],
                ),
                const SizedBox(height: RmSpacing.sm),
                bar,
              ],
            ),
    );
  }
}

/// The localized name of a breakdown row.
String trustFactorLabel(AppLocalizations l10n, TrustFactorId id) =>
    switch (id) {
      TrustFactorId.identity => l10n.profileTrustFactorIdentity,
      TrustFactorId.community => l10n.profileTrustFactorCommunity,
      TrustFactorId.reliability => l10n.profileTrustFactorReliability,
      TrustFactorId.activity => l10n.profileTrustFactorActivity,
    };
