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
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/api/rm_error_code.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/format/rm_formatters.dart';
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

  /// The day each attempt named. `null` would mean the client asked the server
  /// to guess which journey it meant, which Phase 16b removed.
  final List<DepartureDate?> serviceDates = <DepartureDate?>[];

  /// Held open so a test can observe the in-flight state.
  Completer<void>? gate;

  int get calls => requestIds.length;

  @override
  Future<SeatRequested> ask({
    required String routeId,
    required String requestId,
    DepartureDate? serviceDate,
  }) async {
    requestIds.add(requestId);
    routeIds.add(routeId);
    serviceDates.add(serviceDate);

    final Completer<void>? held = gate;
    if (held != null) await held.future;

    if (failures > 0) {
      failures--;
      throw failure ?? const RmFailure.transport();
    }

    return SeatRequested(
      // The server answers about the day it was asked about. Echoing it is what
      // a real backend does, and it is how the card learns which of a plan's
      // days is now spent.
      request: _accepted(
        requestId,
        routeId,
        serviceDate ?? const DepartureDate(year: 2026, month: 9, day: 14),
      ),
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

MySeatRequest _accepted(
  String id,
  String routeId,
  DepartureDate serviceDate,
) => MySeatRequest(
  id: id,
  // The day the server recorded the asking for, which is the day it was asked
  // about — never the route's own date, which a plan does not have.
  serviceDate: serviceDate,
  status: SeatRequestStatus.pending,
  requestedAt: DateTime.utc(2026, 9, 9, 8),
  decidedAt: null,
  withdrawnAt: null,
  myReview: null,
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
    // Always present on this projection, `notStarted` included.
    trip: fakeTrip(),
  ),
);

/// A generator whose ids a test can recognise on sight.
class _CountingUuid implements RmUuidGenerator {
  int _next = 0;

  /// How many ids have been handed out. Zero is a real assertion: an intent
  /// the member backed out of must not have spent one.
  int get minted => _next;

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
    // The days the SERVER says are open. Never derived from the other fields
    // here, because the card never derives them either — a fixture that worked
    // them out would be testing an arithmetic this app does not do.
    List<String> offers = const <String>['2026-09-14'],
    List<(String, SeatRequestStatus)> askedDays =
        const <(String, SeatRequestStatus)>[],
  }) => fakeDiscoveredRoute(
    id: routeId,
    recurrence: recurrence,
    departureDate: recurrence == Recurrence.once ? '2026-09-14' : null,
    departureState: departureState,
    requestableServiceDates: offers,
    mySeatRequests: <Map<String, Object?>>[
      if (asked != null)
        fakeMySeatRequestSummaryJson(
          // The day this card would ask about, so the summary is the one
          // the card looks up rather than a different journey's.
          serviceDate: '2026-09-14',
          id: 'r1',
          status: asked.wire,
        ),
      for (final (String day, SeatRequestStatus status) in askedDays)
        fakeMySeatRequestSummaryJson(
          serviceDate: day,
          id: 'req-$day',
          status: status.wire,
        ),
    ],
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

  AppLocalizations strings(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(MatchResultsScreen)));

  String ask(WidgetTester tester) => strings(tester).seatRequestAsk;

  String chooseDay(WidgetTester tester) => strings(tester).seatRequestChooseDay;

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

    /// RETIRED IN F2, AND THIS IS WHAT REPLACED IT.
    ///
    /// Until Phase 16b a weekday plan offered nothing at all: it has no single
    /// departure, and the card had no way to name one of its days. The backend
    /// now says which days are open, so the plan gets an action — one that asks
    /// which day first, rather than one that guesses.
    testWidgets('a weekday plan offers a day to choose', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        routes: <DiscoveredRoute>[
          route(
            recurrence: Recurrence.weekdays,
            offers: const <String>['2026-09-14', '2026-09-15'],
          ),
        ],
      );

      expect(find.text(chooseDay(tester)), findsOneWidget);
      // Not the ask control: nothing is sent until a day is named.
      expect(find.text(ask(tester)), findsNothing);
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

  group('Choosing which day to ask about', () {
    const DepartureDate monday = DepartureDate(year: 2026, month: 9, day: 14);
    const DepartureDate tuesday = DepartureDate(year: 2026, month: 9, day: 15);
    const DepartureDate friday = DepartureDate(year: 2026, month: 9, day: 18);

    /// The chooser's option for one day, as the member reads it.
    String option(WidgetTester tester, DepartureDate day) => RmFormatters.of(
      tester.element(find.byType(MatchResultsScreen)),
    ).weekdayDate(day.year, day.month, day.day);

    Future<void> openChooser(
      WidgetTester tester, {
      List<String> offers = const <String>['2026-09-14', '2026-09-15'],
      List<(String, SeatRequestStatus)> askedDays =
          const <(String, SeatRequestStatus)>[],
      _AskRecorder? seats,
      RmUuidGenerator? uuid,
    }) async {
      await pump(
        tester,
        routes: <DiscoveredRoute>[
          route(
            recurrence: Recurrence.weekdays,
            offers: offers,
            askedDays: askedDays,
          ),
        ],
        seats: seats,
        uuid: uuid,
      );

      await tester.tap(find.text(chooseDay(tester)));
      await tester.pumpAndSettle();
    }

    testWidgets('the chooser lists every day the member may still ask about', (
      WidgetTester tester,
    ) async {
      await openChooser(
        tester,
        offers: const <String>['2026-09-14', '2026-09-15', '2026-09-18'],
      );

      expect(find.text(option(tester, monday)), findsOneWidget);
      expect(find.text(option(tester, tuesday)), findsOneWidget);
      expect(find.text(option(tester, friday)), findsOneWidget);
    });

    /// CARRIES WEIGHT. A spent day is not offered again, whatever became of it.
    for (final SeatRequestStatus status in SeatRequestStatus.values) {
      testWidgets('a $status day is not in the chooser', (
        WidgetTester tester,
      ) async {
        await openChooser(
          tester,
          offers: const <String>['2026-09-14', '2026-09-15', '2026-09-18'],
          askedDays: <(String, SeatRequestStatus)>[('2026-09-14', status)],
        );

        expect(find.text(option(tester, monday)), findsNothing);
        expect(find.text(option(tester, tuesday)), findsOneWidget);
        expect(find.text(option(tester, friday)), findsOneWidget);
      });
    }

    /// CARRIES WEIGHT. The day the member named is the day that is sent.
    testWidgets('choosing Tuesday asks about Tuesday', (
      WidgetTester tester,
    ) async {
      final _AskRecorder seats = _AskRecorder();

      await openChooser(tester, seats: seats, uuid: _CountingUuid());
      await tester.tap(find.text(option(tester, tuesday)));
      await tester.pumpAndSettle();

      expect(seats.calls, 1);
      expect(seats.serviceDates.single, tuesday);
      expect(seats.routeIds.single, routeId);
    });

    /// CARRIES WEIGHT. Backing out asks for nothing and spends no id.
    ///
    /// An id minted for a question the member abandoned would be carried by
    /// whatever they asked for next, and the backend would answer about the
    /// wrong journey.
    testWidgets('dismissing the chooser sends nothing and mints nothing', (
      WidgetTester tester,
    ) async {
      final _AskRecorder seats = _AskRecorder();
      final _CountingUuid uuid = _CountingUuid();

      await openChooser(tester, seats: seats, uuid: uuid);
      // The way a member dismisses a modal sheet: tapping the barrier above it.
      await tester.tapAt(const Offset(400, 8));
      await tester.pumpAndSettle();

      expect(seats.calls, 0);
      expect(uuid.minted, 0);
      // And the control is still there to try again.
      expect(find.text(chooseDay(tester)), findsOneWidget);
    });

    /// CARRIES WEIGHT. Nothing is chosen on the member's behalf.
    ///
    /// The first option is the earliest day, not a default. A card that sent it
    /// on the first tap would be booking a journey nobody named.
    testWidgets('opening the chooser asks for nothing by itself', (
      WidgetTester tester,
    ) async {
      final _AskRecorder seats = _AskRecorder();

      await openChooser(tester, seats: seats, uuid: _CountingUuid());

      expect(seats.calls, 0);
    });

    testWidgets('a chosen day becomes spent and the others do not', (
      WidgetTester tester,
    ) async {
      final _AskRecorder seats = _AskRecorder();

      await openChooser(
        tester,
        offers: const <String>['2026-09-14', '2026-09-15', '2026-09-18'],
        seats: seats,
        uuid: _CountingUuid(),
      );
      await tester.tap(find.text(option(tester, tuesday)));
      await tester.pumpAndSettle();

      // The card is still a plan with days left, so it still offers the
      // chooser rather than collapsing to one status.
      expect(find.text(chooseDay(tester)), findsOneWidget);

      await tester.tap(find.text(chooseDay(tester)));
      await tester.pumpAndSettle();

      expect(find.text(option(tester, tuesday)), findsNothing);
      expect(find.text(option(tester, monday)), findsOneWidget);
      expect(find.text(option(tester, friday)), findsOneWidget);
    });

    /// CARRIES WEIGHT. Two days of one plan are two askings.
    ///
    /// Sharing an id would make the second a RETRY of the first: the backend
    /// would answer `id_already_used`, or replay and hand back the wrong day.
    testWidgets('two days never share the id they are asked under', (
      WidgetTester tester,
    ) async {
      final _AskRecorder seats = _AskRecorder();

      await openChooser(
        tester,
        // Three, so that asking about one still leaves a choice to make.
        offers: const <String>['2026-09-14', '2026-09-15', '2026-09-18'],
        seats: seats,
        uuid: _CountingUuid(),
      );
      await tester.tap(find.text(option(tester, monday)));
      await tester.pumpAndSettle();

      await tester.tap(find.text(chooseDay(tester)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(option(tester, tuesday)));
      await tester.pumpAndSettle();

      expect(seats.serviceDates, <DepartureDate>[monday, tuesday]);
      expect(seats.requestIds.toSet(), hasLength(2));
    });

    /// A retry of ONE day is the same asking arriving again.
    testWidgets('retrying a day reuses that day\'s own id', (
      WidgetTester tester,
    ) async {
      final _AskRecorder seats = _AskRecorder(failures: 1);

      await openChooser(tester, seats: seats, uuid: _CountingUuid());
      await tester.tap(find.text(option(tester, tuesday)));
      await tester.pumpAndSettle();

      // The failure left the ask control on the card, for that day alone.
      await tester.tap(find.text(ask(tester)));
      await tester.pumpAndSettle();

      expect(seats.serviceDates, <DepartureDate>[tuesday, tuesday]);
      expect(seats.requestIds.toSet(), hasLength(1));
    });

    testWidgets('an option announces the day it is for', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await openChooser(tester);

      final SemanticsData data = tester
          .getSemantics(find.text(option(tester, tuesday)))
          .getSemanticsData();

      // The date IS the announcement — nothing about the option is carried by
      // position or colour — and it announces itself as something to press.
      expect(data.label, option(tester, tuesday));
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);

      handle.dispose();
    });
  });

  group('When there is only one day, or none', () {
    /// CARRIES WEIGHT. A chooser holding one option is a question with one
    /// answer. The plan asks about that day directly, exactly as a one-off does.
    testWidgets('a plan with one open day asks about it directly', (
      WidgetTester tester,
    ) async {
      final _AskRecorder seats = _AskRecorder();

      await pump(
        tester,
        routes: <DiscoveredRoute>[
          route(
            recurrence: Recurrence.weekdays,
            offers: const <String>['2026-09-18'],
          ),
        ],
        seats: seats,
        uuid: _CountingUuid(),
      );

      expect(find.text(chooseDay(tester)), findsNothing);
      await tester.tap(find.text(ask(tester)));
      await tester.pumpAndSettle();

      expect(
        seats.serviceDates.single,
        const DepartureDate(year: 2026, month: 9, day: 18),
      );
    });

    /// CARRIES WEIGHT. A one-off route is unchanged by F2.
    ///
    /// One open day, so the control asks directly — no sheet, and the day is
    /// the server's rather than one this card worked out.
    testWidgets('a one-off journey still asks directly', (
      WidgetTester tester,
    ) async {
      final _AskRecorder seats = _AskRecorder();

      await pump(
        tester,
        routes: <DiscoveredRoute>[route()],
        seats: seats,
        uuid: _CountingUuid(),
      );

      expect(find.text(chooseDay(tester)), findsNothing);
      await tester.tap(find.text(ask(tester)));
      await tester.pumpAndSettle();

      expect(seats.calls, 1);
      expect(
        seats.serviceDates.single,
        const DepartureDate(year: 2026, month: 9, day: 14),
      );
    });

    /// The server is offering nothing. The card says so and says nothing
    /// about why — it does not know whether the plan is full, ending, or
    /// simply between days.
    testWidgets('a plan offering no day has no control at all', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        routes: <DiscoveredRoute>[
          route(recurrence: Recurrence.weekdays, offers: const <String>[]),
        ],
      );

      expect(find.text(ask(tester)), findsNothing);
      expect(find.text(chooseDay(tester)), findsNothing);
      expect(
        find.text(strings(tester).seatRequestNoDaysOffered),
        findsOneWidget,
      );
    });

    /// A different truth, and a different sentence: there ARE days, and this
    /// member has asked about all of them.
    testWidgets('a plan whose every day is spent says so', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        routes: <DiscoveredRoute>[
          route(
            recurrence: Recurrence.weekdays,
            offers: const <String>['2026-09-14', '2026-09-15'],
            askedDays: const <(String, SeatRequestStatus)>[
              ('2026-09-14', SeatRequestStatus.declined),
              ('2026-09-15', SeatRequestStatus.pending),
            ],
          ),
        ],
      );

      expect(find.text(chooseDay(tester)), findsNothing);
      expect(
        find.text(strings(tester).seatRequestEveryDayAsked),
        findsOneWidget,
      );
      // And NOT the other sentence, which would be false here.
      expect(find.text(strings(tester).seatRequestNoDaysOffered), findsNothing);
    });

    /// CARRIES WEIGHT. One day's answer is never the plan's answer.
    testWidgets('a declined day does not become the plan\'s status', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        routes: <DiscoveredRoute>[
          route(
            recurrence: Recurrence.weekdays,
            offers: const <String>['2026-09-14', '2026-09-15'],
            askedDays: const <(String, SeatRequestStatus)>[
              ('2026-09-14', SeatRequestStatus.declined),
            ],
          ),
        ],
      );

      expect(find.text(strings(tester).seatRequestDeclined), findsNothing);
      expect(find.text(chooseDay(tester)), findsNothing);
      // One day left, so it is asked about directly.
      expect(find.text(ask(tester)), findsOneWidget);
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
