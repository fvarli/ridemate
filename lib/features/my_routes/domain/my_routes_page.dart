// ─────────────────────────────────────────────────────────────
// RideMate — What My Routes currently knows
//
// AsyncValue answers the first question — loading, loaded, or failed — and this
// answers what a paginated, mutable list adds to it: is there more, is more on
// its way, did fetching more fail without losing what is already here, and
// which routes have a cancellation in flight.
//
// Those cannot live in AsyncValue itself. Turning the whole screen into
// `AsyncLoading` to fetch page two would blank out the routes already on
// screen, and a failure while loading page two would replace a working list
// with an error — losing what the member could read a moment ago in order to
// report that something they did not ask for went wrong.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

import '../../../core/api/rm_failure.dart';
import '../../../core/routes/published_route.dart';

@immutable
final class MyRoutesPage {
  const MyRoutesPage({
    required this.routes,
    required this.nextCursor,
    this.isLoadingMore = false,
    this.loadMoreFailure,
    this.cancelling = const <String>{},
  });

  /// The routes loaded so far, in the order the server returned them.
  final List<PublishedRoute> routes;

  /// The opaque token that continues the list. Null means the end.
  final String? nextCursor;

  final bool isLoadingMore;

  /// Why the last attempt at another page failed, if it did.
  ///
  /// Held beside the routes rather than replacing them: page two failing is
  /// not a reason to stop showing page one.
  final RmFailure? loadMoreFailure;

  /// Route ids with a cancellation in flight.
  ///
  /// A set, not a single id: two different routes may be cancelled at once
  /// without either waiting on the other, while a second tap on one already
  /// cancelling is a no-op. Nothing is queued.
  final Set<String> cancelling;

  bool get hasMore => nextCursor != null;

  bool get isEmpty => routes.isEmpty;

  bool isCancelling(String routeId) => cancelling.contains(routeId);

  MyRoutesPage copyWith({
    List<PublishedRoute>? routes,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? isLoadingMore,
    RmFailure? loadMoreFailure,
    bool clearLoadMoreFailure = false,
    Set<String>? cancelling,
  }) {
    return MyRoutesPage(
      routes: routes ?? this.routes,
      // `nextCursor: null` cannot mean "reached the end" — a null named
      // argument is indistinguishable from an omitted one, and getting this
      // wrong would either paginate forever or stop after one page.
      nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreFailure: clearLoadMoreFailure
          ? null
          : loadMoreFailure ?? this.loadMoreFailure,
      cancelling: cancelling ?? this.cancelling,
    );
  }

  /// This page with [route] put in place of the one carrying the same id.
  ///
  /// Replaced, never removed: a cancelled journey is still something the member
  /// published, and dropping it from the list would erase their own history
  /// from the only screen that shows it. Position is kept, because the server's
  /// ordering is by publication and cancelling does not republish.
  MyRoutesPage withRouteReplaced(PublishedRoute route) => copyWith(
    routes: <PublishedRoute>[
      for (final PublishedRoute existing in routes)
        if (existing.id == route.id) route else existing,
    ],
  );

  /// This page followed by [next], skipping anything already held.
  ///
  /// The keyset makes duplicates unlikely rather than impossible, and a route
  /// rendered twice would look like a route published twice. Defensive only:
  /// nothing is reordered, and the server's sequence is preserved exactly.
  MyRoutesPage appended(List<PublishedRoute> next, String? cursor) {
    final Set<String> known = <String>{
      for (final PublishedRoute route in routes) route.id,
    };

    return MyRoutesPage(
      routes: <PublishedRoute>[
        ...routes,
        for (final PublishedRoute route in next)
          if (known.add(route.id)) route,
      ],
      nextCursor: cursor,
      cancelling: cancelling,
    );
  }
}
