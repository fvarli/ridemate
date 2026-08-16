// ─────────────────────────────────────────────────────────────
// RideMate — Color tokens
//
// Source of truth: docs/claude-designs/RideMate App.dc.html (immutable).
// Colors are taken verbatim from the source; unlike sizes, they do not scale.
//
// THEMING: this is a ThemeExtension, read via
// `Theme.of(context).extension<RmColors>()!` (or the `context.rmColors`
// helper). It is deliberately NOT a global mutable palette pointer: RideMate
// renders a light sheet over a dark map on the Home screen, so two
// brightnesses can be live in a single frame. A context-scoped extension is
// also lerp-able across theme transitions and safe for golden tests that
// render both themes side by side.
//
// Widgets must never hard-code a hex value. If a colour is missing here, add
// it here.
//
// DARK MODE: the source only provides dark variants for three screens (Home,
// Active Trip, Safety Center). Values marked "extrapolated" below have no dark
// reference in the design and were derived from the source's own light->dark
// surface mapping. They are listed in docs/design-system.md for design review.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

/// Semantic colour palette for one brightness.
@immutable
class RmColors extends ThemeExtension<RmColors> {
  const RmColors({
    required this.brightness,
    required this.primary,
    required this.primaryPressed,
    required this.onPrimary,
    required this.primaryText,
    required this.primarySoft,
    required this.primarySoftBorder,
    required this.success,
    required this.successInk,
    required this.successSoft,
    required this.danger,
    required this.dangerIcon,
    required this.dangerSoft,
    required this.dangerGradientEnd,
    required this.warning,
    required this.warningInk,
    required this.warningSoft,
    required this.warningBorder,
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceMuted,
    required this.sheet,
    required this.navBar,
    required this.border,
    required this.hairline,
    required this.divider,
    required this.ink,
    required this.sub,
    required this.muted,
    required this.faint,
    required this.disabled,
    required this.onInk,
    required this.meterTrack,
    required this.meterTrackInfo,
    required this.meterTrackNeutral,
    required this.mapCanvas,
    required this.mapRoad,
    required this.mapBuilding,
    required this.identityAmber,
    required this.identityGreen,
    required this.identityPurple,
    required this.heroPrimary,
    required this.heroDanger,
    required this.meterPrimary,
    required this.onboardingCanvas,
  });

  /// The brightness this palette was built for.
  final Brightness brightness;

  // ── Brand ──────────────────────────────────────────────────

  /// Primary brand blue. Light `#2E5BFF`, dark `#4D74FF`.
  final Color primary;

  /// Pressed/active primary. The source's only interaction hint is
  /// `style-hover="background:#1E3FBF"` on the onboarding CTA.
  final Color primaryPressed;

  /// Foreground on [primary].
  final Color onPrimary;

  /// Brand colour when used as *text* on a neutral surface (links, active tab
  /// labels). Dark mode lightens this further than [primary] for legibility.
  final Color primaryText;

  /// Tinted brand surface (`#F0F6FF` light) and its border (`#DCE9FF`).
  final Color primarySoft;
  final Color primarySoftBorder;

  // ── Semantic ───────────────────────────────────────────────

  /// Verified / success. Light `#18A957`, dark `#3FD07E`.
  final Color success;

  /// Success text on [successSoft] (`#0F8A43`) — darker for AA contrast.
  final Color successInk;
  final Color successSoft;

  /// Safety / danger. `#E5484D` in BOTH themes — the source deliberately does
  /// not lighten the safety red in dark mode.
  final Color danger;

  /// Danger used as an icon stroke on a dark surface (`#FF6B70`).
  final Color dangerIcon;
  final Color dangerSoft;
  final Color dangerGradientEnd;

  /// Rating / warning. `#F5A524` in both themes.
  final Color warning;
  final Color warningInk;
  final Color warningSoft;
  final Color warningBorder;

  // ── Surfaces ───────────────────────────────────────────────

  /// Screen background.
  final Color background;

  /// Card and sheet surface.
  final Color surface;

  /// A surface sitting on top of [surface] (inner tiles).
  final Color surfaceRaised;

