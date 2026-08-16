// ─────────────────────────────────────────────────────────────
// RideMate — Avatar, verification and presence
//
// Source of truth: docs/claude-designs/RideMate App.dc.html (immutable).
//
// TRUST-SIGNAL HAZARD, recorded deliberately:
//
// The design uses the SAME green circle for two different meanings — with a
// check it means "identity verified", without a check it means "online now".
// In a trust-first product one signal carrying two meanings is a real hazard:
// a member could read a presence dot as a verification badge.
//
// Per the agreed approach, the rendering matches the design exactly (nothing
// changes visually without design approval), but the API keeps the two
// concepts strictly separate and non-interchangeable: [verification] and
// [presence] are distinct types that cannot be passed for one another. If the
// visual is later differentiated, it is a change inside this widget alone.
//
// Geometry is ratio-driven, because the source is provably consistent:
// radius 0.32x the box, initials 0.36x, badge 0.38x. See RmAvatarMetrics.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../icons/rm_icons.dart';
import '../theme/tokens/rm_colors.dart';
import '../theme/tokens/rm_sizing.dart';
import '../theme/tokens/rm_typography.dart';
import 'rm_icon.dart';

/// Whether a member's identity has been verified.
///
/// Distinct from [RmPresence] on purpose — see the file header.
enum RmVerification {
  /// No badge is shown.
  none,

  /// The green check badge. Means identity verification is complete.
  verified,
}

/// Whether a member is currently online.
///
/// Distinct from [RmVerification] on purpose — see the file header.
enum RmPresence {
  /// No dot is shown.
  none,

  /// The green dot. Means online now; says nothing about verification.
  online,
}

/// Identity colour of an avatar. The source uses exactly three gradients.
enum RmIdentity { amber, green, purple }

/// Outline shape of an avatar.
enum RmAvatarShape {
  /// Rounded square. The app's primary avatar form.
  squircle,

  /// Full circle. Map pins and the onboarding hero.
  circle,
}

/// A member avatar with optional verification and presence indicators.
class RmAvatar extends StatelessWidget {
  const RmAvatar({
    required this.initials,
    super.key,
    this.size = RmAvatarSize.md,
    this.shape = RmAvatarShape.squircle,
    this.identity = RmIdentity.amber,
    this.verification = RmVerification.none,
    this.presence = RmPresence.none,
    this.surfaceColor,
    this.semanticLabel,
  });

  /// One or two letters. Build with `RmTextConventions.initials`, which
  /// applies Turkish casing.
  final String initials;

  final double size;
  final RmAvatarShape shape;
  final RmIdentity identity;

  /// Identity verification state. Renders the check badge.
  final RmVerification verification;

  /// Online presence. Renders a plain dot.
  ///
  /// If both are set, verification wins: it is the stronger claim and the
  /// design never stacks the two.
  final RmPresence presence;

  /// The colour of the surface BEHIND the avatar.
  ///
  /// The badge is punched out of its backing with a ring in this colour — the
  /// source varies it across white, page, brand blue and both dark surfaces.
  /// Defaults to the palette surface.
  final Color? surfaceColor;

  /// Screen-reader label, normally the member's name.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final double radius = RmAvatarMetrics.radiusFor(size);

    final Gradient fill = switch (identity) {
      RmIdentity.amber => c.identityAmber,
      RmIdentity.green => c.identityGreen,
      RmIdentity.purple => c.identityPurple,
    };

    final Widget box = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: fill,
        shape: shape == RmAvatarShape.circle
            ? BoxShape.circle
            : BoxShape.rectangle,
        borderRadius: shape == RmAvatarShape.squircle
            ? BorderRadius.circular(radius)
            : null,
      ),
      child: Text(
        initials,
        style: RmTypography.body.copyWith(
          color: c.onPrimary,
          fontSize: RmAvatarMetrics.initialsSizeFor(size),
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );

    final Widget? badge = _buildBadge(c);

    return Semantics(
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: badge == null
          ? box
          : Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                box,
                PositionedDirectional(
                  bottom: -RmAvatarMetrics.badgeOffsetFor(size),
                  end: -RmAvatarMetrics.badgeOffsetFor(size),
                  child: badge,
                ),
              ],
            ),
    );
  }

  Widget? _buildBadge(RmColors c) {
    final double badgeSize = RmAvatarMetrics.badgeSizeFor(size);
    final Color ring = surfaceColor ?? c.surface;

    // Verification is the stronger claim; the design never stacks the two.
    if (verification == RmVerification.verified) {
      return RmVerifiedBadge(size: badgeSize, surfaceColor: ring);
    }
    if (presence == RmPresence.online) {
      return _PresenceDot(size: badgeSize, surfaceColor: ring);
    }
    return null;
  }
}

/// The green check badge meaning "identity verified".
///
/// [surfaceColor] must be the colour behind the avatar: the badge is punched
/// out of that surface with a ring, so a wrong value shows a visible seam.
class RmVerifiedBadge extends StatelessWidget {
  const RmVerifiedBadge({
    required this.size,
    required this.surfaceColor,
    super.key,
    this.semanticLabel,
  });

  final double size;
  final Color surfaceColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return Semantics(
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.success,
          shape: BoxShape.circle,
          border: Border.all(
            color: surfaceColor,
            width: RmSizing.badgeRingWidth,
          ),
        ),
        // The bold check: the source thickens the stroke as the glyph
        // shrinks, so the thin one would vanish at this size.
        child: RmIcon(RmIcons.checkBold, size: size * 0.5, color: c.onPrimary),
      ),
    );
  }
}

/// A plain green dot meaning "online now".
///
/// Deliberately NOT the verified badge — see the hazard note in the header.
class _PresenceDot extends StatelessWidget {
  const _PresenceDot({required this.size, required this.surfaceColor});

  final double size;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.success,
        shape: BoxShape.circle,
        border: Border.all(color: surfaceColor, width: RmSizing.badgeRingWidth),
      ),
    );
  }
}
