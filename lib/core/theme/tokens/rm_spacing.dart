// ─────────────────────────────────────────────────────────────
// RideMate — Spacing tokens
//
// Source of truth: docs/claude-designs/RideMate App.dc.html (immutable).
//
// The design board is drawn at a uniform 0.702 scale (viewport 276x598 =
// iPhone 14 Pro 393x852 scaled down), so every raw value in the source is
// multiplied by 393/276 = 1.4239 and then snapped to a 4pt grid.
//
// Spacing is brightness-independent, so these are plain compile-time
// constants rather than a ThemeExtension — they need no BuildContext and stay
// const-constructible at every call site.
// ─────────────────────────────────────────────────────────────

/// Spacing scale, in logical pixels.
///
/// Derived from the recurring gaps and paddings in the design source
/// (raw 2/3/6/8/11/14/18 px) scaled by [RmScale.factor] and snapped to 4.
abstract final class RmSpacing {
  const RmSpacing._();

  /// Grid unit. Every step below is a multiple of this.
  static const double base = 4;

  /// 2 — hairline gaps inside tight label stacks (design 2px).
  static const double xxs = 2;

  /// 4 — label/value stacks (design 3px).
  static const double xs = base;

  /// 8 — icon-to-label gaps, chip internals (design 5–6px).
  static const double sm = base * 2;

  /// 12 — inner card gaps (design 8–9px).
  static const double md = base * 3;

  /// 16 — standard element gap (design 11px).
  static const double lg = base * 4;

  /// 20 — card padding, section gaps (design 14px).
  static const double xl = base * 5;

  /// 24 — screen gutter, sheet padding (design 18px).
  static const double xxl = base * 6;

  /// 32 — major section separation.
  static const double xxxl = base * 8;

  /// 40 — hero spacing.
  static const double huge = base * 10;

  /// Standard horizontal screen inset (design 18px x 1.4239 = 25.6 -> 24).
  ///
  /// Every screen-level horizontal padding uses this; do not hard-code 24.
  static const double screenGutter = xxl;

  /// `n` grid units to logical pixels.
  static double units(num n) => n * base;
}

/// The single source of the design-board scale factor.
///
/// The artboard is uniformly scaled, so proportions are authoritative but raw
/// pixel values are not. Interactive control heights are additionally clamped
/// to platform minimums — see [RmSizing] and the deviation table in
/// docs/design-system.md.
abstract final class RmScale {
  const RmScale._();

  /// Design-board viewport width, in raw design pixels.
  static const double designWidth = 276;

  /// Target device width in logical pixels (iPhone 14 Pro / typical Android).
  static const double deviceWidth = 393;

  /// 393 / 276 = 1.4239.
  static const double factor = deviceWidth / designWidth;

  /// Scales a raw design-source value to logical pixels.
  ///
  /// Use when deriving a new token from the source. Never use this at a widget
  /// call site — widgets consume named tokens, not scaled literals.
  static double of(double designPx) => designPx * factor;
}
