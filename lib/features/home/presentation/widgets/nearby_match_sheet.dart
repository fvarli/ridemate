// ─────────────────────────────────────────────────────────────
// RideMate — Nearby matches sheet
//
// Source: docs/claude-designs/RideMate App.dc.html, "HOME · MAP" (immutable).
//
// The card floating above the navigation bar: a header with the match count,
// and a condensed match row.
//
// Everything it shows is presentation data. The fare share is cost-sharing
// display only — nothing here charges anyone or implies a pricing rule, and
// the compatibility figure implies no matching rule.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/format/rm_formatters.dart';
import '../../../../core/format/rm_text_conventions.dart';
import '../../../../core/icons/rm_icons.dart';
import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_radius.dart';
import '../../../../core/theme/tokens/rm_sizing.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_avatar.dart';
import '../../../../core/widgets/rm_card.dart';
import '../../../../core/widgets/rm_chip.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/home_snapshot.dart';

/// The floating "routes near you" card.
class NearbyMatchSheet extends StatelessWidget {
  const NearbyMatchSheet({
    required this.snapshot,
    required this.onSeeAllMatches,
    required this.onMatchSelected,
    super.key,
  });

  final HomeSnapshot snapshot;
  final VoidCallback onSeeAllMatches;
  final ValueChanged<NearbyMatch> onMatchSelected;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmFormatters formatters = RmFormatters.of(context);

    return RmCard(
      variant: RmCardVariant.elevated,
      radius: RmRadius.xxl,
      padding: const EdgeInsets.all(RmSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.homeNearbyRoutesTitle,
                    style: RmTypography.titleSm.copyWith(color: c.ink),
                    // Bounded: at a large text scale the count beside it takes
                    // most of the row, and an unbounded title wraps a character
                    // at a time until the card overflows the screen.
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Semantics(
                container: true,
                button: true,
                excludeSemantics: true,
                label: l10n.homeMatchCount(
                  formatters.count(snapshot.matchCount),
                ),
                child: InkWell(
                  onTap: onSeeAllMatches,
                  borderRadius: RmRadius.brXs,
                  child: Padding(
                    padding: const EdgeInsets.all(RmSpacing.xs),
                    child: Text(
                      l10n.homeMatchCount(
                        formatters.count(snapshot.matchCount),
                      ),
                      style: RmTypography.labelSm.copyWith(
                        color: c.primaryText,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          for (final NearbyMatch match in snapshot.matches) ...<Widget>[
            const SizedBox(height: RmSpacing.lg),
            _MatchRow(match: match, onTap: () => onMatchSelected(match)),
          ],
        ],
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.match, required this.onTap});

  final NearbyMatch match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmFormatters formatters = RmFormatters.of(context);

    final String costShare = formatters.money(match.costSharePerPerson);
    final String rating = formatters.rating(match.rating);
    final String compatibility = formatters.percent(match.compatibility);
    final String route = RmTextConventions.route(
      match.origin,
      match.destination,
    );

    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      label: l10n.homeMatchSemanticLabel(
        match.displayName,
        rating,
        route,
        costShare,
        compatibility,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: RmRadius.brLg,
        child: Row(
          children: <Widget>[
            RmAvatar(
              initials: match.initials,
              size: RmAvatarSize.lg,
              identity: match.identity,
              verification: match.isVerified
                  ? RmVerification.verified
                  : RmVerification.none,
              // The badge is punched out of the card behind it.
              surfaceColor: c.surface,
            ),
            const SizedBox(width: RmSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) =>
                            Row(
                              children: <Widget>[
                                // Expanded, not Flexible: the name must absorb
                                // ALL the shrinkage so the rating keeps its
                                // natural size. A loose Flexible would keep the
                                // name's full width and overflow the row.
                                Expanded(
                                  child: Text(
                                    match.displayName,
                                    style: RmTypography.body.copyWith(
                                      color: c.ink,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: RmSpacing.sm),
                                // The rating may take at most half the row.
                                // Unbounded, it keeps growing with the text
                                // scale until it overflows a name that has
                                // already shrunk to nothing.
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: constraints.maxWidth / 2,
                                  ),
                                  // Never the U+2605 glyph: it is absent from
                                  // the bundled fonts and renders as tofu.
                                  child: RmBadge(
                                    label: rating,
                                    icon: RmIcons.starFilled,
                                    numeric: true,
                                  ),
                                ),
                              ],
                            ),
                  ),
                  const SizedBox(height: RmSpacing.xs),
                  Text(
                    route,
                    style: RmTypography.caption.copyWith(color: c.sub),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: RmSpacing.md),
            // Bounded so the price column can never grow past its share and
            // truncate the member's name. RmBadge ellipsizes inside a bounded
            // row, so a longer localized label degrades rather than pushes.
            //
            // Deliberately not scaled with the text: widening it at a large
            // text scale starves the name and rating beside it. The cost share
            // wrapping onto two lines there is the better trade — the figure
            // stays fully readable.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    costShare,
                    style: RmTypography.numericMd.copyWith(color: c.ink),
                  ),
                  const SizedBox(height: RmSpacing.xs),
                  RmBadge(label: l10n.homeCompatibility(compatibility)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
