// ─────────────────────────────────────────────────────────────
// RideMate — Discovery state
//
// The search draft is real, editable state. The offers are a fixture.
//
// No repository is introduced: there is no API to model, and overriding these
// providers is already the seam a real source would use. Building an interface
// for an endpoint that does not exist is the ceremony architecture.md forbids.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/places/place.dart';
import '../domain/mock_discovery_fixtures.dart';
import '../domain/route_offer.dart';
import '../domain/search_draft.dart';

/// The member's in-progress journey query.
///
/// App-scoped rather than screen-scoped, because Match Results echoes the
/// draft in its subtitle and the Search tab must keep its state when the
/// member switches tabs.
final NotifierProvider<SearchDraftController, SearchDraft> searchDraftProvider =
    NotifierProvider<SearchDraftController, SearchDraft>(
      SearchDraftController.new,
    );

class SearchDraftController extends Notifier<SearchDraft> {
  @override
  SearchDraft build() => kInitialSearchDraft;

  void setOrigin(Place place) => state = state.copyWith(origin: place);

  void setDestination(Place place) =>
      state = state.copyWith(destination: place);

  /// Exchanges the two endpoints.
  void swapEndpoints() => state = state.swapped();

  /// Adds or removes a trust filter.
  ///
  /// Presentation only: this changes the chip and the draft, and deliberately
  /// does not affect which offers are returned. See SearchFilterId.
  void toggleFilter(SearchFilterId id) => state = state.withFilterToggled(id);

  void setSort(MatchSortOption sort) => state = state.copyWith(sort: sort);

  void setSeats(int seats) => state = state.copyWith(seats: seats);

  /// Replaces both endpoints, e.g. from a recent search.
  void setJourney({required Place origin, required Place destination}) =>
      state = state.copyWith(origin: origin, destination: destination);
}

/// The offers to show, in the order declared for the current sort.
///
/// Watches only `sort`: the filters intentionally have no effect on results.
final Provider<List<RouteOffer>> routeOffersProvider =
    Provider<List<RouteOffer>>((Ref ref) {
      final MatchSortOption sort = ref.watch(
        searchDraftProvider.select((SearchDraft d) => d.sort),
      );
      return MockRouteOffers.orderedFor(sort);
    });

/// How many offers the CTA and the results header report.
final Provider<int> routeOfferCountProvider = Provider<int>(
  (Ref ref) => ref.watch(routeOffersProvider).length,
);
