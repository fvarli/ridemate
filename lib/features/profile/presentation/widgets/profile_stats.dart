// ─────────────────────────────────────────────────────────────
// RideMate — Profile stat row
//
// Source: "PROFILE · TRUST" (immutable). Three flat tiles: journeys, rating,
// savings.
//
// The comp draws them three-up in a 276px board. `₺2.1k` is five mono glyphs,
// and at the maximum text scale three of these no longer fit across a 360dp
// screen. They stack rather than shrink — the figure is the whole content of
// the tile, so shrinking it to fit defeats the tile (D-profile-3, following
// D-trip-3).
// ─────────────────────────────────────────────────────────────

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/format/rm_formatters.dart';
import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_selector_tile.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/profile_snapshot.dart';

/// The three summary tiles.
class ProfileStats extends StatelessWidget {
  const ProfileStats({required this.snapshot, super.key});

  final ProfileSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmFormatters f = RmFormatters.of(context);

    final List<(String, String, Color)> tiles = <(String, String, Color)>[
      (f.count(snapshot.tripCount), l10n.profileStatTrips, c.ink),
      (f.rating(snapshot.rating), l10n.profileStatRating, c.warning),
      (snapshot.savingsLabel, l10n.profileStatSavings, c.success),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double widest = _widestTile(context, tiles);
        final double available =
            constraints.maxWidth - RmSpacing.md * (tiles.length - 1);
        final bool across = widest * tiles.length <= available;

        final List<Widget> children = <Widget>[
          for (final (String, String, Color) tile in tiles)
            _tile(tile, across: across),
        ];

        return across
            // IntrinsicHeight so the tiles match each other's height without
            // demanding an infinite one from the surrounding list.
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _spaced(children, horizontal: true),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: _spaced(children, horizontal: false),
              );
      },
    );
  }

  Widget _tile((String, String, Color) tile, {required bool across}) {
    final Widget stat = RmStatTile(
      value: tile.$1,
      caption: tile.$2,
      valueColor: tile.$3,
      // The comp leaves Profile's tiles flat; Route Details raises its own.
      elevated: false,
    );
    return across ? Expanded(child: stat) : stat;
  }

  static List<Widget> _spaced(List<Widget> tiles, {required bool horizontal}) {
    return <Widget>[
      for (int i = 0; i < tiles.length; i++) ...<Widget>[
        if (i > 0)
          horizontal
              ? const SizedBox(width: RmSpacing.md)
              : const SizedBox(height: RmSpacing.md),
        tiles[i],
      ],
    ];
  }

  /// The width the widest tile needs before RmStatTile starts shrinking its
  /// figure to fit.
  static double _widestTile(
    BuildContext context,
    List<(String, String, Color)> tiles,
  ) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final TextDirection direction = Directionality.of(context);

    double widest = 0;
    for (final (String, String, Color) tile in tiles) {
      widest = math.max(
        widest,
        math.max(
          _measure(tile.$1, RmTypography.numericMd, scaler, direction),
          _measure(tile.$2, RmTypography.micro, scaler, direction),
        ),
      );
    }
    // RmStatTile pads sm on each side.
    return (widest + RmSpacing.sm * 2).ceilToDouble();
  }

  static double _measure(
    String text,
    TextStyle style,
    TextScaler scaler,
    TextDirection direction,
  ) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final double width = painter.width;
    painter.dispose();
    return width;
  }
}
