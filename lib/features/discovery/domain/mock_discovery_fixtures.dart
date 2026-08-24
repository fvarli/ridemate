// ─────────────────────────────────────────────────────────────
// RideMate — Discovery fixtures
//
// PRESENTATION FIXTURES. NOT BUSINESS RULES.
//
// Everything here reproduces the approved design so the discovery flow can be
// seen and reviewed on a device. None of it is a policy:
//
//   * the places are a fixed list, not a geocoding result;
//   * the offers carry their own figures, none of which is derived;
//   * the ORDER for each sort option is DECLARED, not computed.
//
// That last point matters most. Sorting "most compatible" in code would mean
// the client had authored the ranking rule for a matching engine that does not
// exist and will be backend-owned. Declaring the order per option keeps the
// chips genuinely working while inventing nothing.
// ─────────────────────────────────────────────────────────────

import '../../../core/places/mock_places.dart';
import '../../../core/places/place.dart';
import '../../../core/widgets/rm_avatar.dart';
import 'route_offer.dart';
import 'search_draft.dart';

/// The journey the design shows already filled in.
const SearchDraft kInitialSearchDraft = SearchDraft(
  origin: MockPlaces.kadikoy,
  destination: MockPlaces.levent,
  seats: 1,
  // The design shows only "Sadece doğrulanmış" selected.
  filters: <SearchFilterId>{SearchFilterId.verifiedOnly},
  sort: MatchSortOption.bestMatch,
);

/// One previously-run search, as the design's `SON ARAMALAR` row shows.
///
/// Display only — there is no search history storage and no management UI.
abstract final class MockRecentSearch {
  const MockRecentSearch._();

  static const Place origin = MockPlaces.kadikoy;
  static const Place destination = MockPlaces.maslak;
}

/// The three offers the design draws, with every figure it displays.
abstract final class MockRouteOffers {
  const MockRouteOffers._();

  static const RouteOffer selin = RouteOffer(
    id: 'offer-selin-kadikoy-levent',
    driverName: 'Selin K.',
    initials: 'SK',
    identity: RmIdentity.amber,
    isVerified: true,
    rating: 4.9,
    tripCount: 128,
    sharedRouteCount: 2,
    originLabel: 'Kadıköy İskele',
    destinationLabel: 'Levent Metro',
    departureHour: 8,
    departureMinute: 25,
    arrivalHour: 8,
    arrivalMinute: 57,
    tripMinutes: 32,
    seatsAvailable: 1,
    walkMinutes: 5,
    costSharePerPerson: 18,
    compatibility: 0.94,
    trustScore: 92,
    approvalRate: 0.98,
    sharedDistance: '3.4k',
    memberSince: '2023',
    homeArea: 'Kadıköy',
    vehicleName: 'VW Passat · Gri',
    plate: '34 ABC 128',
    ridePreferences: 'Müzik · Sessiz yolculuk',
  );

  static const RouteOffer mert = RouteOffer(
    id: 'offer-mert-kadikoy-levent',
    driverName: 'Mert A.',
    initials: 'MA',
    identity: RmIdentity.green,
    isVerified: true,
    rating: 4.8,
    tripCount: 64,
    originLabel: 'Kadıköy İskele',
    destinationLabel: 'Levent Metro',
    departureHour: 8,
    departureMinute: 40,
    arrivalHour: 9,
    arrivalMinute: 14,
    tripMinutes: 34,
    seatsAvailable: 2,
    walkMinutes: 9,
    costSharePerPerson: 16,
    compatibility: 0.88,
    trustScore: 86,
    approvalRate: 0.94,
    sharedDistance: '1.9k',
    memberSince: '2024',
    homeArea: 'Kadıköy',
    vehicleName: 'Renault Megane · Beyaz',
    plate: '34 KLM 47',
  );

  /// The condensed card. The design shows no verified badge on this one.
  static const RouteOffer emre = RouteOffer(
    id: 'offer-emre-kadikoy-levent',
    driverName: 'Emre Y.',
    initials: 'EY',
    identity: RmIdentity.purple,
    isVerified: false,
    rating: 4.7,
    tripCount: 41,
    originLabel: 'Kadıköy İskele',
    destinationLabel: 'Levent Metro',
    departureHour: 9,
    departureMinute: 0,
    arrivalHour: 9,
    arrivalMinute: 36,
    tripMinutes: 36,
    seatsAvailable: 3,
    walkMinutes: 11,
    costSharePerPerson: 14,
    compatibility: 0.81,
    trustScore: 78,
    approvalRate: 0.9,
    sharedDistance: '820',
    memberSince: '2024',
    homeArea: 'Ataşehir',
    vehicleName: 'Fiat Egea · Mavi',
    plate: '34 TR 903',
  );

  static const List<RouteOffer> all = <RouteOffer>[selin, mert, emre];

  /// The order to show for each sort option.
  ///
  /// DECLARED, NOT COMPUTED. These lists are presentation fixtures chosen so
  /// each chip visibly does something. They are not a RideMate ranking rule,
  /// and no code derives them from the offers' figures.
  static const Map<MatchSortOption, List<String>> orderBySort =
      <MatchSortOption, List<String>>{
        MatchSortOption.bestMatch: <String>[
          'offer-selin-kadikoy-levent',
          'offer-mert-kadikoy-levent',
          'offer-emre-kadikoy-levent',
        ],
        MatchSortOption.nearest: <String>[
          'offer-selin-kadikoy-levent',
          'offer-mert-kadikoy-levent',
          'offer-emre-kadikoy-levent',
        ],
        MatchSortOption.cheapest: <String>[
          'offer-emre-kadikoy-levent',
          'offer-mert-kadikoy-levent',
          'offer-selin-kadikoy-levent',
        ],
      };

  /// The offers in the order declared for [sort].
  ///
  /// A lookup, not a sort: it reads the declared list and returns those
  /// offers. Nothing is compared or ranked.
  static List<RouteOffer> orderedFor(MatchSortOption sort) {
    final List<String> ids = orderBySort[sort]!;
    return <RouteOffer>[for (final String id in ids) byId(id)!];
  }

  /// The offer with [id], or null.
  static RouteOffer? byId(String id) {
    for (final RouteOffer offer in all) {
      if (offer.id == id) return offer;
    }
    return null;
  }
}
