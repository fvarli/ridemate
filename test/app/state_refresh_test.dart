// ─────────────────────────────────────────────────────────────
// RideMate — Seeing what somebody else changed
//
// Two members, one journey. The passenger asks; the driver answers on another
// phone. Before this, neither screen asked the server again while it stayed
// open, so each member went on reading the other's old answer.
//
// The freshness model under test is exactly two things: a pull, and a return
// to the foreground. Every assertion here is about the SERVER's changed answer
// reaching the screen, and about nothing being shown that the server did not
// send — no optimistic transition, no fixture, and no old answer presented as
// a new one.
// ─────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/app/foreground_refresh.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/journeys/journey.dart';
import 'package:ridemate/core/routes/departure.dart';
import 'package:ridemate/core/routes/my_route.dart';
import 'package:ridemate/core/routes/published_route.dart';
import 'package:ridemate/core/seat_requests/seat_request.dart';
import 'package:ridemate/core/seat_requests/seat_request_decoder.dart';
import 'package:ridemate/core/trips/trip_lifecycle.dart';
import 'package:ridemate/features/home/presentation/home_screen.dart';
import 'package:ridemate/features/journeys/application/journeys_providers.dart';
import 'package:ridemate/features/journeys/data/journeys_repository.dart';
import 'package:ridemate/features/journeys/presentation/journey_status_screen.dart';
import 'package:ridemate/features/my_routes/application/my_routes_providers.dart';
import 'package:ridemate/features/my_routes/data/my_routes_repository.dart';
import 'package:ridemate/features/my_routes/presentation/my_routes_screen.dart';
import 'package:ridemate/features/profile/application/my_profile_providers.dart';
import 'package:ridemate/features/seat_requests/application/seat_request_providers.dart';
import 'package:ridemate/features/seat_requests/data/seat_request_repository.dart';
import 'package:ridemate/features/seat_requests/presentation/my_requests_screen.dart';
import 'package:ridemate/features/seat_requests/presentation/route_requests_screen.dart';
import 'package:ridemate/features/seat_requests/presentation/widgets/incoming_request_card.dart';
import 'package:ridemate/features/seat_requests/presentation/widgets/my_request_card.dart';
import 'package:ridemate/l10n/app_localizations.dart';

import '../support/fakes.dart';
import '../support/fonts.dart';
import '../support/pump.dart';

/// One of the passenger's askings, through the real decoder.
MySeatRequest _mine({
  SeatRequestStatus status = SeatRequestStatus.pending,
  bool routeCancelled = false,
}) => SeatRequestDecoder.mine(<String, Object?>{
  'id': '01991d00-0000-7000-8000-000000000001',
  'service_date': '2026-09-24',
  'status': status.wire,
  'requested_at': '2026-09-09T08:00:00Z',
  'decided_at': status == SeatRequestStatus.pending
      ? null
      : '2026-09-09T09:00:00Z',
  'withdrawn_at': null,
  'my_review': null,
  'route': <String, Object?>{
    ...fakeRouteJson(
      id: '01991b00-0000-7000-8000-000000000001',
      originLabel: 'Kadıköy',
      destinationLabel: 'Levent',
      recurrence: Recurrence.once,
      departureDate: '2026-09-24',
      status: routeCancelled ? RouteStatus.cancelled : RouteStatus.published,
      cancelledAt: routeCancelled ? '2026-09-10T08:00:00Z' : null,
    ),
    'driver': <String, Object?>{
      'display_name': 'İrem Yılmaz',
      'initials': 'İY',
    },
    'trip': fakeTripJson(),
  },
}, 200);

/// A seat-request backend whose answer changes between reads, the way it does
/// when somebody else acts on it.
class _Backend implements SeatRequestRepository {
  _Backend({List<MySeatRequest>? mine, List<IncomingSeatRequest>? incoming})
    : mineNow = mine ?? <MySeatRequest>[],
      incomingNow = incoming ?? <IncomingSeatRequest>[];

