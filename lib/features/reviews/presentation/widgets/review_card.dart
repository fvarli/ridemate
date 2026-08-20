// ─────────────────────────────────────────────────────────────
// RideMate — Review card
//
// Source: "REVIEWS · İTİBAR" (immutable). Avatar, name, relative date and
// context, the rating, then the prose.
//
// The card is one semantics node. Split up, the initials are spelled out
// letter by letter and the rating floats loose from the person it belongs to.
//
// The avatar carries neither a verification badge nor a presence dot: the
// comp draws neither, and a review author's identity state is a claim this
// screen has no business making.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/format/rm_formatters.dart';
import '../../../../core/icons/rm_icons.dart';
import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_sizing.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_avatar.dart';
import '../../../../core/widgets/rm_card.dart';
import '../../../../core/widgets/rm_icon.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/review_entry.dart';

/// One review.
class ReviewCard extends StatelessWidget {
  const ReviewCard({required this.entry, super.key});

  final ReviewEntry entry;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmFormatters f = RmFormatters.of(context);

    final String meta = '${entry.age}${RmFormatters.separator}${entry.context}';

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: l10n.reviewsEntrySemanticLabel(
        entry.authorName,
        entry.age,
        entry.context,
        l10n.reviewsRatingSemanticLabel(f.rating(entry.rating)),
        entry.body,
      ),
      child: RmCard(
        padding: const EdgeInsets.all(RmSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                RmAvatar(
                  initials: entry.authorInitials,
                  size: RmAvatarSize.lg,
                  identity: entry.authorIdentity,
                ),
                const SizedBox(width: RmSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        entry.authorName,
                        style: RmTypography.labelSm.copyWith(color: c.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        meta,
                        style: RmTypography.overline.copyWith(color: c.muted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: RmSpacing.sm),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    RmIcon(
                      RmIcons.starFilled,
                      size: RmIconSize.sm,
                      color: c.warning,
                    ),
                    const SizedBox(width: RmSpacing.xs),
                    Text(
                      f.rating(entry.rating),
                      style: RmTypography.numericMicro.copyWith(
                        color: c.warning,
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: RmSpacing.md),
            Text(
              entry.body,
              style: RmTypography.bodySm.copyWith(color: c.sub, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