  /// Muted inset well (inputs, driver strip).
  final Color surfaceMuted;

  /// Bottom-sheet surface.
  final Color sheet;

  /// Bottom navigation bar surface.
  final Color navBar;

  /// Standard 1px card border.
  final Color border;

  /// Lighter separator: nav-bar top border, chat header rule.
  final Color hairline;

  /// Divider inside a card.
  final Color divider;

  // ── Text ───────────────────────────────────────────────────

  /// Primary text.
  final Color ink;

  /// Secondary/body text.
  final Color sub;

  /// Tertiary metadata text.
  final Color muted;

  /// Quaternary label text.
  final Color faint;

  /// Disabled text, chevrons, empty step indicators.
  final Color disabled;

  /// Foreground on [ink]-filled surfaces (selected sort chips, map labels).
  ///
  /// Must invert with the theme: [ink] is near-black in light and near-white
  /// in dark, so a fixed white here would render white-on-white in dark mode.
  final Color onInk;

  // ── Meters ─────────────────────────────────────────────────

  /// Default meter/ring track (`#EEF0F4`).
  final Color meterTrack;

  /// Track inside a tinted-blue well (`#DCE9FF`).
  final Color meterTrackInfo;

  /// Track inside a neutral well (`#E4E8EE`).
  final Color meterTrackNeutral;

  // ── Map (consumed from Phase 3 onward) ─────────────────────

  final Color mapCanvas;
  final Color mapRoad;
  final Color mapBuilding;

  // ── Identity gradients ─────────────────────────────────────
  // Avatars encode identity by gradient. The source uses exactly three, at
  // 135deg, and does not vary them between themes.

  final Gradient identityAmber;
  final Gradient identityGreen;
  final Gradient identityPurple;

  // ── Feature gradients ──────────────────────────────────────

  /// Blue hero header / trust-ring card.
  final Gradient heroPrimary;

  /// SOS hero card.
  final Gradient heroDanger;

  /// Compatibility meter fill.
  final Gradient meterPrimary;

  /// Full-bleed onboarding canvas.
  final Gradient onboardingCanvas;

  /// All three identity gradients, in the order the source introduces them.
  List<Gradient> get identityGradients => <Gradient>[
    identityAmber,
    identityGreen,
    identityPurple,
  ];

  // ── Light ──────────────────────────────────────────────────

