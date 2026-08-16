// ─────────────────────────────────────────────────────────────
// RideMate — Match results
//
// Source: docs/claude-designs/RideMate App.dc.html, "MATCH RESULTS" (immutable).
//
// Back + two-line title → sort chips → the results list. No bottom dock: the
// design has none here, and it deliberately clips the third card as a scroll
// affordance, so the list genuinely scrolls.
//
// NO MATCHING LOGIC. The list and its order come from a fixture; each sort
// option has a DECLARED order rather than a computed one. See
// mock_discovery_fixtures.dart. The search filters, including the female-driver
// preference, do not narrow or reorder this list.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/format/rm_formatters.dart';
import '../../../core/format/rm_text_conventions.dart';
import '../../../core/icons/rm_icons.dart';
import '../../../core/theme/tokens/rm_colors.dart';
import '../../../core/theme/tokens/rm_spacing.dart';
import '../../../core/theme/tokens/rm_typography.dart';
import '../../../core/widgets/rm_chip.dart';
import '../../../core/widgets/rm_icon_button.dart';
import '../../../l10n/app_localizations.dart';
import '../application/discovery_providers.dart';
import '../domain/route_offer.dart';
import '../domain/search_draft.dart';
import 'widgets/match_card.dart';

/// The results list.
class MatchResultsScreen extends ConsumerWidget {
  const MatchResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RmColors c = context.rmColors;
    final SearchDraft draft = ref.watch(searchDraftProvider);
    final List<RouteOffer> offers = ref.watch(routeOffersProvider);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _Header(draft: draft, resultCount: offers.length),
            const SizedBox(height: RmSpacing.md),
            _SortRow(selected: draft.sort),
            const SizedBox(height: RmSpacing.lg),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  RmSpacing.screenGutter,
                  0,
                  RmSpacing.screenGutter,
                  RmSpacing.huge,
                ),
                itemCount: offers.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: RmSpacing.md),
                itemBuilder: (BuildContext context, int index) => MatchCard(
                  offer: offers[index],
                  // The tier is a presentation rank the fixture's order
                  // assigns; nothing is scored here.
                  tier: switch (index) {
                    0 => MatchCardTier.highlighted,
                    1 => MatchCardTier.standard,
                    _ => MatchCardTier.condensed,
                  },
                  onInspect: () => context.pushNamed(
                    AppRoutes.routeDetails,
                    pathParameters: <String, String>{
                      AppRoutes.routeIdParam: offers[index].id,
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.draft, required this.resultCount});

  final SearchDraft draft;
  final int resultCount;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmFormatters f = RmFormatters.of(context);

    // The header echoes the draft back, so the member can see what produced
    // these results.
    final String route = RmTextConventions.route(
      draft.origin.label.split(',').first,
      draft.destination.label.split(',').first,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        RmSpacing.screenGutter,
        RmSpacing.lg,
        RmSpacing.screenGutter,
        0,
      ),
      child: Row(
        children: <Widget>[
          RmIconButton(
            icon: RmIcons.chevronLeft,
            semanticLabel: l10n.commonBack,
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: RmSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Semantics(
                  header: true,
                  child: Text(
                    l10n.matchesTitle(f.count(resultCount)),
                    style: RmTypography.titleMd.copyWith(color: c.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  l10n.matchesSubtitle(route, l10n.matchesWhenSummary),
                  style: RmTypography.caption.copyWith(color: c.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The sort chips.
///
/// Selecting one changes the DECLARED order the fixture returns. No comparison
/// or ranking happens in code.
class _SortRow extends ConsumerWidget {
  const _SortRow({required this.selected});

  final MatchSortOption selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    String labelFor(MatchSortOption option) => switch (option) {
      MatchSortOption.bestMatch => l10n.matchesSortBest,
      MatchSortOption.nearest => l10n.matchesSortNearest,
      MatchSortOption.cheapest => l10n.matchesSortCheapest,
    };

    return SizedBox(
      height: RmSpacing.huge + RmSpacing.md,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: RmSpacing.screenGutter),
        children: <Widget>[
          for (final MatchSortOption option
              in MatchSortOption.values) ...<Widget>[
            RmChip(
              label: labelFor(option),
              // The design selects the sort chip in ink, not brand blue.
              tone: RmChipTone.ink,
              selected: option == selected,
              compact: true,
              onTap: () =>
                  ref.read(searchDraftProvider.notifier).setSort(option),
            ),
            const SizedBox(width: RmSpacing.sm),
          ],
        ],
      ),
    );
  }
}
