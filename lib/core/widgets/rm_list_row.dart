// ─────────────────────────────────────────────────────────────
// RideMate — List row, section label, inline message, skeleton
//
// Source of truth: docs/claude-designs/RideMate App.dc.html (immutable).
//
// RmListRow covers the navigation rows on Profile and the Safety Center. The
// source shows two leading treatments — a bare icon, and an icon inside a
// tinted tile whose colour is semantic (green trusted contacts, blue verify,
// red block/report) — and two trailing treatments, a chevron or a count badge.
//
// RmSkeleton is INVENTED. The source has no loading state at all; this is
// derived from the surfaceMuted token so screens have something honest to
// show while data is in flight.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../icons/rm_icons.dart';
import '../theme/tokens/rm_colors.dart';
import '../theme/tokens/rm_motion.dart';
import '../theme/tokens/rm_radius.dart';
import '../theme/tokens/rm_sizing.dart';
import '../theme/tokens/rm_spacing.dart';
import '../theme/tokens/rm_typography.dart';
import 'rm_card.dart';
import 'rm_icon.dart';

/// Semantic colour of a list row's leading icon tile.
enum RmRowTone { neutral, primary, success, warning, danger }

/// A navigation row: leading icon, title, optional subtitle, trailing affordance.
class RmListRow extends StatelessWidget {
  const RmListRow({
    required this.title,
    super.key,
    this.subtitle,
    this.icon,
    this.tone = RmRowTone.neutral,
    this.tintedIcon = true,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;

  /// Leading icon from [RmIcons].
  final String? icon;

  /// Drives the leading tile and icon colour.
  final RmRowTone tone;

  /// Whether the icon sits in a tinted tile (Safety Center) or bare (Profile).
  final bool tintedIcon;

  /// Trailing widget. Defaults to a chevron when [onTap] is set.
  final Widget? trailing;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final (Color iconColor, Color tint) = switch (tone) {
      RmRowTone.neutral => (c.sub, c.surfaceMuted),
      RmRowTone.primary => (c.primaryText, c.primarySoft),
      RmRowTone.success => (c.success, c.successSoft),
      RmRowTone.warning => (c.warning, c.warningSoft),
      RmRowTone.danger => (c.danger, c.dangerSoft),
    };

    final Widget? leading = icon == null
        ? null
        : tintedIcon
        ? Container(
            width: RmSizing.iconButtonSm,
            height: RmSizing.iconButtonSm,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: tint, borderRadius: RmRadius.brMd),
            child: RmIcon(icon!, size: RmIconSize.md, color: iconColor),
          )
        : RmIcon(icon!, size: RmIconSize.md, color: iconColor);

    return RmCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: RmSpacing.lg,
        vertical: RmSpacing.md,
      ),
      semanticLabel: subtitle == null ? title : '$title. $subtitle',
      child: Row(
        children: <Widget>[
          if (leading != null) ...<Widget>[
            leading,
            const SizedBox(width: RmSpacing.lg),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: RmTypography.body.copyWith(color: c.ink),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: RmSpacing.xxs),
                  Text(
                    subtitle!,
                    style: RmTypography.captionSm.copyWith(color: c.muted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: RmSpacing.md),
            trailing!,
          ] else if (onTap != null) ...<Widget>[
            const SizedBox(width: RmSpacing.md),
            RmIcon(
              RmIcons.chevronRight,
              size: RmIconSize.md,
              color: c.disabled,
            ),
          ],
        ],
      ),
    );
  }
}

/// An uppercase section heading, e.g. `GÜVEN FİLTRELERİ`.
class RmSectionLabel extends StatelessWidget {
  const RmSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text.toUpperCase(),
        style: RmTypography.labelSm.copyWith(color: context.rmColors.sub),
      ),
    );
  }
}

/// An inline advisory banner.
///
/// Derived from the amber safety banner in the chat screen — the one genuine
/// inline-message component in the source — generalised across tones.
class RmInlineMessage extends StatelessWidget {
  const RmInlineMessage({
    required this.message,
    super.key,
    this.icon = RmIcons.shieldAlert,
    this.tone = RmRowTone.warning,
  });

  final String message;
  final String icon;
  final RmRowTone tone;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final (Color fg, Color bg, Color border) = switch (tone) {
      RmRowTone.warning => (c.warningInk, c.warningSoft, c.warningBorder),
      RmRowTone.danger => (c.danger, c.dangerSoft, c.danger),
      RmRowTone.success => (c.successInk, c.successSoft, c.success),
      RmRowTone.primary ||
      RmRowTone.neutral => (c.primaryText, c.primarySoft, c.primarySoftBorder),
    };

    return Container(
      padding: const EdgeInsets.all(RmSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: RmRadius.brMd,
        border: Border.all(color: border, width: RmSizing.borderWidth),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          RmIcon(icon, size: RmIconSize.md, color: fg),
          const SizedBox(width: RmSpacing.md),
          Expanded(
            child: Text(
              message,
              style: RmTypography.caption.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// A shimmering placeholder for content that has not arrived yet.
///
/// INVENTED: the source contains no loading state. Built purely from the
/// surfaceMuted token so it inherits both themes for free.
class RmSkeleton extends StatefulWidget {
  const RmSkeleton({
    super.key,
    this.width,
    this.height = RmSpacing.lg,
    this.radius = RmRadius.xs,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<RmSkeleton> createState() => _RmSkeletonState();
}

class _RmSkeletonState extends State<RmSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: RmMotion.pulse,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return ExcludeSemantics(
      child: FadeTransition(
        // Reuses the source's rm-pulse opacity range so loading feels like
        // part of the same system as the live-trip dot.
        opacity: Tween<double>(
          begin: 1,
          end: RmMotion.pulseMinOpacity,
        ).animate(CurvedAnimation(parent: _controller, curve: RmMotion.ease)),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: c.surfaceMuted,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}
