// ─────────────────────────────────────────────────────────────
// RideMate — Discovery results
//
// TWO PROVIDERS, BECAUSE THERE ARE TWO QUESTIONS
//
//   what did the member ask for   — a query, or nothing yet
//   what did the server answer    — results, or a failure
//
// Kept apart so "no search has been made" is a state rather than an empty list.
// An empty list means the server found nothing between those two places, which
// is a real answer and a different one.
//
// The query is two place ids. Not seats, not a sort, not a date: the endpoint
// accepts none of them and refuses unknown parameters, and carrying them here
// would be building the shape of a search the product cannot perform.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/api_client_provider.dart';
import '../../../app/providers/session_provider.dart';
import '../../../core/api/rm_failure.dart';
import '../../../core/api/rm_retry.dart';
import '../../../core/routes/discovered_route.dart';
import '../data/discovery_repository.dart';

final Provider<DiscoveryRepository> discoveryRepositoryProvider =
    Provider<DiscoveryRepository>(
      (Ref ref) => ApiDiscoveryRepository(
        client: ref.watch(rmApiClientProvider),
        session: ref.watch(rmSessionProvider),
      ),
    );

/// Where a member wants to travel between.
@immutable
final class DiscoveryQuery {
  const DiscoveryQuery({
    required this.originPlaceId,
    required this.destinationPlaceId,
  });

  final String originPlaceId;
  final String destinationPlaceId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveryQuery &&
          other.originPlaceId == originPlaceId &&
          other.destinationPlaceId == destinationPlaceId;

  @override
  int get hashCode => Object.hash(originPlaceId, destinationPlaceId);
}

/// The search in effect, or null before anybody has searched.
final NotifierProvider<DiscoveryQueryController, DiscoveryQuery?>
discoveryQueryProvider =
    NotifierProvider<DiscoveryQueryController, DiscoveryQuery?>(
      DiscoveryQueryController.new,
    );

class DiscoveryQueryController extends Notifier<DiscoveryQuery?> {
  @override
  DiscoveryQuery? build() => null;

  void search(DiscoveryQuery query) => state = query;

  void clear() => state = null;
}

/// What discovery currently has to show.
@immutable
sealed class DiscoveryState {
  const DiscoveryState();
}

/// Nobody has searched yet. Not the same as finding nothing.
final class DiscoveryIdle extends DiscoveryState {
  const DiscoveryIdle();
}

/// The server's answer for the query in effect.
final class DiscoveryMatches extends DiscoveryState {
  const DiscoveryMatches({
    required this.routes,
    required this.nextCursor,
    this.isLoadingMore = false,
    this.loadMoreFailure,
  });

  final List<DiscoveredRoute> routes;

  /// Opaque, and passed back exactly as received. Null is the only
  /// end-of-list signal; an empty page is not one.
  final String? nextCursor;

  final bool isLoadingMore;
  final RmFailure? loadMoreFailure;

  bool get hasMore => nextCursor != null;
  bool get isEmpty => routes.isEmpty;

  DiscoveryMatches copyWith({
    List<DiscoveredRoute>? routes,
    String? nextCursor,
    bool clearCursor = false,
    bool? isLoadingMore,
    RmFailure? loadMoreFailure,
    bool clearLoadMoreFailure = false,
  }) => DiscoveryMatches(
    routes: routes ?? this.routes,
    nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailure: clearLoadMoreFailure
        ? null
        : loadMoreFailure ?? this.loadMoreFailure,
  );
}

/// Results for the query in effect.
///
/// AUTO-DISPOSE, for the reason Phase 10 learned twice on hardware: a provider
/// that outlives its listeners serves a page the server has not confirmed since
/// it was read — here, journeys that may since have been cancelled or departed.
///
/// `retry` is stated rather than left to the default. Riverpod would otherwise
/// re-run a failed search ten times on a backoff, hammering a backend that has
/// just failed while the member is shown nothing. See [noAutomaticRetry].
final AsyncNotifierProvider<DiscoveryController, DiscoveryState>
discoveryProvider = AsyncNotifierProvider<DiscoveryController, DiscoveryState>(
  DiscoveryController.new,
  isAutoDispose: true,
  retry: noAutomaticRetry,
);

class DiscoveryController extends AsyncNotifier<DiscoveryState> {
  @override
  Future<DiscoveryState> build() async {
    final DiscoveryQuery? query = ref.watch(discoveryQueryProvider);

    // Nothing asked, nothing requested. An empty result would claim the server
    // was consulted and found none, which nobody has established.
    if (query == null) return const DiscoveryIdle();

    final DiscoveryResult result = await ref
        .watch(discoveryRepositoryProvider)
        .between(
          originPlaceId: query.originPlaceId,
          destinationPlaceId: query.destinationPlaceId,
          limit: kDiscoveryPageSize,
        );

    return DiscoveryMatches(
      routes: result.routes,
      nextCursor: result.nextCursor,
    );
  }

  /// Asks the server again, from the first page.
  ///
  /// `invalidateSelf` rather than assigning state: re-running build produces
  /// the loading state, the request and the answer as one step, and discards
  /// the old cursor by construction.
  void refresh() => ref.invalidateSelf();

  /// Fetches the page after the one already held.
  ///
  /// Existing results stay on screen throughout, including on failure: losing
  /// what a member can already read in order to report that more did not
  /// arrive would take away the part that worked.
  Future<void> loadMore() async {
    final DiscoveryState? current = state.value;

    if (current is! DiscoveryMatches ||
        !current.hasMore ||
        current.isLoadingMore) {
      return;
    }

    final String cursor = current.nextCursor!;
    final DiscoveryQuery? query = ref.read(discoveryQueryProvider);

    if (query == null) return;

    state = AsyncData<DiscoveryState>(
      current.copyWith(isLoadingMore: true, clearLoadMoreFailure: true),
    );

    try {
      final DiscoveryResult result = await ref
          .read(discoveryRepositoryProvider)
          .between(
            originPlaceId: query.originPlaceId,
            destinationPlaceId: query.destinationPlaceId,
            cursor: cursor,
            limit: kDiscoveryPageSize,
          );

      final DiscoveryState? latest = state.value;
      final DiscoveryMatches base = latest is DiscoveryMatches
          ? latest
          : current;

      // Appended by id, so a route seen twice renders once. Order is never
      // recomputed — the server owns it.
      final Set<String> seen = <String>{
        for (final DiscoveredRoute route in base.routes) route.id,
      };

      state = AsyncData<DiscoveryState>(
        base.copyWith(
          routes: <DiscoveredRoute>[
            ...base.routes,
            for (final DiscoveredRoute route in result.routes)
              if (seen.add(route.id)) route,
          ],
          nextCursor: result.nextCursor,
          clearCursor: result.nextCursor == null,
          isLoadingMore: false,
        ),
      );
    } on RmFailure catch (failure) {
      final DiscoveryState? latest = state.value;
      final DiscoveryMatches base = latest is DiscoveryMatches
          ? latest
          : current;

      // The cursor is untouched, so retrying asks for the same page again.
      state = AsyncData<DiscoveryState>(
        base.copyWith(isLoadingMore: false, loadMoreFailure: failure),
      );
    }
  }
}
