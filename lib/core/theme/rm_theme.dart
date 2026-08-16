// ─────────────────────────────────────────────────────────────
// RideMate — Theme assembly
//
// Builds the light and dark [ThemeData] from the token layer and attaches
// [RmColors] and [RmShadows] as ThemeExtensions.
//
// MaterialApp receives theme + darkTheme + themeMode, so Flutter resolves
// brightness itself. There is no global mutable palette and no manual
// brightness observer: a widget always reads the palette of ITS OWN subtree,
// which matters because RideMate floats light sheets over dark map surfaces.
//
// Component themes exist so stock Material widgets (dialogs, snackbars,
// text selection, scrollbars) inherit the RideMate language without every
// call site restating it.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens/rm_colors.dart';
import 'tokens/rm_radius.dart';
import 'tokens/rm_shadows.dart';
import 'tokens/rm_sizing.dart';
import 'tokens/rm_spacing.dart';
import 'tokens/rm_typography.dart';

/// Builders for the RideMate [ThemeData].
abstract final class RmTheme {
  const RmTheme._();

  /// Light theme.
  static ThemeData get light => _build(RmColors.light, RmShadows.light);

  /// Dark theme.
  static ThemeData get dark => _build(RmColors.dark, RmShadows.dark);

  /// The theme for [brightness].
  static ThemeData of(Brightness brightness) =>
      brightness == Brightness.light ? light : dark;

  /// System UI overlay style (status-bar icons) for a screen whose top
  /// surface has the given [brightness].
  ///
  /// A real app does not draw its own status bar — the design board's mock
  /// status bars are device chrome, not UI. This is how that intent is
  /// expressed instead.
  static SystemUiOverlayStyle overlayStyleFor(Brightness surfaceBrightness) =>
      surfaceBrightness == Brightness.light
      ? SystemUiOverlayStyle.dark
      : SystemUiOverlayStyle.light;

  static ThemeData _build(RmColors c, RmShadows s) {
    final ColorScheme scheme = ColorScheme(
      brightness: c.brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.primarySoft,
      onPrimaryContainer: c.primaryText,
      secondary: c.success,
      onSecondary: c.onPrimary,
      secondaryContainer: c.successSoft,
      onSecondaryContainer: c.successInk,
      tertiary: c.warning,
      onTertiary: c.ink,
      tertiaryContainer: c.warningSoft,
      onTertiaryContainer: c.warningInk,
      error: c.danger,
      onError: c.onPrimary,
      errorContainer: c.dangerSoft,
      onErrorContainer: c.danger,
      surface: c.surface,
      onSurface: c.ink,
      onSurfaceVariant: c.sub,
      surfaceContainerLowest: c.surface,
      surfaceContainerLow: c.surfaceRaised,
      surfaceContainer: c.background,
      surfaceContainerHigh: c.surfaceMuted,
      surfaceContainerHighest: c.surfaceMuted,
      outline: c.border,
      outlineVariant: c.hairline,
      shadow: c.ink,
      scrim: c.ink,
      inverseSurface: c.ink,
      onInverseSurface: c.onInk,
      inversePrimary: c.primaryText,
    );

    final ThemeData base = ThemeData(
      useMaterial3: true,
      brightness: c.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      fontFamily: RmTypography.fontFamily,
      textTheme: RmTypography.textTheme(c.ink),
      // Guarantees Material's own hit targets clear 48dp.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkSparkle.splashFactory,
      extensions: <ThemeExtension<dynamic>>[c, s],
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: RmTypography.titleMd.copyWith(color: c.ink),
        systemOverlayStyle: overlayStyleFor(c.brightness),
      ),
      dividerTheme: DividerThemeData(
        color: c.divider,
        thickness: RmSizing.borderWidth,
        space: RmSizing.borderWidth,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.sheet,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: c.disabled,
        shape: const RoundedRectangleBorder(borderRadius: RmRadius.sheetTop),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: RmRadius.brXl),
        titleTextStyle: RmTypography.titleSm.copyWith(color: c.ink),
        contentTextStyle: RmTypography.bodyRegular.copyWith(color: c.sub),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.ink,
        contentTextStyle: RmTypography.caption.copyWith(color: c.onInk),
        shape: const RoundedRectangleBorder(borderRadius: RmRadius.brMd),
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(RmSpacing.screenGutter),
      ),
      // RideMate ships its own RmButton; these keep any stock Material button
      // that slips in from looking foreign.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(RmSizing.ctaXl),
          shape: const RoundedRectangleBorder(borderRadius: RmRadius.brLg),
          textStyle: RmTypography.label,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primaryText,
          minimumSize: const Size(0, RmSizing.ctaMd),
          textStyle: RmTypography.label,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: c.ink,
          minimumSize: const Size.square(RmSizing.iconButtonSm),
          shape: const RoundedRectangleBorder(borderRadius: RmRadius.brMd),
        ),
      ),
      iconTheme: IconThemeData(color: c.ink, size: RmIconSize.md),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.meterTrack,
        circularTrackColor: c.meterTrack,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll<Color>(c.disabled),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionColor: c.primarySoftBorder,
        selectionHandleColor: c.primary,
      ),
      splashColor: c.primarySoft,
      highlightColor: c.primarySoft,
    );
  }
}

/// Ergonomic access to RideMate theme values.
extension RmThemeContext on BuildContext {
  /// Whether the active RideMate theme is dark.
  bool get rmIsDark => Theme.of(this).brightness == Brightness.dark;
}
