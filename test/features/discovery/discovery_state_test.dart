// ─────────────────────────────────────────────────────────────
// RideMate — Discovery state
//
// The distinction this file exists for: NOBODY HAS SEARCHED is not the same as
// FOUND NOTHING. One is the app before a question was asked; the other is the
// server's answer. Collapsing them would tell a member there are no journeys
// between two places they never named.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/api/rm_error_code.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/places/place.dart';
import 'package:ridemate/core/routes/departure.dart';
import 'package:ridemate/core/routes/discovered_route.dart';
import 'package:ridemate/core/routes/published_route.dart';
import 'package:ridemate/core/routes/ride_rule.dart';
import 'package:ridemate/features/discovery/application/discovery_search_providers.dart';
import 'package:ridemate/features/discovery/data/discovery_repository.dart';

DiscoveredRoute _route(String id) => DiscoveredRoute(
  id: id,
  origin: const Place(id: 'p1', label: 'Kadıköy'),
  destination: const Place(id: 'p2', label: 'Levent'),
  recurrence: Recurrence.weekdays,
  departureDate: null,
  departureTime: const DepartureTime(hour: 8, minute: 25),
  timezone: 'Europe/Istanbul',
  departureState: DepartureState.upcoming,
  seatsOffered: 3,
  rules: const <RideRuleId>{RideRuleId.noSmoking},
  driver: const DiscoveredDriver(displayName: 'İrem Yılmaz', initials: 'İY'),
  mySeatRequest: null,
);

/// A discovery endpoint a test can steer, recording what it was asked.
class _FakeDiscoveryRepository implements DiscoveryRepository {
  _FakeDiscoveryRepository({
    this.pages = const <DiscoveryResult>[],
    this.failure,
  });

  List<DiscoveryResult> pages;
  RmFailure? failure;

  int callCount = 0;
  final List<String?> cursors = <String?>[];
  final List<String> origins = <String>[];

  @override
  Future<DiscoveryResult> between({
    required String originPlaceId,
    required String destinationPlaceId,
    String? cursor,
    int limit = kDiscoveryPageSize,
  }) async {
    callCount++;
    cursors.add(cursor);
    origins.add(originPlaceId);

    final RmFailure? failure = this.failure;
    if (failure != null) throw failure;

    return pages.isEmpty
        ? const DiscoveryResult(routes: <DiscoveredRoute>[], nextCursor: null)
        : pages.removeAt(0);
  }
}

