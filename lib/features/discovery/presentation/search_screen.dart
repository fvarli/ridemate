// ─────────────────────────────────────────────────────────────
// RideMate — Search routes
//
// Source: docs/claude-designs/RideMate App.dc.html, "SEARCH ROUTES" (immutable).
//
// Title → from/to card → search, with the primary action docked at the bottom.
//
// DEVIATION D-search-1: this screen keeps the bottom navigation bar, which the
// comp omits. `Ara` is one of the four designed tab destinations, so Search IS
// a tab.
//
// DEVIATION D-search-2: the comp's when tile, seat stepper, five trust filters
// and recent-search row are GONE.
//
// They were real, editable state that changed a chip and changed nothing else —
// honest enough while the results were a fixture, because a control that
// reorders an invented list is not lying to anybody. Phase 12 made the results
// real, and the endpoint accepts two place ids and refuses everything else. A
// `Doğrulanmış` filter above journeys the server actually returned reads as a
// filter the server applied; a seat count reads as availability nothing tracks;
// a date reads as matching to a day, which needs occurrences nobody has built.
//
// Collecting those values and discarding them is how a member comes to believe
// a filter works. They come back when something can answer them.
//
// The CTA no longer reports a result count either: it said how many results
// there would be BEFORE the search had run.
//
// ENDPOINTS COME FROM THE SERVER'S CATALOGUE
//
// The same places Create Route publishes against, so a chosen endpoint is an id
// the discovery query can actually use. No geocoding, no autocomplete, no
// location — and no fixture fallback when the catalogue cannot be read.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/icons/rm_icons.dart';
import '../../../core/places/place.dart';
import '../../../core/theme/tokens/rm_colors.dart';
import '../../../core/theme/tokens/rm_spacing.dart';
import '../../../core/theme/tokens/rm_typography.dart';
import '../../../core/widgets/rm_button.dart';
import '../../../core/widgets/rm_cta_dock.dart';
import '../../../core/widgets/rm_list_row.dart';
import '../../../core/widgets/rm_place_picker_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../create_route/application/place_catalogue_providers.dart';
import '../application/discovery_providers.dart';
import '../application/discovery_search_providers.dart';
import '../domain/search_draft.dart';
import 'widgets/from_to_card.dart';

/// The journey search screen.
class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final SearchDraft draft = ref.watch(searchDraftProvider);
    final AsyncValue<List<Place>> catalogue = ref.watch(placeCatalogueProvider);

    // A refreshed catalogue may no longer contain something already chosen.
    // Matched on id: a place that has gone is gone, whatever it was called, and
    // keeping a reference the server would reject helps nobody.
    ref.listen<AsyncValue<List<Place>>>(placeCatalogueProvider, (
      AsyncValue<List<Place>>? previous,
      AsyncValue<List<Place>> next,
    ) {
      final List<Place>? places = next.value;
      if (places != null) {
        ref.read(searchDraftProvider.notifier).reconcileWith(places);
      }
    });

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
                      onEditOrigin: () =>
                          _pick(context, ref, catalogue, isOrigin: true),
                      onEditDestination: () =>
                          _pick(context, ref, catalogue, isOrigin: false),
                      onSwap: () => ref
                          .read(searchDraftProvider.notifier)
                          .swapEndpoints(),
                    ),
                  ),
                  // The catalogue's own state, said plainly. No fixture list
                  // stands in for it.
                  if (catalogue.hasError) ...<Widget>[
                    const SizedBox(height: RmSpacing.lg),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: RmSpacing.screenGutter,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          RmInlineMessage(
                            message: l10n.createRoutePlacesUnavailable,
                            icon: RmIcons.alertTriangle,
                            tone: RmRowTone.danger,
                          ),
                          const SizedBox(height: RmSpacing.md),
                          RmButton(
                            label: l10n.commonRetry,
                            size: RmButtonSize.sm,
                            variant: RmButtonVariant.outline,
                            onPressed: () => ref
                                .read(placeCatalogueProvider.notifier)
                                .refresh(),
                          ),
                        ],
                      ),
                    ),
                  ] else if (catalogue.isLoading) ...<Widget>[
                    const SizedBox(height: RmSpacing.lg),
                    _Hint(l10n.createRoutePlacesLoading),
                  ] else if (!draft.isComplete) ...<Widget>[
                    const SizedBox(height: RmSpacing.lg),
                    _Hint(l10n.searchIncomplete),
                  ],
                ],
              ),
            ),
            RmCtaDock(
              children: <Widget>[
                Expanded(
                  child: RmButton(
                    label: l10n.searchSubmit,
                    // Null disables it. Not a dead control: it becomes tappable
                    // as soon as there are two different places to ask about.
                    onPressed: draft.isComplete
                        ? () => _search(context, ref, draft)
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Turns the draft into the query the results provider watches, then opens
  /// the list. The screen performs no request of its own.
  void _search(BuildContext context, WidgetRef ref, SearchDraft draft) {
    ref
        .read(discoveryQueryProvider.notifier)
        .search(
          DiscoveryQuery(
            originPlaceId: draft.origin!.id,
            destinationPlaceId: draft.destination!.id,
          ),
        );

    context.pushNamed(AppRoutes.matches);
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Place>> catalogue, {
    required bool isOrigin,
  }) async {
    final List<Place>? places = catalogue.value;

    // The picker opens only with a catalogue the server confirmed. With none,
    // there is nothing honest to offer.
    if (places == null || places.isEmpty) return;

    final SearchDraft draft = ref.read(searchDraftProvider);
    final AppLocalizations l10n = AppLocalizations.of(context);

    final Place? place = await showPlacePicker(
      context,
      title: isOrigin
          ? l10n.searchPlacePickerOriginTitle
          : l10n.searchPlacePickerDestinationTitle,
      places: places,
      selected: isOrigin ? draft.origin : draft.destination,
    );

    if (place == null) return;

    final SearchDraftController controller = ref.read(
      searchDraftProvider.notifier,
    );
    isOrigin ? controller.setOrigin(place) : controller.setDestination(place);
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
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

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: RmSpacing.screenGutter),
    child: Text(
      text,
      style: RmTypography.caption.copyWith(color: context.rmColors.sub),
    ),
  );
}
