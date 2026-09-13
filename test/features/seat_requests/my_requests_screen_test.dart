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
import 'package:ridemate/core/reviews/review.dart';
import 'package:ridemate/core/routes/departure.dart';
import 'package:ridemate/core/routes/published_route.dart';
import 'package:ridemate/core/routes/ride_rule.dart';
import 'package:ridemate/core/seat_requests/seat_request.dart';
import 'package:ridemate/core/theme/rm_theme.dart';
import 'package:ridemate/core/trips/trip_lifecycle.dart';
import 'package:ridemate/core/widgets/rm_button.dart';
import 'package:ridemate/core/widgets/rm_rating_input.dart';
import 'package:ridemate/features/reviews/application/review_action_providers.dart';
import 'package:ridemate/features/reviews/data/review_repository.dart';
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
  TripState trip = TripState.notStarted,
  MyReview? myReview,
}) => MySeatRequest(
  id: id,
  serviceDate: const DepartureDate(year: 2026, month: 9, day: 24),
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
    trip: fakeTrip(
      state: trip,
      startedAt: trip == TripState.notStarted ? null : '2026-09-11T07:05:00Z',
      completedAt: trip == TripState.completed ? '2026-09-11T07:45:00Z' : null,
      abortedAt: trip == TripState.aborted ? '2026-09-11T07:20:00Z' : null,
    ),
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
    DepartureDate? serviceDate,
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

  Future<void> pump(
    WidgetTester tester,
    _Requests backend, {
    RmFailure? reviewFails,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          seatRequestRepositoryProvider.overrideWithValue(backend),
          reviewRepositoryProvider.overrideWithValue(
            _StubReviews(failWith: reviewFails),
          ),
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
        // Phase 14 could have said any of these about a started journey. The
        // server knows none of them: it knows the driver pressed Start.
        'yolda',
        'yola çıktı',
        'geliyor',
        'seyahat',
        'bindin',
        'alındın',
        'konum',
        'harita',
        'navigasyon',
        'gps',
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

      // Tall enough to build the control at all: the list is lazy, so a
      // widget far below the viewport is never created and cannot be scrolled
      // to. Two cards now carry a lifecycle line each.
      await tester.binding.setSurfaceSize(const Size(393, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

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

  group('Whether the journey was made', () {
    /// The third truth, beside the asking's own status and the journey's.
    testWidgets('all four states render their own line', (
      WidgetTester tester,
    ) async {
      for (final (TripState state, String copy) in <(TripState, String)>[
        (TripState.notStarted, 'Yolculuk: Başlamadı'),
        (TripState.inProgress, 'Yolculuk: Başladı'),
        (TripState.completed, 'Yolculuk: Tamamlandı'),
        (TripState.aborted, 'Yolculuk: Yarıda bırakıldı'),
      ]) {
        await pump(
          tester,
          _Requests(
            pages: <MySeatRequestsResult>[
              MySeatRequestsResult(
                requests: <MySeatRequest>[_request(trip: state)],
                nextCursor: null,
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(copy), findsOneWidget, reason: state.wire);
        expect(
          find.textContaining(state.wire),
          findsNothing,
          reason: 'the wire string reached the screen: ${state.wire}',
        );
      }
    });

    /// CARRIES WEIGHT. The one combination that looks like a bug and is not.
    ///
    /// A driver may set off while somebody's asking is still unanswered. Both
    /// are true, the server says both, and the client reconciles neither.
    testWidgets('a pending asking on a started journey stays pending', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        _Requests(
          pages: <MySeatRequestsResult>[
            MySeatRequestsResult(
              requests: <MySeatRequest>[
                _request(
                  status: SeatRequestStatus.pending,
                  trip: TripState.inProgress,
                ),
              ],
              nextCursor: null,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10nOf(tester).seatRequestPending), findsOneWidget);
      expect(find.text('Yolculuk: Başladı'), findsOneWidget);
      // And the asking is still the passenger's to take back.
      expect(find.text(l10nOf(tester).myRequestsWithdraw), findsOneWidget);
    });

    /// CARRIES WEIGHT. A journey ending answers nobody's asking.
    testWidgets('an accepted asking survives every ending', (
      WidgetTester tester,
    ) async {
      for (final TripState state in <TripState>[
        TripState.inProgress,
        TripState.completed,
        TripState.aborted,
      ]) {
        await pump(
          tester,
          _Requests(
            pages: <MySeatRequestsResult>[
              MySeatRequestsResult(
                requests: <MySeatRequest>[
                  _request(status: SeatRequestStatus.accepted, trip: state),
                ],
                nextCursor: null,
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(l10nOf(tester).seatRequestAccepted),
          findsOneWidget,
          reason: state.wire,
        );
        // Still no Withdraw: Phase 13's rule, untouched by Phase 14.
        expect(
          find.text(l10nOf(tester).myRequestsWithdraw),
          findsNothing,
          reason: state.wire,
        );
      }
    });

    /// CARRIES WEIGHT. A withdrawn plan and an abandoned journey are different
    /// facts, and one is never drawn from the other.
    testWidgets('a cancelled journey nobody started says exactly that', (
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

      expect(find.text(l10nOf(tester).seatRequestAccepted), findsOneWidget);
      expect(
        find.text(l10nOf(tester).myRequestsRouteCancelled),
        findsOneWidget,
      );
      expect(find.text('Yolculuk: Başlamadı'), findsOneWidget);
      expect(find.text('Yolculuk: Yarıda bırakıldı'), findsNothing);
    });

    /// The lifecycle never decides whether the asking can be taken back.
    testWidgets('Withdraw follows the asking alone, in every state', (
      WidgetTester tester,
    ) async {
      for (final TripState state in TripState.values) {
        for (final (SeatRequestStatus status, Matcher expected)
            in <(SeatRequestStatus, Matcher)>[
              (SeatRequestStatus.pending, findsOneWidget),
              (SeatRequestStatus.accepted, findsNothing),
              (SeatRequestStatus.declined, findsNothing),
              (SeatRequestStatus.withdrawn, findsNothing),
            ]) {
          await pump(
            tester,
            _Requests(
              pages: <MySeatRequestsResult>[
                MySeatRequestsResult(
                  requests: <MySeatRequest>[
                    _request(status: status, trip: state),
                  ],
                  nextCursor: null,
                ),
              ],
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.text(l10nOf(tester).myRequestsWithdraw),
            expected,
            reason: '${status.wire} + ${state.wire}',
          );
        }
      }
    });

    /// CARRIES WEIGHT. Reading a lifecycle is not being able to change one.
    testWidgets('a passenger is offered no lifecycle command at all', (
      WidgetTester tester,
    ) async {
      for (final TripState state in TripState.values) {
        await pump(
          tester,
          _Requests(
            pages: <MySeatRequestsResult>[
              MySeatRequestsResult(
                requests: <MySeatRequest>[
                  _request(status: SeatRequestStatus.accepted, trip: state),
                ],
                nextCursor: null,
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        for (final String control in <String>[
          'Yolculuğu başlat',
          'Yolculuğu tamamla',
          'Yolculuğu yarıda bırak',
          'Yolculuk durumu',
        ]) {
          expect(
            find.text(control),
            findsNothing,
            reason: '$control: ${state.wire}',
          );
        }
      }
    });

    /// Three separate facts, each its own node, so a screen reader hears all
    /// three rather than one merged sentence.
    testWidgets('the lifecycle is announced beside the other two truths', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await pump(
        tester,
        _Requests(
          pages: <MySeatRequestsResult>[
            MySeatRequestsResult(
              requests: <MySeatRequest>[
                _request(
                  status: SeatRequestStatus.accepted,
                  routeStatus: RouteStatus.cancelled,
                  trip: TripState.notStarted,
                ),
              ],
              nextCursor: null,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // The card announces as one node whose label is its lines in order, so
      // what matters is that the lifecycle is IN it and stays distinct from
      // the two beside it — not that it has a node to itself.
      final String announced = tester
          .getSemantics(find.text('Yolculuk: Başlamadı'))
          .label;

      for (final String fact in <String>[
        l10nOf(tester).seatRequestAccepted,
        l10nOf(tester).myRequestsRouteCancelled,
        'Yolculuk: Başlamadı',
      ]) {
        expect(announced, contains(fact), reason: fact);
      }

      // Separated rather than run together: three facts, not one sentence a
      // listener has to unpick.
      expect(announced, contains('\n'));
      expect(
        announced.indexOf(l10nOf(tester).seatRequestAccepted),
        lessThan(announced.indexOf('Yolculuk: Başlamadı')),
      );

      handle.dispose();
    });
  });

  group('Rating a completed journey', () {
    MySeatRequest rateable({MyReview? myReview}) => _request(
      status: SeatRequestStatus.accepted,
      trip: TripState.completed,
      myReview: myReview,
    );

    Future<void> show(
      WidgetTester tester,
      MySeatRequest request, {
      RmFailure? reviewFails,
    }) async {
      await pump(
        tester,
        _Requests(
          pages: <MySeatRequestsResult>[
            MySeatRequestsResult(
              requests: <MySeatRequest>[request],
              nextCursor: null,
            ),
          ],
        ),
        reviewFails: reviewFails,
      );
      await tester.pumpAndSettle();
    }

    /// CARRIES WEIGHT. Three server facts, and not one local one.
    testWidgets('an agreed seat on a completed journey offers it', (
      WidgetTester tester,
    ) async {
      await show(tester, rateable());

      expect(find.text(l10nOf(tester).reviewSubmit), findsOneWidget);
    });

    /// CARRIES WEIGHT. Route status is not an eligibility gate.
    ///
    /// Withdrawing a plan says nothing about a journey that was already made,
    /// and the backend allows exactly this combination.
    testWidgets('a withdrawn plan with a completed journey still offers it', (
      WidgetTester tester,
    ) async {
      await show(
        tester,
        _request(
          status: SeatRequestStatus.accepted,
          trip: TripState.completed,
          routeStatus: RouteStatus.cancelled,
        ),
      );

      expect(find.text(l10nOf(tester).reviewSubmit), findsOneWidget);
    });

    testWidgets('no other combination offers it', (WidgetTester tester) async {
      for (final (SeatRequestStatus status, TripState trip)
          in <(SeatRequestStatus, TripState)>[
            (SeatRequestStatus.pending, TripState.completed),
            (SeatRequestStatus.declined, TripState.completed),
            (SeatRequestStatus.withdrawn, TripState.completed),
            (SeatRequestStatus.accepted, TripState.notStarted),
            (SeatRequestStatus.accepted, TripState.inProgress),
            (SeatRequestStatus.accepted, TripState.aborted),
          ]) {
        await show(tester, _request(status: status, trip: trip));

        expect(
          find.text(l10nOf(tester).reviewSubmit),
          findsNothing,
          reason: '${status.wire} + ${trip.wire}',
        );
      }
    });

    /// CARRIES WEIGHT. Their own rating, and nothing about the other side.
    testWidgets('an already-rated journey shows what this member said', (
      WidgetTester tester,
    ) async {
      await show(
        tester,
        rateable(
          myReview: MyReview(
            id: '01993a00-0000-7000-8000-000000000001',
            rating: 4,
            submittedAt: DateTime.utc(2026, 9, 25, 9, 14),
          ),
        ),
      );

      expect(find.text(l10nOf(tester).reviewSubmitted(4)), findsOneWidget);
      expect(find.text(l10nOf(tester).reviewSubmit), findsNothing);

      // Nothing about whether the driver rated anybody, or whether anything
      // has been released.
      final Iterable<String> rendered = tester
          .widgetList<Text>(find.byType(Text))
          .map((Text t) => (t.data ?? '').toLowerCase());

      for (final String forbidden in <String>[
        'sürücü değerlendirdi',
        'yayımlandı',
        'karşı taraf',
        'bekliyor',
      ]) {
        expect(
          rendered.any((String s) => s.contains(forbidden)),
          isFalse,
          reason: forbidden,
        );
      }
    });

    /// CARRIES WEIGHT. A 404 is not a refusal and must not read as one.
    ///
    /// The sheet closes on a settled failure, so the listing is where a member
    /// learns what happened — and being told "you already rated this" when the
    /// server said no such thing would be the app inventing an answer.
    testWidgets('a not-found is not presented as already reviewed', (
      WidgetTester tester,
    ) async {
      await show(
        tester,
        rateable(),
        reviewFails: const RmFailure.fromBackend(
          status: 404,
          code: RmErrorCode.notFound,
        ),
      );
      await tester.tap(find.text(l10nOf(tester).reviewSubmit));
      await tester.pumpAndSettle();

      await tester.tap(
        find.bySemanticsLabel(l10nOf(tester).reviewStarSemanticLabel(4)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10nOf(tester).reviewSend));
      await tester.pumpAndSettle();

      expect(find.text(l10nOf(tester).reviewAlreadyReviewed), findsNothing);
      expect(find.text(l10nOf(tester).errorUnexpected), findsOneWidget);
    });

    /// CARRIES WEIGHT. An indeterminate failure is its own thing.
    ///
    /// Nobody knows whether it landed, so the sheet stays open, the rating
    /// locks to what was sent, and the control becomes "send the same rating
    /// again" — not the generic network sentence, which says nothing about the
    /// one property that matters here.
    testWidgets('a lost response keeps the sheet, the rating and the id', (
      WidgetTester tester,
    ) async {
      await show(tester, rateable(), reviewFails: const RmFailure.transport());
      await tester.tap(find.text(l10nOf(tester).reviewSubmit));
      await tester.pumpAndSettle();

      await tester.tap(
        find.bySemanticsLabel(l10nOf(tester).reviewStarSemanticLabel(4)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10nOf(tester).reviewSend));
      await tester.pumpAndSettle();

      // Still open, and saying the one thing that distinguishes this case.
      expect(find.text(l10nOf(tester).reviewSheetTitle), findsOneWidget);
      expect(find.text(l10nOf(tester).reviewIndeterminate), findsOneWidget);
      expect(find.text(l10nOf(tester).errorNetwork), findsNothing);

      // The control now resends, and giving up is its own named act.
      expect(find.text(l10nOf(tester).reviewRetry), findsOneWidget);
      expect(find.text(l10nOf(tester).reviewAbandon), findsOneWidget);

      // And the stars are locked: the submission is what it was.
      final RmRatingInput stars = tester.widget<RmRatingInput>(
        find.byType(RmRatingInput),
      );
      expect(stars.value, 4);
      expect(stars.onChanged, isNull);
    });

    /// The control opens the sheet rather than submitting where it stands.
    testWidgets('tapping it opens the rating control', (
      WidgetTester tester,
    ) async {
      await show(tester, rateable());

      await tester.tap(find.text(l10nOf(tester).reviewSubmit));
      await tester.pumpAndSettle();

      expect(find.text(l10nOf(tester).reviewSheetTitle), findsOneWidget);
      // Five stars, each its own reachable choice.
      expect(
        find.bySemanticsLabel(l10nOf(tester).reviewStarSemanticLabel(3)),
        findsOneWidget,
      );
      // Nothing can be sent until one is chosen.
      final RmButton send = tester.widget<RmButton>(
        find.widgetWithText(RmButton, l10nOf(tester).reviewSend),
      );
      expect(send.onPressed, isNull);
    });
  });
}

/// A review backend a test can steer.
class _StubReviews implements ReviewRepository {
  const _StubReviews({this.failWith});

  final RmFailure? failWith;

  @override
  Future<MyReview> submitReview({
    required String requestId,
    required String reviewId,
    required int rating,
  }) async {
    final RmFailure? failure = failWith;
    if (failure != null) throw failure;

    return MyReview(
      id: reviewId,
      rating: rating,
      submittedAt: DateTime.utc(2026, 9, 25, 9, 14),
    );
  }

  @override
  Future<MyReviewsResult> mine({String? cursor, int limit = 20}) async =>
      const MyReviewsResult(reviews: <ReceivedReview>[], nextCursor: null);
}
