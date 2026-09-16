// ─────────────────────────────────────────────────────────────
// RideMate — Which days this member may still ask about
//
// Discovery publishes two dated lists and they answer different questions: the
// days the ROUTE offers, and the days THIS MEMBER has spent. The card offers
// the difference, and this is the only place that difference is worked out.
//
// The cases below are mostly about the ways a subtraction can be subtly wrong —
// matching on the wrong thing, reading a terminal status as a release, or
// letting one day's answer speak for the plan.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/routes/departure.dart';
import 'package:ridemate/core/routes/discovered_route.dart';
import 'package:ridemate/core/seat_requests/seat_request.dart';

import '../../support/fakes.dart';

void main() {
  DepartureDate day(int d) => DepartureDate(year: 2026, month: 9, day: d);

  /// A plan offering [offers], on which this member has asked about [asked].
  DiscoveredRoute route({
    List<int> offers = const <int>[14, 15, 16],
    List<(int, String)> asked = const <(int, String)>[],
  }) => fakeDiscoveredRoute(
    requestableServiceDates: <String>[
      for (final int d in offers) '2026-09-${d.toString().padLeft(2, '0')}',
    ],
    mySeatRequests: <Map<String, Object?>>[
      for (final (int d, String status) in asked)
        fakeMySeatRequestSummaryJson(
          serviceDate: '2026-09-${d.toString().padLeft(2, '0')}',
          id: 'req-$d',
          status: status,
        ),
    ],
  );

  List<int> selectable(DiscoveredRoute r) => <int>[
    for (final DepartureDate d in r.selectableServiceDates) d.day,
  ];

  group('With nothing asked about', () {
    test('a route offering nothing has nothing to select', () {
      expect(route(offers: const <int>[]).selectableServiceDates, isEmpty);
    });

    test('every offered day is selectable, in the server order', () {
      expect(selectable(route(offers: const <int>[18, 14, 15])), <int>[
        18,
        14,
        15,
      ]);
    });

    /// The list is handed back as it arrived rather than rebuilt, and either
    /// way it must equal the route's own.
    test('the answer is the offered days themselves', () {
      final DiscoveredRoute r = route();

      expect(r.selectableServiceDates, r.requestableServiceDates);
    });
  });

  group('A day that has been asked about is spent', () {
    /// CARRIES WEIGHT. Every status, including the two that ended.
    ///
    /// A member gets one asking per journey for that journey's lifetime.
    /// `declined` and `withdrawn` are ends, not releases — reading either as
    /// "free again" would put a control on the card that the server refuses
    /// with `already_requested`.
    for (final String status in <String>[
      'pending',
      'accepted',
      'declined',
      'withdrawn',
    ]) {
      test('a $status asking removes exactly its own day', () {
        final DiscoveredRoute r = route(asked: <(int, String)>[(15, status)]);

        expect(selectable(r), <int>[14, 16]);
      });
    }

    test('two askings remove exactly those two days', () {
      final DiscoveredRoute r = route(
        asked: const <(int, String)>[(14, 'declined'), (16, 'accepted')],
      );

      expect(selectable(r), <int>[15]);
    });

    test('asking about every offered day leaves nothing', () {
      final DiscoveredRoute r = route(
        asked: const <(int, String)>[
          (14, 'pending'),
          (15, 'withdrawn'),
          (16, 'declined'),
        ],
      );

      expect(r.selectableServiceDates, isEmpty);
      // And the route still says it offers them: the two lists stay separate,
      // so the card can tell "you have asked about all of them" apart from
      // "there are none".
      expect(r.requestableServiceDates, hasLength(3));
    });

    /// CARRIES WEIGHT. One day's answer is not the plan's.
    ///
    /// The defect this prevents is a card that reads `mySeatRequests.isNotEmpty`
    /// and stops offering a plan the member has asked about once.
    test('a day asked about does not close the days beside it', () {
      final DiscoveredRoute r = route(
        offers: const <int>[14, 15, 16, 17, 18],
        asked: const <(int, String)>[(15, 'declined')],
      );

      expect(selectable(r), <int>[14, 16, 17, 18]);
    });
  });

  group('Matching is by day and nothing else', () {
    /// An asking for a day the route is no longer offering — a plan whose
    /// horizon has moved on since, or a response read out of order. It must
    /// remove nothing, because it matches nothing.
    test('an asking outside the offered days changes none of them', () {
      final DiscoveredRoute r = route(
        asked: const <(int, String)>[(28, 'pending')],
      );

      expect(selectable(r), <int>[14, 15, 16]);
    });

    /// CARRIES WEIGHT. The route id is not part of the test, and cannot be.
    ///
    /// `mySeatRequests` already holds only this route's askings — the server
    /// scopes it — so a subtraction that also compared ids would be comparing
    /// a constant. What must never happen is the reverse: treating any asking
    /// on this route as closing every day of it.
    test('an asking on one day is not an asking on the route', () {
      final DiscoveredRoute r = route(
        asked: const <(int, String)>[(14, 'accepted')],
      );

      expect(r.mySeatRequests, hasLength(1));
      expect(selectable(r), isNot(isEmpty));
      expect(selectable(r), <int>[15, 16]);
    });
  });

  group('Order survives the subtraction', () {
    test('the remaining days keep the server order they arrived in', () {
      final DiscoveredRoute r = route(
        offers: const <int>[18, 14, 16, 15],
        asked: const <(int, String)>[(16, 'pending')],
      );

      expect(selectable(r), <int>[18, 14, 15]);
    });
  });

  group('The lookup for one day is unchanged', () {
    test('seatRequestOn finds only the asking for that exact day', () {
      final DiscoveredRoute r = route(
        asked: const <(int, String)>[(15, 'declined')],
      );

      final MySeatRequestSummary? found = r.seatRequestOn(day(15));
      expect(found?.status, SeatRequestStatus.declined);
      expect(r.seatRequestOn(day(14)), isNull);
      expect(r.seatRequestOn(null), isNull);
    });
  });
}