  List<MySeatRequest> mineNow;
  List<IncomingSeatRequest> incomingNow;
  bool fails = false;

  /// Holds every read open until completed, the way a slow network does.
  Completer<void>? gate;

  int mineReads = 0;
  int incomingReads = 0;

  @override
  Future<MySeatRequestsResult> mine({String? cursor, int limit = 20}) async {
    mineReads++;
    await gate?.future;
    if (fails) throw const RmFailure.transport();

    return MySeatRequestsResult(requests: mineNow, nextCursor: null);
  }

  @override
  Future<IncomingSeatRequestsResult> forRoute(
    String routeId, {
    String? cursor,
    int limit = 20,
  }) async {
    incomingReads++;
    await gate?.future;
    if (fails) throw const RmFailure.transport();

    return IncomingSeatRequestsResult(requests: incomingNow, nextCursor: null);
  }

  @override
  Future<SeatRequested> ask({
    required String routeId,
    required String requestId,
    DepartureDate? serviceDate,
  }) => throw UnimplementedError();

  @override
  Future<MySeatRequest> withdraw(String requestId) =>
      throw UnimplementedError();

  @override
  Future<IncomingSeatRequest> accept(String requestId) =>
      throw UnimplementedError();

  @override
  Future<IncomingSeatRequest> decline(String requestId) =>
      throw UnimplementedError();
}

const String _routeId = '01991b00-0000-7000-8000-0000000000a1';

/// Somebody asking the driver for a seat.
IncomingSeatRequest _incoming(String id, String passenger) =>
    IncomingSeatRequest(
      id: id,
      serviceDate: const DepartureDate(year: 2026, month: 9, day: 24),
      status: SeatRequestStatus.pending,
      requestedAt: DateTime.utc(2026, 9, 9, 8),
      decidedAt: null,
      withdrawnAt: null,
      myReview: null,
      passenger: SeatRequestMember(displayName: passenger, initials: 'XX'),
    );

/// The driver's journeys, whose lifecycle can move on another device.
class _Journeys implements JourneysRepository {
  _Journeys(this.trip);

  TripState trip;
  bool fails = false;

  int feedReads = 0;
  int journeyReads = 0;

  Journey get _now => fakeJourney(routeId: _routeId, trip: trip);

  @override
  Future<MyJourneysResult> page({String? cursor, int limit = 20}) async {
    feedReads++;
    if (fails) throw const RmFailure.transport();

    return MyJourneysResult(journeys: <Journey>[_now], nextCursor: null);
  }

  @override
  Future<Journey> journey({
    required String routeId,
    required DepartureDate serviceDate,
  }) async {
    journeyReads++;
    if (fails) throw const RmFailure.transport();

    return _now;
  }

  @override
  Future<TripLifecycle> startTrip({
    required String routeId,
    required DepartureDate serviceDate,
  }) => throw UnimplementedError();

  @override
  Future<TripLifecycle> completeTrip({
    required String routeId,
    required DepartureDate serviceDate,
  }) => throw UnimplementedError();

  @override
  Future<TripLifecycle> abortTrip({
    required String routeId,
    required DepartureDate serviceDate,
  }) => throw UnimplementedError();
}

/// The member pulls the list down and lets go.
Future<void> _pull(WidgetTester tester) async {
  await tester.fling(find.byType(Scrollable).first, const Offset(0, 400), 1000);
  await tester.pumpAndSettle();
}

