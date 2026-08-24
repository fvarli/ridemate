import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/places/mock_places.dart';
import 'package:ridemate/features/discovery/application/discovery_providers.dart';
import 'package:ridemate/features/discovery/domain/mock_discovery_fixtures.dart';
import 'package:ridemate/features/discovery/domain/route_offer.dart';
import 'package:ridemate/features/discovery/domain/search_draft.dart';

void main() {
  ProviderContainer container() {
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  group('SearchDraft', () {
    test('starts from the journey the design shows', () {
      const SearchDraft d = kInitialSearchDraft;
      expect(d.origin, MockPlaces.kadikoy);
      expect(d.destination, MockPlaces.levent);
      expect(d.seats, 1);
      expect(d.sort, MatchSortOption.bestMatch);
      // The design selects exactly one filter.
      expect(d.filters, <SearchFilterId>{SearchFilterId.verifiedOnly});
    });

    test('swapping exchanges the endpoints', () {
      final SearchDraft swapped = kInitialSearchDraft.swapped();
      expect(swapped.origin, kInitialSearchDraft.destination);
      expect(swapped.destination, kInitialSearchDraft.origin);
      // Swapping twice returns the original.
      expect(swapped.swapped(), kInitialSearchDraft);
    });

    test('toggling a filter adds then removes it', () {
      const SearchFilterId id = SearchFilterId.noSmoking;
      final SearchDraft on = kInitialSearchDraft.withFilterToggled(id);
      expect(on.isFilterSelected(id), isTrue);

      final SearchDraft off = on.withFilterToggled(id);
      expect(off.isFilterSelected(id), isFalse);
      expect(off, kInitialSearchDraft);
    });

    test('toggling one filter leaves the others alone', () {
      final SearchDraft d = kInitialSearchDraft.withFilterToggled(
        SearchFilterId.minRating,
      );
      expect(d.isFilterSelected(SearchFilterId.verifiedOnly), isTrue);
      expect(d.isFilterSelected(SearchFilterId.minRating), isTrue);
      expect(d.filters.length, 2);
    });

    test('compares by value, so provider rebuilds are meaningful', () {
      expect(kInitialSearchDraft, kInitialSearchDraft.copyWith());
      expect(
        kInitialSearchDraft,
        isNot(kInitialSearchDraft.copyWith(seats: 2)),
      );
      expect(
        kInitialSearchDraft.hashCode,
        kInitialSearchDraft.copyWith().hashCode,
      );
    });
  });

  group('Route offers reproduce the approved design', () {
    test('the best match carries every figure the design shows', () {
      const RouteOffer o = MockRouteOffers.selin;
      expect(o.driverName, 'Selin K.');
      expect(o.rating, 4.9);
      expect(o.tripCount, 128);
      expect(o.sharedRouteCount, 2);
      expect(o.costSharePerPerson, 18);
      expect(o.compatibility, 0.94);
      expect(o.trustScore, 92);
      expect(o.approvalRate, 0.98);
      expect(o.sharedDistance, '3.4k');
      expect(o.seatsAvailable, 1);
      expect(o.walkMinutes, 5);
      expect(o.tripMinutes, 32);
      expect(o.plate, '34 ABC 128');
    });

    test('the three cost shares and compatibilities match the design', () {
      expect(
        MockRouteOffers.all
            .map((RouteOffer o) => o.costSharePerPerson)
            .toList(),
        <int>[18, 16, 14],
      );
      expect(
        MockRouteOffers.all.map((RouteOffer o) => o.compatibility).toList(),
        <double>[0.94, 0.88, 0.81],
      );
      expect(
        MockRouteOffers.all.map((RouteOffer o) => o.rating).toList(),
        <double>[4.9, 4.8, 4.7],
      );
    });

    test('the condensed offer is unverified, as the design draws it', () {
      expect(MockRouteOffers.emre.isVerified, isFalse);
      expect(MockRouteOffers.selin.isVerified, isTrue);
      expect(MockRouteOffers.mert.isVerified, isTrue);
    });

    test('lookup by id finds every offer and rejects unknown ones', () {
      for (final RouteOffer o in MockRouteOffers.all) {
        expect(MockRouteOffers.byId(o.id), o);
      }
      expect(MockRouteOffers.byId('does-not-exist'), isNull);
    });
  });

  group('Ordering is declared, never computed', () {
    test('every sort option declares an order over the same offers', () {
      final Set<String> allIds = MockRouteOffers.all
          .map((RouteOffer o) => o.id)
          .toSet();

      for (final MatchSortOption sort in MatchSortOption.values) {
        final List<String> declared = MockRouteOffers.orderBySort[sort]!;
        expect(
          declared.toSet(),
          allIds,
          reason: '$sort must cover every offer and invent none',
        );
        expect(
          declared.length,
          allIds.length,
          reason: '$sort must not repeat an offer',
        );
      }
    });

    test('changing sort changes the order the fixture declares', () {
      final List<RouteOffer> best = MockRouteOffers.orderedFor(
        MatchSortOption.bestMatch,
      );
      final List<RouteOffer> cheapest = MockRouteOffers.orderedFor(
        MatchSortOption.cheapest,
      );

      expect(best.first, MockRouteOffers.selin);
      expect(cheapest.first, MockRouteOffers.emre);
      expect(best, isNot(cheapest));
    });

    test('orderedFor returns exactly the declared sequence', () {
      // A lookup, not a sort: the output is the declared id list, in order.
      // Nothing compares compatibility, distance or cost to produce it.
      for (final MatchSortOption sort in MatchSortOption.values) {
        expect(
          MockRouteOffers.orderedFor(sort).map((RouteOffer o) => o.id).toList(),
          MockRouteOffers.orderBySort[sort],
          reason: '$sort must echo its declared order verbatim',
        );
      }
    });

    test(
      'two options may declare the same order without any rule saying so',
      () {
        // "Nearest" and "best match" happen to declare the same sequence. That
        // is a fixture choice, not a consequence of a shared comparator — there
        // is no comparator.
        expect(
          MockRouteOffers.orderBySort[MatchSortOption.nearest],
          MockRouteOffers.orderBySort[MatchSortOption.bestMatch],
        );
      },
    );
  });

  group('SearchDraftController', () {
    test('editing endpoints updates the draft', () {
      final ProviderContainer c = container();
      final SearchDraftController controller = c.read(
        searchDraftProvider.notifier,
      );

      controller.setOrigin(MockPlaces.maslak);
      expect(c.read(searchDraftProvider).origin, MockPlaces.maslak);

      controller.setDestination(MockPlaces.atasehir);
      expect(c.read(searchDraftProvider).destination, MockPlaces.atasehir);

      controller.swapEndpoints();
      expect(c.read(searchDraftProvider).origin, MockPlaces.atasehir);
      expect(c.read(searchDraftProvider).destination, MockPlaces.maslak);
    });

    test('sort drives which declared order the offers provider returns', () {
      final ProviderContainer c = container();

      expect(c.read(routeOffersProvider).first, MockRouteOffers.selin);

      c.read(searchDraftProvider.notifier).setSort(MatchSortOption.cheapest);
      expect(c.read(routeOffersProvider).first, MockRouteOffers.emre);
    });
  });

  group('Filters are preferences, not eligibility rules', () {
    test('toggling any filter leaves the results untouched', () {
      // Filtering even a mock list would define how RideMate applies these
      // preferences. That is a backend, legal and product decision.
      final ProviderContainer c = container();
      final List<RouteOffer> before = c.read(routeOffersProvider);

      for (final SearchFilterId id in SearchFilterId.values) {
        c.read(searchDraftProvider.notifier).toggleFilter(id);
        expect(
          c.read(routeOffersProvider),
          before,
          reason: '$id must not change the results',
        );
      }
    });

    test('the female-driver filter in particular changes nothing', () {
      // Gender-based matching in transport is regulated. Until legal, safety
      // and product review, this preference is presentation only.
      final ProviderContainer c = container();
      final List<RouteOffer> before = c.read(routeOffersProvider);

      c
          .read(searchDraftProvider.notifier)
          .toggleFilter(kFilterNeedingPolicyReview);

      expect(
        c
            .read(searchDraftProvider)
            .isFilterSelected(kFilterNeedingPolicyReview),
        isTrue,
        reason: 'the chip still toggles',
      );
      expect(
        c.read(routeOffersProvider),
        before,
        reason: 'but it must not filter or reorder anything',
      );
      expect(kFilterNeedingPolicyReview, SearchFilterId.femaleDriver);
    });
  });
}
