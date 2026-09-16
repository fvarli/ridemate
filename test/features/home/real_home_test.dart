// ─────────────────────────────────────────────────────────────
// RideMate — Home tells the truth about this member and nobody else
//
// WHAT THIS FILE IS DEFENDING
//
// Home was the app's landing screen and its least truthful one: a map with
// driver pins, a greeting to somebody called Elif, saved addresses nobody had
// saved, and a 94% match with a rated, verified Selin K. at ₺18 a head. Six
// capabilities this product does not have, asserted about a person who does not
// exist, to a member who had just signed in.
//
// So the cases below are in two halves. One half proves the fabrications are
// gone and cannot come back. The other proves what replaced them is genuinely
// the server's answer — including the awkward parts: a journey started
// yesterday, a journey whose plan was cancelled, and an asking that was
// declined. Each of those is easy to "tidy away" into a cleaner-looking screen,
// and each of them is something the member is entitled to see.
//
// AND THAT THE THREE SECTIONS FAIL SEPARATELY
//
// They are three resources. A journeys outage that blanked out the askings
// would take away what did load in order to report what did not.
// ─────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ridemate/app/router/app_routes.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/format/rm_formatters.dart';
import 'package:ridemate/core/journeys/journey.dart';
import 'package:ridemate/core/places/place.dart';
import 'package:ridemate/core/profile/profile.dart';
import 'package:ridemate/core/routes/departure.dart';
import 'package:ridemate/core/routes/published_route.dart';
import 'package:ridemate/core/routes/ride_rule.dart';
import 'package:ridemate/core/seat_requests/seat_request.dart';
import 'package:ridemate/core/theme/rm_theme.dart';
import 'package:ridemate/core/trips/trip_lifecycle.dart';
import 'package:ridemate/features/home/presentation/home_screen.dart';
import 'package:ridemate/features/journeys/application/journeys_providers.dart';
import 'package:ridemate/features/profile/application/my_profile_providers.dart';
import 'package:ridemate/features/profile/data/profile_repository.dart';
import 'package:ridemate/features/seat_requests/application/seat_request_providers.dart';
import 'package:ridemate/features/seat_requests/data/seat_request_repository.dart';
import 'package:ridemate/l10n/app_localizations.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';

/// The passenger's own askings, as this screen reads them.
class _Requests implements SeatRequestRepository {
  _Requests({this.requests = const <MySeatRequest>[], this.failure});

  final List<MySeatRequest> requests;
  final RmFailure? failure;

  int reads = 0;

