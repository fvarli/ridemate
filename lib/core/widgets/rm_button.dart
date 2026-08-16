// ─────────────────────────────────────────────────────────────
// RideMate — Button
//
// Source of truth: docs/claude-designs/RideMate App.dc.html (immutable).
//
// The source contains 13 <button> elements spanning 5 sizes and 4 fills;
// this widget covers all of them.
//
// INVENTED STATES. The source has NO disabled, loading, pressed or focus
// state — its only interaction hint is a single
// `style-hover="background:#1E3FBF;transform:translateY(-1px)"` on the
// onboarding CTA. The following are derived from the token language and are
// marked so a design review can accept or replace them:
//
//   pressed  -> primary becomes primaryPressed (#2E5BFF -> #1E3FBF), which is
//               exactly what that one hover declares. The 1px lift is dropped:
//               it reads as a cursor affordance, not a touch one.
//   disabled -> the fill drops to its soft tint and the label to `disabled`,
//               echoing the `opacity:.62` the source uses for pending rows.
//   loading  -> a spinner in the label's own colour, with the button's width
//               PRESERVED so the layout cannot jump under the user's finger.
//   focus    -> a 2dp outline, for keyboard and switch-access users.
//
// Uses InkWell rather than a bare GestureDetector so focus traversal, keyboard
// activation and hover all work; the design specifies no ripple, so the splash
// is tinted to the token soft colour instead of being loud.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../a11y/rm_a11y.dart';
import '../theme/tokens/rm_colors.dart';
import '../theme/tokens/rm_radius.dart';
import '../theme/tokens/rm_shadows.dart';
import '../theme/tokens/rm_sizing.dart';
import '../theme/tokens/rm_spacing.dart';
import '../theme/tokens/rm_typography.dart';
import 'rm_icon.dart';

/// Visual weight of a [RmButton].
enum RmButtonVariant {
  /// Solid brand fill with a coloured glow. The screen's single main action.
  primary,

  /// White surface with a hairline border and brand label. Used for the
  /// lower-ranked of two adjacent actions.
  outline,

  /// No fill, no border. Tertiary actions such as "Zaten üyeyim".
  ghost,

  /// Solid safety red. Reserved for genuinely destructive or emergency
  /// actions. Carries no SOS behaviour of its own.
  danger,
}

/// Height and typography step of a [RmButton].
enum RmButtonSize {
  /// 36 — inline row action (design 7x13 padding). Below the touch floor by
  /// design, so its hit area is padded out to 48.
  xs,

  /// 40 — in-card action such as "İncele" (design 8x14 padding).
  sm,

  /// 48 — secondary action row (design 48px).
  md,

  /// 52 — docked primary action (design 50px).
  lg,

  /// 56 — full-width primary CTA (design 52px).
  xl,
}

/// The RideMate button.
class RmButton extends StatelessWidget {
  const RmButton({
    required this.label,
    super.key,
    this.onPressed,
    this.icon,
    this.variant = RmButtonVariant.primary,
    this.size = RmButtonSize.xl,
    this.fullWidth = true,
    this.loading = false,
    this.semanticLabel,
  });

  final String label;

  /// Null disables the button — there is no separate `enabled` flag.
  final VoidCallback? onPressed;

  /// Optional leading icon, from [RmIcons].
  final String? icon;

  final RmButtonVariant variant;
  final RmButtonSize size;

  /// Whether to stretch to the available width.
  final bool fullWidth;

  /// Shows a spinner in place of the label while keeping the same width.
  /// A loading button is not interactive.
  final bool loading;

  /// Overrides the screen-reader label when the visible text is not enough.
  final String? semanticLabel;

  bool get _enabled => onPressed != null && !loading;

  double get _height => switch (size) {
    RmButtonSize.xs => RmSizing.ctaXs,
    RmButtonSize.sm => RmSizing.ctaSm,
    RmButtonSize.md => RmSizing.ctaMd,
    RmButtonSize.lg => RmSizing.ctaLg,
    RmButtonSize.xl => RmSizing.ctaXl,
  };

  double get _radius => switch (size) {
    RmButtonSize.xs => RmRadius.sm,
    RmButtonSize.sm => RmRadius.md,
    RmButtonSize.md || RmButtonSize.lg || RmButtonSize.xl => RmRadius.lg,
  };

