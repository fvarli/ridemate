// ─────────────────────────────────────────────────────────────
// RideMate — Elevation / shadow tokens
//
// Source of truth: docs/claude-designs/RideMate App.dc.html (immutable).
//
// This is a ThemeExtension because elevation is genuinely brightness-
// dependent in this design: dark mode does not dim the shadows, it REPLACES
// them with 1px borders. Most neutral shadows are therefore empty in dark,
// and the corresponding surfaces gain a border instead.
//
// Coloured shadows (primary glow, FAB, danger) survive into dark mode, with
// the hue swapped to the dark primary — the source does exactly this.
//
// Offsets and blur radii are scaled by the 1.4239 design-board factor; alpha
// values are taken verbatim. Material's numeric `elevation` is not used
// anywhere: shadows are applied directly via BoxDecoration.boxShadow.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

/// Shadow sets for one brightness.
@immutable
class RmShadows extends ThemeExtension<RmShadows> {
  const RmShadows({
    required this.cardSoft,
    required this.cardRaised,
    required this.cardFloat,
    required this.overlay,
    required this.sheetFloat,
    required this.sheetUp,
    required this.primary,
    required this.fab,
    required this.danger,
    required this.selected,
  });

  /// Lowest ambient card elevation. `0 8 22 rgba(15,23,41,.06)`.
  final List<BoxShadow> cardSoft;

  /// Stat tiles. `0 8 18 rgba(15,23,41,.08)`.
  final List<BoxShadow> cardRaised;

  /// Search field floating over a map. `0 10 24 rgba(15,23,41,.10)`.
  final List<BoxShadow> cardFloat;

  /// Card overlapping a hero header. `0 14 30 rgba(15,23,41,.10)`.
  final List<BoxShadow> overlay;

  /// Detached sheet floating over a map. `0 16 40 rgba(15,23,41,.22)`.
  final List<BoxShadow> sheetFloat;

  /// Bottom sheet, casting upward. `0 -10 30 rgba(15,23,41,.12)`.
  final List<BoxShadow> sheetUp;

  /// Primary CTA glow. `0 12 24 rgba(46,91,255,.32)`.
  final List<BoxShadow> primary;

  /// Floating action button. `0 10 20 rgba(46,91,255,.40)`.
  final List<BoxShadow> fab;

  /// SOS / danger surface. `0 14 30 rgba(229,72,77,.30)`.
  final List<BoxShadow> danger;

  /// Selected (best-match) card. `0 12 28 rgba(46,91,255,.14)`.
  final List<BoxShadow> selected;

  /// No shadow. Dark mode uses borders instead.
  static const List<BoxShadow> none = <BoxShadow>[];

  static const RmShadows light = RmShadows(
    cardSoft: <BoxShadow>[
      BoxShadow(
        color: Color(0x0F0F1729),
        blurRadius: 31,
        offset: Offset(0, 11),
      ),
    ],
    cardRaised: <BoxShadow>[
      BoxShadow(
        color: Color(0x140F1729),
        blurRadius: 26,
        offset: Offset(0, 11),
      ),
    ],
    cardFloat: <BoxShadow>[
      BoxShadow(
        color: Color(0x1A0F1729),
        blurRadius: 34,
        offset: Offset(0, 14),
      ),
    ],
    overlay: <BoxShadow>[
      BoxShadow(
        color: Color(0x1A0F1729),
        blurRadius: 43,
        offset: Offset(0, 20),
      ),
    ],
    sheetFloat: <BoxShadow>[
      BoxShadow(
        color: Color(0x380F1729),
        blurRadius: 57,
        offset: Offset(0, 23),
      ),
    ],
    sheetUp: <BoxShadow>[
      BoxShadow(
        color: Color(0x1F0F1729),
        blurRadius: 43,
        offset: Offset(0, -14),
      ),
    ],
    primary: <BoxShadow>[
      BoxShadow(
        color: Color(0x522E5BFF),
        blurRadius: 34,
        offset: Offset(0, 17),
      ),
    ],
    fab: <BoxShadow>[
      BoxShadow(
        color: Color(0x662E5BFF),
        blurRadius: 28,
        offset: Offset(0, 14),
      ),
    ],
    danger: <BoxShadow>[
      BoxShadow(
        color: Color(0x4DE5484D),
        blurRadius: 43,
        offset: Offset(0, 20),
      ),
    ],
    selected: <BoxShadow>[
      BoxShadow(
        color: Color(0x242E5BFF),
        blurRadius: 40,
        offset: Offset(0, 17),
      ),
    ],
  );

  /// Dark mode: neutral shadows are dropped in favour of 1px borders, exactly
  /// as the source's three dark screens do. Only the floating sheet keeps a
  /// (much heavier) shadow, and the coloured glows survive with the dark
  /// primary hue.
  static const RmShadows dark = RmShadows(
    cardSoft: none,
    cardRaised: none,
    cardFloat: none,
    overlay: none,
    sheetFloat: <BoxShadow>[
      BoxShadow(
        color: Color(0x80000000),
        blurRadius: 57,
        offset: Offset(0, 23),
      ),
    ],
    sheetUp: none,
    primary: <BoxShadow>[
      BoxShadow(
        color: Color(0x524D74FF),
        blurRadius: 34,
        offset: Offset(0, 17),
      ),
    ],
    fab: <BoxShadow>[
      BoxShadow(
        color: Color(0x734D74FF),
        blurRadius: 28,
        offset: Offset(0, 14),
      ),
    ],
    danger: <BoxShadow>[
      BoxShadow(
        color: Color(0x59E5484D),
        blurRadius: 43,
        offset: Offset(0, 20),
      ),
    ],
    selected: none,
  );

  @override
  RmShadows copyWith({Brightness? brightness}) => brightness == null
      ? this
      : (brightness == Brightness.light ? light : dark);

  @override
  RmShadows lerp(covariant RmShadows? other, double t) {
    if (other == null || identical(this, other)) return this;
    List<BoxShadow> l(List<BoxShadow> a, List<BoxShadow> b) =>
        BoxShadow.lerpList(a, b, t) ?? b;

    return RmShadows(
      cardSoft: l(cardSoft, other.cardSoft),
      cardRaised: l(cardRaised, other.cardRaised),
      cardFloat: l(cardFloat, other.cardFloat),
      overlay: l(overlay, other.overlay),
      sheetFloat: l(sheetFloat, other.sheetFloat),
      sheetUp: l(sheetUp, other.sheetUp),
      primary: l(primary, other.primary),
      fab: l(fab, other.fab),
      danger: l(danger, other.danger),
      selected: l(selected, other.selected),
    );
  }
}

/// Ergonomic access to the RideMate shadow set.
extension RmShadowsContext on BuildContext {
  /// The active [RmShadows] for this subtree.
  RmShadows get rmShadows => Theme.of(this).extension<RmShadows>()!;
}
