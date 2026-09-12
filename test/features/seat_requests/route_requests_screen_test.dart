// ─────────────────────────────────────────────────────────────
// RideMate — Incoming requests
//
// The driver's two answers, and the line this screen must not cross: capacity
// belongs to the backend. Nothing here counts accepted rows, and a refused
// acceptance never becomes an acceptance.
// ─────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/api/rm_error_code.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/reviews/review.dart';
import 'package:ridemate/core/routes/my_route.dart';
import 'package:ridemate/core/seat_requests/seat_request.dart';
import 'package:ridemate/core/theme/rm_theme.dart';
import 'package:ridemate/core/trips/trip_lifecycle.dart';
import 'package:ridemate/features/my_routes/application/my_routes_providers.dart';
import 'package:ridemate/features/my_routes/data/my_routes_repository.dart';
import 'package:ridemate/features/seat_requests/application/seat_request_providers.dart';
import 'package:ridemate/features/seat_requests/data/seat_request_repository.dart';
import 'package:ridemate/features/seat_requests/presentation/route_requests_screen.dart';
import 'package:ridemate/features/seat_requests/presentation/widgets/incoming_request_card.dart';
import 'package:ridemate/l10n/app_localizations.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';

const String _routeId = '01991c00-0000-7000-8000-000000000001';

IncomingSeatRequest _incoming({
  String id = 'q1',
  SeatRequestStatus status = SeatRequestStatus.pending,
  String passenger = 'Ayşe Demir',
  String initials = 'AD',
  MyReview? myReview,
}) => IncomingSeatRequest(
  id: id,
  status: status,
  requestedAt: DateTime.utc(2026, 9, 9, 8),
  decidedAt:
      status == SeatRequestStatus.accepted ||
          status == SeatRequestStatus.declined
      ? DateTime.utc(2026, 9, 9, 9)
      : null,
  withdrawnAt: status == SeatRequestStatus.withdrawn
      ? DateTime.utc(2026, 9, 9, 9)
      : null,
  myReview: myReview,
  passenger: SeatRequestMember(displayName: passenger, initials: initials),
);

/// A backend a test can steer.
class _Incoming implements SeatRequestRepository {
  _Incoming({List<IncomingSeatRequestsResult>? pages, this.readFails = false})
    : pages = pages ?? <IncomingSeatRequestsResult>[];

  final List<IncomingSeatRequestsResult> pages;
  bool readFails;

  /// What a decision answers with, or throws.
  IncomingSeatRequest? decided;
  RmFailure? decisionFailure;
  Completer<void>? gate;

  int reads = 0;
  final List<String> accepted = <String>[];
  final List<String> declined = <String>[];

  @override
  Future<IncomingSeatRequestsResult> forRoute(
    String routeId, {
    String? cursor,
    int limit = 20,
  }) async {
    reads++;

    if (readFails) throw const RmFailure.transport();

    return pages.isEmpty
        ? const IncomingSeatRequestsResult(
            requests: <IncomingSeatRequest>[],
            nextCursor: null,
          )
        : pages.removeAt(0);
  }

  @override
  Future<IncomingSeatRequest> accept(String requestId) {
    accepted.add(requestId);

    return _answer(requestId, SeatRequestStatus.accepted);
  }

  @override
  Future<IncomingSeatRequest> decline(String requestId) {
    declined.add(requestId);

    return _answer(requestId, SeatRequestStatus.declined);
  }

  Future<IncomingSeatRequest> _answer(
    String requestId,
    SeatRequestStatus status,
  ) async {
    final Completer<void>? held = gate;
    if (held != null) await held.future;

    final RmFailure? failure = decisionFailure;
    if (failure != null) throw failure;

    return decided ?? _incoming(id: requestId, status: status);
  }

  @override
  Future<SeatRequested> ask({
    required String routeId,
    required String requestId,
  }) => throw UnimplementedError();

  @override
  Future<MySeatRequestsResult> mine({String? cursor, int limit = 20}) =>
      throw UnimplementedError();

  @override
  Future<MySeatRequest> withdraw(String requestId) =>
      throw UnimplementedError();
}

