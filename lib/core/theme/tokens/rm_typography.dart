// ─────────────────────────────────────────────────────────────
// RideMate — Typography tokens
//
// Source of truth: docs/claude-designs/RideMate App.dc.html (immutable).
//
// THE RULE, taken from the design source and applied there without exception:
//
//     Manrope       -> all prose and UI text
//     IBM Plex Mono -> all DATA: prices, trust scores, percentages, times,
//                      plate numbers, counts, distances
//
// The `numeric*` roles below are the mono half. Use them for any rendered
// number; use the Manrope roles for everything else. This is the single most
// recognisable characteristic of the RideMate visual language.
//
// The source declares 63 distinct size+weight pairs, with heavy half-pixel
// usage (9.5/10.5/11.5/12.5/13.5/14.5/15.5 px). Those are consolidated here
// into 20 named roles, each scaled by the 1.4239 design-board factor and
// rounded to a whole pixel.
//
// COLOURLESS BY DESIGN: no role carries a colour. Colour comes from RmColors
// at the call site. This removes the entire class of "text style carrying the
// wrong brightness's colour" bugs and lets every style stay a compile-time
// constant.
//
// U+2605 (star) is NOT present in either bundled family. Never render a star
// as text — use RmIcon with the approved star artwork. See assets/fonts/README.md.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

/// The RideMate type scale. All styles are colourless.
abstract final class RmTypography {
  const RmTypography._();

  /// Prose and UI.
  static const String fontFamily = 'Manrope';

  /// Data only — see the rule in the file header.
  static const String monoFontFamily = 'IBM Plex Mono';

  // ── Titles (Manrope) ───────────────────────────────────────

  /// 36/w800 — onboarding headline (design 25px).
  static const TextStyle titleXl = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w800,
    height: 1.12,
    letterSpacing: -0.85,
  );

  /// 32/w800 — large screen title (design 22px).
  static const TextStyle titleLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.57,
  );

  /// 24/w800 — section and screen title (design 17px).
  static const TextStyle titleMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.25,
    letterSpacing: -0.3,
  );

  /// 19/w800 — card and sheet title (design 13.5px).
  static const TextStyle titleSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 19,
    fontWeight: FontWeight.w800,
    height: 1.3,
  );

  // ── Body (Manrope) ─────────────────────────────────────────

  /// 20/w700 — field value, chat contact name (design 14.5px).
  static const TextStyle bodyLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  /// 18/w700 — list-row title (design 13px). The most common role in the
  /// source (35 occurrences).
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.35,
  );

  /// 18/w500 — chat bubble, running prose (design 13px).
  static const TextStyle bodyRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  /// 18/w500 — review paragraph, looser leading (design 12.5px).
  static const TextStyle bodySm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  // ── Labels (Manrope) ───────────────────────────────────────

  /// 17/w700 — chip and small-button label (design 12px).
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  /// 16/w700 — uppercase section header, e.g. `GÜVEN FİLTRELERİ` (design 11px).
  static const TextStyle labelSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.43,
  );

  /// 16/w500 — metadata line (design 11px).
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.35,
  );

  /// 15/w500 — list subtitle (design 10.5px).
  static const TextStyle captionSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  /// 14/w600 — navigation label, stat-tile caption (design 9.5px).
  static const TextStyle micro = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// 14/w500 — uppercase field eyebrow, e.g. `NEREDEN` / `KOLTUK`
  /// (design 10px, letter-spacing 1px).
  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 1.42,
  );

  // ── Numeric / data (IBM Plex Mono) ─────────────────────────

  /// 48/w800 — reviews hero rating (design 34px).
  static const TextStyle numericXl = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w800,
    height: 1,
  );

  /// 32/w800 — trust score in a ring, headline price (design 22px).
  static const TextStyle numericLg = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1,
  );

  /// 24/w800 — stat-tile value, card price (design 17px).
  static const TextStyle numericMd = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.1,
  );

  /// 18/w800 — compatibility percentage (design 13px).
  static const TextStyle numericSm = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );

  /// 17/w700 — timeline times, plate numbers (design 12px).
  static const TextStyle numericXs = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  /// 14/w600 — rating badge, trust-breakdown values (design 9.5px).
  static const TextStyle numericMicro = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// Every role, keyed by name — powers the design-system gallery and the
  /// typography golden test.
  static const Map<String, TextStyle> all = <String, TextStyle>{
    'titleXl': titleXl,
    'titleLg': titleLg,
    'titleMd': titleMd,
    'titleSm': titleSm,
    'bodyLg': bodyLg,
    'body': body,
    'bodyRegular': bodyRegular,
    'bodySm': bodySm,
    'label': label,
    'labelSm': labelSm,
    'caption': caption,
    'captionSm': captionSm,
    'micro': micro,
    'overline': overline,
    'numericXl': numericXl,
    'numericLg': numericLg,
    'numericMd': numericMd,
    'numericSm': numericSm,
    'numericXs': numericXs,
    'numericMicro': numericMicro,
  };

  /// Maps the RideMate scale onto Material's [TextTheme] so stock widgets
  /// inherit the right family, size and weight without extra wiring.
  ///
  /// [color] is applied as the default ink for the active brightness;
  /// RideMate widgets still set colour explicitly from [RmColors].
  static TextTheme textTheme(Color color) => TextTheme(
    displayLarge: numericXl.copyWith(color: color),
    displayMedium: titleXl.copyWith(color: color),
    displaySmall: titleLg.copyWith(color: color),
    headlineMedium: titleLg.copyWith(color: color),
    headlineSmall: titleMd.copyWith(color: color),
    titleLarge: titleMd.copyWith(color: color),
    titleMedium: titleSm.copyWith(color: color),
    titleSmall: body.copyWith(color: color),
    bodyLarge: bodyLg.copyWith(color: color),
    bodyMedium: bodyRegular.copyWith(color: color),
    bodySmall: caption.copyWith(color: color),
    labelLarge: label.copyWith(color: color),
    labelMedium: labelSm.copyWith(color: color),
    labelSmall: micro.copyWith(color: color),
  );
}
