// ─────────────────────────────────────────────────────────────
// RideMate — Choosing a rating
//
// Five stars, one to five, whole. Not a slider and not a decimal: a fractional
// rating on a single review is an invitation for some screen to average them,
// and RideMate publishes no aggregate at all.
//
// A CONTROL, NOT A DISPLAY
//
// The design's own star row — retired with the Reviews fixture in Phase 15 —
// took a `double`, filled every star regardless of it, and collapsed the row
// into one node announcing a number. Correct for displaying an invented
// figure, wrong for a control somebody operates. [RmRatingDisplay] is the
// read-only half, and it is a separate widget for the same reason.
//
// EACH STAR IS ITS OWN NODE
//
// A screen reader needs five reachable choices, each saying which it is and
// whether it is the one selected — not one node reading a number nobody has
// chosen yet. Every star carries at least the minimum tap target, which the
// design's star glyph does not.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../a11y/rm_tap_target.dart';
import '../icons/rm_icons.dart';
import '../theme/tokens/rm_colors.dart';
import '../theme/tokens/rm_sizing.dart';
import '../theme/tokens/rm_spacing.dart';
import 'rm_icon.dart';

/// How many stars the scale has. The backend accepts one to five, whole.
const int kRatingScale = 5;

/// A one-to-five rating a member chooses.
class RmRatingInput extends StatelessWidget {
  const RmRatingInput({
    required this.label,
    required this.onChanged,
    super.key,
    this.value,
  });

  /// The chosen rating, or null when nothing is chosen yet.
  ///
  /// Null is the honest starting state: a control that began at three would be
  /// putting an opinion in somebody's mouth.
  final int? value;

  /// Called with the star that was tapped. Null disables the whole control —
  /// while a submission is in flight, or while its answer is unknown.
  final ValueChanged<int>? onChanged;

  /// Names each star, e.g. `(3) => '3 yıldız'`. Localized by the caller: this
  /// widget holds no copy of its own.
  final String Function(int) label;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final ValueChanged<int>? onChanged = this.onChanged;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int star = 1; star <= kRatingScale; star++) ...<Widget>[
          if (star > 1) const SizedBox(width: RmSpacing.xxs),
          RmTapTarget(
            // Null leaves the star inert and exposes no button semantics, so a
            // disabled control is not announced as something to press.
            onTap: onChanged == null ? null : () => onChanged(star),
            semanticLabel: label(star),
            child: RmIcon(
              // Filled up to the chosen star. The difference is the selected
              // state, and it is a shape rather than only a colour — a tint
              // alone would be the one thing a colour-blind member cannot read.
              (value ?? 0) >= star ? RmIcons.starFilled : RmIcons.star,
              size: RmIconSize.md,
              color: (value ?? 0) >= star ? c.warning : c.muted,
            ),
          ),
        ],
      ],
    );
  }
}