  @override
  Future<MySeatRequestsResult> mine({String? cursor, int limit = 20}) async {
    reads++;
    final RmFailure? thrown = failure;
    if (thrown != null) throw thrown;

    return MySeatRequestsResult(requests: requests, nextCursor: null);
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

MySeatRequest _request({
  String id = 'q1',
  String origin = 'Kadıköy',
  String destination = 'Levent',
  String serviceDate = '2026-09-24',
  SeatRequestStatus status = SeatRequestStatus.pending,
}) => MySeatRequest(
  id: id,
  serviceDate: DepartureDate(
    year: int.parse(serviceDate.substring(0, 4)),
    month: int.parse(serviceDate.substring(5, 7)),
    day: int.parse(serviceDate.substring(8, 10)),
  ),
  status: status,
  requestedAt: DateTime.utc(2026, 9, 9, 8),
  decidedAt: null,
  withdrawnAt: null,
  myReview: null,
  route: SeatRequestRoute(
    id: 'route-$id',
    origin: Place(id: 'p1', label: origin),
    destination: Place(id: 'p2', label: destination),
    recurrence: Recurrence.once,
    departureDate: const DepartureDate(year: 2026, month: 9, day: 24),
    departureTime: const DepartureTime(hour: 8, minute: 25),
    timezone: 'Europe/Istanbul',
    status: RouteStatus.published,
    departureState: DepartureState.upcoming,
    seatsOffered: 3,
    rules: const <RideRuleId>{},
    driver: const SeatRequestMember(displayName: 'İrem Yılmaz', initials: 'İY'),
    trip: fakeTrip(),
  ),
);

void main() {
  setUpAll(loadRideMateFonts);

  late List<String> pushed;

  /// Home inside a router, so navigation is asserted as navigation rather than
  /// as a callback that happens to fire.
  Future<void> pump(
    WidgetTester tester, {
    ProfileRepository? profile,
    List<Journey> journeys = const <Journey>[],
    RmFailure? journeysFailure,
    List<MySeatRequest> requests = const <MySeatRequest>[],
    RmFailure? requestsFailure,
    Size size = const Size(393, 852),
  }) async {
    pushed = <String>[];

    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Widget stub(String name) => Scaffold(body: Text('STUB:$name'));

    final GoRouter router = GoRouter(
      initialLocation: '/',
      observers: <NavigatorObserver>[_Recorder(pushed)],
      routes: <RouteBase>[
        GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
        GoRoute(
          path: '/search',
          name: AppRoutes.search,
          builder: (_, _) => stub(AppRoutes.search),
        ),
        GoRoute(
          path: '/me/routes',
          name: AppRoutes.myRoutes,
          builder: (_, _) => stub(AppRoutes.myRoutes),
        ),
        GoRoute(
          path: '/me/requests',
          name: AppRoutes.myRequests,
          builder: (_, _) => stub(AppRoutes.myRequests),
        ),
        GoRoute(
          path: '/me/routes/:routeId/journeys/:serviceDate',
          name: AppRoutes.journeyStatus,
          builder: (_, GoRouterState state) => stub(
            '${state.pathParameters['routeId']}@'
            '${state.pathParameters['serviceDate']}',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          profileRepositoryProvider.overrideWithValue(
            profile ?? FakeProfileRepository(),
          ),
          journeysRepositoryProvider.overrideWithValue(
            FakeJourneys(journeys: journeys, failure: journeysFailure),
          ),
          seatRequestRepositoryProvider.overrideWithValue(
            _Requests(requests: requests, failure: requestsFailure),
          ),
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
  }

  AppLocalizations strings(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(HomeScreen)));

  String dayLabel(WidgetTester tester, String iso) =>
      RmFormatters.of(tester.element(find.byType(HomeScreen))).weekdayDate(
        int.parse(iso.substring(0, 4)),
        int.parse(iso.substring(5, 7)),
        int.parse(iso.substring(8, 10)),
      );

  // ------------------------------------------------ the fabrications are gone

  group('Nothing on Home is invented', () {
    /// CARRIES WEIGHT. Every claim the old Home made, refused by name.
    testWidgets('no fabricated member, figure or place is rendered', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        journeys: <Journey>[fakeJourney()],
        requests: <MySeatRequest>[_request()],
      );

      for (final String forbidden in <String>[
        // The person.
        'Selin', 'SK', 'Elif',
        // The figures none of which any endpoint knows.
        '4.9', '94', '%', '₺', '18',
        // The places nobody saved.
        'Kadıköy · Levent', 'İş ·', 'Üniversite',
        // The capabilities.
        'Doğrulanmış', 'uyum', 'puan',
      ]) {
        expect(find.textContaining(forbidden), findsNothing, reason: forbidden);
      }
    });

    /// The map went with them. It was documented as decorative, but a map with
    /// pins reads as positions, and this product knows nobody's position.
    testWidgets('no map is drawn', (WidgetTester tester) async {
      await pump(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      // The map widget is not built, and its source is not even imported —
      // pinned structurally below as well.
      expect(
        find.byWidgetPredicate(
          (Widget w) => w.runtimeType.toString().contains('HomeMap'),
        ),
        findsNothing,
      );
    });
  });

  // ------------------------------------------------------- the real greeting

  group('The greeting is this member', () {
    testWidgets('renders the name the server returned', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        profile: FakeProfileRepository(
          profile: const Profile(displayName: 'Zeynep Kaya', initials: 'ZK'),
        ),
      );

      expect(find.textContaining('Zeynep Kaya'), findsOneWidget);
    });

    /// CARRIES WEIGHT. A failed profile read never produces a name.
    ///
    /// The old Home greeted Elif whoever was signed in. A greeting that falls
    /// back to a remembered or default name would be the same defect with a
    /// smaller blast radius.
    testWidgets('a failed profile leaves the greeting nameless', (
      WidgetTester tester,
    ) async {
      await pump(tester, profile: FakeProfileRepository.offline());

      expect(find.text(strings(tester).homeGreeting), findsOneWidget);
      expect(find.textContaining('Ayşe'), findsNothing);
    });

    /// And a profile outage does not take the rest of Home with it.
    testWidgets('the other sections survive a failed profile', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        profile: FakeProfileRepository.offline(),
        journeys: <Journey>[fakeJourney(originLabel: 'Üsküdar')],
      );

      expect(find.textContaining('Üsküdar'), findsOneWidget);
    });
  });

