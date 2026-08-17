// ─────────────────────────────────────────────────────────────
// RideMate — Search draft
//
// What the member has entered so far. Local presentation state: it drives what
// the Search screen shows and what the Match Results header echoes back.
//
// It does NOT drive matching. Nothing here filters, ranks or scores anything —
// see mock_route_offers.dart for why ordering is a fixture rather than a rule.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

import '../../../core/places/place.dart';

/// The trust filters the design draws on the Search screen.
///
/// These are **search preferences**, not eligibility rules. Toggling one
/// changes only the chip and this draft.
enum SearchFilterId {
  /// `Sadece doğrulanmış`
  verifiedOnly,

  /// `4.5+ puan`
  minRating,

  /// `Kadın sürücü` — see the note below.
  femaleDriver,

  /// `Sigara yok`
  noSmoking,

  /// `Ortak bağlantı`
  mutualConnection,
}

/// How the results list is ordered.
///
/// The order for each option is declared in the fixture; no option is computed.
enum MatchSortOption {
  /// `En uyumlu`
  bestMatch,

  /// `En yakın`
  nearest,

  /// `En ucuz`
  cheapest,
}

/// A gender-based travel preference.
///
/// [SearchFilterId.femaleDriver] is rendered because the approved design
/// includes it, and it toggles like any other chip. It deliberately has **no
/// effect on results**.
///
/// Gender-based matching in transport is regulated, and differently across
/// jurisdictions — sometimes expressly permitted as a safety measure,
/// sometimes restricted as discrimination. Connecting this preference to a
/// real matching engine is a legal, safety and product decision for Türkiye,
/// not something the client layer may quietly author. Recorded in
/// docs/architecture.md.
const SearchFilterId kFilterNeedingPolicyReview = SearchFilterId.femaleDriver;

/// The member's in-progress journey query.
@immutable
final class SearchDraft {
  const SearchDraft({
    required this.origin,
    required this.destination,
    required this.seats,
    required this.filters,
    required this.sort,
  });

  final Place origin;
  final Place destination;

  /// How many seats the member wants. The design shows `1 kişi`.
  final int seats;

  /// Selected trust filters. Presentation only.
  final Set<SearchFilterId> filters;

  final MatchSortOption sort;

  bool isFilterSelected(SearchFilterId id) => filters.contains(id);

  SearchDraft copyWith({
    Place? origin,
    Place? destination,
    int? seats,
    Set<SearchFilterId>? filters,
    MatchSortOption? sort,
  }) => SearchDraft(
    origin: origin ?? this.origin,
    destination: destination ?? this.destination,
    seats: seats ?? this.seats,
    filters: filters ?? this.filters,
    sort: sort ?? this.sort,
  );

  /// Exchanges the two endpoints.
  SearchDraft swapped() => copyWith(origin: destination, destination: origin);

  /// Adds or removes [id].
  SearchDraft withFilterToggled(SearchFilterId id) {
    final Set<SearchFilterId> next = <SearchFilterId>{...filters};
    if (!next.remove(id)) next.add(id);
    return copyWith(filters: next);
  }

  @override
  bool operator ==(Object other) =>
      other is SearchDraft &&
      other.origin == origin &&
      other.destination == destination &&
      other.seats == seats &&
      other.sort == sort &&
      setEquals(other.filters, filters);

  @override
  int get hashCode => Object.hash(
    origin,
    destination,
    seats,
    sort,
    Object.hashAllUnordered(filters),
  );
}