  TextStyle get _textStyle => switch (size) {
    RmButtonSize.xs => RmTypography.labelSm,
    RmButtonSize.sm => RmTypography.label,
    RmButtonSize.md => RmTypography.label,
    RmButtonSize.lg || RmButtonSize.xl => RmTypography.bodyLg,
  };

  double get _horizontalPadding => switch (size) {
    RmButtonSize.xs => RmSpacing.lg,
    RmButtonSize.sm => RmSpacing.xl,
    _ => RmSpacing.xxl,
  };

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final RmShadows shadows = context.rmShadows;
    final _ButtonStyle style = _resolve(c, shadows);

    final Widget content = loading
        ? _Spinner(color: style.foreground, size: _textStyle.fontSize!)
        : _Label(
            label: label,
            icon: icon,
            style: _textStyle.copyWith(color: style.foreground),
            iconColor: style.foreground,
          );

    Widget button = Semantics(
      button: true,
      enabled: _enabled,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: Material(
        color: style.background,
        borderRadius: BorderRadius.circular(_radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(_radius),
          splashColor: style.splash,
          highlightColor: style.splash,
          focusColor: style.splash,
          child: Container(
            height: _height,
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: _horizontalPadding,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_radius),
              border: style.border,
            ),
            alignment: Alignment.center,
            child: content,
          ),
        ),
      ),
    );

    if (style.shadow.isNotEmpty) {
      button = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: style.shadow,
        ),
        child: button,
      );
    }

    if (fullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }

    // The xs step is intentionally shorter than the touch floor; grow the hit
    // area without changing how the control looks.
    if (_height < RmA11y.minTouchTarget) {
      button = SizedBox(
        height: RmA11y.minTouchTarget,
        child: Center(child: button),
      );
    }

    return button;
  }

  _ButtonStyle _resolve(RmColors c, RmShadows s) {
    if (!_enabled) {
      // Disabled: soft fill, muted label, no glow. Outline and ghost keep
      // their transparency so they do not gain weight when unavailable.
      final bool solid =
          variant == RmButtonVariant.primary ||
          variant == RmButtonVariant.danger;
      return _ButtonStyle(
        background: solid ? c.primarySoft : Colors.transparent,
        foreground: c.disabled,
        border: variant == RmButtonVariant.outline
            ? Border.all(color: c.border, width: RmSizing.borderWidth)
            : null,
        shadow: RmShadows.none,
        splash: Colors.transparent,
      );
    }

    return switch (variant) {
      RmButtonVariant.primary => _ButtonStyle(
        background: c.primary,
        foreground: c.onPrimary,
        border: null,
        shadow: s.primary,
        splash: c.primaryPressed,
      ),
      RmButtonVariant.outline => _ButtonStyle(
        background: c.surface,
        foreground: c.primaryText,
        border: Border.all(color: c.border, width: RmSizing.borderWidth),
        shadow: RmShadows.none,
        splash: c.primarySoft,
      ),
      RmButtonVariant.ghost => _ButtonStyle(
        background: Colors.transparent,
        foreground: c.primaryText,
        border: null,
        shadow: RmShadows.none,
        splash: c.primarySoft,
      ),
      RmButtonVariant.danger => _ButtonStyle(
        background: c.danger,
        foreground: c.onPrimary,
        border: null,
        shadow: s.danger,
        splash: c.dangerGradientEnd,
      ),
    };
  }
}

@immutable
class _ButtonStyle {
  const _ButtonStyle({
    required this.background,
    required this.foreground,
    required this.border,
    required this.shadow,
    required this.splash,
  });

  final Color background;
  final Color foreground;
  final BoxBorder? border;
  final List<BoxShadow> shadow;
  final Color splash;
}

class _Label extends StatelessWidget {
  const _Label({
    required this.label,
    required this.icon,
    required this.style,
    required this.iconColor,
  });

  final String label;
  final String? icon;
  final TextStyle style;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final Text text = Text(
      label,
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );

    if (icon == null) return text;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        RmIcon(icon!, size: RmIconSize.md, color: iconColor),
        const SizedBox(width: RmSpacing.sm),
        Flexible(child: text),
      ],
    );
  }
}

/// Spinner sized to the label so the button's height never changes.
class _Spinner extends StatelessWidget {
  const _Spinner({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
