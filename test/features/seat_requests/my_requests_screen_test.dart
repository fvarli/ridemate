// ─────────────────────────────────────────────────────────────
// RideMate — My Requests
//
// A member's own history, and the things it must not do to it: hide a row
// because the journey moved on, merge two truths into one, offer to withdraw
// something that has already been answered, or claim a withdrawal the server
// has not confirmed.
// ─────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/api/rm_error_code.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/places/place.dart';
import 'package:ridemate/core/routes/departure.dart';
import 'package:ridemate/core/routes/published_route.dart';
import 'package:ridemate/core/routes/ride_rule.dart';
import 'package:ridemate/core/seat_requests/seat_request.dart';
import 'package:ridemate/core/theme/rm_theme.dart';
import 'package:ridemate/features/seat_requests/application/seat_request_providers.dart';
import 'package:ridemate/features/seat_requests/data/seat_request_repository.dart';
import 'package:ridemate/features/seat_requests/presentation/my_requests_screen.dart';
import 'package:ridemate/features/seat_requests/presentation/widgets/my_request_card.dart';
import 'package:ridemate/l10n/app_localizations.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';

MySeatRequest _request({
  String id = 'q1',
  SeatRequestStatus status = SeatRequestStatus.pending,
  RouteStatus routeStatus = RouteStatus.published,
  DepartureState departureState = DepartureState.upcoming,
  String driver = 'İrem Yılmaz',
  String initials = 'İY',
}) => MySeatRequest(
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
  route: SeatRequestRoute(
    id: 'route-$id',
    origin: const Place(id: 'p1', label: 'Kadıköy'),
    destination: const Place(id: 'p2', label: 'Levent'),
    recurrence: Recurrence.once,
    departureDate: const DepartureDate(year: 2026, month: 9, day: 14),
    departureTime: const DepartureTime(hour: 8, minute: 25),
    timezone: 'Europe/Istanbul',
    status: routeStatus,
    departureState: departureState,
    seatsOffered: 3,
    rules: const <RideRuleId>{},
    driver: SeatRequestMember(displayName: driver, initials: initials),
    // Always present on this projection, `notStarted` included.
    trip: fakeTrip(),
  ),
);

/// A backend a test can steer.
class _Requests implements SeatRequestRepository {
  _Requests({List<MySeatRequestsResult>? pages, this.readFails = false})
    : pages = pages ?? <MySeatRequestsResult>[];

  final List<MySeatRequestsResult> pages;
  bool readFails;

  /// What a withdrawal answers with, or throws.
  MySeatRequest? withdrawn;
  RmFailure? withdrawFailure;
  Completer<void>? gate;

  int reads = 0;
  final List<String> withdrawals = <String>[];

  @override
  Future<MySeatRequestsResult> mine({String? cursor, int limit = 20}) async {
    reads++;

    if (readFails) throw const RmFailure.transport();

    return pages.isEmpty
        ? const MySeatRequestsResult(
            requests: <MySeatRequest>[],
            nextCursor: null,
          )
        : pages.removeAt(0);
  }

  @override
  Future<MySeatRequest> withdraw(String requestId) async {
    withdrawals.add(requestId);

    final Completer<void>? held = gate;
    if (held != null) await held.future;

    final RmFailure? failure = withdrawFailure;
    if (failure != null) throw failure;

    return withdrawn ??
        _request(id: requestId, status: SeatRequestStatus.withdrawn);
  }

  @override
  Future<SeatRequested> ask({
    required String routeId,
    required String requestId,
  }) => throw UnimplementedError();

  @override
  Future<IncomingSeatRequestsResult> forRoute(
    String routeId, {
    String? cursor,
    int limit = 20,
  }) => throw UnimplementedError();

  @override
  Future<IncomingSeatRequest> accept(String requestId) =>
      throw UnimplementedError();

  @override
  Future<IncomingSeatRequest> decline(String requestId) =>
      throw UnimplementedError();
}

