// ─────────────────────────────────────────────────────────────
// RideMate — Icon widget
//
// Renders an approved SVG from [RmIcons] at a token size, tinted with a token
// colour. Icons are decorative by default and hidden from screen readers;
// pass [semanticLabel] only when the icon carries meaning no adjacent text
// already conveys.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../icons/rm_icons.dart';
import '../theme/tokens/rm_colors.dart';
import '../theme/tokens/rm_sizing.dart';

/// An icon from the approved RideMate set.
class RmIcon extends StatelessWidget {
  const RmIcon(
    this.asset, {
    super.key,
    this.size = RmIconSize.md,
    this.color,
    this.semanticLabel,
  });

  /// A constant from [RmIcons].
  final String asset;

  /// One of the [RmIconSize] steps. Arbitrary sizes are allowed but should be
  /// rare — the steps snap to whole device pixels.
  final double size;

  /// Tint. Defaults to the current text colour, then to the palette ink, so an
  /// icon inside coloured text follows it without extra wiring.
  final Color? color;

  /// Screen-reader label. Leave null for decorative icons.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final Color resolved =
        color ??
        DefaultTextStyle.of(context).style.color ??
        context.rmColors.ink;

    // Directional glyphs mirror in RTL so the chevron keeps pointing "back"
    // and the send arrow keeps flying toward the end of the line.
    final bool mirror =
        RmIcons.directional.contains(asset) &&
        Directionality.of(context) == TextDirection.rtl;

    Widget icon = SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(resolved, BlendMode.srcIn),
    );

    if (mirror) {
      icon = Transform.flip(flipX: true, child: icon);
    }

    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: SizedBox(width: size, height: size, child: icon),
    );
  }
}
