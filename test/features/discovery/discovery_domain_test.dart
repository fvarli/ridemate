// ─────────────────────────────────────────────────────────────
// RideMate — Discovery domain
//
// The search draft, and the fixture Route Details still runs on.
//
// WHAT LEFT WITH PHASE 12
//
// The filter, sort and ordering groups tested controls that changed a chip and
// changed nothing else. That was a real invariant while the results were a
// fixture — "a filter is a preference, not an eligibility rule" was worth
// pinning — and it stopped being one when the controls were removed rather than
// kept and ignored. Deleted with their subject, not weakened.
//
// MockRouteOffers stays because Route Details still renders it and Phase 12
// does not migrate that screen. Its figures are still pinned below, on the one
// surface that is still openly a fixture.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/places/place.dart';
import 'package:ridemate/features/discovery/application/discovery_providers.dart';
import 'package:ridemate/features/discovery/domain/mock_discovery_fixtures.dart';
import 'package:ridemate/features/discovery/domain/route_offer.dart';
import 'package:ridemate/features/discovery/domain/search_draft.dart';

const Place _kadikoy = Place(id: 'p1', label: 'Kadıköy, Vapur İskelesi');
const Place _levent = Place(id: 'p2', label: 'Levent, Metro İstasyonu');
const Place _maslak = Place(id: 'p3', label: 'Maslak');

void main() {
  ProviderContainer container() {
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  group('SearchDraft', () {
    /// CARRIES WEIGHT. There is no honest default endpoint.
    ///
    /// A place the client made up would match no route, and choosing one from
    /// the catalogue would be deciding where somebody is travelling from.
    test('starts with nothing chosen', () {
      const SearchDraft d = SearchDraft();

      expect(d.origin, isNull);
      expect(d.destination, isNull);
      expect(d.isComplete, isFalse);
    });

    test('is complete only with two different places', () {
      expect(
        const SearchDraft(origin: _kadikoy).isComplete,
        isFalse,
        reason: 'one endpoint is not a journey',
      );
      expect(
        const SearchDraft(origin: _kadikoy, destination: _kadikoy).isComplete,
        isFalse,
        reason: 'a place to itself is not a journey, and the API refuses it',
      );
      expect(
        const SearchDraft(origin: _kadikoy, destination: _levent).isComplete,
        isTrue,
      );
    });

    test('swapping exchanges the endpoints, set or not', () {
      const SearchDraft both = SearchDraft(
        origin: _kadikoy,
        destination: _levent,
      );
      expect(both.swapped().origin, _levent);
      expect(both.swapped().destination, _kadikoy);

      const SearchDraft half = SearchDraft(origin: _kadikoy);
      expect(half.swapped().origin, isNull);
      expect(half.swapped().destination, _kadikoy);
    });

    test('compares by value, so provider rebuilds are meaningful', () {
      const SearchDraft a = SearchDraft(origin: _kadikoy, destination: _levent);
      const SearchDraft b = SearchDraft(origin: _kadikoy, destination: _levent);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('SearchDraftController', () {
    test('editing endpoints updates the draft', () {
      final ProviderContainer c = container();
      final SearchDraftController controller = c.read(
        searchDraftProvider.notifier,
      );

      controller.setOrigin(_kadikoy);
      controller.setDestination(_levent);

      expect(c.read(searchDraftProvider).origin, _kadikoy);
      expect(c.read(searchDraftProvider).destination, _levent);
      expect(c.read(searchDraftProvider).isComplete, isTrue);
    });

    /// CARRIES WEIGHT. Matched by id, never by label.
    ///
    /// A label is what a place is called, not what it is, and two places can be
    /// renamed into each other's names. Keeping a reference the server would
    /// reject helps nobody.
    test('a refreshed catalogue clears endpoints it no longer contains', () {
      final ProviderContainer c = container();
      final SearchDraftController controller = c.read(
        searchDraftProvider.notifier,
      );

      controller.setOrigin(_kadikoy);
      controller.setDestination(_levent);

      controller.reconcileWith(const <Place>[_kadikoy, _maslak]);

      expect(c.read(searchDraftProvider).origin, _kadikoy);
      expect(
        c.read(searchDraftProvider).destination,
        isNull,
        reason: 'Levent is not in the refreshed catalogue',
      );
    });

    test('a place renamed but still present is kept', () {
      final ProviderContainer c = container();
      final SearchDraftController controller = c.read(
        searchDraftProvider.notifier,
      );

      controller.setOrigin(_kadikoy);
      controller.reconcileWith(const <Place>[
        Place(id: 'p1', label: 'Somewhere else entirely'),
      ]);

      expect(c.read(searchDraftProvider).origin, isNotNull);
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
}