void main() {
  setUpAll(loadRideMateFonts);

  Future<void> pump(WidgetTester tester, _Requests backend) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          seatRequestRepositoryProvider.overrideWithValue(backend),
        ],
        child: MaterialApp(
          theme: RmTheme.of(Brightness.light),
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MyRequestsScreen(),
        ),
      ),
    );
  }

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(MyRequestsScreen)));

  group('States', () {
    testWidgets('loading says so while the first page is in flight', (
      WidgetTester tester,
    ) async {
      await pump(tester, _Requests());
      await tester.pump();

      expect(find.byType(MyRequestCard), findsNothing);

      await tester.pumpAndSettle();
    });

    /// A successful read that held nothing. Never what a failure looks like.
    testWidgets('empty is a server answer, not a failure', (
      WidgetTester tester,
    ) async {
      await pump(tester, _Requests());
      await tester.pumpAndSettle();

      final AppLocalizations l10n = l10nOf(tester);

      expect(find.text(l10n.myRequestsEmpty), findsOneWidget);
      expect(find.text(l10n.commonRetry), findsNothing);
    });

    testWidgets('a failed read says so and offers a retry', (
      WidgetTester tester,
    ) async {
      final _Requests backend = _Requests(readFails: true);
      await pump(tester, backend);
      await tester.pumpAndSettle();

      final AppLocalizations l10n = l10nOf(tester);

      expect(find.text(l10n.myRequestsEmpty), findsNothing);
      expect(find.text(l10n.commonRetry), findsOneWidget);

      backend.readFails = false;
      backend.pages.add(
        MySeatRequestsResult(
          requests: <MySeatRequest>[_request()],
          nextCursor: null,
        ),
      );

      await tester.tap(find.text(l10n.commonRetry));
      await tester.pumpAndSettle();

      expect(find.byType(MyRequestCard), findsOneWidget);
    });
  });

  group('History', () {
    testWidgets('all four statuses render truthfully', (
      WidgetTester tester,
    ) async {
      // Tall enough for four cards: a ListView only builds what is near the
      // viewport, and a row this test never scrolled to would look absent.
      await tester.binding.setSurfaceSize(const Size(393, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pump(
        tester,
        _Requests(
          pages: <MySeatRequestsResult>[
            MySeatRequestsResult(
              requests: <MySeatRequest>[
                for (final SeatRequestStatus status in SeatRequestStatus.values)
                  _request(id: status.wire, status: status),
              ],
              nextCursor: null,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final AppLocalizations l10n = l10nOf(tester);

      expect(find.text(l10n.seatRequestPending), findsOneWidget);
      expect(find.text(l10n.seatRequestAccepted), findsOneWidget);
      expect(find.text(l10n.seatRequestDeclined), findsOneWidget);
      expect(find.text(l10n.seatRequestWithdrawn), findsOneWidget);
      expect(find.byType(MyRequestCard), findsNWidgets(4));
    });

    /// THE ONE THAT MATTERS.
    ///
    /// The driver agreed to share a seat and then withdrew the journey. Both
    /// happened, and neither is corrected by the other.
    testWidgets('an accepted request on a cancelled journey shows both', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        _Requests(
          pages: <MySeatRequestsResult>[
            MySeatRequestsResult(
              requests: <MySeatRequest>[
                _request(
                  status: SeatRequestStatus.accepted,
                  routeStatus: RouteStatus.cancelled,
                ),
              ],
              nextCursor: null,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final AppLocalizations l10n = l10nOf(tester);

      expect(find.text(l10n.seatRequestAccepted), findsOneWidget);
      expect(find.text(l10n.myRequestsRouteCancelled), findsOneWidget);
      // And no invented third state reconciling them.
      expect(find.text(l10n.seatRequestDeclined), findsNothing);
      expect(find.text(l10n.seatRequestWithdrawn), findsNothing);
    });

    testWidgets('a departed journey stays in history', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        _Requests(
          pages: <MySeatRequestsResult>[
            MySeatRequestsResult(
              requests: <MySeatRequest>[
                _request(departureState: DepartureState.past),
              ],
              nextCursor: null,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MyRequestCard), findsOneWidget);
      expect(find.text(l10nOf(tester).myRequestsRouteDeparted), findsOneWidget);
    });

    /// CARRIES WEIGHT. Nothing on this screen claims what the product cannot.
    testWidgets('no unsupported claim appears anywhere', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        _Requests(
          pages: <MySeatRequestsResult>[
            MySeatRequestsResult(
              requests: <MySeatRequest>[_request()],
              nextCursor: null,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final Iterable<String> rendered = tester
          .widgetList<Text>(find.byType(Text))
          .map((Text t) => t.data ?? '')
          .map((String s) => s.toLowerCase());

      for (final String forbidden in <String>[
        '★',
        'puan',
        'güven',
        'doğrulan',
        'uyum',
        'yürü',
        '₺',
        'ücret',
        'fiyat',
        'ödeme',
        'kalan koltuk',
        'boş koltuk',
      ]) {
        expect(
          rendered.any((String s) => s.contains(forbidden)),
          isFalse,
          reason: '"$forbidden" reached the screen',
        );
      }
    });
  });

  group('Withdrawing', () {
    testWidgets('only a pending request offers it', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(393, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pump(
        tester,
        _Requests(
          pages: <MySeatRequestsResult>[
            MySeatRequestsResult(
              requests: <MySeatRequest>[
                for (final SeatRequestStatus status in SeatRequestStatus.values)
                  _request(id: status.wire, status: status),
              ],
              nextCursor: null,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10nOf(tester).myRequestsWithdraw), findsOneWidget);
    });

    testWidgets('nothing is withdrawn before the server says so', (
      WidgetTester tester,
    ) async {
      final _Requests backend = _Requests(
        pages: <MySeatRequestsResult>[
          MySeatRequestsResult(
            requests: <MySeatRequest>[_request()],
            nextCursor: null,
          ),
        ],
      )..gate = Completer<void>();

      await pump(tester, backend);
      await tester.pumpAndSettle();

      final AppLocalizations l10n = l10nOf(tester);

      await tester.tap(find.text(l10n.myRequestsWithdraw));
      await tester.pump();

      // In flight: still pending, and the control is disabled.
      expect(find.text(l10n.seatRequestPending), findsOneWidget);
      expect(find.text(l10n.seatRequestWithdrawn), findsNothing);

      // The label is gone while it loads, which is how RmButton renders a
      // disabled in-flight control — so there is nothing left to tap twice.
      expect(find.text(l10n.myRequestsWithdraw), findsNothing);
      expect(backend.withdrawals, hasLength(1));

      backend.gate!.complete();
      await tester.pumpAndSettle();

      // And only now, from the server's own version of the request.
      expect(find.text(l10n.seatRequestWithdrawn), findsOneWidget);
    });

    testWidgets('success changes only that row', (WidgetTester tester) async {
      final _Requests backend = _Requests(
        pages: <MySeatRequestsResult>[
          MySeatRequestsResult(
            requests: <MySeatRequest>[
              _request(id: 'q1'),
              _request(id: 'q2', driver: 'Ayşe Demir', initials: 'AD'),
            ],
            nextCursor: null,
          ),
        ],
      )..withdrawn = _request(id: 'q1', status: SeatRequestStatus.withdrawn);

      await pump(tester, backend);
      await tester.pumpAndSettle();

      final AppLocalizations l10n = l10nOf(tester);

      await tester.tap(find.text(l10n.myRequestsWithdraw).first);
      await tester.pumpAndSettle();

      expect(find.text(l10n.seatRequestWithdrawn), findsOneWidget);
      // The other row is untouched, and the order is unchanged.
      expect(find.text(l10n.seatRequestPending), findsOneWidget);
      expect(
        tester
            .widgetList<MyRequestCard>(find.byType(MyRequestCard))
            .map((MyRequestCard card) => card.request.id)
            .toList(),
        <String>['q1', 'q2'],
      );
    });

    /// The server knows something this client does not, and it cannot be
    /// applied locally without inventing a transition nobody performed.
    testWidgets('a conflicting answer re-reads instead of guessing', (
      WidgetTester tester,
    ) async {
      final _Requests backend =
          _Requests(
              pages: <MySeatRequestsResult>[
                MySeatRequestsResult(
                  requests: <MySeatRequest>[_request()],
                  nextCursor: null,
                ),
                // What the re-read finds: the driver had already accepted it.
                MySeatRequestsResult(
                  requests: <MySeatRequest>[
                    _request(status: SeatRequestStatus.accepted),
                  ],
                  nextCursor: null,
                ),
              ],
            )
            ..withdrawFailure = const RmFailure.fromBackend(
              status: 409,
              code: RmErrorCode.conflict,
              reason: 'already_accepted',
              currentStatus: 'accepted',
            );

      await pump(tester, backend);
      await tester.pumpAndSettle();

      final AppLocalizations l10n = l10nOf(tester);

      await tester.tap(find.text(l10n.myRequestsWithdraw));
      await tester.pumpAndSettle();

      expect(backend.reads, 2);
      expect(find.text(l10n.seatRequestAccepted), findsOneWidget);
      // Not the state the client was asking for.
      expect(find.text(l10n.seatRequestWithdrawn), findsNothing);
    });
  });

  group('Paging', () {
    testWidgets('load more appends without duplicating a row', (
      WidgetTester tester,
    ) async {
      final _Requests backend = _Requests(
        pages: <MySeatRequestsResult>[
          MySeatRequestsResult(
            requests: <MySeatRequest>[
              _request(id: 'q1'),
              _request(id: 'q2'),
            ],
            nextCursor: 'more',
          ),
          MySeatRequestsResult(
            // q2 repeated, as a row written between two reads can be.
            requests: <MySeatRequest>[
              _request(id: 'q2'),
              _request(id: 'q3'),
            ],
            nextCursor: null,
          ),
        ],
      );

      await pump(tester, backend);
      await tester.pumpAndSettle();

      // The control sits below the fold with two cards above it, and a tap on
      // an off-screen widget hits nothing.
      final Finder more = find.text(l10nOf(tester).myRequestsLoadMore);
      await tester.ensureVisible(more);
      await tester.pumpAndSettle();
      await tester.tap(more);
      await tester.pumpAndSettle();

      expect(
        tester
            .widgetList<MyRequestCard>(find.byType(MyRequestCard))
            .map((MyRequestCard card) => card.request.id)
            .toList(),
        <String>['q1', 'q2', 'q3'],
      );
    });

    testWidgets('a failed second page keeps the first on screen', (
      WidgetTester tester,
    ) async {
      final _Requests backend = _Requests(
        pages: <MySeatRequestsResult>[
          MySeatRequestsResult(
            requests: <MySeatRequest>[_request()],
            nextCursor: 'more',
          ),
        ],
      );

      await pump(tester, backend);
      await tester.pumpAndSettle();

      final AppLocalizations l10n = l10nOf(tester);

      backend.readFails = true;
      await tester.tap(find.text(l10n.myRequestsLoadMore));
      await tester.pumpAndSettle();

      expect(find.byType(MyRequestCard), findsOneWidget);
      expect(find.text(l10n.myRequestsLoadMoreFailed), findsOneWidget);
      // The cursor is untouched, so the control offers to try again.
      expect(find.text(l10n.commonRetry), findsOneWidget);
    });
  });

  group('What the screen does not do', () {
    testWidgets('tapping a row opens nothing', (WidgetTester tester) async {
      await pump(
        tester,
        _Requests(
          pages: <MySeatRequestsResult>[
            MySeatRequestsResult(
              requests: <MySeatRequest>[
                _request(status: SeatRequestStatus.accepted),
              ],
              nextCursor: null,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kadıköy → Levent'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Still here. Route Details is fixture-backed and this screen is not a
      // way into it.
      expect(find.byType(MyRequestsScreen), findsOneWidget);
    });
  });
}
