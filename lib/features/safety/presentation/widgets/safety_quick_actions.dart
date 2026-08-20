// ─────────────────────────────────────────────────────────────
// RideMate — Safety quick actions
//
// Source: "SAFETY · SOS" (immutable). Two tiles: call 112, share the trip.
//
// NEITHER TILE DOES WHAT IT SAYS, and both say so when pressed.
//
// `112'yi ara` cannot place a call: there is no `tel:` URI, no url_launcher,
// no platform channel, no permission request and no dialler integration
// anywhere in this app. Its message names that gap rather than apologising
// generically, because the missing capability is the useful part.
//
// Which number to offer is also a product question — 112 is EU and Turkey,
// and the app already ships English and declares Arabic as a target — and so
// is whether an app should place the call at all or hand the member to their
// own dialler. Both are recorded in docs/design-system.md §8.
//
// `Yolculuğu paylaş` shares nothing. There is no live location.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_radius.dart';
import '../../../../core/theme/tokens/rm_sizing.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_card.dart';
import '../../../../core/widgets/rm_icon.dart';
import '../../../../l10n/app_localizations.dart';

/// The two-up action row.
class SafetyQuickActions extends StatelessWidget {
  const SafetyQuickActions({required this.actions, super.key});

  final List<SafetyQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < actions.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: RmSpacing.md),
            Expanded(child: _QuickActionTile(action: actions[i])),
          ],
        ],
      ),
    );
  }
}

/// One quick action, as declared by the screen.
@immutable
class SafetyQuickAction {
  const SafetyQuickAction({
    required this.icon,
    required this.title,
    required this.caption,
    required this.tone,
    required this.onPressed,
  });

  final String icon;
  final String title;
  final String caption;
  final SafetyActionTone tone;
  final VoidCallback onPressed;
}

/// The two tints the design uses.
enum SafetyActionTone { danger, primary }

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final SafetyQuickAction action;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);

    final (Color icon, Color tint) = switch (action.tone) {
      SafetyActionTone.danger => (c.danger, c.dangerSoft),
      SafetyActionTone.primary => (c.primary, c.primarySoft),
    };

    return RmCard(
      onTap: action.onPressed,
      padding: const EdgeInsets.all(RmSpacing.lg),
      // Announced exactly as drawn. What pressing it does is the message it
      // shows, not a different label.
      semanticLabel: l10n.safetyQuickActionSemanticLabel(
        action.title,
        action.caption,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: RmSizing.iconButtonSm,
            height: RmSizing.iconButtonSm,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: tint, borderRadius: RmRadius.brMd),
            child: RmIcon(action.icon, size: RmIconSize.md, color: icon),
          ),
          const SizedBox(height: RmSpacing.md),
          Text(
            action.title,
            style: RmTypography.labelSm.copyWith(color: c.ink),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            action.caption,
            style: RmTypography.overline.copyWith(color: c.muted),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
