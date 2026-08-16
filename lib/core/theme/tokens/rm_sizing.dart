// ─────────────────────────────────────────────────────────────
// RideMate — Sizing tokens (control heights, icon and avatar sizes)
//
// Source of truth: docs/claude-designs/RideMate App.dc.html (immutable).
//
// IMPORTANT: the 1.4239 design-board scale governs *proportion*, not
// interactive ergonomics. Applying it literally would produce a 74pt primary
// button and a 102pt navigation bar. Interactive heights are therefore
// clamped to platform norms, and every clamp is recorded in the table in
// docs/design-system.md. Values marked "clamped" below are deliberate
// deviations from the source, not transcription errors.
// ─────────────────────────────────────────────────────────────

/// Control sizes, in logical pixels.
abstract final class RmSizing {
  const RmSizing._();

  // ── Buttons ────────────────────────────────────────────────
  // Design 52/50/48 would scale to 74/71/68. Clamped.

  /// 56 — full-width primary CTA (design 52px, clamped from 74).
  static const double ctaXl = 56;

  /// 52 — docked/flex primary CTA (design 50px, clamped from 71).
  static const double ctaLg = 52;

  /// 48 — secondary action row (design 48px, clamped from 68).
  static const double ctaMd = 48;

  /// 40 — small in-card action (design 8x14 padding button).
  static const double ctaSm = 40;

  /// 36 — extra-small in-row action (design 7x13 padding button).
  ///
  /// Below the 48dp touch floor by design; must be wrapped in [RmTapTarget]
  /// so the *tappable* area still reaches 48.
  static const double ctaXs = 36;

  // ── Icon buttons ───────────────────────────────────────────

  /// 48 — back tile, swap, floating map control (design 34px -> 48.4).
  ///
  /// The scale lands almost exactly on the 48dp minimum touch target.
  static const double iconButtonSm = 48;

  /// 56 — call / message actions (design 40px -> 57).
  static const double iconButtonMd = 56;

  /// 56 — docked icon button (design 48x50 -> 68x71, clamped).
  static const double iconButtonLg = 56;

  /// 60 — centre floating action button (design 50px -> 71, clamped).
  static const double fab = 60;

  // ── Navigation ─────────────────────────────────────────────

  /// 64 — bottom navigation bar, excluding safe-area inset
  /// (design 72px -> 102, clamped).
  static const double navBarHeight = 64;

  // ── Form controls ──────────────────────────────────────────

  /// 56 x 32 switch track (design 46x27 -> 65x38, clamped).
  static const double switchTrackWidth = 56;
  static const double switchTrackHeight = 32;

  /// 26 — switch knob (design 21px).
  static const double switchKnob = 26;

  /// 3 — switch knob inset (design 3px).
  static const double switchKnobInset = 3;

  /// 44 — stepper increment/decrement control (design 28px -> 40).
  static const double stepperButton = 44;

  // ── Meters ─────────────────────────────────────────────────

  /// 8 — linear meter height; the corner radius always equals the height
  /// (design 5–6px -> 7–8.5).
  static const double meterHeight = 8;

  /// 10 — trust-ring stroke width (design 7px).
  static const double trustRingStroke = 10;

  /// 104 — trust ring diameter (design 72–74px).
  static const double trustRingSize = 104;

  // ── Misc ───────────────────────────────────────────────────

  /// 1 — hairline border width. Not scaled: a border is a physical hairline,
  /// not a proportional measure.
  static const double borderWidth = 1;

  /// 2 — emphasised border, used for selected cards (design 1.5px).
  static const double borderWidthEmphasis = 2;

  /// 3 — the ring that punches the verified badge out of its backing surface
  /// (design 2.5px).
  static const double badgeRingWidth = 3;
}

/// Icon sizes, in logical pixels.
///
/// The source renders icons at 13/16/17/18/19/20/22/23/24 raw px — fractions
/// of the 24-unit viewBox that would land on fractional device pixels after
/// scaling. These four steps snap the scaled values to whole pixels.
abstract final class RmIconSize {
  const RmIconSize._();

  /// 20 — leading icon inside a chip (design 13px).
  static const double sm = 20;

  /// 24 — list rows, buttons, chevrons (design 16–18px).
  static const double md = 24;

  /// 28 — standalone actions (design 19–20px).
  static const double lg = 28;

  /// 32 — navigation bar, FAB, card headers (design 22–24px).
  static const double xl = 32;
}

/// Avatar sizes, in logical pixels.
///
/// The source is provably ratio-consistent rather than table-driven: across
/// all ten avatar instances the corner radius is 0.32x the box and the
/// initials are 0.36x. [RmAvatarMetrics] encodes those ratios so any size
/// stays on-design.
abstract final class RmAvatarSize {
  const RmAvatarSize._();

  /// 32 — stacked social-proof avatars (design 24px).
  static const double xs = 32;

  /// 40 — small inline avatar (design 30px).
  static const double sm = 40;

  /// 48 — map pin, compact row (design 34px).
  static const double md = 48;

  /// 56 — review row, chat header (design 38–40px).
  static const double lg = 56;

  /// 64 — driver strip, condensed match card (design 44–46px).
  static const double xl = 64;

  /// 72 — match card (design 48px).
  static const double xxl = 72;

  /// 84 — profile / route-details header (design 58–60px).
  static const double hero = 84;
}

/// Derived avatar geometry.
///
/// Ratios measured from the design source and constant across every instance.
abstract final class RmAvatarMetrics {
  const RmAvatarMetrics._();

  /// Squircle corner radius as a fraction of the box (design: 38->12, 40->13,
  /// 44->14, 46->14, 48->15, 58->18, 60->19 — all ~0.32).
  static const double radiusRatio = 0.32;

  /// Initials font size as a fraction of the box (~0.36 throughout).
  static const double initialsRatio = 0.36;

  /// Verified/presence badge diameter as a fraction of the avatar (~0.38).
  static const double badgeRatio = 0.38;

  /// How far the badge overhangs the avatar's corner (~0.09 of the box).
  static const double badgeOffsetRatio = 0.09;

  static double radiusFor(double size) => size * radiusRatio;
  static double initialsSizeFor(double size) => size * initialsRatio;
  static double badgeSizeFor(double size) => size * badgeRatio;
  static double badgeOffsetFor(double size) => size * badgeOffsetRatio;
}
