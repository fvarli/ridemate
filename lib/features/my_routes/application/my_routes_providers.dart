// ─────────────────────────────────────────────────────────────
// RideMate — My Routes state
//
// THE SERVER IS THE READ AUTHORITY
//
// This list comes from `GET /me/routes` and from nowhere else. Create Route
// knows when a publication succeeded and could hand the route over directly,
// and that is exactly what must not happen: an optimistic entry would show a
// journey that the list endpoint has never confirmed, and the one bug that
// matters here — publishing succeeds but the route is not really the member's
// to see — would be hidden by the very screen meant to reveal it. A newly
// published route appears by opening this screen or refreshing it.
//
// Nothing is cached and nothing is persisted. No cursor survives the screen.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/api_client_provider.dart';
import '../../../app/providers/session_provider.dart';
import '../../../core/api/rm_failure.dart';
import '../../../core/api/rm_retry.dart';
import '../../../core/routes/published_route.dart';
import '../data/my_routes_repository.dart';
import '../domain/my_routes_page.dart';

final Provider<MyRoutesRepository> myRoutesRepositoryProvider =
    Provider<MyRoutesRepository>(
      (Ref ref) => ApiMyRoutesRepository(
        client: ref.watch(rmApiClientProvider),
        session: ref.watch(rmSessionProvider),
      ),
    );

/// The member's routes, loaded when the screen first asks.
///
/// `retry` is stated, not left to the default. Riverpod would otherwise retry a
/// failed page ten times on a backoff, and the member would be shown a loading
/// state throughout — told nothing, while the app asked a broken backend
/// eleven times. See [noAutomaticRetry].
final AsyncNotifierProvider<MyRoutesController, MyRoutesPage> myRoutesProvider =
    AsyncNotifierProvider<MyRoutesController, MyRoutesPage>(
      MyRoutesController.new,
      retry: noAutomaticRetry,
    );

class MyRoutesController extends AsyncNotifier<MyRoutesPage> {
  @override
  Future<MyRoutesPage> build() async {
    final MyRoutesResult result = await ref
        .watch(myRoutesRepositoryProvider)
        .page(limit: kMyRoutesPageSize);

    return MyRoutesPage(routes: result.routes, nextCursor: result.nextCursor);
  }

  /// Starts again from the newest route.
  ///
  /// `invalidateSelf` rather than assigning state by hand: re-running build is
  /// what produces the loading state, the request and the answer as one step,
  /// and it discards the old cursor by construction. Assigning `state` after a
  /// FAILED build also re-initialises the notifier, which sends two requests
  /// for one tap — the defect F3 found and fixed. The list is replaced only
  /// when the new first page actually arrives.
  void refresh() => ref.invalidateSelf();

  /// Fetches the page after the one already held.
  ///
  /// Existing routes stay on screen throughout, including when this fails:
  /// losing page one to report that page two did not arrive would take away
  /// what the member could already read.
  Future<void> loadMore() async {
    final MyRoutesPage? page = state.value;

    // Nothing to continue, no cursor to continue with, or a request already in
    // flight. A second tap joins the first rather than sending the cursor
    // twice and appending the same page to itself.
    if (page == null || !page.hasMore || page.isLoadingMore) return;

    final String cursor = page.nextCursor!;

    state = AsyncData<MyRoutesPage>(
      page.copyWith(isLoadingMore: true, clearLoadMoreFailure: true),
    );

    try {
      final MyRoutesResult result = await ref
          .read(myRoutesRepositoryProvider)
          .page(cursor: cursor, limit: kMyRoutesPageSize);

      final MyRoutesPage current = state.value ?? page;

      state = AsyncData<MyRoutesPage>(
        current.appended(result.routes, result.nextCursor),
      );
    } on RmFailure catch (failure) {
      final MyRoutesPage current = state.value ?? page;

      // The cursor is untouched, so retrying asks for the same page again.
      state = AsyncData<MyRoutesPage>(
        current.copyWith(isLoadingMore: false, loadMoreFailure: failure),
      );
    }
  }

  /// Withdraws one route, replacing it with what the server returns.
  ///
  /// Never optimistic. The route on screen changes only after the server has
  /// said it is cancelled, and it changes to the server's own version of the
  /// route rather than to a locally edited copy.
  ///
  /// Returns the failure when there was one, so the caller can say so; the
  /// route itself is left exactly as it was.
  Future<RmFailure?> cancel(String routeId) async {
    final MyRoutesPage? page = state.value;

    // A repeated tap while this route is already cancelling is the same
    // intention arriving twice.
    if (page == null || page.isCancelling(routeId)) return null;

    state = AsyncData<MyRoutesPage>(
      page.copyWith(cancelling: <String>{...page.cancelling, routeId}),
    );

    try {
      final PublishedRoute cancelled = await ref
          .read(myRoutesRepositoryProvider)
          .cancel(routeId);

      state = AsyncData<MyRoutesPage>(
        _released(routeId).withRouteReplaced(cancelled),
      );

      return null;
    } on RmFailure catch (failure) {
      // The list is untouched. A 404 does not delete anything locally — the
      // server declining to find a route is not evidence about what this
      // member has — and a 409 does not render as cancelled.
      state = AsyncData<MyRoutesPage>(_released(routeId));

      return failure;
    }
  }

  MyRoutesPage _released(String routeId) {
    final MyRoutesPage page = state.value!;

    return page.copyWith(
      cancelling: <String>{
        for (final String id in page.cancelling)
          if (id != routeId) id,
      },
    );
  }
}
