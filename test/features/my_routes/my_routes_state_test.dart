import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/api/rm_error_code.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/routes/published_route.dart';
import 'package:ridemate/features/my_routes/application/my_routes_providers.dart';
import 'package:ridemate/features/my_routes/data/my_routes_repository.dart';
import 'package:ridemate/features/my_routes/domain/my_routes_page.dart';

import '../../support/fakes.dart';

/// Paging through the member's routes, and withdrawing one.
void main() {
  late FakeMyRoutesRepository routes;

  ProviderContainer container(
    List<MyRoutesResult> pages, {
    RmFailure? failure,
  }) {
    routes = FakeMyRoutesRepository(pages: pages, failure: failure);

    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        myRoutesRepositoryProvider.overrideWithValue(routes),
      ],
    );
    addTearDown(c.dispose);

    // A live listener, the way the screen holds one, so this container
    // behaves like the running app rather than like a bare read.
    //
    // (An earlier comment here blamed auto-dispose. That was wrong —
    // AsyncNotifierProvider defaults to `isAutoDispose: false`. What actually
    // went wrong was the automatic retry this provider now declines; see
    // test/app/backend_read_retry_test.dart.)
    c.listen<AsyncValue<MyRoutesPage>>(
      myRoutesProvider,
      (AsyncValue<MyRoutesPage>? _, AsyncValue<MyRoutesPage> _) {},
      fireImmediately: true,
    );

    return c;
  }

  MyRoutesResult page(List<String> ids, {String? next}) => MyRoutesResult(
    routes: <PublishedRoute>[for (final String id in ids) fakeRoute(id: id)],
    nextCursor: next,
  );

  Future<MyRoutesPage> loaded(ProviderContainer c) async {
    await c.read(myRoutesProvider.future);

    return c.read(myRoutesProvider).value!;
  }

  List<String> idsOf(MyRoutesPage page) => <String>[
    for (final PublishedRoute r in page.routes) r.id,
  ];

  group('The first page', () {
    test('is requested with no cursor and the contract limit', () async {
      final ProviderContainer c = container(<MyRoutesResult>[
        page(<String>['a', 'b']),
      ]);

      final MyRoutesPage first = await loaded(c);

      expect(routes.cursors, <String?>[null]);
      expect(routes.limits, <int>[kMyRoutesPageSize]);
      expect(idsOf(first), <String>['a', 'b']);
    });

    test('starts as loading', () {
      final ProviderContainer c = container(<MyRoutesResult>[
        page(<String>['a']),
      ]);

      expect(c.read(myRoutesProvider), isA<AsyncLoading<MyRoutesPage>>());
    });

    test('an empty account is empty, not broken', () async {
      final ProviderContainer c = container(<MyRoutesResult>[page(<String>[])]);

      final MyRoutesPage first = await loaded(c);

      expect(first.isEmpty, isTrue);
      expect(first.hasMore, isFalse);
    });

    /// CARRIES WEIGHT, and note what is asserted.
    ///
    /// Observed through `hasError`, which is true whether the provider settles
    /// on AsyncError or — had it been left to retry — sat in a loading state
    /// carrying the error. The screen matches the same way, so this asserts
    /// what the screen actually reads.
    test('a transport failure surfaces, and retrying asks again', () async {
      final ProviderContainer c = container(
        <MyRoutesResult>[],
        failure: const RmFailure.transport(),
      );

      await pumpEventQueue();

      final AsyncValue<MyRoutesPage> failed = c.read(myRoutesProvider);
      expect(failed.hasError, isTrue);
      expect(failed.error, isA<RmFailure>());
      expect(failed.value, isNull, reason: 'no list is invented on failure');
      expect(routes.callCount, 1);

      routes
        ..failure = null
        ..chain(<MyRoutesResult>[
          page(<String>['a']),
        ]);

      c.read(myRoutesProvider.notifier).refresh();
      final MyRoutesPage after = await loaded(c);

      expect(idsOf(after), <String>['a']);
      // One request per attempt. Assigning state after a failed build would
      // re-initialise the notifier and send two.
      expect(routes.callCount, 2);
    });
  });

  group('Loading more', () {
    /// CARRIES WEIGHT. The token the server gave is the token it gets back.
    test('sends exactly the cursor the server returned', () async {
      const String token = 'opaque==token/value';
      final ProviderContainer c = container(<MyRoutesResult>[
        page(<String>['a'], next: token),
        page(<String>['b']),
      ]);

      await loaded(c);
      await c.read(myRoutesProvider.notifier).loadMore();

      expect(routes.cursors, <String?>[null, token]);
    });

    test('appends in server order and keeps what was there', () async {
      final ProviderContainer c = container(<MyRoutesResult>[
        page(<String>['a', 'b'], next: 'more'),
        page(<String>['c', 'd']),
      ]);

      await loaded(c);
      await c.read(myRoutesProvider.notifier).loadMore();

      final MyRoutesPage after = c.read(myRoutesProvider).value!;
      expect(idsOf(after), <String>['a', 'b', 'c', 'd']);
      expect(after.hasMore, isFalse);
    });

    /// CARRIES WEIGHT. Page two failing must not cost the member page one.
    test('a failure keeps every route already loaded', () async {
      final ProviderContainer c = container(<MyRoutesResult>[
        page(<String>['a', 'b'], next: 'more'),
      ]);

      await loaded(c);
      routes.failure = const RmFailure.transport();

      await c.read(myRoutesProvider.notifier).loadMore();

      final MyRoutesPage after = c.read(myRoutesProvider).value!;
      expect(idsOf(after), <String>['a', 'b']);
      expect(after.loadMoreFailure, isNotNull);
      expect(after.isLoadingMore, isFalse);
      // The cursor is untouched, so a retry asks for the same page again.
      expect(after.nextCursor, 'more');
    });

    test('retrying after a failure re-sends the same cursor', () async {
      final ProviderContainer c = container(<MyRoutesResult>[
        page(<String>['a'], next: 'more'),
        page(<String>['b']),
      ]);

      await loaded(c);
      routes.failure = const RmFailure.transport();
      await c.read(myRoutesProvider.notifier).loadMore();

      // Serving by cursor means the retry simply asks for the same page
      // again, exactly as a real keyset endpoint would answer it.
      routes.failure = null;
      await c.read(myRoutesProvider.notifier).loadMore();

      expect(routes.cursors, <String?>[null, 'more', 'more']);
      expect(idsOf(c.read(myRoutesProvider).value!), <String>['a', 'b']);
    });

    /// Two taps on the button are one intention arriving twice.
    test('concurrent load-more makes one request', () async {
      final ProviderContainer c = container(<MyRoutesResult>[
        page(<String>['a'], next: 'more'),
        page(<String>['b']),
      ]);

      await loaded(c);
      routes.hold();

      final MyRoutesController controller = c.read(myRoutesProvider.notifier);
      final Future<void> first = controller.loadMore();
      final Future<void> second = controller.loadMore();
      final Future<void> third = controller.loadMore();

      routes.release();
      await Future.wait<void>(<Future<void>>[first, second, third]);

      // One for the first page, one for the load-more. Not three.
      expect(routes.callCount, 2);
      expect(idsOf(c.read(myRoutesProvider).value!), <String>['a', 'b']);
    });

    test('there is nothing to load when the cursor is null', () async {
      final ProviderContainer c = container(<MyRoutesResult>[
        page(<String>['a']),
      ]);

      await loaded(c);
      await c.read(myRoutesProvider.notifier).loadMore();

      expect(routes.callCount, 1);
    });

    /// The keyset makes this unlikely rather than impossible, and a route
    /// rendered twice would read as a route published twice.
    test('a route seen twice is held once', () async {
      final ProviderContainer c = container(<MyRoutesResult>[
        page(<String>['a', 'b'], next: 'more'),
        page(<String>['b', 'c']),
      ]);

      await loaded(c);
      await c.read(myRoutesProvider.notifier).loadMore();

      expect(idsOf(c.read(myRoutesProvider).value!), <String>['a', 'b', 'c']);
    });

    /// An empty page is not the end. Only a null cursor is.
    test('an empty page still carries its cursor forward', () async {
      final ProviderContainer c = container(<MyRoutesResult>[
        page(<String>['a'], next: 'one'),
        page(<String>[], next: 'two'),
        page(<String>['b']),
      ]);

      await loaded(c);
      await c.read(myRoutesProvider.notifier).loadMore();

      expect(c.read(myRoutesProvider).value!.hasMore, isTrue);

      await c.read(myRoutesProvider.notifier).loadMore();

      expect(routes.cursors, <String?>[null, 'one', 'two']);
      expect(idsOf(c.read(myRoutesProvider).value!), <String>['a', 'b']);
    });
  });

  group('Refreshing', () {
    /// CARRIES WEIGHT. A refresh is page one, from the top, with no cursor.
    test('discards the cursor and starts again', () async {
      final ProviderContainer c = container(<MyRoutesResult>[
        page(<String>['a'], next: 'more'),
        page(<String>['b']),
      ]);

      await loaded(c);
      await c.read(myRoutesProvider.notifier).loadMore();
      expect(idsOf(c.read(myRoutesProvider).value!), <String>['a', 'b']);

      // The member published something while reading, so page one is now
      // different. A refresh must see that rather than resuming mid-list.
      routes.chain(<MyRoutesResult>[
        page(<String>['z'], next: 'fresh'),
      ]);

      c.read(myRoutesProvider.notifier).refresh();
      final MyRoutesPage after = await loaded(c);

      // Back to the top: the third request names no position at all.
      expect(routes.cursors, <String?>[null, 'more', null]);
      expect(idsOf(after), <String>['z']);
      expect(after.nextCursor, 'fresh');
    });
  });

  group('Cancelling', () {
    test('replaces exactly one route with what the server returned', () async {
      final ProviderContainer c = container(<MyRoutesResult>[
        page(<String>['a', 'b', 'c']),
      ]);

      await loaded(c);
      routes.cancelResult = fakeRoute(
        id: 'b',
        status: RouteStatus.cancelled,
        cancelledAt: '2026-08-28T10:00:00+00:00',
      );

      final RmFailure? failure = await c
          .read(myRoutesProvider.notifier)
          .cancel('b');

      expect(failure, isNull);
      expect(routes.cancelled, <String>['b']);

      final MyRoutesPage after = c.read(myRoutesProvider).value!;
      // Still three, still in the same order: cancelling preserves history.
      expect(idsOf(after), <String>['a', 'b', 'c']);
      expect(after.routes[1].status, RouteStatus.cancelled);
      expect(after.routes[0].status, RouteStatus.published);
      expect(after.routes[2].status, RouteStatus.published);
    });

    /// CARRIES WEIGHT. Cancelling withdraws a journey; it does not erase it.
    test('never removes the route from the list', () async {
      final ProviderContainer c = container(<MyRoutesResult>[
        page(<String>['a']),
      ]);

      await loaded(c);
      await c.read(myRoutesProvider.notifier).cancel('a');

      expect(c.read(myRoutesProvider).value!.routes, hasLength(1));
    });

    test('a repeated tap during one cancellation makes one request', () async {
      final ProviderContainer c = container(<MyRoutesResult>[
        page(<String>['a']),
      ]);

      await loaded(c);
      routes.hold();

      final MyRoutesController controller = c.read(myRoutesProvider.notifier);
      final Future<RmFailure?> first = controller.cancel('a');
      final Future<RmFailure?> second = controller.cancel('a');

      expect(c.read(myRoutesProvider).value!.isCancelling('a'), isTrue);

      routes.release();
      await Future.wait<RmFailure?>(<Future<RmFailure?>>[first, second]);

      expect(routes.cancelled, <String>['a']);
      expect(c.read(myRoutesProvider).value!.isCancelling('a'), isFalse);
    });

    test('two different routes cancel independently', () async {
      final ProviderContainer c = container(<MyRoutesResult>[
        page(<String>['a', 'b']),
      ]);

      await loaded(c);
      routes.hold();

      final MyRoutesController controller = c.read(myRoutesProvider.notifier);
      final Future<RmFailure?> first = controller.cancel('a');
      final Future<RmFailure?> second = controller.cancel('b');

      final MyRoutesPage busy = c.read(myRoutesProvider).value!;
      expect(busy.isCancelling('a'), isTrue);
      expect(busy.isCancelling('b'), isTrue);

      routes.release();
      await Future.wait<RmFailure?>(<Future<RmFailure?>>[first, second]);

      expect(routes.cancelled, <String>['a', 'b']);
      expect(c.read(myRoutesProvider).value!.cancelling, isEmpty);
    });

    /// CARRIES WEIGHT for every failure: the route is left exactly as it was.
    test('a failure changes nothing about the route', () async {
      for (final RmFailure failure in <RmFailure>[
        const RmFailure.transport(),
        const RmFailure.fromBackend(
          status: 500,
          code: RmErrorCode.internalError,
        ),
        const RmFailure.fromBackend(status: 429, code: RmErrorCode.rateLimited),
        // An unreadable 200: the cancellation may actually have happened.
        const RmFailure.fromBackend(status: 200, code: RmErrorCode.unexpected),
        const RmFailure.fromBackend(status: 409, code: RmErrorCode.conflict),
        const RmFailure.fromBackend(status: 404, code: RmErrorCode.notFound),
        const RmFailure.fromBackend(status: 403, code: RmErrorCode.forbidden),
      ]) {
        final ProviderContainer c = container(<MyRoutesResult>[
          page(<String>['a', 'b']),
        ]);

        await loaded(c);
        final MyRoutesPage before = c.read(myRoutesProvider).value!;
        routes.cancelFailure = failure;

        final RmFailure? reported = await c
            .read(myRoutesProvider.notifier)
            .cancel('a');

        expect(reported, failure, reason: '$failure');

        final MyRoutesPage after = c.read(myRoutesProvider).value!;
        // Nothing removed, nothing marked cancelled, nothing else touched.
        expect(idsOf(after), idsOf(before), reason: '$failure');
        expect(
          after.routes.first.status,
          RouteStatus.published,
          reason: '$failure',
        );
        expect(after.isCancelling('a'), isFalse, reason: '$failure');
      }
    });

    /// A 404 says the server would not act on that id. It is not evidence
    /// about what this member has, and deleting on it would remove a route the
    /// list itself had just returned.
    test('a not-found does not delete anything locally', () async {
      final ProviderContainer c = container(<MyRoutesResult>[
        page(<String>['a', 'b']),
      ]);

      await loaded(c);
      routes.cancelFailure = const RmFailure.fromBackend(
        status: 404,
        code: RmErrorCode.notFound,
      );

      await c.read(myRoutesProvider.notifier).cancel('a');

      expect(idsOf(c.read(myRoutesProvider).value!), <String>['a', 'b']);
    });

    /// A conflict means the departure has passed. It is not a cancellation.
    test('a conflict never renders as cancelled', () async {
      final ProviderContainer c = container(<MyRoutesResult>[
        page(<String>['a']),
      ]);

      await loaded(c);
      routes.cancelFailure = const RmFailure.fromBackend(
        status: 409,
        code: RmErrorCode.conflict,
      );

      await c.read(myRoutesProvider.notifier).cancel('a');

      expect(
        c.read(myRoutesProvider).value!.routes.single.status,
        RouteStatus.published,
      );
    });

    /// Retrying an indeterminate outcome targets the same route, with the same
    /// bodyless POST. There is no attempt id, because the route id is one.
    test('retrying an indeterminate cancel targets the same route', () async {
      final ProviderContainer c = container(<MyRoutesResult>[
        page(<String>['a']),
      ]);

      await loaded(c);
      routes.cancelFailure = const RmFailure.transport();
      await c.read(myRoutesProvider.notifier).cancel('a');

      routes.cancelFailure = null;
      routes.cancelResult = fakeRoute(id: 'a', status: RouteStatus.cancelled);
      await c.read(myRoutesProvider.notifier).cancel('a');

      expect(routes.cancelled, <String>['a', 'a']);
      expect(
        c.read(myRoutesProvider).value!.routes.single.status,
        RouteStatus.cancelled,
      );
    });

    /// The corrected idempotency invariant: what matters is the resource
    /// state, not that two responses were byte-identical. `departure_state` is
    /// read at the moment of asking and may legitimately have moved on.
    test('a second cancellation is accepted with a different state', () async {
      final ProviderContainer c = container(<MyRoutesResult>[
        page(<String>['a']),
      ]);

      await loaded(c);
      routes.cancelResult = fakeRoute(
        id: 'a',
        status: RouteStatus.cancelled,
        cancelledAt: '2026-08-28T10:00:00+00:00',
      );
      await c.read(myRoutesProvider.notifier).cancel('a');

      // Same cancellation, observed later: cancelled_at is unchanged but the
      // derived departure state has moved.
      routes.cancelResult = fakeRoute(
        id: 'a',
        status: RouteStatus.cancelled,
        departureState: DepartureState.past,
        cancelledAt: '2026-08-28T10:00:00+00:00',
      );
      final RmFailure? failure = await c
          .read(myRoutesProvider.notifier)
          .cancel('a');

      expect(failure, isNull);

      final PublishedRoute after = c
          .read(myRoutesProvider)
          .value!
          .routes
          .single;
      expect(after.status, RouteStatus.cancelled);
      expect(after.cancelledAt, '2026-08-28T10:00:00+00:00');
      expect(after.departureState, DepartureState.past);
    });
  });
}
