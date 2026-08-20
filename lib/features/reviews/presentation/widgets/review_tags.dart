// ─────────────────────────────────────────────────────────────
// RideMate — Review attribute tags
//
// Source: "REVIEWS · İTİBAR" (immutable). Four tinted pills that wrap.
//
// The counts sum to more than the review total because a review carries
// several tags. Nothing here adds them up, and nothing filters by them: the
// comp draws no tag interaction at all, so they are display only.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/format/rm_formatters.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/widgets/rm_chip.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/review_entry.dart';

/// The attribute tag cloud.
class ReviewTags extends StatelessWidget {
  const ReviewTags({required this.tags, super.key});

  final List<ReviewTag> tags;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmFormatters f = RmFormatters.of(context);

    return Wrap(
      spacing: RmSpacing.sm,
      runSpacing: RmSpacing.sm,
      children: <Widget>[
        for (final ReviewTag tag in tags)
          RmChip(
            label: l10n.reviewsTagLabel(tag.label, f.count(tag.count)),
            tone: RmChipTone.info,
          ),
      ],
    );
  }
}
