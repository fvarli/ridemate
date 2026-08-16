// ─────────────────────────────────────────────────────────────
// RideMate — Icon button
//
// Source of truth: docs/claude-designs/RideMate App.dc.html (immutable).
//
// Covers every icon-only control in the source: the 34px back tile and swap
// tile, the 34px chat send button, the 40px call and message actions, the
// 48x50 docked button and the floating map controls.
//
// A screen-reader label is REQUIRED. An icon-only control with no label is
// invisible to assistive technology, and several of these are safety-relevant
// (call the driver, share the trip).
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../theme/tokens/rm_colors.dart';
import '../theme/tokens/rm_radius.dart';
import '../theme/tokens/rm_shadows.dart';
import '../theme/tokens/rm_sizing.dart';
import 'rm_icon.dart';

/// Fill treatment of an [RmIconButton].
enum RmIconButtonVariant {
  /// White (or dark) surface with a hairline border. Back buttons, map
  /// controls.
  surface,

  /// Solid brand fill. The chat send button.
  filled,

  /// Solid success fill. The call action.
  success,

  /// Tinted brand surface. The route swap control.
  tinted,

  /// Solid safety red.
  danger,
}

/// Box size of an [RmIconButton].
enum RmIconButtonSize {
  /// 48 — back tile, swap, floating map control (design 34px).
  sm,

  /// 56 — call and message actions, docked buttons (design 40-50px).
  md,
}

/// An icon-only control.
class RmIconButton extends StatelessWidget {
  const RmIconButton({
    required this.icon,
    required this.semanticLabel,
    super.key,
    this.onPressed,
    this.variant = RmIconButtonVariant.surface,
    this.size = RmIconButtonSize.sm,
    this.elevated = false,
  });

  /// A constant from [RmIcons].
  final String icon;

  /// Required: this control has no visible text.
  final String semanticLabel;

  /// Null disables the button.
  final VoidCallback? onPressed;

  final RmIconButtonVariant variant;
  final RmIconButtonSize size;

  /// Adds the floating shadow used when the control sits over a map.
  final bool elevated;

  bool get _enabled => onPressed != null;

  double get _box => switch (size) {
    RmIconButtonSize.sm => RmSizing.iconButtonSm,
    RmIconButtonSize.md => RmSizing.iconButtonMd,
  };

  double get _iconSize => switch (size) {
    RmIconButtonSize.sm => RmIconSize.md,
    RmIconButtonSize.md => RmIconSize.lg,
  };

  double get _radius => switch (size) {
    RmIconButtonSize.sm => RmRadius.md,
    RmIconButtonSize.md => RmRadius.lg,
  };

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final (Color background, Color foreground, BoxBorder? border) = _resolve(c);

    Widget button = Semantics(
      button: true,
      enabled: _enabled,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(_radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(_radius),
          splashColor: c.primarySoft,
          child: Container(
            width: _box,
            height: _box,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_radius),
              border: border,
            ),
            child: RmIcon(icon, size: _iconSize, color: foreground),
          ),
        ),
      ),
    );

    if (elevated) {
      button = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: context.rmShadows.cardFloat,
        ),
        child: button,
      );
    }

    return button;
  }

  (Color, Color, BoxBorder?) _resolve(RmColors c) {
    if (!_enabled) {
      return (
        c.surfaceMuted,
        c.disabled,
        Border.all(color: c.border, width: RmSizing.borderWidth),
      );
    }

    return switch (variant) {
      RmIconButtonVariant.surface => (
        c.surface,
        c.ink,
        Border.all(color: c.border, width: RmSizing.borderWidth),
      ),
      RmIconButtonVariant.filled => (c.primary, c.onPrimary, null),
      RmIconButtonVariant.success => (c.success, c.onPrimary, null),
      RmIconButtonVariant.tinted => (
        c.primarySoft,
        c.primaryText,
        Border.all(color: c.primarySoftBorder, width: RmSizing.borderWidth),
      ),
      RmIconButtonVariant.danger => (c.danger, c.onPrimary, null),
    };
  }
}

/// The centre floating action button of the navigation bar.
///
/// The source draws it at 50px with an 18px negative top margin so it
/// protrudes above the bar. The size is clamped to 60 (from a scaled 71).
class RmFab extends StatelessWidget {
  const RmFab({
    required this.icon,
    required this.semanticLabel,
    super.key,
    this.onPressed,
  });

  final String icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: RmRadius.brXl,
          boxShadow: context.rmShadows.fab,
        ),
        child: Material(
          color: onPressed == null ? c.disabled : c.primary,
          borderRadius: RmRadius.brXl,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            borderRadius: RmRadius.brXl,
            child: SizedBox(
              width: RmSizing.fab,
              height: RmSizing.fab,
              child: Center(
                child: RmIcon(icon, size: RmIconSize.xl, color: c.onPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
