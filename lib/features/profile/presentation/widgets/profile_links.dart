// ─────────────────────────────────────────────────────────────
// RideMate — Profile list rows
//
// Source: "PROFILE · TRUST" (immutable).
//
// The comp draws three rows. `Doğrulama rozetleri` carried a `4 / 5` count and
// is GONE: the number counted verification steps nobody has taken, on a screen
// that now shows a real account. A count of completed checks, beside a real
// name, reads as a fact about that member — and there is no verification
// system to make it one.
//
// What remains is navigation, which promises only what it delivers.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/icons/rm_icons.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/widgets/rm_list_row.dart';
import '../../../../l10n/app_localizations.dart';

/// The navigation rows below the header.
class ProfileLinks extends StatelessWidget {
  const ProfileLinks({
    required this.onEditProfile,
    required this.onOpenReviews,
    required this.onOpenMyRoutes,
    required this.onOpenMyRequests,
    super.key,
  });

  final VoidCallback onEditProfile;
  final VoidCallback onOpenReviews;
  final VoidCallback onOpenMyRoutes;
  final VoidCallback onOpenMyRequests;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // First, because it is the only row that changes something a member
        // owns rather than opening a list.
        RmListRow(
          title: l10n.profileEditName,
          icon: RmIcons.person,
          tone: RmRowTone.primary,
          tintedIcon: false,
          onTap: onEditProfile,
        ),
        const SizedBox(height: RmSpacing.sm),
        RmListRow(
          title: l10n.profileMyRoutes,
          icon: RmIcons.car,
          tone: RmRowTone.primary,
          tintedIcon: false,
          onTap: onOpenMyRoutes,
        ),
        const SizedBox(height: RmSpacing.sm),
        // The passenger side of the same history: what this member asked for,
        // beside what they published.
        RmListRow(
          title: l10n.myRequestsOpen,
          icon: RmIcons.check,
          tone: RmRowTone.primary,
          tintedIcon: false,
          onTap: onOpenMyRequests,
        ),
        const SizedBox(height: RmSpacing.sm),
        // Still fixture-backed, and still only a link. It opens a screen that
        // makes its own claims; this row makes none.
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
