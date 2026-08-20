// ─────────────────────────────────────────────────────────────
// RideMate — Profile identity header
//
// Source: "PROFILE · TRUST" (immutable). The brand gradient, the squircle
// avatar with its verification badge, the name, and the membership pill.
//
// The badge is VERIFICATION, not presence. RmAvatar keeps the two apart on
// purpose and this screen only ever makes the identity claim — see
// rm_avatar.dart. Neither claim is backed by anything: there is no identity
// provider and no accounts.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_sizing.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_avatar.dart';
import '../../../../core/widgets/rm_chip.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/profile_snapshot.dart';

/// Design 50px of gradient below the identity block, at RmScale.factor.
const double kProfileHeaderFoot = 71;

/// The gradient identity header.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({required this.snapshot, super.key});

  final ProfileSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);

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
                initials: snapshot.initials,
                size: RmAvatarSize.hero,
                identity: snapshot.identity,
                verification: snapshot.verification,
                // The badge is punched out of the gradient it sits on.
                surfaceColor: c.primary,
                semanticLabel: snapshot.name,
              ),
              const SizedBox(width: RmSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      snapshot.name,
                      style: RmTypography.titleSm.copyWith(color: c.onPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: RmSpacing.xs),
                    // The comp sizes this pill to its content, so it is laid
                    // out at its own width rather than stretched.
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: RmBadge(
                        label: l10n.profileMemberBadge,
                        tone: RmBadgeTone.onColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
