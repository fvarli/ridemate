// ─────────────────────────────────────────────────────────────
// RideMate — What a member is searching for
//
// The draft is the Search screen's editable state: two endpoints, chosen from
// the server's catalogue. Submitting turns it into a DiscoveryQuery, which is
// what the results provider watches.
//
// The offers this file used to expose are gone. They were MockRouteOffers in a
// declared order per sort option, and Match Results reads the real endpoint
// now. Route Details still uses the fixture, and still says so on its own face.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/places/place.dart';
import '../domain/search_draft.dart';

/// The member's in-progress journey query.
///
/// App-scoped rather than screen-scoped, so the Search tab keeps what was typed
/// when the member switches tabs.
final NotifierProvider<SearchDraftController, SearchDraft> searchDraftProvider =
    NotifierProvider<SearchDraftController, SearchDraft>(
      SearchDraftController.new,
    );

class SearchDraftController extends Notifier<SearchDraft> {
  @override
  SearchDraft build() => const SearchDraft();

  void setOrigin(Place place) => state = state.copyWith(origin: place);

  void setDestination(Place place) =>
      state = state.copyWith(destination: place);

  /// Exchanges the two endpoints.
  void swapEndpoints() => state = state.swapped();

  /// Drops any endpoint the refreshed catalogue no longer contains.
  ///
  /// Matched by id, never by label: a label is what a place is called, not what
  /// it is, and two places can be renamed into each other's names.
  void reconcileWith(List<Place> places) {
    final Set<String> available = <String>{
      for (final Place place in places) place.id,
    };

    state = SearchDraft(
      origin: available.contains(state.origin?.id) ? state.origin : null,
      destination: available.contains(state.destination?.id)
          ? state.destination
          : null,
    );
  }
}