  // ------------------------------------------------------------ the journeys

  group('Your driving shows the feed, and only the feed', () {
    testWidgets('empty says so without a reason', (WidgetTester tester) async {
      await pump(tester);

      expect(find.text(strings(tester).journeysEmpty), findsOneWidget);
    });

    testWidgets('rows keep the order the server sent them', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        journeys: <Journey>[
          fakeJourney(serviceDate: '2026-09-15', originLabel: 'Bir'),
          fakeJourney(serviceDate: '2026-09-18', originLabel: 'İki'),
        ],
      );

      final int first = tester
          .getTopLeft(find.textContaining('Bir'))
          .dy
          .round();
      final int second = tester
          .getTopLeft(find.textContaining('İki'))
          .dy
          .round();

      expect(first, lessThan(second), reason: 'the preview sorted');
    });

    /// CARRIES WEIGHT. A journey under way survives its own day.
    ///
    /// `/me/journeys` keeps it deliberately. A Home that filtered by "is this
    /// today" would hide the one journey its driver still has to close — and
    /// would do it at one minute past midnight.
    testWidgets('an in-progress journey from an earlier day is shown', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        journeys: <Journey>[
          fakeJourney(
            serviceDate: '2020-01-01',
            trip: TripState.inProgress,
            startedAt: '2020-01-01T05:05:00Z',
          ),
        ],
      );