void main() {
  setUpAll(loadRideMateFonts);

  Future<void> pump(
    WidgetTester tester,
    _Incoming backend, {
    TripState? trip,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          seatRequestRepositoryProvider.overrideWithValue(backend),
          // The driver's incoming rows carry no journey, so the screen reads
          // the trip from the owner's own list. Null means that list holds no
          // such route — which must NOT read as a completed journey.
          myRoutesRepositoryProvider.overrideWithValue(
            FakeMyRoutesRepository(
              pages: <MyRoutesResult>[
                MyRoutesResult(
                  routes: <MyRoute>[
                    if (trip != null)
                      fakeMyRoute(
                        id: _routeId,
                        trip: trip,
                        startedAt: trip == TripState.notStarted
                            ? null
                            : '2026-09-11T07:05:00Z',
                        completedAt: trip == TripState.completed
                            ? '2026-09-11T07:45:00Z'
                            : null,
                        abortedAt: trip == TripState.aborted
                            ? '2026-09-11T07:20:00Z'
                            : null,
                      ),
                  ],
                  nextCursor: null,
                ),
              ],
            ),
          ),
        ],
        child: MaterialApp(
          theme: RmTheme.of(Brightness.light),
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const RouteRequestsScreen(routeId: _routeId),
        ),
      ),
    );
  }

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(RouteRequestsScreen)));

  _Incoming holding(List<IncomingSeatRequest> requests, {String? cursor}) =>
      _Incoming(
        pages: <IncomingSeatRequestsResult>[
          IncomingSeatRequestsResult(requests: requests, nextCursor: cursor),
        ],
      );

  Finder acceptIn(WidgetTester tester, String passenger) => find.descendant(
    of: find.ancestor(
      of: find.text(passenger),
      matching: find.byType(IncomingRequestCard),
    ),
    matching: find.text(l10nOf(tester).routeRequestsAccept),
  );

  group('States', () {
    testWidgets('empty is a server answer, not a failure', (
      WidgetTester tester,
    ) async {
      await pump(tester, _Incoming());
      await tester.pumpAndSettle();

      expect(find.text(l10nOf(tester).routeRequestsEmpty), findsOneWidget);
      expect(find.text(l10nOf(tester).commonRetry), findsNothing);
    });

    testWidgets('a failed read says so and offers a retry', (
      WidgetTester tester,
    ) async {
      final _Incoming backend = _Incoming(readFails: true);
      await pump(tester, backend);
      await tester.pumpAndSettle();

      expect(find.text(l10nOf(tester).commonRetry), findsOneWidget);

      backend.readFails = false;
      backend.pages.add(
        IncomingSeatRequestsResult(
          requests: <IncomingSeatRequest>[_incoming()],
          nextCursor: null,
        ),
      );

      await tester.tap(find.text(l10nOf(tester).commonRetry));
      await tester.pumpAndSettle();

      expect(find.byType(IncomingRequestCard), findsOneWidget);
    });
  });

  group('What can be answered', () {
    testWidgets(
      'all four statuses render, and only pending offers a decision',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(393, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await pump(
          tester,
          holding(<IncomingSeatRequest>[
            for (final SeatRequestStatus status in SeatRequestStatus.values)
              _incoming(
                id: status.wire,
                status: status,
                passenger: status.wire,
              ),
          ]),
        );
        await tester.pumpAndSettle();

        final AppLocalizations l10n = l10nOf(tester);

        expect(find.text(l10n.seatRequestPending), findsOneWidget);
        expect(find.text(l10n.seatRequestAccepted), findsOneWidget);
        expect(find.text(l10n.seatRequestDeclined), findsOneWidget);
        expect(find.text(l10n.seatRequestWithdrawn), findsOneWidget);

        // Exactly one of each control: only the pending row offers them.
        expect(find.text(l10n.routeRequestsAccept), findsOneWidget);
        expect(find.text(l10n.routeRequestsDecline), findsOneWidget);
      },
    );

    /// Taking an asking back is the passenger's to do.
    testWidgets('the driver is never offered withdraw', (
      WidgetTester tester,
    ) async {
      await pump(tester, holding(<IncomingSeatRequest>[_incoming()]));
      await tester.pumpAndSettle();

      expect(find.text(l10nOf(tester).myRequestsWithdraw), findsNothing);
    });
  });

  group('Deciding', () {
    testWidgets('accept is not optimistic', (WidgetTester tester) async {
      final _Incoming backend = holding(<IncomingSeatRequest>[_incoming()])
        ..gate = Completer<void>();

      await pump(tester, backend);
      await tester.pumpAndSettle();

      final AppLocalizations l10n = l10nOf(tester);

      await tester.tap(find.text(l10n.routeRequestsAccept));
      await tester.pump();

      // In flight: still pending, and both controls are unavailable.
      expect(find.text(l10n.seatRequestPending), findsOneWidget);
      expect(find.text(l10n.seatRequestAccepted), findsNothing);
      expect(find.text(l10n.routeRequestsAccept), findsNothing);
      expect(backend.accepted, hasLength(1));

      backend.gate!.complete();
      await tester.pumpAndSettle();

      expect(find.text(l10n.seatRequestAccepted), findsOneWidget);
    });

    testWidgets('decline is not optimistic', (WidgetTester tester) async {
      final _Incoming backend = holding(<IncomingSeatRequest>[_incoming()])
        ..gate = Completer<void>();

      await pump(tester, backend);
      await tester.pumpAndSettle();

      final AppLocalizations l10n = l10nOf(tester);

      await tester.tap(find.text(l10n.routeRequestsDecline));
      await tester.pump();

      expect(find.text(l10n.seatRequestDeclined), findsNothing);

      backend.gate!.complete();
      await tester.pumpAndSettle();

      expect(find.text(l10n.seatRequestDeclined), findsOneWidget);
    });

    testWidgets('success changes only that row, and does not move it', (
      WidgetTester tester,
    ) async {
      final _Incoming backend = holding(<IncomingSeatRequest>[
        _incoming(id: 'q1', passenger: 'Ayşe Demir'),
        _incoming(id: 'q2', passenger: 'Zeynep Kaya', initials: 'ZK'),
      ])..decided = _incoming(id: 'q1', status: SeatRequestStatus.accepted);

      await pump(tester, backend);
      await tester.pumpAndSettle();

      await tester.tap(acceptIn(tester, 'Ayşe Demir'));
      await tester.pumpAndSettle();

      final AppLocalizations l10n = l10nOf(tester);

      expect(find.text(l10n.seatRequestAccepted), findsOneWidget);
      expect(find.text(l10n.seatRequestPending), findsOneWidget);
      expect(
        tester
            .widgetList<IncomingRequestCard>(find.byType(IncomingRequestCard))
            .map((IncomingRequestCard card) => card.request.id)
            .toList(),
        <String>['q1', 'q2'],
      );
    });

    /// One row deciding must not disable the others.
    testWidgets('a busy row leaves unrelated rows usable', (
      WidgetTester tester,
    ) async {
      final _Incoming backend = holding(<IncomingSeatRequest>[
        _incoming(id: 'q1', passenger: 'Ayşe Demir'),
        _incoming(id: 'q2', passenger: 'Zeynep Kaya', initials: 'ZK'),
      ])..gate = Completer<void>();

      await pump(tester, backend);
      await tester.pumpAndSettle();

      await tester.tap(acceptIn(tester, 'Ayşe Demir'));
      await tester.pump();

      // The other row's control is still there and still works.
      final Finder other = acceptIn(tester, 'Zeynep Kaya');
      expect(other, findsOneWidget);

      await tester.tap(other);
      await tester.pump();

      expect(backend.accepted, <String>['q1', 'q2']);

      backend.gate!.complete();
      await tester.pumpAndSettle();
    });
  });

  group('When the server refuses', () {
    /// CAPACITY IS THE BACKEND'S. A refused acceptance is not an acceptance,
    /// and nothing here counts seats to decide otherwise.
    testWidgets('route_full leaves the row exactly as it was', (
      WidgetTester tester,
    ) async {
      final _Incoming backend = holding(<IncomingSeatRequest>[_incoming()])
        ..decisionFailure = const RmFailure.fromBackend(
          status: 409,
          code: RmErrorCode.conflict,
          reason: 'route_full',
        );

      await pump(tester, backend);
      await tester.pumpAndSettle();

      final AppLocalizations l10n = l10nOf(tester);

      await tester.tap(find.text(l10n.routeRequestsAccept));
      await tester.pumpAndSettle();

      expect(find.text(l10n.seatRequestAccepted), findsNothing);
      expect(find.text(l10n.seatRequestPending), findsOneWidget);
      expect(find.text(l10n.routeRequestsFull), findsOneWidget);
      // A fact about the journey, not the request: no re-read hides it.
      expect(backend.reads, 1);
    });

    testWidgets('route_unavailable fabricates no request state', (
      WidgetTester tester,
    ) async {
      final _Incoming backend = holding(<IncomingSeatRequest>[_incoming()])
        ..decisionFailure = const RmFailure.fromBackend(
          status: 409,
          code: RmErrorCode.conflict,
          reason: 'route_unavailable',
        );

      await pump(tester, backend);
      await tester.pumpAndSettle();

      final AppLocalizations l10n = l10nOf(tester);

      await tester.tap(find.text(l10n.routeRequestsAccept));
      await tester.pumpAndSettle();

      expect(find.text(l10n.seatRequestPending), findsOneWidget);
      expect(find.text(l10n.routeRequestsRouteUnavailable), findsOneWidget);
    });

    /// The server knows something this client does not, and it cannot be
    /// applied locally without inventing a transition nobody performed.
    testWidgets('a terminal-state refusal re-reads authoritatively', (
      WidgetTester tester,
    ) async {
      final _Incoming backend =
          _Incoming(
              pages: <IncomingSeatRequestsResult>[
                IncomingSeatRequestsResult(
                  requests: <IncomingSeatRequest>[_incoming()],
                  nextCursor: null,
                ),
                // What the re-read finds: the passenger had taken it back.
                IncomingSeatRequestsResult(
                  requests: <IncomingSeatRequest>[
                    _incoming(status: SeatRequestStatus.withdrawn),
                  ],
                  nextCursor: null,
                ),
              ],
            )
            ..decisionFailure = const RmFailure.fromBackend(
              status: 409,
              code: RmErrorCode.conflict,
              reason: 'withdrawn',
              currentStatus: 'withdrawn',
            );

      await pump(tester, backend);
      await tester.pumpAndSettle();

      final AppLocalizations l10n = l10nOf(tester);

      await tester.tap(find.text(l10n.routeRequestsAccept));
      await tester.pumpAndSettle();

      expect(backend.reads, 2);
      expect(find.text(l10n.seatRequestWithdrawn), findsOneWidget);
      expect(find.text(l10n.seatRequestAccepted), findsNothing);
    });

    /// Declining creates no obligation and frees no seat, so the backend
    /// permits it on a dead journey — and the client must not decide otherwise.
    testWidgets('decline is never blocked by the client', (
      WidgetTester tester,
    ) async {
      final _Incoming backend = holding(<IncomingSeatRequest>[_incoming()]);

      await pump(tester, backend);
      await tester.pumpAndSettle();

      final AppLocalizations l10n = l10nOf(tester);

      // Nothing about the journey's state is consulted anywhere: the control
      // is offered on a pending request and the call goes out.
      await tester.tap(find.text(l10n.routeRequestsDecline));
      await tester.pumpAndSettle();

      expect(backend.declined, <String>['q1']);
      expect(find.text(l10n.seatRequestDeclined), findsOneWidget);
    });
  });

  group('Paging', () {
    testWidgets('load more appends without duplicating a row', (
      WidgetTester tester,
    ) async {
      final _Incoming backend = _Incoming(
        pages: <IncomingSeatRequestsResult>[
          IncomingSeatRequestsResult(
            requests: <IncomingSeatRequest>[
              _incoming(id: 'q1'),
              _incoming(id: 'q2', passenger: 'Zeynep Kaya', initials: 'ZK'),
            ],
            nextCursor: 'more',
          ),
          IncomingSeatRequestsResult(
            requests: <IncomingSeatRequest>[
              // q2 repeated, as a row written between two reads can be.
              _incoming(id: 'q2', passenger: 'Zeynep Kaya', initials: 'ZK'),
              _incoming(id: 'q3', passenger: 'Mert Kaya', initials: 'MK'),
            ],
            nextCursor: null,
          ),
        ],
      );

      await pump(tester, backend);
      await tester.pumpAndSettle();

      // Below the fold with two cards above it.
      final Finder more = find.text(l10nOf(tester).routeRequestsLoadMore);
      await tester.ensureVisible(more);
      await tester.pumpAndSettle();
      await tester.tap(more);
      await tester.pumpAndSettle();

      expect(
        tester
            .widgetList<IncomingRequestCard>(find.byType(IncomingRequestCard))
            .map((IncomingRequestCard card) => card.request.id)
            .toList(),
        <String>['q1', 'q2', 'q3'],
      );
    });

    testWidgets('a failed second page keeps the first on screen', (
      WidgetTester tester,
    ) async {
      final _Incoming backend = holding(<IncomingSeatRequest>[
        _incoming(),
      ], cursor: 'more');

      await pump(tester, backend);
      await tester.pumpAndSettle();

      final AppLocalizations l10n = l10nOf(tester);

      backend.readFails = true;
      final Finder more = find.text(l10n.routeRequestsLoadMore);
      await tester.ensureVisible(more);
      await tester.pumpAndSettle();
      await tester.tap(more);
      await tester.pumpAndSettle();

      expect(find.byType(IncomingRequestCard), findsOneWidget);
      expect(find.text(l10n.routeRequestsLoadMoreFailed), findsOneWidget);
    });
  });

  group('What the screen never says', () {
    /// CARRIES WEIGHT. No identifier, and no claim the product cannot make.
    testWidgets('no private data and no unsupported claim reaches it', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        holding(<IncomingSeatRequest>[
          _incoming(status: SeatRequestStatus.accepted),
        ]),
      );
      await tester.pumpAndSettle();

      final Iterable<String> rendered = tester
          .widgetList<Text>(find.byType(Text))
          .map((Text t) => (t.data ?? '').toLowerCase());

      for (final String forbidden in <String>[
        '+90',
        'q1',
        '01991',
        '★',
        'puan',
        'güven',
        'doğrulan',
        '₺',
        'ücret',
        'fiyat',
        'ödeme',
        'kalan',
        'boş koltuk',
        'koltuk sunuluyor',
      ]) {
        expect(
          rendered.any((String s) => s.contains(forbidden)),
          isFalse,
          reason: '"$forbidden" reached the screen',
        );
      }
    });

    testWidgets('tapping a row opens nothing', (WidgetTester tester) async {
      await pump(
        tester,
        holding(<IncomingSeatRequest>[
          _incoming(status: SeatRequestStatus.accepted),
        ]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ayşe Demir'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(RouteRequestsScreen), findsOneWidget);
    });
  });

  group('Rating a passenger', () {
    _Incoming accepted({MyReview? myReview}) => _Incoming(
      pages: <IncomingSeatRequestsResult>[
        IncomingSeatRequestsResult(
          requests: <IncomingSeatRequest>[
            _incoming(status: SeatRequestStatus.accepted, myReview: myReview),
          ],
          nextCursor: null,
        ),
      ],
    );

    testWidgets('an agreed seat on a completed journey offers it', (
      WidgetTester tester,
    ) async {
      await pump(tester, accepted(), trip: TripState.completed);
      await tester.pumpAndSettle();

      expect(find.text(l10nOf(tester).reviewSubmit), findsOneWidget);
    });

    testWidgets('no other journey state offers it', (
      WidgetTester tester,
    ) async {
      for (final TripState state in <TripState>[
        TripState.notStarted,
        TripState.inProgress,
        TripState.aborted,
      ]) {
        await pump(tester, accepted(), trip: state);
        await tester.pumpAndSettle();

        expect(
          find.text(l10nOf(tester).reviewSubmit),
          findsNothing,
          reason: state.wire,
        );
      }
    });

    /// CARRIES WEIGHT. A projection that is not there is not a completed trip.
    ///
    /// The driver's own list is the only source of the journey here, so an
    /// absent row must read as "unknown", never as "made".
    testWidgets('a journey missing from the owner list offers nothing', (
      WidgetTester tester,
    ) async {
      await pump(tester, accepted());
      await tester.pumpAndSettle();

      expect(find.text(l10nOf(tester).reviewSubmit), findsNothing);
    });

    /// CARRIES WEIGHT. A list that failed to load is not a completed journey.
    ///
    /// The `null` case is the owner's list still loading or erroring. It has to
    /// read as "unknown", because an unreadable page is the weakest possible
    /// evidence that a trip was made.
    testWidgets('an unreadable owner list offers nothing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            seatRequestRepositoryProvider.overrideWithValue(accepted()),
            myRoutesRepositoryProvider.overrideWithValue(
              FakeMyRoutesRepository.offline(),
            ),
          ],
          child: MaterialApp(
            theme: RmTheme.of(Brightness.light),
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const RouteRequestsScreen(routeId: _routeId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10nOf(tester).reviewSubmit), findsNothing);
    });

    testWidgets('an unagreed seat offers nothing, however the journey went', (
      WidgetTester tester,
    ) async {
      for (final SeatRequestStatus status in <SeatRequestStatus>[
        SeatRequestStatus.pending,
        SeatRequestStatus.declined,
        SeatRequestStatus.withdrawn,
      ]) {
        await pump(
          tester,
          _Incoming(
            pages: <IncomingSeatRequestsResult>[
              IncomingSeatRequestsResult(
                requests: <IncomingSeatRequest>[_incoming(status: status)],
                nextCursor: null,
              ),
            ],
          ),
          trip: TripState.completed,
        );
        await tester.pumpAndSettle();

        expect(
          find.text(l10nOf(tester).reviewSubmit),
          findsNothing,
          reason: status.wire,
        );
      }
    });

    testWidgets('an already-rated passenger shows this driver own rating', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        accepted(
          myReview: MyReview(
            id: '01993a00-0000-7000-8000-000000000001',
            rating: 2,
            submittedAt: DateTime.utc(2026, 9, 25, 9, 14),
          ),
        ),
        trip: TripState.completed,
      );
      await tester.pumpAndSettle();

      expect(find.text(l10nOf(tester).reviewSubmitted(2)), findsOneWidget);
      expect(find.text(l10nOf(tester).reviewSubmit), findsNothing);
    });
  });
}
