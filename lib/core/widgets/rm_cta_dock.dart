// ─────────────────────────────────────────────────────────────
// RideMate — Bottom action dock
//
// Source of truth: docs/claude-designs/RideMate App.dc.html (immutable).
//
// The design docks a primary action to the bottom of Search, Route Details and
// Create Route, over a gradient scrim that fades from the page background so
// content scrolls away underneath rather than colliding with the button.
//
// The scrim is the page background fading to transparent upward, so it always
// matches whatever surface it sits on, in either theme.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../theme/tokens/rm_colors.dart';
import '../theme/tokens/rm_spacing.dart';

/// A bottom-anchored action bar over a fading scrim.
class RmCtaDock extends StatelessWidget {
  const RmCtaDock({
    required this.children,
    super.key,
    this.spacing = RmSpacing.md,
  });

  /// The dock's contents, laid out in a row. A single full-width button is the
  /// common case; Route Details also puts a price block and an icon button here.
  final List<Widget> children;

  /// Gap between [children].
  final double spacing;

  /// Where the scrim becomes fully opaque. Matches the design's 35–38%.
  static const double _scrimStop = 0.38;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[c.background.withValues(alpha: 0), c.background],
          stops: const <double>[0, _scrimStop],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            RmSpacing.screenGutter,
            RmSpacing.xl,
            RmSpacing.screenGutter,
            RmSpacing.xl,
          ),
          child: Row(
            children: <Widget>[
              for (int i = 0; i < children.length; i++) ...<Widget>[
                if (i > 0) SizedBox(width: spacing),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