      expect(
        find.textContaining(dayLabel(tester, '2020-01-01')),
        findsOneWidget,
      );
    });

    /// And its plan being cancelled does not hide it either.
    testWidgets('an in-progress journey of a cancelled plan is shown', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        journeys: <Journey>[
          fakeJourney(
            routeStatus: 'cancelled',
            trip: TripState.inProgress,
            startedAt: '2026-09-16T05:05:00Z',
          ),
        ],
      );

      expect(find.textContaining('Kadıköy'), findsOneWidget);
    });

    /// Two days of one plan stay two rows.
    testWidgets('two dates of one route are distinct rows', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        journeys: <Journey>[
          fakeJourney(serviceDate: '2026-09-16'),
          fakeJourney(serviceDate: '2026-09-15'),
        ],
      );

      expect(
        find.textContaining(dayLabel(tester, '2026-09-16')),
        findsOneWidget,
      );
      expect(
        find.textContaining(dayLabel(tester, '2026-09-15')),
        findsOneWidget,
      );
    });

    /// CARRIES WEIGHT. A preview is a prefix, never a summary.
    ///
    /// No total, no "and 4 more": the page this read returns is not the whole
    /// collection, so any count would be a number about a list nobody has.
    testWidgets('a long feed shows a prefix and states no total', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        journeys: <Journey>[
          for (int i = 1; i <= 6; i++) fakeJourney(serviceDate: '2026-09-0$i'),
        ],
      );

      expect(
        find.textContaining(dayLabel(tester, '2026-09-01')),
        findsOneWidget,
      );
      expect(find.textContaining(dayLabel(tester, '2026-09-06')), findsNothing);
      for (final String total in <String>['6', '+3', '4 ']) {
        expect(find.textContaining(total), findsNothing, reason: total);
      }
    });

    testWidgets('a failure says so and offers a retry', (
      WidgetTester tester,
    ) async {
      await pump(tester, journeysFailure: const RmFailure.transport());

      expect(find.text(strings(tester).commonRetry), findsOneWidget);
      expect(find.text(strings(tester).journeysEmpty), findsNothing);
    });
  });

  // ------------------------------------------------------------ the requests

  group('Your requests shows what the server calls them', () {
    testWidgets('empty says so', (WidgetTester tester) async {
      await pump(tester);

      expect(find.text(strings(tester).myRequestsEmpty), findsOneWidget);
    });

    /// CARRIES WEIGHT. Every status, including the ones that ended.
    ///
    /// Accepted is a driver's answer, not a seat held — and declined and
    /// withdrawn are not hidden to make the screen look tidier.
    testWidgets('each status is rendered as itself', (
      WidgetTester tester,
    ) async {
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
        await pump(tester, requests: <MySeatRequest>[_request(status: status)]);

        expect(
          find.text(copy(strings(tester))),
          findsOneWidget,
          reason: status.name,
        );
        // And never upgraded into a journey that is going to happen.
        for (final String invented in <String>[
          'Onaylandı ✓',
          'Rezerve',
          'Yolculuk yakında',
        ]) {
          expect(find.textContaining(invented), findsNothing);
        }
      }
    });

    testWidgets('rows keep the order the server sent them', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        requests: <MySeatRequest>[
          _request(id: 'a', origin: 'Bir'),
          _request(id: 'b', origin: 'İki'),
        ],
      );

      expect(
        tester.getTopLeft(find.textContaining('Bir')).dy,
        lessThan(tester.getTopLeft(find.textContaining('İki')).dy),
      );
    });

    /// Minimum projection: Home names the journey, not the driver.
    testWidgets('no other member is named', (WidgetTester tester) async {
      await pump(tester, requests: <MySeatRequest>[_request()]);

      expect(find.textContaining('İrem'), findsNothing);
      expect(find.textContaining('İY'), findsNothing);
    });
  });

  // --------------------------------------------------- independence and nav

  group('One section failing does not erase the others', () {
    testWidgets('journeys fail, requests still render', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        journeysFailure: const RmFailure.transport(),
        requests: <MySeatRequest>[_request(origin: 'Üsküdar')],
      );

      expect(find.textContaining('Üsküdar'), findsOneWidget);
    });

    testWidgets('requests fail, journeys still render', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        journeys: <Journey>[fakeJourney(originLabel: 'Beşiktaş')],
        requestsFailure: const RmFailure.transport(),
      );

      expect(find.textContaining('Beşiktaş'), findsOneWidget);
    });
  });

  group('Home goes where it says', () {
    testWidgets('the primary action opens Search', (WidgetTester tester) async {
      await pump(tester);

      await tester.tap(find.text(strings(tester).homeFindRide));
      await tester.pumpAndSettle();

      expect(find.text('STUB:${AppRoutes.search}'), findsOneWidget);
    });

    /// CARRIES WEIGHT. A journey is opened by its own identity.
    testWidgets('a journey opens its exact route AND day', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        journeys: <Journey>[
          fakeJourney(routeId: 'r-1', serviceDate: '2026-09-16'),
          fakeJourney(routeId: 'r-1', serviceDate: '2026-09-15'),
        ],
      );

      // The SECOND row: opening the first would pass a screen that always
      // opened "the next journey".
      await tester.tap(find.textContaining(dayLabel(tester, '2026-09-15')));
      await tester.pumpAndSettle();

      expect(find.text('STUB:r-1@2026-09-15'), findsOneWidget);
    });

    testWidgets('manage opens the real My Routes and My Requests', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text(strings(tester).myRoutesTitle));
      await tester.pumpAndSettle();
      expect(find.text('STUB:${AppRoutes.myRoutes}'), findsOneWidget);
    });

    testWidgets('see all opens My Requests', (WidgetTester tester) async {
      await pump(tester, requests: <MySeatRequest>[_request()]);

      await tester.tap(find.text(strings(tester).homeSeeAll));
      await tester.pumpAndSettle();
      expect(find.text('STUB:${AppRoutes.myRequests}'), findsOneWidget);
    });
  });

  // ------------------------------------------------------------- structural

  group('Home depends on nothing fabricated', () {
    String code(String path) => File(path)
        .readAsLinesSync()
        .where((String l) => !l.trimLeft().startsWith('//'))
        .join('\n');

    Iterable<File> homeFiles() => Directory('lib/features/home')
        .listSync(recursive: true)
        .whereType<File>()
        .where((File f) => f.path.endsWith('.dart'));

    /// CARRIES WEIGHT. The fixture Home is not imported by the real one.
    ///
    /// The files still exist — R3 decides their fate — so the guard is about
    /// what the screen DEPENDS on, not about what is on disk.
    test('the real Home imports no fixture', () {
      final String home = code(
        'lib/features/home/presentation/home_screen.dart',
      );

      for (final String banned in <String>[
        'home_providers',
        'home_snapshot',
        'HomeSnapshot',
        'NearbyMatch',
        'home_map',
        'HomeMap',
        'nearby_match_sheet',
        'mock_discovery_fixtures',
        'MockRouteOffers',
        'chat_fixtures',
        'mock_places',
      ]) {
        expect(home.contains(banned), isFalse, reason: banned);
      }
    });

    test('home navigates to no fixture screen', () {
      for (final File file in homeFiles()) {
        final String source = code(file.path);
        expect(
          source.contains('AppRoutes.routeDetails'),
          isFalse,
          reason: file.path,
        );
        expect(source.contains('AppRoutes.chat'), isFalse, reason: file.path);
        expect(
          source.contains('AppRoutes.activeTrip'),
          isFalse,
          reason: file.path,
        );
      }
    });

    /// CARRIES WEIGHT. No unsupported capability re-entered through Home.
    test('the real Home models nothing this product does not have', () {
      final String home = code(
        'lib/features/home/presentation/home_screen.dart',
      );

      for (final String banned in <String>[
        'rating',
        'Rating',
        'isVerified',
        'RmVerification',
        'compatibility',
        'costShare',
        'money(',
        'Geolocator',
        'Position',
        'LatLng',
        'GoogleMap',
        'MapboxMap',
        'timezone',
        // And the client-side temporal authority Phase 16b removed.
        'DateTime.now',
        'toLocal',
        'isBefore',
        'isAfter',
        'addDays',
      ]) {
        expect(home.contains(banned), isFalse, reason: banned);
      }
    });

    /// No fourth request appeared to fill the screen.
    test('home does not read my routes', () {
      final String home = code(
        'lib/features/home/presentation/home_screen.dart',
      );

      expect(home.contains('myRoutesProvider'), isFalse);
      expect(home.contains('MyRoutesRepository'), isFalse);
      // But it still links there.
      expect(home.contains('AppRoutes.myRoutes'), isTrue);
    });

    /// And no Home repository was invented to aggregate the three reads.
    test('no home repository or api client exists', () {
      for (final File file in homeFiles()) {
        for (final String banned in <String>[
          'HomeRepository',
          'RmApiClient',
          'ApiHomeRepository',
        ]) {
          expect(code(file.path).contains(banned), isFalse, reason: file.path);
        }
      }
    });
  });
}

/// Records the named routes a test pushed.
class _Recorder extends NavigatorObserver {
  _Recorder(this.pushed);

  final List<String> pushed;

  @override
  void didPush(Route<Object?> route, Route<Object?>? previous) {
    final String? name = route.settings.name;
    if (name != null) pushed.add(name);
  }
}
