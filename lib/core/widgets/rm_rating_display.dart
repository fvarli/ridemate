// ─────────────────────────────────────────────────────────────
// RideMate — Showing a rating somebody else chose
//
// The read-only half of [RmRatingInput], and a separate widget rather than that
// one with its callback removed. A disabled input is still five tap targets and
// five semantics nodes offering choices, which is the wrong shape for a fact
// nobody can change: a screen reader should hear the rating once, as a number
// out of five, not walk five stars to work it out.
//
// DELIBERATELY NOT `StarRow` EITHER
//
// The fixture's row takes a `double` and fills every star regardless of it,
// because the design draws five gold stars beside an invented 4.9. Here the
// number is real and one member's own, so the stars must actually show it —
// and the widget must not live in the fixture directory a real screen is
// forbidden to import.
//
// ONE RATING, NEVER AN AGGREGATE
//
// An `int` one to five, which is what a single review holds. There is no
// average, no half star and no count: a decimal here is how a screen starts
// implying several ratings were folded into one.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../icons/rm_icons.dart';
import '../theme/tokens/rm_colors.dart';
import '../theme/tokens/rm_sizing.dart';
import '../theme/tokens/rm_spacing.dart';
import 'rm_icon.dart';
import 'rm_rating_input.dart' show kRatingScale;

/// One member's rating of one journey, shown rather than chosen.
class RmRatingDisplay extends StatelessWidget {
  const RmRatingDisplay({
    required this.rating,
    required this.semanticLabel,
    super.key,
    this.size = RmIconSize.sm,
  });

  /// One to five, whole — exactly what the server sent.
  final int rating;

  /// Says the rating in words, e.g. `4 / 5`. Localized by the caller: this
  /// widget holds no copy of its own.
  final String semanticLabel;

  final double size;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return Semantics(
      container: true,
      // One node saying the number. The five glyphs underneath carry no
      // meaning a reader could use, and read out individually they are noise.
      excludeSemantics: true,
      label: semanticLabel,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int star = 1; star <= kRatingScale; star++) ...<Widget>[
            if (star > 1) const SizedBox(width: RmSpacing.xxs),
            RmIcon(
              // Filled up to the rating, outlined past it. A shape rather than
              // only a tint, for the reason the input gives: a colour-only
              // difference is the one a colour-blind member cannot read.
              rating >= star ? RmIcons.starFilled : RmIcons.star,
              size: size,
              color: rating >= star ? c.warning : c.muted,
            ),
          ],
        ],
      ),
    );
  }
}
