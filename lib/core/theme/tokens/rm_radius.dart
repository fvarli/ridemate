// ─────────────────────────────────────────────────────────────
// RideMate — Corner radius tokens
//
// Source of truth: docs/claude-designs/RideMate App.dc.html (immutable).
//
// The source uses 22 distinct raw radii (5,6,7,8,9,10,11,12,13,14,15,16,17,18,
// 19,20,22,26,30,36,46,99). After the 1.4239 scale they collapse cleanly onto
// the 9-step scale below. Mapping:
//
//   5,6    -> xs      8,9    -> sm      10,11     -> md
//   13,14,15 -> lg    16,17  -> xl      18,19,20  -> xxl
//   22     -> xxxl    26     -> sheet   99        -> pill
//
// 36 and 46 in the source are the phone-bezel and screen corners of the design
// board itself — device chrome, not app UI — and are deliberately not tokens.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/widgets.dart';

/// Corner radii, in logical pixels, with ready-made [BorderRadius] values.
abstract final class RmRadius {
  const RmRadius._();

  /// 8 — progress-bar fills, micro badges (design 5–6px).
  static const double xs = 8;

  /// 12 — extra-small buttons, chat date pill, stepper controls (design 8–9px).
  static const double sm = 12;

  /// 16 — small buttons, icon tiles, tinted wells (design 10–11px).
  static const double md = 16;

  /// 20 — default card, list row, primary button (design 13–15px).
  static const double lg = 20;

  /// 24 — search field, larger cards, FAB (design 16–17px).
  static const double xl = 24;

  /// 28 — match cards, hero cards (design 18–20px).
  static const double xxl = 28;

  /// 32 — trust-ring card (design 22px).
  static const double xxxl = 32;

  /// 36 — bottom-sheet top corners (design 26px).
  static const double sheet = 36;

  /// Fully rounded: chips, pills, filters, switch tracks (design 99px).
  static const double pill = 999;

  static const BorderRadius brXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius brXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius brXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius brXxxl = BorderRadius.all(Radius.circular(xxxl));
  static const BorderRadius brPill = BorderRadius.all(Radius.circular(pill));

  /// Top-only rounding for bottom sheets.
  ///
  /// The source rounds only the top; its bottom corners merely echo the design
  /// board's own device corners, which do not exist in a real app.
  static const BorderRadius sheetTop = BorderRadius.only(
    topLeft: Radius.circular(sheet),
    topRight: Radius.circular(sheet),
  );
}
