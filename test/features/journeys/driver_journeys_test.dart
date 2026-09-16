// ─────────────────────────────────────────────────────────────
// RideMate — A driver reaching, and moving, one dated journey
//
// THE DISTINCTION THIS FILE EXISTS FOR
//
// `MyRoute.trip == null` and `Journey.trip == notStarted` are different facts,
// and the first is the one that keeps getting read as the second. Null means
// the question does not apply — a plan has no single journey — and
// `not_started` means a concrete morning has not been begun. A screen that
// conflates them offers Start on a plan, which the server refuses, or hides it
// on a journey it would have taken.
//
// AND THE OTHER WAY A DAY GETS LOST
//
// A journey that is under way stays reachable after its own day has passed, and
// after its plan has been cancelled. The backend keeps both on purpose: a
// driver mid-journey at one minute past midnight must still be able to close
// it. A client that filtered by "is this today" or "is the plan still live"
// would strand them, and would do it silently.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ridemate/core/api/rm_error_code.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/format/rm_formatters.dart';
import 'package:ridemate/core/journeys/journey.dart';
import 'package:ridemate/core/routes/departure.dart';
import 'package:ridemate/core/routes/my_route.dart';
import 'package:ridemate/core/theme/rm_theme.dart';
import 'package:ridemate/core/trips/trip_lifecycle.dart';
import 'package:ridemate/core/trips/trip_state_copy.dart';
import 'package:ridemate/features/journeys/application/journeys_providers.dart';
import 'package:ridemate/features/journeys/data/journeys_repository.dart';
import 'package:ridemate/features/journeys/presentation/journey_status_screen.dart';
import 'package:ridemate/features/journeys/presentation/widgets/journey_card.dart';
import 'package:ridemate/features/journeys/presentation/widgets/journeys_section.dart';
import 'package:ridemate/features/my_routes/application/my_routes_providers.dart';
import 'package:ridemate/features/my_routes/data/my_routes_repository.dart';
import 'package:ridemate/features/my_routes/presentation/my_routes_screen.dart';
import 'package:ridemate/l10n/app_localizations.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';

/// A journeys backend a test can steer, recording exactly what it was asked.
class _FakeJourneys implements JourneysRepository {
  _FakeJourneys({this.feed = const <Journey>[], this.detail});

  List<Journey> feed;

  /// What the dated read answers with. Null means "build one for whatever day
  /// was asked about", which is what a well-behaved server does.
  Journey? detail;

  final List<({String verb, String routeId, DepartureDate serviceDate})> calls =
      <({String verb, String routeId, DepartureDate serviceDate})>[];

  RmFailure? refuseCommandsWith;

  @override
  Future<MyJourneysResult> page({String? cursor, int limit = 20}) async =>
      MyJourneysResult(journeys: feed, nextCursor: null);

  @override
  Future<Journey> journey({
    required String routeId,
    required DepartureDate serviceDate,
  }) async {
    calls.add((verb: 'read', routeId: routeId, serviceDate: serviceDate));

    return detail ??
        fakeJourney(routeId: routeId, serviceDate: serviceDate.iso);
  }

  @override
  Future<TripLifecycle> startTrip({
    required String routeId,
    required DepartureDate serviceDate,
  }) => _command('start', routeId, serviceDate, TripState.inProgress);

  @override
  Future<TripLifecycle> completeTrip({
    required String routeId,
    required DepartureDate serviceDate,
  }) => _command('complete', routeId, serviceDate, TripState.completed);

  @override
  Future<TripLifecycle> abortTrip({
    required String routeId,
    required DepartureDate serviceDate,
  }) => _command('abort', routeId, serviceDate, TripState.aborted);

  Future<TripLifecycle> _command(
    String verb,
    String routeId,
    DepartureDate serviceDate,
    TripState reached,
  ) async {
    calls.add((verb: verb, routeId: routeId, serviceDate: serviceDate));

    final RmFailure? refusal = refuseCommandsWith;
    if (refusal != null) throw refusal;

    return fakeTrip(state: reached, startedAt: '2026-09-16T05:05:00Z');
  }
}

