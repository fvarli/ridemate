// ─────────────────────────────────────────────────────────────
// RideMate — Asking for a seat from a real result
//
// The card's first action, and the four ways it must not lie: it does not
// appear where the server would refuse it, it does not claim success before
// the server says so, it does not come back once an asking exists, and a
// retry after a lost response is the SAME asking rather than a second one.
// ─────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/api/rm_error_code.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/id/rm_uuid.dart';
import 'package:ridemate/core/places/place.dart';
import 'package:ridemate/core/routes/departure.dart';
import 'package:ridemate/core/routes/discovered_route.dart';
import 'package:ridemate/core/routes/published_route.dart';
import 'package:ridemate/core/routes/ride_rule.dart';
import 'package:ridemate/core/seat_requests/seat_request.dart';
import 'package:ridemate/core/theme/rm_theme.dart';
import 'package:ridemate/features/create_route/application/publication_providers.dart';
import 'package:ridemate/features/discovery/application/discovery_search_providers.dart';
import 'package:ridemate/features/discovery/data/discovery_repository.dart';
import 'package:ridemate/features/discovery/presentation/match_results_screen.dart';
import 'package:ridemate/features/discovery/presentation/widgets/discovered_route_card.dart';
import 'package:ridemate/features/seat_requests/application/seat_request_providers.dart';
import 'package:ridemate/features/seat_requests/data/seat_request_repository.dart';
import 'package:ridemate/l10n/app_localizations.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';

/// A seat-request backend that records exactly what it was asked.
class _AskRecorder implements SeatRequestRepository {
  _AskRecorder({this.failures = 0, this.failure});

  /// How many of the first attempts fail before one succeeds.
  int failures;
  RmFailure? failure;

  final List<String> requestIds = <String>[];
  final List<String> routeIds = <String>[];

  /// Held open so a test can observe the in-flight state.
  Completer<void>? gate;

  int get calls => requestIds.length;

  @override
  Future<SeatRequested> ask({
    required String routeId,
    required String requestId,
  }) async {
    requestIds.add(requestId);
    routeIds.add(routeId);

    final Completer<void>? held = gate;
    if (held != null) await held.future;

    if (failures > 0) {
      failures--;
      throw failure ?? const RmFailure.transport();
    }

    return SeatRequested(
      request: _accepted(requestId, routeId),
      wasAlreadyRequested: false,
    );
  }

  @override
  Future<MySeatRequestsResult> mine({String? cursor, int limit = 20}) async =>
      const MySeatRequestsResult(requests: <MySeatRequest>[], nextCursor: null);

  @override
  Future<MySeatRequest> withdraw(String requestId) =>
      throw UnimplementedError();

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

MySeatRequest _accepted(String id, String routeId) => MySeatRequest(
  id: id,
  status: SeatRequestStatus.pending,
  requestedAt: DateTime.utc(2026, 9, 9, 8),
  decidedAt: null,
  withdrawnAt: null,
  route: SeatRequestRoute(
    id: routeId,
    origin: const Place(id: 'p1', label: 'Kadıköy'),
    destination: const Place(id: 'p2', label: 'Levent'),
    recurrence: Recurrence.once,
    departureDate: const DepartureDate(year: 2026, month: 9, day: 14),
    departureTime: const DepartureTime(hour: 8, minute: 25),
    timezone: 'Europe/Istanbul',
    status: RouteStatus.published,
    departureState: DepartureState.upcoming,
    seatsOffered: 3,
    rules: const <RideRuleId>{},
    driver: const SeatRequestMember(displayName: 'İrem Yılmaz', initials: 'İY'),
  ),
);

/// A generator whose ids a test can recognise on sight.
class _CountingUuid implements RmUuidGenerator {
  int _next = 0;

