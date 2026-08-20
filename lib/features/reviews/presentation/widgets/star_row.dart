// ─────────────────────────────────────────────────────────────
// RideMate — Star row
//
// Source: "REVIEWS · İTİBAR" (immutable), which prints `★★★★★` literally.
//
// U+2605 is absent from both bundled families, so it ships as five icons
// (D-icon-4). They are one semantics node: five separate announcements say
// nothing a rating does not already say, and the glyph itself must never be
// read out.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/format/rm_formatters.dart';
import '../../../../core/icons/rm_icons.dart';
import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_sizing.dart';
import '../../../../core/widgets/rm_icon.dart';
import '../../../../l10n/app_localizations.dart';

/// How many stars the scale has. The design draws five.
const int kStarCount = 5;

/// A row of filled stars.
class StarRow extends StatelessWidget {
  const StarRow({required this.rating, super.key, this.size = RmIconSize.sm});

  /// Announced, not drawn: the comp fills every star regardless.
  final double rating;

  final double size;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmFormatters f = RmFormatters.of(context);

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: l10n.reviewsRatingSemanticLabel(f.rating(rating)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < kStarCount; i++)
            RmIcon(RmIcons.starFilled, size: size, color: c.warning),
        ],
      ),
    );
  }
}