void main() {
  setUpAll(loadRideMateFonts);

  const String routeId = '01991b00-0000-7000-8000-0000000000a1';

  Widget app(Widget home, {List<Override> overrides = const <Override>[]}) =>
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: RmTheme.of(Brightness.light),
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      );

  AppLocalizations strings(WidgetTester tester, Type of) =>
      AppLocalizations.of(tester.element(find.byType(of)));

  String dayLabel(WidgetTester tester, Type of, String iso) {
    final DepartureDate day = DepartureDate(
      year: int.parse(iso.substring(0, 4)),
      month: int.parse(iso.substring(5, 7)),
      day: int.parse(iso.substring(8, 10)),
    );

    return RmFormatters.of(
      tester.element(find.byType(of)),
    ).weekdayDate(day.year, day.month, day.day);
  }

  group('The journeys section on My Routes', () {
    Future<_FakeJourneys> pumpMyRoutes(
      WidgetTester tester, {
      required List<Journey> feed,
      List<MyRoute> routes = const <MyRoute>[],
    }) async {
      final _FakeJourneys journeys = _FakeJourneys(feed: feed);

      await tester.pumpWidget(
        app(
          const MyRoutesScreen(),
          overrides: <Override>[
            journeysRepositoryProvider.overrideWithValue(journeys),
            myRoutesRepositoryProvider.overrideWithValue(
              FakeMyRoutesRepository(
                pages: <MyRoutesResult>[
                  MyRoutesResult(routes: routes, nextCursor: null),
                ],
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      return journeys;
    }

    testWidgets('a plan with no journey today says so and offers nothing', (
      WidgetTester tester,
    ) async {
      await pumpMyRoutes(tester, feed: const <Journey>[]);

      expect(
        find.text(strings(tester, MyRoutesScreen).journeysEmpty),
        findsOneWidget,
      );
      expect(find.byType(JourneyCard), findsNothing);
    });

    /// CARRIES WEIGHT. A plan's own card still has no lifecycle.
    ///
    /// `MyRoute.trip` is null for a recurring plan and means the question does
    /// not apply. It must not become `not_started`: the card would then offer
    /// Start on a plan, which the server refuses because a plan has no single
    /// journey to begin.
    testWidgets('a recurring plan is never shown as a journey not started', (
      WidgetTester tester,
    ) async {
      await pumpMyRoutes(
        tester,
        feed: const <Journey>[],
        routes: <MyRoute>[
          fakeMyRoute(recurrence: Recurrence.weekdays, trip: null),
        ],
      );

      final AppLocalizations l10n = strings(tester, MyRoutesScreen);

      // Neither the state nor the control a journey would carry.
      expect(find.text(l10n.myRoutesStartTrip), findsNothing);
      expect(find.text(l10n.tripStateNotStarted), findsNothing);
    });

    /// And the same day, on the journeys feed, DOES say not started — because
    /// there the question applies.
    testWidgets('a dated journey with no trip says not started', (
      WidgetTester tester,
    ) async {
      await pumpMyRoutes(
        tester,
        feed: <Journey>[fakeJourney(serviceDate: '2026-09-16')],
        routes: <MyRoute>[
          fakeMyRoute(recurrence: Recurrence.weekdays, trip: null),
        ],
      );

      expect(
        find.text(strings(tester, MyRoutesScreen).tripStateNotStarted),
        findsOneWidget,
      );
    });

    /// CARRIES WEIGHT. A journey under way survives its own day.
    ///
    /// The feed deliberately keeps it, whatever its date. A client that hid it
    /// because the day looks past would strand a driver at one minute past
    /// midnight with a trip they cannot close.
    testWidgets('an in-progress journey from an earlier day is still shown', (
      WidgetTester tester,
    ) async {
      await pumpMyRoutes(
        tester,
        feed: <Journey>[
          fakeJourney(
            serviceDate: '2020-01-01',
            trip: TripState.inProgress,
            startedAt: '2020-01-01T05:05:00Z',
          ),
        ],
      );

      expect(find.byType(JourneyCard), findsOneWidget);
      expect(
        find.textContaining(dayLabel(tester, MyRoutesScreen, '2020-01-01')),
        findsOneWidget,
      );
    });

    /// And survives its plan being cancelled.
    testWidgets('an in-progress journey of a cancelled plan is still shown', (
      WidgetTester tester,
    ) async {
      await pumpMyRoutes(
        tester,
        feed: <Journey>[
          fakeJourney(
            routeStatus: 'cancelled',
            trip: TripState.inProgress,
            startedAt: '2026-09-16T05:05:00Z',
          ),
        ],
      );

      expect(find.byType(JourneyCard), findsOneWidget);
    });

    /// CARRIES WEIGHT. Several days of one plan stay several rows.
    testWidgets('two journeys of one route are two separate rows', (
      WidgetTester tester,
    ) async {
      await pumpMyRoutes(
        tester,
        feed: <Journey>[
          fakeJourney(serviceDate: '2026-09-16'),
          fakeJourney(serviceDate: '2026-09-15'),
        ],
      );

      expect(find.byType(JourneyCard), findsNWidgets(2));
      expect(
        find.textContaining(dayLabel(tester, MyRoutesScreen, '2026-09-16')),
        findsOneWidget,
      );
      expect(
        find.textContaining(dayLabel(tester, MyRoutesScreen, '2026-09-15')),
        findsOneWidget,
      );
    });

    testWidgets('the rows keep the order the server sent them', (
      WidgetTester tester,
    ) async {
      await pumpMyRoutes(
        tester,
        feed: <Journey>[
          fakeJourney(serviceDate: '2026-09-15'),
          fakeJourney(serviceDate: '2026-09-16'),
        ],
      );

      final List<String> shown = tester
          .widgetList<JourneyCard>(find.byType(JourneyCard))
          .map((JourneyCard card) => card.journey.serviceDate.iso)
          .toList();

      expect(shown, <String>['2026-09-15', '2026-09-16'], reason: 'sorted');
    });

    testWidgets('a row announces its own day', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpMyRoutes(
        tester,
        feed: <Journey>[fakeJourney(serviceDate: '2026-09-16')],
      );

      final String day = dayLabel(tester, MyRoutesScreen, '2026-09-16');

      expect(
        tester.getSemantics(find.byType(JourneyCard)).label,
        contains(day),
      );

      handle.dispose();
    });
  });

  group('One journey, opened by its own identity', () {
    Future<_FakeJourneys> pumpJourney(
      WidgetTester tester, {
      String serviceDate = '2026-09-16',
      Journey? detail,
      RmFailure? refuse,
    }) async {
      final _FakeJourneys journeys = _FakeJourneys(detail: detail)
        ..refuseCommandsWith = refuse;

      await tester.pumpWidget(
        app(
          JourneyStatusScreen(routeId: routeId, serviceDate: serviceDate),
          overrides: <Override>[
            journeysRepositoryProvider.overrideWithValue(journeys),
          ],
        ),
      );
      await tester.pumpAndSettle();

      return journeys;
    }

    /// CARRIES WEIGHT. The screen asks about the day it was opened with.
    testWidgets('the exact day is read, not today and not the first', (
      WidgetTester tester,
    ) async {
      final _FakeJourneys journeys = await pumpJourney(
        tester,
        serviceDate: '2026-09-15',
      );

      expect(journeys.calls.single.verb, 'read');
      expect(journeys.calls.single.routeId, routeId);
      expect(
        journeys.calls.single.serviceDate,
        const DepartureDate(year: 2026, month: 9, day: 15),
      );
    });

    testWidgets('the day is shown as well as read', (
      WidgetTester tester,
    ) async {
      await pumpJourney(tester, serviceDate: '2026-09-15');

      expect(
        find.text(dayLabel(tester, JourneyStatusScreen, '2026-09-15')),
        findsOneWidget,
      );
    });

    /// A path that does not name a real day asks the server nothing.
    for (final String bad in <String>[
      '2026-02-30',
      '16-09-2026',
      '2026-9-16',
      'today',
      '',
    ]) {
      testWidgets('`$bad` is refused without a request', (
        WidgetTester tester,
      ) async {
        final _FakeJourneys journeys = await pumpJourney(
          tester,
          serviceDate: bad,
        );

        expect(journeys.calls, isEmpty);
        expect(
          find.text(strings(tester, JourneyStatusScreen).journeyNotFound),
          findsOneWidget,
        );
      });
    }

    for (final (String verb, TripState from, TripState to)
        in <(String, TripState, TripState)>[
          ('start', TripState.notStarted, TripState.inProgress),
          ('complete', TripState.inProgress, TripState.completed),
          ('abort', TripState.inProgress, TripState.aborted),
        ]) {
      testWidgets('$verb names the day and shows what came back', (
        WidgetTester tester,
      ) async {
        final _FakeJourneys journeys = await pumpJourney(
          tester,
          serviceDate: '2026-09-15',
          detail: fakeJourney(
            serviceDate: '2026-09-15',
            trip: from,
            startedAt: from == TripState.inProgress
                ? '2026-09-15T05:05:00Z'
                : null,
          ),
        );

        final AppLocalizations l10n = strings(tester, JourneyStatusScreen);
        final String label = switch (verb) {
          'start' => l10n.myRoutesStartTrip,
          'complete' => l10n.myRoutesCompleteTrip,
          _ => l10n.myRoutesAbortTrip,
        };

        await tester.tap(find.text(label));
        await tester.pumpAndSettle();

        expect(journeys.calls.last.verb, verb);
        expect(
          journeys.calls.last.serviceDate,
          const DepartureDate(year: 2026, month: 9, day: 15),
        );
        expect(find.text(tripStateLabel(l10n, to)), findsOneWidget);
      });
    }

    /// CARRIES WEIGHT. A journey under way is endable whatever its day says.
    testWidgets('a journey from an earlier day can still be ended', (
      WidgetTester tester,
    ) async {
      await pumpJourney(
        tester,
        serviceDate: '2020-01-01',
        detail: fakeJourney(
          serviceDate: '2020-01-01',
          trip: TripState.inProgress,
          startedAt: '2020-01-01T05:05:00Z',
        ),
      );

      final AppLocalizations l10n = strings(tester, JourneyStatusScreen);
      expect(find.text(l10n.myRoutesCompleteTrip), findsOneWidget);
      expect(find.text(l10n.myRoutesAbortTrip), findsOneWidget);
    });

    /// And whatever became of its plan.
    testWidgets('a journey of a cancelled plan can still be ended', (
      WidgetTester tester,
    ) async {
      await pumpJourney(
        tester,
        detail: fakeJourney(
          routeStatus: 'cancelled',
          trip: TripState.inProgress,
          startedAt: '2026-09-16T05:05:00Z',
        ),
      );

      expect(
        find.text(strings(tester, JourneyStatusScreen).myRoutesCompleteTrip),
        findsOneWidget,
      );
    });

    testWidgets('a journey not started offers no ending', (
      WidgetTester tester,
    ) async {
      await pumpJourney(tester);

      final AppLocalizations l10n = strings(tester, JourneyStatusScreen);
      expect(find.text(l10n.myRoutesStartTrip), findsOneWidget);
      expect(find.text(l10n.myRoutesCompleteTrip), findsNothing);
    });

    testWidgets('a finished journey offers nothing at all', (
      WidgetTester tester,
    ) async {
      await pumpJourney(tester, detail: fakeJourney(trip: TripState.completed));

      final AppLocalizations l10n = strings(tester, JourneyStatusScreen);
      expect(find.text(l10n.myRoutesStartTrip), findsNothing);
      expect(find.text(l10n.myRoutesCompleteTrip), findsNothing);
      expect(find.text(l10n.myRoutesAbortTrip), findsNothing);
    });
  });

  group('What a refusal says', () {
    Future<void> pumpRefusing(
      WidgetTester tester,
      String reason, {
      TripState from = TripState.notStarted,
    }) async {
      final _FakeJourneys journeys =
          _FakeJourneys(
              detail: fakeJourney(
                trip: from,
                startedAt: from == TripState.inProgress
                    ? '2026-09-16T05:05:00Z'
                    : null,
              ),
            )
            ..refuseCommandsWith = RmFailure.fromBackend(
              status: 409,
              code: RmErrorCode.conflict,
              reason: reason,
            );

      await tester.pumpWidget(
        app(
          const JourneyStatusScreen(
            routeId: routeId,
            serviceDate: '2026-09-16',
          ),
          overrides: <Override>[
            journeysRepositoryProvider.overrideWithValue(journeys),
          ],
        ),
      );
      await tester.pumpAndSettle();
    }

    for (final (String reason, String Function(AppLocalizations) copy)
        in <(String, String Function(AppLocalizations))>[
          (
            'departure_not_reached',
            (AppLocalizations l) => l.myRoutesStartDepartureNotReached,
          ),
          (
            'service_date_passed',
            (AppLocalizations l) => l.myRoutesStartServiceDatePassed,
          ),
          (
            'route_unavailable',
            (AppLocalizations l) => l.myRoutesStartRouteUnavailable,
          ),
          (
            'recurring_route_unsupported',
            (AppLocalizations l) => l.myRoutesStartRecurringUnsupported,
          ),
        ]) {
      testWidgets('a start refused with $reason says so', (
        WidgetTester tester,
      ) async {
        await pumpRefusing(tester, reason);

        final AppLocalizations l10n = strings(tester, JourneyStatusScreen);
        await tester.tap(find.text(l10n.myRoutesStartTrip));
        await tester.pumpAndSettle();

        expect(find.text(copy(l10n)), findsOneWidget);
        // And the journey is exactly as it was: a journey the backend would
        // not start is not a journey that started.
        expect(
          find.text(tripStateLabel(l10n, TripState.notStarted)),
          findsOneWidget,
        );
      });
    }

    for (final (String reason, String Function(AppLocalizations) copy)
        in <(String, String Function(AppLocalizations))>[
          (
            'already_completed',
            (AppLocalizations l) => l.myRoutesTripAlreadyCompleted,
          ),
          (
            'already_aborted',
            (AppLocalizations l) => l.myRoutesTripAlreadyAborted,
          ),
        ]) {
      testWidgets('an ending refused with $reason says so', (
        WidgetTester tester,
      ) async {
        await pumpRefusing(tester, reason, from: TripState.inProgress);

        final AppLocalizations l10n = strings(tester, JourneyStatusScreen);
        await tester.tap(find.text(l10n.myRoutesCompleteTrip));
        await tester.pumpAndSettle();

        expect(find.text(copy(l10n)), findsOneWidget);
      });
    }

    testWidgets('an ending refused with trip_not_started says so', (
      WidgetTester tester,
    ) async {
      await pumpRefusing(
        tester,
        'trip_not_started',
        from: TripState.inProgress,
      );

      final AppLocalizations l10n = strings(tester, JourneyStatusScreen);
      await tester.tap(find.text(l10n.myRoutesAbortTrip));
      await tester.pumpAndSettle();

      expect(find.text(l10n.myRoutesTripNotStarted), findsOneWidget);
    });

    /// A reason this build has never heard of is not guessed at.
    testWidgets('an unknown reason falls back to the generic message', (
      WidgetTester tester,
    ) async {
      await pumpRefusing(tester, 'some_future_reason');

      final AppLocalizations l10n = strings(tester, JourneyStatusScreen);
      await tester.tap(find.text(l10n.myRoutesStartTrip));
      await tester.pumpAndSettle();

      expect(find.text(l10n.myRoutesStartDepartureNotReached), findsNothing);
      expect(find.text(l10n.myRoutesStartServiceDatePassed), findsNothing);
    });
  });

  group('The section reaches the journey', () {
    testWidgets('tapping a row opens that day, and no other', (
      WidgetTester tester,
    ) async {
      final _FakeJourneys journeys = _FakeJourneys(
        feed: <Journey>[
          fakeJourney(serviceDate: '2026-09-16'),
          fakeJourney(serviceDate: '2026-09-15'),
        ],
      );

      final GoRouter router = GoRouter(
        initialLocation: '/',
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: JourneysSection()),
          ),
          GoRoute(
            path: '/me/routes/:routeId/journeys/:serviceDate',
            name: 'journeyStatus',
            builder: (_, GoRouterState state) => JourneyStatusScreen(
              routeId: state.pathParameters['routeId'] ?? '',
              serviceDate: state.pathParameters['serviceDate'] ?? '',
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            journeysRepositoryProvider.overrideWithValue(journeys),
          ],
          child: MaterialApp.router(
            theme: RmTheme.of(Brightness.light),
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The SECOND row: picking the first would pass whatever a screen that
      // always opened "the first journey" did.
      await tester.tap(find.byType(JourneyCard).last);
      await tester.pumpAndSettle();

      expect(find.byType(JourneyStatusScreen), findsOneWidget);
      expect(
        journeys.calls.last.serviceDate,
        const DepartureDate(year: 2026, month: 9, day: 15),
      );
    });
  });
}
