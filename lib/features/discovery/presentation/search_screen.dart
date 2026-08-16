// ─────────────────────────────────────────────────────────────
// RideMate — Search routes
//
// Source: docs/claude-designs/RideMate App.dc.html, "SEARCH ROUTES" (immutable).
//
// Title → from/to card → when + seats tiles → trust filters → recent searches,
// with the primary action docked at the bottom.
//
// DEVIATION D-search-1: this screen keeps the bottom navigation bar, which the
// comp omits. `Ara` is one of the four designed tab destinations, so Search IS
// a tab; the comp omits the bar on almost every screen. The CTA dock therefore
// sits above the bar rather than at the very bottom of the window.
//
// PHASE 3 SCOPE. No geocoding, no autocomplete, no date picker, no location.
// The filters are presentation preferences and change no results — see
// search_draft.dart, and note the policy review the female-driver filter needs.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/format/rm_formatters.dart';
import '../../../core/icons/rm_icons.dart';
import '../../../core/theme/tokens/rm_colors.dart';
import '../../../core/theme/tokens/rm_sizing.dart';
import '../../../core/theme/tokens/rm_spacing.dart';
import '../../../core/theme/tokens/rm_typography.dart';
import '../../../core/widgets/rm_button.dart';
import '../../../core/widgets/rm_chip.dart';
import '../../../core/widgets/rm_cta_dock.dart';
import '../../../core/widgets/rm_list_row.dart';
import '../../../core/widgets/rm_selector_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../application/discovery_providers.dart';
import '../domain/mock_discovery_fixtures.dart';
import '../domain/place.dart';
import '../domain/search_draft.dart';
import 'widgets/from_to_card.dart';
import 'widgets/place_picker_sheet.dart';

/// The journey search screen.
class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final SearchDraft draft = ref.watch(searchDraftProvider);
    final int resultCount = ref.watch(routeOfferCountProvider);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: RmSpacing.xxl),
                children: <Widget>[
                  _Title(l10n.searchTitle),
                  const SizedBox(height: RmSpacing.xl),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: RmSpacing.screenGutter,
                    ),
                    child: FromToCard(
                      origin: draft.origin,
                      destination: draft.destination,
                      onEditOrigin: () => _pickOrigin(context, ref, draft),
                      onEditDestination: () =>
                          _pickDestination(context, ref, draft),
                      onSwap: () => ref
                          .read(searchDraftProvider.notifier)
                          .swapEndpoints(),
                    ),
                  ),
                  const SizedBox(height: RmSpacing.lg),
                  _WhenAndSeats(draft: draft),
                  const SizedBox(height: RmSpacing.xxl),
                  _Section(title: l10n.searchFiltersTitle),
                  const SizedBox(height: RmSpacing.lg),
                  _FilterChips(draft: draft),
                  const SizedBox(height: RmSpacing.xxl),
                  _Section(title: l10n.searchRecentTitle),
                  const SizedBox(height: RmSpacing.lg),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: RmSpacing.screenGutter,
                    ),
                    child: _RecentSearchRow(
                      onTap: () => ref
                          .read(searchDraftProvider.notifier)
                          .setJourney(
                            origin: MockRecentSearch.origin,
                            destination: MockRecentSearch.destination,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            RmCtaDock(
              children: <Widget>[
                Expanded(
                  child: RmButton(
                    label: l10n.searchSubmit(
                      RmFormatters.of(context).count(resultCount),
                    ),
                    onPressed: () => context.pushNamed(AppRoutes.matches),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickOrigin(
    BuildContext context,
    WidgetRef ref,
    SearchDraft draft,
  ) async {
    final Place? place = await showPlacePicker(
      context,
      title: AppLocalizations.of(context).searchPlacePickerOriginTitle,
      places: MockPlaces.all,
      selected: draft.origin,
    );
    if (place != null) ref.read(searchDraftProvider.notifier).setOrigin(place);
  }

  Future<void> _pickDestination(
    BuildContext context,
    WidgetRef ref,
    SearchDraft draft,
  ) async {
    final Place? place = await showPlacePicker(
      context,
      title: AppLocalizations.of(context).searchPlacePickerDestinationTitle,
      places: MockPlaces.all,
      selected: draft.destination,
    );
    if (place != null) {
      ref.read(searchDraftProvider.notifier).setDestination(place);
    }
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        RmSpacing.screenGutter,
        RmSpacing.lg,
        RmSpacing.screenGutter,
        0,
      ),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: RmTypography.titleLg.copyWith(color: context.rmColors.ink),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: RmSpacing.screenGutter),
      child: RmSectionLabel(title),
    );
  }
}

/// The when + seats pair. Display-only in Phase 3: no date picker exists.
class _WhenAndSeats extends StatelessWidget {
  const _WhenAndSeats({required this.draft});

  final SearchDraft draft;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: RmSpacing.screenGutter),
      child: Row(
        children: <Widget>[
          Expanded(
            child: RmSelectorTile(
              label: l10n.searchWhenLabel,
              value: l10n.searchWhenValue,
            ),
          ),
          const SizedBox(width: RmSpacing.md),
          Expanded(
            child: RmSelectorTile(
              label: l10n.searchSeatsLabel,
              value: l10n.searchSeatsValue(draft.seats),
            ),
          ),
        ],
      ),
    );
  }
}

/// The trust filter cloud.
///
/// Toggling changes only the chip and the draft. Nothing here filters results.
class _FilterChips extends ConsumerWidget {
  const _FilterChips({required this.draft});

  final SearchDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    String labelFor(SearchFilterId id) => switch (id) {
      SearchFilterId.verifiedOnly => l10n.searchFilterVerifiedOnly,
      SearchFilterId.minRating => l10n.searchFilterMinRating,
      SearchFilterId.femaleDriver => l10n.searchFilterFemaleDriver,
      SearchFilterId.noSmoking => l10n.searchFilterNoSmoking,
      SearchFilterId.mutualConnection => l10n.searchFilterMutualConnection,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: RmSpacing.screenGutter),
      child: Wrap(
        spacing: RmSpacing.sm,
        runSpacing: RmSpacing.sm,
        children: <Widget>[
          for (final SearchFilterId id in SearchFilterId.values)
            RmChip(
              label: labelFor(id),
              selected: draft.isFilterSelected(id),
              compact: true,
              // The design gives only the selected chip a leading check.
              icon: draft.isFilterSelected(id) ? RmIcons.check : null,
              onTap: () =>
                  ref.read(searchDraftProvider.notifier).toggleFilter(id),
            ),
        ],
      ),
    );
  }
}

/// One previously-run search. Display only — no history storage.
class _RecentSearchRow extends StatelessWidget {
  const _RecentSearchRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmColors c = context.rmColors;

    return RmListRow(
      title:
          '${MockRecentSearch.origin.label.split(',').first}'
          ' → '
          '${MockRecentSearch.destination.label.split(',').first}',
      icon: RmIcons.clock,
      tintedIcon: false,
      trailing: Text(
        l10n.dateYesterday,
        style: RmTypography.caption.copyWith(color: c.faint),
      ),
      onTap: onTap,
    );
  }
}

/// Reserved so the docked action never sits under the navigation bar.
const double kSearchDockClearance = RmSizing.navBarHeight;