void main() {
  ProviderContainer containerWith(_FakeDiscoveryRepository repository) {
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        discoveryRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(c.dispose);

    return c;
  }

  const DiscoveryQuery query = DiscoveryQuery(
    originPlaceId: 'p1',
    destinationPlaceId: 'p2',
  );

  group('Before anybody searches', () {
    /// CARRIES WEIGHT. No question asked, no request made, and no claim that
    /// nothing was found.
    test('the state is idle and nothing is requested', () async {
      final _FakeDiscoveryRepository repository = _FakeDiscoveryRepository();
      final ProviderContainer c = containerWith(repository);

      expect(await c.read(discoveryProvider.future), isA<DiscoveryIdle>());
      expect(repository.callCount, 0);
    });
  });

  group('Searching', () {
    test('a query produces one request and its results', () async {
      final _FakeDiscoveryRepository repository = _FakeDiscoveryRepository(
        pages: <DiscoveryResult>[
          DiscoveryResult(
            routes: <DiscoveredRoute>[_route('a')],
            nextCursor: null,
          ),
        ],
      );
      final ProviderContainer c = containerWith(repository);

      c.read(discoveryQueryProvider.notifier).search(query);
      final DiscoveryState state = await c.read(discoveryProvider.future);

      expect(repository.callCount, 1);
      expect(repository.cursors, <String?>[null]);
      expect(state, isA<DiscoveryMatches>());

      final DiscoveryMatches matches = state as DiscoveryMatches;
      expect(matches.routes.single.id, 'a');
      expect(matches.routes.single.driver.initials, 'İY');
      expect(matches.hasMore, isFalse);
    });

    /// Finding nothing is an answer, and a different one from idle.
    test('an empty page is matches, not idle', () async {
      final _FakeDiscoveryRepository repository = _FakeDiscoveryRepository();
      final ProviderContainer c = containerWith(repository);

      c.read(discoveryQueryProvider.notifier).search(query);
      final DiscoveryState state = await c.read(discoveryProvider.future);

      expect(state, isA<DiscoveryMatches>());
      expect((state as DiscoveryMatches).isEmpty, isTrue);
      expect(state.hasMore, isFalse);
    });

    test('a new query asks again', () async {
      final _FakeDiscoveryRepository repository = _FakeDiscoveryRepository(
        pages: <DiscoveryResult>[
          DiscoveryResult(
            routes: <DiscoveredRoute>[_route('a')],
            nextCursor: null,
          ),
          DiscoveryResult(
            routes: <DiscoveredRoute>[_route('b')],
            nextCursor: null,
          ),
        ],
      );
      final ProviderContainer c = containerWith(repository);

      c.read(discoveryQueryProvider.notifier).search(query);
      await c.read(discoveryProvider.future);

      c
          .read(discoveryQueryProvider.notifier)
          .search(
            const DiscoveryQuery(originPlaceId: 'p3', destinationPlaceId: 'p4'),
          );
      final DiscoveryState state = await c.read(discoveryProvider.future);

      expect(repository.callCount, 2);
      expect(repository.origins, <String>['p1', 'p3']);
      expect((state as DiscoveryMatches).routes.single.id, 'b');
    });
  });

  group('Paging', () {
    /// CARRIES WEIGHT. The cursor is passed back exactly as received.
    test('load more sends the cursor verbatim and appends in order', () async {
      const String opaque = 'eyJpdiI6IngveSt6In0=';
      final _FakeDiscoveryRepository repository = _FakeDiscoveryRepository(
        pages: <DiscoveryResult>[
          DiscoveryResult(
            routes: <DiscoveredRoute>[_route('a')],
            nextCursor: opaque,
          ),
          DiscoveryResult(
            routes: <DiscoveredRoute>[_route('b')],
            nextCursor: null,
          ),
        ],
      );
      final ProviderContainer c = containerWith(repository);

      c.read(discoveryQueryProvider.notifier).search(query);
      await c.read(discoveryProvider.future);

      await c.read(discoveryProvider.notifier).loadMore();

      expect(repository.cursors, <String?>[null, opaque]);

      final DiscoveryMatches matches =
          c.read(discoveryProvider).value! as DiscoveryMatches;
      expect(
        <String>[for (final DiscoveredRoute r in matches.routes) r.id],
        <String>['a', 'b'],
      );
      expect(matches.hasMore, isFalse, reason: 'a null cursor is the end');
    });

    test('a repeated route appears once', () async {
      final _FakeDiscoveryRepository repository = _FakeDiscoveryRepository(
        pages: <DiscoveryResult>[
          DiscoveryResult(
            routes: <DiscoveredRoute>[_route('a')],
            nextCursor: 'c',
          ),
          DiscoveryResult(
            routes: <DiscoveredRoute>[_route('a'), _route('b')],
            nextCursor: null,
          ),
        ],
      );
      final ProviderContainer c = containerWith(repository);

      c.read(discoveryQueryProvider.notifier).search(query);
      await c.read(discoveryProvider.future);
      await c.read(discoveryProvider.notifier).loadMore();

      final DiscoveryMatches matches =
          c.read(discoveryProvider).value! as DiscoveryMatches;
      expect(
        <String>[for (final DiscoveredRoute r in matches.routes) r.id],
        <String>['a', 'b'],
      );
    });

    test('a failed load more keeps what was already found', () async {
      final _FakeDiscoveryRepository repository = _FakeDiscoveryRepository(
        pages: <DiscoveryResult>[
          DiscoveryResult(
            routes: <DiscoveredRoute>[_route('a')],
            nextCursor: 'c',
          ),
        ],
      );
      final ProviderContainer c = containerWith(repository);

      c.read(discoveryQueryProvider.notifier).search(query);
      await c.read(discoveryProvider.future);

      repository.failure = const RmFailure.transport();
      await c.read(discoveryProvider.notifier).loadMore();

      final DiscoveryMatches matches =
          c.read(discoveryProvider).value! as DiscoveryMatches;
      expect(matches.routes.single.id, 'a');
      expect(matches.loadMoreFailure, isA<RmFailure>());
      // Untouched, so retrying asks for the same page again.
      expect(matches.nextCursor, 'c');
    });
  });

  group('Failures', () {
    /// CARRIES WEIGHT. A failed search must never read as "nothing found".
    for (final (String label, RmFailure failure) in <(String, RmFailure)>[
      ('an unreachable backend', const RmFailure.transport()),
      (
        'a server error',
        const RmFailure.fromBackend(
          status: 500,
          code: RmErrorCode.internalError,
        ),
      ),
      (
        'a malformed success',
        const RmFailure.fromBackend(status: 200, code: RmErrorCode.unexpected),
      ),
    ]) {
      test('$label is an error, never empty matches', () async {
        final _FakeDiscoveryRepository repository = _FakeDiscoveryRepository(
          failure: failure,
        );
        final ProviderContainer c = containerWith(repository);

        c.read(discoveryQueryProvider.notifier).search(query);
        c.listen<AsyncValue<DiscoveryState>>(
          discoveryProvider,
          (AsyncValue<DiscoveryState>? _, AsyncValue<DiscoveryState> _) {},
          fireImmediately: true,
        );
        await pumpEventQueue();

        final AsyncValue<DiscoveryState> state = c.read(discoveryProvider);
        expect(state.hasError, isTrue);
        expect(state.value, isNot(isA<DiscoveryMatches>()));
      });
    }

    /// The provider states `retry`, so a failed search is one request that
    /// stays failed until somebody asks again.
    test('a failed search is not retried automatically', () async {
      final _FakeDiscoveryRepository repository = _FakeDiscoveryRepository(
        failure: const RmFailure.transport(),
      );
      final ProviderContainer c = containerWith(repository);

      c.read(discoveryQueryProvider.notifier).search(query);
      c.listen<AsyncValue<DiscoveryState>>(
        discoveryProvider,
        (AsyncValue<DiscoveryState>? _, AsyncValue<DiscoveryState> _) {},
        fireImmediately: true,
      );
      await pumpEventQueue();

      expect(repository.callCount, 1);

      // Riverpod's default would have retried on a backoff by now.
      await Future<void>.delayed(const Duration(milliseconds: 700));

      expect(
        repository.callCount,
        1,
        reason: 'nothing may ask again on a timer',
      );
    });

    test('refresh asks exactly once more', () async {
      final _FakeDiscoveryRepository repository = _FakeDiscoveryRepository(
        failure: const RmFailure.transport(),
      );
      final ProviderContainer c = containerWith(repository);

      c.read(discoveryQueryProvider.notifier).search(query);
      c.listen<AsyncValue<DiscoveryState>>(
        discoveryProvider,
        (AsyncValue<DiscoveryState>? _, AsyncValue<DiscoveryState> _) {},
        fireImmediately: true,
      );
      await pumpEventQueue();
      expect(repository.callCount, 1);

      repository
        ..failure = null
        ..pages = <DiscoveryResult>[
          DiscoveryResult(
            routes: <DiscoveredRoute>[_route('a')],
            nextCursor: null,
          ),
        ];

      c.read(discoveryProvider.notifier).refresh();
      await pumpEventQueue();

      expect(
        repository.callCount,
        2,
        reason: 'one deliberate action, one request',
      );
    });
  });

  group('Lifecycle', () {
    /// Auto-dispose: a held page goes stale, and here that means journeys that
    /// may since have been cancelled or departed.
    test('a new subscription after the last one ends re-reads', () async {
      final _FakeDiscoveryRepository repository = _FakeDiscoveryRepository(
        pages: <DiscoveryResult>[
          DiscoveryResult(
            routes: <DiscoveredRoute>[_route('a')],
            nextCursor: null,
          ),
          DiscoveryResult(
            routes: <DiscoveredRoute>[_route('b')],
            nextCursor: null,
          ),
        ],
      );
      final ProviderContainer c = containerWith(repository);
      c.read(discoveryQueryProvider.notifier).search(query);

      final ProviderSubscription<AsyncValue<DiscoveryState>> first = c
          .listen<AsyncValue<DiscoveryState>>(
            discoveryProvider,
            (AsyncValue<DiscoveryState>? _, AsyncValue<DiscoveryState> _) {},
            fireImmediately: true,
          );
      await c.read(discoveryProvider.future);
      expect(repository.callCount, 1);

      first.close();
      await pumpEventQueue();

      c.listen<AsyncValue<DiscoveryState>>(
        discoveryProvider,
        (AsyncValue<DiscoveryState>? _, AsyncValue<DiscoveryState> _) {},
        fireImmediately: true,
      );
      final DiscoveryState reread = await c.read(discoveryProvider.future);

      expect(repository.callCount, 2, reason: 'exactly one new read');
      expect((reread as DiscoveryMatches).routes.single.id, 'b');
    });
  });
}