  static const RmColors light = RmColors(
    brightness: Brightness.light,
    primary: Color(0xFF2E5BFF),
    primaryPressed: Color(0xFF1E3FBF),
    onPrimary: Color(0xFFFFFFFF),
    primaryText: Color(0xFF2E5BFF),
    primarySoft: Color(0xFFF0F6FF),
    primarySoftBorder: Color(0xFFDCE9FF),
    success: Color(0xFF18A957),
    successInk: Color(0xFF0F8A43),
    successSoft: Color(0xFFE7F7EE),
    danger: Color(0xFFE5484D),
    dangerIcon: Color(0xFFE5484D),
    dangerSoft: Color(0xFFFDEAEA),
    dangerGradientEnd: Color(0xFFC2363B),
    warning: Color(0xFFF5A524),
    warningInk: Color(0xFFC98A1B),
    warningSoft: Color(0xFFFFF6E9),
    warningBorder: Color(0xFFF6E2B8),
    background: Color(0xFFF6F8FB),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF4F6F9),
    sheet: Color(0xFFFFFFFF),
    navBar: Color(0xFFFFFFFF),
    border: Color(0xFFE7E9EF),
    hairline: Color(0xFFEEF0F4),
    divider: Color(0xFFF0F2F6),
    ink: Color(0xFF0F1729),
    sub: Color(0xFF5B6478),
    muted: Color(0xFF8A93A6),
    faint: Color(0xFF9AA1B0),
    disabled: Color(0xFFC7CDDA),
    onInk: Color(0xFFFFFFFF),
    meterTrack: Color(0xFFEEF0F4),
    meterTrackInfo: Color(0xFFDCE9FF),
    meterTrackNeutral: Color(0xFFE4E8EE),
    mapCanvas: Color(0xFFE3E9F0),
    mapRoad: Color(0xFFD2DAE4),
    mapBuilding: Color(0xFFDCE3EC),
    identityAmber: _amber,
    identityGreen: _green,
    identityPurple: _purple,
    heroPrimary: _heroPrimary,
    heroDanger: _heroDangerLight,
    meterPrimary: _meterPrimary,
    onboardingCanvas: _onboardingCanvas,
  );

  // ── Dark ───────────────────────────────────────────────────

  static const RmColors dark = RmColors(
    brightness: Brightness.dark,
    primary: Color(0xFF4D74FF),
    primaryPressed: Color(0xFF1E3FBF),
    onPrimary: Color(0xFFFFFFFF),
    primaryText: Color(0xFF7FA0FF),
    primarySoft: Color(0xFF16203A),
    primarySoftBorder: Color(0xFF24365E),
    success: Color(0xFF3FD07E),
    successInk: Color(0xFF3FD07E),
    successSoft: Color(0xFF10301F),
    danger: Color(0xFFE5484D),
    dangerIcon: Color(0xFFFF6B70),
    dangerSoft: Color(0xFF2A1518),
    dangerGradientEnd: Color(0xFFB22F34),
    warning: Color(0xFFF5A524),
    // Extrapolated: the source has no dark amber surface anywhere.
    warningInk: Color(0xFFF5A524),
    warningSoft: Color(0xFF2A1F10),
    warningBorder: Color(0xFF4A3616),
    background: Color(0xFF0B0E14),
    surface: Color(0xFF151A23),
    surfaceRaised: Color(0xFF181E29),
    surfaceMuted: Color(0xFF181E29),
    sheet: Color(0xFF11151D),
    navBar: Color(0xFF0E1219),
    border: Color(0xFF232A38),
    hairline: Color(0xFF1C2230),
    divider: Color(0xFF232A38),
    ink: Color(0xFFF2F4F8),
    sub: Color(0xFF9BA3B4),
    muted: Color(0xFF9BA3B4),
    faint: Color(0xFF5B6478),
    disabled: Color(0xFF3A4252),
    // Inverted deliberately: `ink` is near-white in dark mode, so a white
    // foreground would be invisible on an ink-filled surface.
    onInk: Color(0xFF0B0E14),
    meterTrack: Color(0xFF232A38),
    meterTrackInfo: Color(0xFF24365E),
    meterTrackNeutral: Color(0xFF232A38),
    mapCanvas: Color(0xFF0E131C),
    mapRoad: Color(0xFF1A2130),
    mapBuilding: Color(0xFF151B27),
    identityAmber: _amber,
    identityGreen: _green,
    identityPurple: _purple,
    heroPrimary: _heroPrimary,
    heroDanger: _heroDangerDark,
    meterPrimary: _meterPrimary,
    onboardingCanvas: _onboardingCanvas,
  );

  // ── Gradient definitions (verbatim from the source) ────────

  /// `linear-gradient(135deg,#F5A524,#E8841A)`
  static const LinearGradient _amber = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFF5A524), Color(0xFFE8841A)],
  );

  /// `linear-gradient(135deg,#18A957,#0F8A43)`
  static const LinearGradient _green = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF18A957), Color(0xFF0F8A43)],
  );

  /// `linear-gradient(135deg,#9D6BFF,#6E3FE8)`
  static const LinearGradient _purple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF9D6BFF), Color(0xFF6E3FE8)],
  );

  /// `linear-gradient(150deg,#1E3FBF,#2E5BFF)` — trust-ring and hero headers.
  static const LinearGradient _heroPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF1E3FBF), Color(0xFF2E5BFF)],
  );

  /// `linear-gradient(160deg,#E5484D,#C2363B)`
  static const LinearGradient _heroDangerLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFE5484D), Color(0xFFC2363B)],
  );

  /// `linear-gradient(160deg,#E5484D,#B22F34)`
  static const LinearGradient _heroDangerDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFE5484D), Color(0xFFB22F34)],
  );

  /// `linear-gradient(90deg,#2E5BFF,#5B82FF)`
  static const LinearGradient _meterPrimary = LinearGradient(
    colors: <Color>[Color(0xFF2E5BFF), Color(0xFF5B82FF)],
  );

  /// `linear-gradient(170deg,#16357A 0%,#2E5BFF 46%,#1E3FBF 100%)`
  static const LinearGradient _onboardingCanvas = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFF16357A), Color(0xFF2E5BFF), Color(0xFF1E3FBF)],
    stops: <double>[0, 0.46, 1],
  );

  /// The palette for [brightness].
  ///
  /// The two palettes are const singletons and are never partially modified,
  /// so this resolves to one of them rather than exposing 44 optional fields.
  @override
  RmColors copyWith({Brightness? brightness}) =>
      brightness == null || brightness == this.brightness
      ? this
      : (brightness == Brightness.light ? light : dark);

  /// Interpolates every field.
  ///
  /// Material animates its own [ColorScheme] over `kThemeAnimationDuration`,
  /// so snapping here would leave RideMate surfaces flipping instantly while
  /// everything around them cross-fades. Every field is interpolated so the
  /// two stay in step.
  @override
  RmColors lerp(covariant RmColors? other, double t) {
    if (other == null || identical(this, other)) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    Gradient g(Gradient a, Gradient b) => Gradient.lerp(a, b, t)!;

    return RmColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      primary: c(primary, other.primary),
      primaryPressed: c(primaryPressed, other.primaryPressed),
      onPrimary: c(onPrimary, other.onPrimary),
      primaryText: c(primaryText, other.primaryText),
      primarySoft: c(primarySoft, other.primarySoft),
      primarySoftBorder: c(primarySoftBorder, other.primarySoftBorder),
      success: c(success, other.success),
      successInk: c(successInk, other.successInk),
      successSoft: c(successSoft, other.successSoft),
      danger: c(danger, other.danger),
      dangerIcon: c(dangerIcon, other.dangerIcon),
      dangerSoft: c(dangerSoft, other.dangerSoft),
      dangerGradientEnd: c(dangerGradientEnd, other.dangerGradientEnd),
      warning: c(warning, other.warning),
      warningInk: c(warningInk, other.warningInk),
      warningSoft: c(warningSoft, other.warningSoft),
      warningBorder: c(warningBorder, other.warningBorder),
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surfaceRaised: c(surfaceRaised, other.surfaceRaised),
      surfaceMuted: c(surfaceMuted, other.surfaceMuted),
      sheet: c(sheet, other.sheet),
      navBar: c(navBar, other.navBar),
      border: c(border, other.border),
      hairline: c(hairline, other.hairline),
      divider: c(divider, other.divider),
      ink: c(ink, other.ink),
      sub: c(sub, other.sub),
      muted: c(muted, other.muted),
      faint: c(faint, other.faint),
      disabled: c(disabled, other.disabled),
      onInk: c(onInk, other.onInk),
      meterTrack: c(meterTrack, other.meterTrack),
      meterTrackInfo: c(meterTrackInfo, other.meterTrackInfo),
      meterTrackNeutral: c(meterTrackNeutral, other.meterTrackNeutral),
      mapCanvas: c(mapCanvas, other.mapCanvas),
      mapRoad: c(mapRoad, other.mapRoad),
      mapBuilding: c(mapBuilding, other.mapBuilding),
      identityAmber: g(identityAmber, other.identityAmber),
      identityGreen: g(identityGreen, other.identityGreen),
      identityPurple: g(identityPurple, other.identityPurple),
      heroPrimary: g(heroPrimary, other.heroPrimary),
      heroDanger: g(heroDanger, other.heroDanger),
      meterPrimary: g(meterPrimary, other.meterPrimary),
      onboardingCanvas: g(onboardingCanvas, other.onboardingCanvas),
    );
  }
}

/// Ergonomic access to the RideMate palette.
extension RmColorsContext on BuildContext {
  /// The active [RmColors] for this subtree.
  RmColors get rmColors => Theme.of(this).extension<RmColors>()!;
}
