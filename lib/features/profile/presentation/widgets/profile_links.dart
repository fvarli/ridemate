// ─────────────────────────────────────────────────────────────
// RideMate — Profile list rows
//
// Source: "PROFILE · TRUST" (immutable). Two rows.
//
// `Doğrulama rozetleri` carries a `4 / 5` count and NO chevron, so it is not
// tappable — and it therefore announces no button. The comp draws it that
// way; it counts the five steps /verification already models but does not
// link to them, which is raised in docs/design-system.md §8 rather than
// invented here.
//
// The count only exists in the trailing badge, which emits no semantics of
// its own, so the row's announcement is spelled out explicitly. Without that
// a screen-reader user hears the title and never learns the number that is
// the entire point of the row.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/format/rm_formatters.dart';
import '../../../../core/icons/rm_icons.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/widgets/rm_chip.dart';
import '../../../../core/widgets/rm_list_row.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/profile_snapshot.dart';

/// The two navigation rows below the stats.
class ProfileLinks extends StatelessWidget {
  const ProfileLinks({
    required this.snapshot,
    required this.onOpenReviews,
    super.key,
  });

  final ProfileSnapshot snapshot;
  final VoidCallback onOpenReviews;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmFormatters f = RmFormatters.of(context);

    final String done = f.count(snapshot.verifiedBadgeCount);
    final String total = f.count(snapshot.verifiedBadgeTotal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        RmListRow(
          title: l10n.profileVerificationBadges,
          icon: RmIcons.shieldCheck,
          tone: RmRowTone.success,
          tintedIcon: false,
          trailing: RmBadge(label: '$done / $total'),
          semanticLabel: l10n.profileVerificationBadgesSemanticLabel(
            done,
            total,
          ),
        ),
        const SizedBox(height: RmSpacing.sm),
        RmListRow(
          title: l10n.profileMyReviews,
          icon: RmIcons.star,
          tone: RmRowTone.warning,
          tintedIcon: false,
          onTap: onOpenReviews,
        ),
      ],
    );
  }
}
