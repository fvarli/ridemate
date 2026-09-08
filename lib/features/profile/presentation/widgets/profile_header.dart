// ─────────────────────────────────────────────────────────────
// RideMate — Profile identity header
//
// Source: "PROFILE · TRUST" (immutable). The brand gradient, the squircle
// avatar and the name.
//
// WHAT THE COMP DRAWS HERE THAT THE PRODUCT CANNOT SAY
//
// The design puts a green identity-verified badge on the avatar and a
// `Doğrulanmış üye · 2024'ten beri` pill beside the name. Both were harmless
// while every member on this screen was imaginary. They are not harmless now:
// this header renders a real account's real name, and a verification badge
// beside it would be the app asserting an identity check that does not exist,
// next to the one thing on the screen that is true.
//
// So the badge is RmVerification.none and the pill is gone. RmAvatar keeps
// verification and presence apart on purpose (see rm_avatar.dart); this screen
// now makes neither claim.
//
// The avatar's colour is a fixed decorative choice, NOT derived from the
// member. A per-member colour would imply a categorisation nobody has defined,
// which is the same mistake as a tone computed from a score.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/profile/profile.dart';
import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_sizing.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_avatar.dart';

/// Design 50px of gradient below the identity block, at RmScale.factor.
const double kProfileHeaderFoot = 71;

/// The gradient identity header.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({required this.profile, super.key});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Always the brand gradient, so the status-bar glyphs are light in
      // either theme.
      value: SystemUiOverlayStyle.light,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: c.heroPrimary),
        padding: const EdgeInsets.fromLTRB(
          RmSpacing.screenGutter,
          0,
          RmSpacing.screenGutter,
          kProfileHeaderFoot,
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              RmAvatar(
                // The server's letters, rendered as they arrived. Deriving
                // them here would be a second implementation of a rule the
                // backend already owns — and Turkish casing is exactly where
                // the two would disagree.
                initials: profile.initials,
                size: RmAvatarSize.hero,
                identity: RmIdentity.purple,
                verification: RmVerification.none,
                surfaceColor: c.primary,
                semanticLabel: profile.displayName,
              ),
              const SizedBox(width: RmSpacing.md),
              Expanded(
                child: Text(
                  profile.displayName,
                  style: RmTypography.titleSm.copyWith(color: c.onPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