  @override
  String v7() =>
      '01991d00-0000-7000-8000-${(++_next).toString().padLeft(12, '0')}';
}

void main() {
  setUpAll(loadRideMateFonts);

  const String routeId = '01991c00-0000-7000-8000-000000000001';

  DiscoveredRoute route({
    Recurrence recurrence = Recurrence.once,
    DepartureState departureState = DepartureState.upcoming,
    SeatRequestStatus? asked,
  }) => fakeDiscoveredRoute(
    id: routeId,
    recurrence: recurrence,
    departureDate: recurrence == Recurrence.once ? '2026-09-14' : null,
    departureState: departureState,
    mySeatRequest: asked == null
        ? null
        : <String, Object?>{'id': 'r1', 'status': asked.wire},
  );

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    required List<DiscoveredRoute> routes,
    SeatRequestRepository? seats,
    RmUuidGenerator? uuid,
  }) async {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        discoveryRepositoryProvider.overrideWithValue(
          FakeDiscoveryRepository(
            pages: <DiscoveryResult>[
              DiscoveryResult(routes: routes, nextCursor: null),
            ],
          ),
        ),
        discoveryQueryProvider.overrideWith(SearchedQueryController.new),
        if (seats != null)
          seatRequestRepositoryProvider.overrideWithValue(seats),
        if (uuid != null) uuidGeneratorProvider.overrideWithValue(uuid),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: RmTheme.of(Brightness.light),
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MatchResultsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return container;
  }

  String ask(WidgetTester tester) => AppLocalizations.of(
    tester.element(find.byType(MatchResultsScreen)),
  ).seatRequestAsk;

  /// The action inside the card for one driver.
  ///
  /// Scoped, because after a failure a card shows both a message and the
  /// action, and `.first`/`.last` over the whole screen stops meaning what it
  /// looks like it means.
  Finder askIn(WidgetTester tester, String driver) => find.descendant(
    of: find.ancestor(
      of: find.text(driver),
      matching: find.byType(DiscoveredRouteCard),
    ),
    matching: find.text(ask(tester)),
  );

  group('When the action appears', () {
    testWidgets('a one-off, upcoming, unasked journey offers it', (
      WidgetTester tester,
    ) async {
      await pump(tester, routes: <DiscoveredRoute>[route()]);

      expect(find.text(ask(tester)), findsOneWidget);
    });

    /// No single departure to hold a seat on, so no action — and deliberately
    /// not a disabled one, which would say the feature exists and is being
    /// withheld from this member.
    testWidgets('a weekday plan offers none', (WidgetTester tester) async {
      await pump(
        tester,
        routes: <DiscoveredRoute>[route(recurrence: Recurrence.weekdays)],
      );

      expect(find.text(ask(tester)), findsNothing);
      expect(
        find.text(
          AppLocalizations.of(
            tester.element(find.byType(MatchResultsScreen)),
          ).seatRequestRecurringUnsupported,
        ),
        findsOneWidget,
      );
    });

    testWidgets('a departed journey offers none', (WidgetTester tester) async {
      await pump(
        tester,
        routes: <DiscoveredRoute>[route(departureState: DepartureState.past)],
      );

      expect(find.text(ask(tester)), findsNothing);
    });
  });

  group('When an asking already exists', () {
    for (final (
          SeatRequestStatus status,
          String Function(AppLocalizations) copy,
        )
        in <(SeatRequestStatus, String Function(AppLocalizations))>[
          (
            SeatRequestStatus.pending,
            (AppLocalizations l) => l.seatRequestPending,
          ),
          (
            SeatRequestStatus.accepted,
            (AppLocalizations l) => l.seatRequestAccepted,
          ),
          (
            SeatRequestStatus.declined,
            (AppLocalizations l) => l.seatRequestDeclined,
          ),
          (
            SeatRequestStatus.withdrawn,
            (AppLocalizations l) => l.seatRequestWithdrawn,
          ),
        ]) {
      testWidgets('$status shows its state and no action', (
        WidgetTester tester,
      ) async {
        await pump(tester, routes: <DiscoveredRoute>[route(asked: status)]);

        final AppLocalizations l10n = AppLocalizations.of(
          tester.element(find.byType(MatchResultsScreen)),
        );

        expect(find.text(copy(l10n)), findsOneWidget);
        // Terminal or not: one asking per journey for its lifetime, so the
        // action never comes back.
        expect(find.text(ask(tester)), findsNothing);
      });
    }
  });

  group('Sending', () {
    testWidgets(
      'one tap sends once, and a second while in flight sends nothing',
      (WidgetTester tester) async {
        final _AskRecorder seats = _AskRecorder()..gate = Completer<void>();
        await pump(
          tester,
          routes: <DiscoveredRoute>[route()],
          seats: seats,
          uuid: _CountingUuid(),
        );

        await tester.tap(find.text(ask(tester)));
        await tester.pump();

        // In flight: the label changed and the control is disabled.
        expect(find.text(ask(tester)), findsNothing);

        await tester.tap(find.byType(InkWell).last, warnIfMissed: false);
        await tester.pump();

        expect(seats.calls, 1);

        seats.gate!.complete();
        await tester.pumpAndSettle();
      },
    );

    testWidgets('nothing claims success before the server answers', (
      WidgetTester tester,
    ) async {
      final _AskRecorder seats = _AskRecorder()..gate = Completer<void>();
      await pump(
        tester,
        routes: <DiscoveredRoute>[route()],
        seats: seats,
        uuid: _CountingUuid(),
      );

      await tester.tap(find.text(ask(tester)));
      await tester.pump();

      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(MatchResultsScreen)),
      );

      expect(find.text(l10n.seatRequestPending), findsNothing);

      seats.gate!.complete();
      await tester.pumpAndSettle();

      // And only afterwards, from what the server returned.
      expect(find.text(l10n.seatRequestPending), findsOneWidget);
    });

    testWidgets('a transport failure leaves the journey unasked', (
      WidgetTester tester,
    ) async {
      final _AskRecorder seats = _AskRecorder(failures: 1);
      await pump(
        tester,
        routes: <DiscoveredRoute>[route()],
        seats: seats,
        uuid: _CountingUuid(),
      );

      await tester.tap(find.text(ask(tester)));
      await tester.pumpAndSettle();

      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(MatchResultsScreen)),
      );

      expect(find.text(l10n.seatRequestPending), findsNothing);
      expect(find.text(l10n.seatRequestFailed), findsOneWidget);
      // The action is back, because nothing was recorded.
      expect(find.text(ask(tester)), findsOneWidget);
    });

    /// THE ONE THE WHOLE CLIENT-GENERATED ID EXISTS FOR.
    ///
    /// The passenger taps, the server records the asking, the response is
    /// lost. The retry must carry the SAME id — otherwise the backend cannot
    /// recognise it as the same asking, and answers `already_requested` about
    /// a request that actually succeeded.
    testWidgets('an explicit retry reuses the same request id', (
      WidgetTester tester,
    ) async {
      final _AskRecorder seats = _AskRecorder(failures: 1);
      await pump(
        tester,
        routes: <DiscoveredRoute>[route()],
        seats: seats,
        uuid: _CountingUuid(),
      );

      await tester.tap(find.text(ask(tester)));
      await tester.pumpAndSettle();

      await tester.tap(find.text(ask(tester)));
      await tester.pumpAndSettle();

      expect(seats.calls, 2);
      expect(seats.requestIds.first, seats.requestIds.last);
      expect(seats.routeIds, <String>[routeId, routeId]);
    });

    /// And a genuinely new intent is a genuinely new id.
    testWidgets('a different journey gets its own id', (
      WidgetTester tester,
    ) async {
      final _AskRecorder seats = _AskRecorder(failures: 2);
      const String otherId = '01991c00-0000-7000-8000-000000000002';

      await pump(
        tester,
        routes: <DiscoveredRoute>[
          route(),
          fakeDiscoveredRoute(
            id: otherId,
            recurrence: Recurrence.once,
            departureDate: '2026-09-15',
            displayName: 'Zeynep Kaya',
            initials: 'ZK',
          ),
        ],
        seats: seats,
        uuid: _CountingUuid(),
      );

      await tester.tap(askIn(tester, 'Ayşe Demir'));
      await tester.pumpAndSettle();

      // The second card sits below the fold once the first has grown a
      // failure message, and a tap on an off-screen control hits nothing.
      final Finder second = askIn(tester, 'Zeynep Kaya');
      await tester.ensureVisible(second);
      await tester.pumpAndSettle();
      await tester.tap(second);
      await tester.pumpAndSettle();

      expect(seats.routeIds, <String>[routeId, otherId]);
      expect(seats.requestIds.first, isNot(seats.requestIds.last));
    });
  });

  group('Reconciliation', () {
    /// The client does not know the real request id, so it must not invent
    /// one: it re-reads the search and shows whatever the server returns.
    testWidgets('already_requested re-reads discovery rather than guessing', (
      WidgetTester tester,
    ) async {
      final _AskRecorder seats = _AskRecorder(
        failures: 1,
        failure: const RmFailure.fromBackend(
          status: 409,
          code: RmErrorCode.conflict,
          reason: 'already_requested',
          currentStatus: 'pending',
        ),
      );

      final ProviderContainer container = await pump(
        tester,
        routes: <DiscoveredRoute>[route()],
        seats: seats,
        uuid: _CountingUuid(),
      );

      // The re-read answers with the asking the server actually holds.
      container.read(discoveryRepositoryProvider);

      await tester.tap(find.text(ask(tester)));
      await tester.pumpAndSettle();

      // No fabricated id reached the card: the state came from a refresh, and
      // the fake's only page is exhausted, so the list is empty rather than
      // showing an invented request.
      expect(find.text(ask(tester)), findsNothing);
    });

    testWidgets('route_unavailable reconciles too', (
      WidgetTester tester,
    ) async {
      final _AskRecorder seats = _AskRecorder(
        failures: 1,
        failure: const RmFailure.fromBackend(
          status: 409,
          code: RmErrorCode.conflict,
          reason: 'route_unavailable',
        ),
      );

      await pump(
        tester,
        routes: <DiscoveredRoute>[route()],
        seats: seats,
        uuid: _CountingUuid(),
      );

      await tester.tap(find.text(ask(tester)));
      await tester.pumpAndSettle();

      expect(find.text(ask(tester)), findsNothing);
    });
  });

  group('What the card still does not do', () {
    testWidgets('a real result opens no fixture Route Details', (
      WidgetTester tester,
    ) async {
      await pump(tester, routes: <DiscoveredRoute>[route()]);

      // The journey body is inert; only the action is tappable.
      await tester.tap(
        find.text('Sunucu Yeri Bir → Sunucu Yeri İki'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(find.byType(MatchResultsScreen), findsOneWidget);
    });

    testWidgets('asking one card does not reorder the results', (
      WidgetTester tester,
    ) async {
      const String otherId = '01991c00-0000-7000-8000-000000000002';
      final _AskRecorder seats = _AskRecorder();

      await pump(
        tester,
        routes: <DiscoveredRoute>[
          route(),
          fakeDiscoveredRoute(
            id: otherId,
            recurrence: Recurrence.once,
            departureDate: '2026-09-15',
            displayName: 'Zeynep Kaya',
            initials: 'ZK',
          ),
        ],
        seats: seats,
        uuid: _CountingUuid(),
      );

      List<String> drivers() => tester
          .widgetList<DiscoveredRouteCard>(find.byType(DiscoveredRouteCard))
          .map((DiscoveredRouteCard card) => card.route.driver.displayName)
          .toList();

      expect(drivers(), <String>['Ayşe Demir', 'Zeynep Kaya']);

      await tester.tap(askIn(tester, 'Ayşe Demir'));
      await tester.pumpAndSettle();

      // The asked card legitimately changes height — its action became a
      // status — but the results keep their order and their number.
      expect(drivers(), <String>['Ayşe Demir', 'Zeynep Kaya']);
    });
  });
}
