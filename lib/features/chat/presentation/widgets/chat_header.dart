// ─────────────────────────────────────────────────────────────
// RideMate — Chat header
//
// Source: docs/claude-designs/RideMate App.dc.html, "CHAT" (immutable).
//
// This header is the design's own proof that presence and verification are two
// different claims: it shows a plain green dot ON the avatar and a green check
// BESIDE the name, at the same time. RmAvatar drops presence when verification
// is also passed to it — correctly, since the design never stacks them on one
// badge — so the check is rendered as its own RmVerifiedBadge in the name row.
//
// The row announces once: name, verified, online. The presence dot itself stays
// silent, because the visible "Çevrimiçi" line already says it and a second
// node would say it twice.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/icons/rm_icons.dart';
import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_sizing.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_avatar.dart';
import '../../../../core/widgets/rm_icon_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/chat_fixtures.dart';

/// Back control, participant identity and presence.
class ChatHeader extends StatelessWidget {
  const ChatHeader({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(
          bottom: BorderSide(color: c.hairline, width: RmSizing.borderWidth),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            RmSpacing.screenGutter,
            RmSpacing.lg,
            RmSpacing.screenGutter,
            RmSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              RmIconButton(
                icon: RmIcons.chevronLeft,
                semanticLabel: l10n.commonBack,
                onPressed: onBack,
              ),
              const SizedBox(width: RmSpacing.md),
              Expanded(
                child: Semantics(
                  container: true,
                  excludeSemantics: true,
                  label: l10n.chatHeaderSemanticLabel(MockChatParticipant.name),
                  child: Row(
                    children: <Widget>[
                      RmAvatar(
                        initials: MockChatParticipant.initials,
                        size: RmAvatarSize.sm,
                        identity: MockChatParticipant.identity,
                        // Presence only. The verified check is a separate badge
                        // below — see the file header.
                        presence: MockChatParticipant.presence,
                        surfaceColor: c.surface,
                      ),
                      const SizedBox(width: RmSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Flexible(
                                  child: Text(
                                    MockChatParticipant.name,
                                    style: RmTypography.bodyLg.copyWith(
                                      color: c.ink,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: RmSpacing.xs),
                                if (MockChatParticipant.verification ==
                                    RmVerification.verified)
                                  RmVerifiedBadge(
                                    size: RmIconSize.sm,
                                    surfaceColor: c.surface,
                                  ),
                              ],
                            ),
                            Text(
                              l10n.chatOnline,
                              style: RmTypography.captionSm.copyWith(
                                color: c.success,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