/// The app goes to the background and comes back.
Future<void> _leaveAndReturn(WidgetTester tester) async {
  for (final AppLifecycleState state in <AppLifecycleState>[
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadRideMateFonts);

  Future<AppLocalizations> pump(
    WidgetTester tester,
    Widget screen,
    List<Override> overrides,
  ) async {
    tester.usefulPhoneViewport();
    await tester.pumpRmScreen(
      ForegroundRefresh(child: screen),
      overrides: overrides,
    );
    await tester.pumpAndSettle();

    return AppLocalizations.of(tester.element(find.byWidget(screen)));
  }

  group('My Requests — the passenger', () {
    testWidgets('a pull shows the driver\'s answer: pending → accepted', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend(mine: <MySeatRequest>[_mine()]);
      final AppLocalizations l10n = await pump(
        tester,
        const MyRequestsScreen(),
        <Override>[seatRequestRepositoryProvider.overrideWithValue(backend)],
      );

      expect(find.text(l10n.seatRequestPending), findsOneWidget);

      // The driver accepts on their own phone. Nothing on this one knows.
      backend.mineNow = <MySeatRequest>[
        _mine(status: SeatRequestStatus.accepted),
      ];
      await tester.pump(const Duration(minutes: 5));
      expect(find.text(l10n.seatRequestPending), findsOneWidget);

      await _pull(tester);

      expect(backend.mineReads, 2);
      expect(find.text(l10n.seatRequestAccepted), findsOneWidget);
      expect(find.text(l10n.seatRequestPending), findsNothing);
    });

    testWidgets('a pull shows a decline, and a journey withdrawn since', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend(mine: <MySeatRequest>[_mine()]);
      final AppLocalizations l10n = await pump(
        tester,
        const MyRequestsScreen(),
        <Override>[seatRequestRepositoryProvider.overrideWithValue(backend)],
      );

      backend.mineNow = <MySeatRequest>[
        _mine(status: SeatRequestStatus.declined, routeCancelled: true),
      ];
      await _pull(tester);

      expect(find.text(l10n.seatRequestDeclined), findsOneWidget);
      expect(find.text(l10n.myRequestsRouteCancelled), findsOneWidget);
    });

    testWidgets('the indicator waits for the server, not for the send', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend(mine: <MySeatRequest>[_mine()]);
      final AppLocalizations l10n = await pump(
        tester,
        const MyRequestsScreen(),
        <Override>[seatRequestRepositoryProvider.overrideWithValue(backend)],
      );

      final Completer<void> slow = backend.gate = Completer<void>();
      backend.mineNow = <MySeatRequest>[
        _mine(status: SeatRequestStatus.accepted),
      ];
      await tester.fling(
        find.byType(Scrollable).first,
        const Offset(0, 400),
        1000,
      );
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Asked, not answered: still spinning, and the rows already read stay
      // on screen rather than being replaced by a loading state.
      expect(backend.mineReads, 2);
      expect(find.byType(RefreshProgressIndicator), findsOneWidget);
      expect(find.text(l10n.seatRequestPending), findsOneWidget);
      expect(find.text(l10n.commonLoading), findsNothing);

      slow.complete();
      backend.gate = null;
      await tester.pumpAndSettle();

      expect(find.byType(RefreshProgressIndicator), findsNothing);
      expect(find.text(l10n.seatRequestAccepted), findsOneWidget);
    });

    testWidgets('an empty list can be pulled, and fills when an asking lands', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend();
      final AppLocalizations l10n = await pump(
        tester,
        const MyRequestsScreen(),
        <Override>[seatRequestRepositoryProvider.overrideWithValue(backend)],
      );

      expect(find.text(l10n.myRequestsEmpty), findsOneWidget);

      backend.mineNow = <MySeatRequest>[_mine()];
      await _pull(tester);

      expect(find.byType(MyRequestCard), findsOneWidget);
    });

    testWidgets('a failed refresh keeps the last answer and says it is old', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend(mine: <MySeatRequest>[_mine()]);
      final AppLocalizations l10n = await pump(
        tester,
        const MyRequestsScreen(),
        <Override>[seatRequestRepositoryProvider.overrideWithValue(backend)],
      );

      backend.fails = true;
      await _pull(tester);

      // Not erased, and not presented as fresh.
      expect(find.text(l10n.seatRequestPending), findsOneWidget);
      expect(find.text(l10n.commonRefreshFailed), findsOneWidget);
      // Not the full-screen failure a first read shows.
      expect(find.text(l10n.commonRetry), findsNothing);

      // Asking again clears the sentence along with the old answer.
      backend.fails = false;
      backend.mineNow = <MySeatRequest>[
        _mine(status: SeatRequestStatus.accepted),
      ];
      await _pull(tester);

      expect(find.text(l10n.commonRefreshFailed), findsNothing);
      expect(find.text(l10n.seatRequestAccepted), findsOneWidget);
    });

    testWidgets('a first read that failed can be pulled as well as retried', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend(mine: <MySeatRequest>[_mine()])
        ..fails = true;
      final AppLocalizations l10n = await pump(
        tester,
        const MyRequestsScreen(),
        <Override>[seatRequestRepositoryProvider.overrideWithValue(backend)],
      );

      expect(find.text(l10n.commonRetry), findsOneWidget);
      expect(find.text(l10n.commonRefreshFailed), findsNothing);

      backend.fails = false;
      await _pull(tester);

      expect(find.text(l10n.seatRequestPending), findsOneWidget);
    });

    testWidgets('returning to the app re-reads it', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend(mine: <MySeatRequest>[_mine()]);
      final AppLocalizations l10n = await pump(
        tester,
        const MyRequestsScreen(),
        <Override>[seatRequestRepositoryProvider.overrideWithValue(backend)],
      );

      backend.mineNow = <MySeatRequest>[
        _mine(status: SeatRequestStatus.accepted),
      ];
      await _leaveAndReturn(tester);

      expect(backend.mineReads, 2);
      expect(find.text(l10n.seatRequestAccepted), findsOneWidget);
    });

    testWidgets('a notification shade is not a return', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend(mine: <MySeatRequest>[_mine()]);
      await pump(tester, const MyRequestsScreen(), <Override>[
        seatRequestRepositoryProvider.overrideWithValue(backend),
      ]);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(backend.mineReads, 1);
    });
  });

  group('Route Requests — the driver', () {
    List<Override> overrides(_Backend backend) => <Override>[
      seatRequestRepositoryProvider.overrideWithValue(backend),
      myRoutesRepositoryProvider.overrideWithValue(
        FakeMyRoutesRepository(
          pages: <MyRoutesResult>[
            MyRoutesResult(
              routes: <MyRoute>[fakeMyRoute(id: _routeId)],
              nextCursor: null,
            ),
          ],
        ),
      ),
    ];

    testWidgets('a pull shows an asking that arrived since', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend(
        incoming: <IncomingSeatRequest>[_incoming('q1', 'Ayşe Demir')],
      );
      await pump(
        tester,
        const RouteRequestsScreen(routeId: _routeId),
        overrides(backend),
      );

      expect(find.byType(IncomingRequestCard), findsOneWidget);

      // A second passenger asks from their own phone.
      backend.incomingNow = <IncomingSeatRequest>[
        _incoming('q1', 'Ayşe Demir'),
        _incoming('q2', 'Mert Kaya'),
      ];
      await _pull(tester);

      expect(backend.incomingReads, 2);
      expect(find.byType(IncomingRequestCard), findsNWidgets(2));
      expect(find.text('Mert Kaya'), findsOneWidget);
    });

    testWidgets('a driver with no askings yet can pull for the first', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend();
      await pump(
        tester,
        const RouteRequestsScreen(routeId: _routeId),
        overrides(backend),
      );

      expect(find.byType(IncomingRequestCard), findsNothing);

      backend.incomingNow = <IncomingSeatRequest>[
        _incoming('q1', 'Ayşe Demir'),
      ];
      await _pull(tester);

      expect(find.text('Ayşe Demir'), findsOneWidget);
    });

    testWidgets('returning to the app re-reads it', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend();
      await pump(
        tester,
        const RouteRequestsScreen(routeId: _routeId),
        overrides(backend),
      );

      backend.incomingNow = <IncomingSeatRequest>[
        _incoming('q1', 'Ayşe Demir'),
      ];
      await _leaveAndReturn(tester);

      expect(backend.incomingReads, 2);
      expect(find.text('Ayşe Demir'), findsOneWidget);
    });
  });

  group('Journeys — the lifecycle moved elsewhere', () {
    testWidgets('Journey Status shows a start made on another device', (
      WidgetTester tester,
    ) async {
      final _Journeys journeys = _Journeys(TripState.notStarted);
      final AppLocalizations l10n = await pump(
        tester,
        const JourneyStatusScreen(routeId: _routeId, serviceDate: '2026-09-16'),
        <Override>[journeysRepositoryProvider.overrideWithValue(journeys)],
      );

      expect(find.text(l10n.tripStateNotStarted), findsOneWidget);

      journeys.trip = TripState.inProgress;
      await _pull(tester);

      expect(journeys.journeyReads, 2);
      expect(find.text(l10n.tripStateInProgress), findsOneWidget);
      expect(find.text(l10n.tripStateNotStarted), findsNothing);
    });

    testWidgets('a failed re-read is not reported as a missing journey', (
      WidgetTester tester,
    ) async {
      final _Journeys journeys = _Journeys(TripState.notStarted);
      final AppLocalizations l10n = await pump(
        tester,
        const JourneyStatusScreen(routeId: _routeId, serviceDate: '2026-09-16'),
        <Override>[journeysRepositoryProvider.overrideWithValue(journeys)],
      );

      journeys.fails = true;
      await _pull(tester);

      expect(find.text(l10n.journeyNotFound), findsNothing);
      expect(find.text(l10n.tripStateNotStarted), findsOneWidget);
      expect(find.text(l10n.commonRefreshFailed), findsOneWidget);
    });

    testWidgets('returning to the app re-reads Journey Status', (
      WidgetTester tester,
    ) async {
      final _Journeys journeys = _Journeys(TripState.inProgress);
      final AppLocalizations l10n = await pump(
        tester,
        const JourneyStatusScreen(routeId: _routeId, serviceDate: '2026-09-16'),
        <Override>[journeysRepositoryProvider.overrideWithValue(journeys)],
      );

      journeys.trip = TripState.completed;
      await _leaveAndReturn(tester);

      expect(find.text(l10n.tripStateCompleted), findsOneWidget);
    });

    testWidgets('My Routes re-reads its plans and its journeys together', (
      WidgetTester tester,
    ) async {
      final _Journeys journeys = _Journeys(TripState.notStarted);
      final FakeMyRoutesRepository routes = FakeMyRoutesRepository(
        pages: <MyRoutesResult>[
          MyRoutesResult(routes: <MyRoute>[fakeMyRoute()], nextCursor: null),
        ],
      );
      await pump(tester, const MyRoutesScreen(), <Override>[
        journeysRepositoryProvider.overrideWithValue(journeys),
        myRoutesRepositoryProvider.overrideWithValue(routes),
      ]);

      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(MyRoutesScreen)),
      );

      journeys.trip = TripState.aborted;
      await _pull(tester);

      expect(routes.callCount, 2);
      expect(journeys.feedReads, 2);
      expect(find.text(l10n.tripStateAborted), findsWidgets);
    });

    testWidgets('a failed journeys re-read keeps the plans beside it', (
      WidgetTester tester,
    ) async {
      final _Journeys journeys = _Journeys(TripState.notStarted);
      final FakeMyRoutesRepository routes = FakeMyRoutesRepository(
        pages: <MyRoutesResult>[
          MyRoutesResult(routes: <MyRoute>[fakeMyRoute()], nextCursor: null),
        ],
      );
      await pump(tester, const MyRoutesScreen(), <Override>[
        journeysRepositoryProvider.overrideWithValue(journeys),
        myRoutesRepositoryProvider.overrideWithValue(routes),
      ]);

      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(MyRoutesScreen)),
      );

      journeys.fails = true;
      await _pull(tester);

      // Said once, by the section whose feed failed.
      expect(find.text(l10n.commonRefreshFailed), findsOneWidget);
      expect(find.text(l10n.tripStateNotStarted), findsWidgets);
      expect(find.text(l10n.commonRetry), findsNothing);
    });
  });

  group('Home — the tab that never closes', () {
    testWidgets(
      'one pull re-reads the journeys and the askings, not the name',
      (WidgetTester tester) async {
        final _Backend backend = _Backend(mine: <MySeatRequest>[_mine()]);
        final _Journeys journeys = _Journeys(TripState.notStarted);
        final FakeProfileRepository profile = FakeProfileRepository();
        final AppLocalizations l10n =
            await pump(tester, const HomeScreen(), <Override>[
              seatRequestRepositoryProvider.overrideWithValue(backend),
              journeysRepositoryProvider.overrideWithValue(journeys),
              profileRepositoryProvider.overrideWithValue(profile),
            ]);

        expect(find.text(l10n.seatRequestPending), findsOneWidget);

        backend.mineNow = <MySeatRequest>[
          _mine(status: SeatRequestStatus.accepted),
        ];
        journeys.trip = TripState.inProgress;
        await _pull(tester);

        expect(backend.mineReads, 2);
        expect(journeys.feedReads, 2);
        expect(profile.readCount, 1);
        expect(find.text(l10n.seatRequestAccepted), findsOneWidget);
        expect(find.text(l10n.tripStateInProgress), findsOneWidget);
      },
    );

    testWidgets('returning to the app re-reads both sections', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend(mine: <MySeatRequest>[_mine()]);
      final _Journeys journeys = _Journeys(TripState.notStarted);
      final FakeProfileRepository profile = FakeProfileRepository();
      final AppLocalizations l10n =
          await pump(tester, const HomeScreen(), <Override>[
            seatRequestRepositoryProvider.overrideWithValue(backend),
            journeysRepositoryProvider.overrideWithValue(journeys),
            profileRepositoryProvider.overrideWithValue(profile),
          ]);

      backend.mineNow = <MySeatRequest>[
        _mine(status: SeatRequestStatus.declined),
      ];
      await _leaveAndReturn(tester);

      expect(backend.mineReads, 2);
      expect(journeys.feedReads, 2);
      expect(profile.readCount, 1);
      expect(find.text(l10n.seatRequestDeclined), findsOneWidget);
    });

    testWidgets('one section failing to refresh leaves the other fresh', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend(mine: <MySeatRequest>[_mine()]);
      final _Journeys journeys = _Journeys(TripState.notStarted);
      final AppLocalizations l10n = await pump(
        tester,
        const HomeScreen(),
        <Override>[
          seatRequestRepositoryProvider.overrideWithValue(backend),
          journeysRepositoryProvider.overrideWithValue(journeys),
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
        ],
      );

      journeys.fails = true;
      backend.mineNow = <MySeatRequest>[
        _mine(status: SeatRequestStatus.accepted),
      ];
      await _pull(tester);

      expect(find.text(l10n.commonRefreshFailed), findsOneWidget);
      expect(find.text(l10n.tripStateNotStarted), findsOneWidget);
      expect(find.text(l10n.seatRequestAccepted), findsOneWidget);
    });
  });

  test('the foreground re-read list names only what another member moves', () {
    expect(kForegroundRereads, <ProviderOrFamily>[
      mySeatRequestsProvider,
      incomingSeatRequestsProvider,
      myJourneysProvider,
      journeyProvider,
      myRoutesProvider,
    ]);
  });
}
