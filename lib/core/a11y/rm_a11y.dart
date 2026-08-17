// ─────────────────────────────────────────────────────────────
// RideMate — Accessibility foundations
//
// RideMate is a safety product. Someone may be reaching for a control while
// walking to a pickup point, one-handed, in the dark, at speed. Touch targets
// and contrast are functional requirements here, not compliance checkboxes.
//
// This file holds the numeric constants; see [RmTapTarget] for the wrapper
// widget, and individual Rm* widgets for the Semantics they attach.
// ─────────────────────────────────────────────────────────────

/// Accessibility constants, in logical pixels.
abstract final class RmA11y {
  const RmA11y._();

  /// Minimum interactive touch target (Material guidance; matches Flutter's
  /// `kMinInteractiveDimension`). Named here so the intent is explicit at
  /// call sites.
  ///
  /// Several design controls are visually smaller than this — the stepper
  /// buttons ([RmSizing.stepperButton], 44, scaled from the design's 28px)
  /// and the 7x13 padded inline buttons. Those keep their visual size and are
  /// wrapped in [RmTapTarget] so the *tappable* area still reaches 48.
  static const double minTouchTarget = 48;

  /// Upper bound honoured when reasoning about layout under text scaling.
  ///
  /// The user's setting is never clamped below this; it is a hint for
  /// choosing flexible layouts, and the ceiling applied at the app root so a
  /// 200% system setting cannot make a safety control unreachable.
  static const double maxTextScale = 1.6;

  /// WCAG AA contrast ratio for normal text.
  static const double contrastAaNormal = 4.5;

  /// WCAG AA contrast ratio for large text (>=18pt bold or >=24pt).
  static const double contrastAaLarge = 3;
}
