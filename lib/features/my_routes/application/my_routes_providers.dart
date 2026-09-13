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
import '../../../core/trips/trip_decoder.dart';
import '../../../core/trips/trip_lifecycle.dart';
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
/// AUTO-DISPOSE, BECAUSE A CACHED LIST GOES STALE THE MOMENT ANYTHING PUBLISHES
///
/// This provider used to live for the whole process. Leaving My Routes kept the
/// loaded page, so a driver who published a journey and then opened My Routes in
/// the same session was shown the list as it had been BEFORE they published —
/// their new route simply absent. Found on a physical device: published at
/// 01:44, the screen still rendering a page read at 01:38. In a trust product
/// the reasonable conclusion is that publishing failed.
///
/// Auto-disposing fixes it at the only place that owns the problem. When the
/// screen is popped its `ref.watch` is the last listener to go, the provider is
/// disposed, and the next entry reads the server again. The alternatives were
/// worse: invalidating from the publication controller would wire Create Route
/// into My Routes and break the feature boundary a guard enforces, and
/// inserting the published route locally would show a journey the list endpoint
/// had never confirmed.
///
/// The cost is one request per screen entry. That is the right price for a list
/// whose whole purpose is to say what the server currently holds.
///
/// `retry` is stated, not left to the default. Riverpod would otherwise retry a
/// failed page ten times on a backoff, and the member would be shown a loading
/// state throughout — told nothing, while the app asked a broken backend
/// eleven times. See [noAutomaticRetry].
final AsyncNotifierProvider<MyRoutesController, MyRoutesPage> myRoutesProvider =
    AsyncNotifierProvider<MyRoutesController, MyRoutesPage>(
      MyRoutesController.new,
      isAutoDispose: true,
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

  /// Says the journey on [routeId] is under way.
  Future<RmFailure?> startTrip(String routeId) =>
      _lifecycle(routeId, (MyRoutesRepository repo) => repo.startTrip(routeId));

  /// Says it was made.
  ///
  /// Shares every rule with [startTrip] because they are the same kind of
  /// thing: one command, one route, the server's answer. Nothing about
  /// finishing a journey is more or less optimistic than beginning one.
  Future<RmFailure?> completeTrip(String routeId) => _lifecycle(
    routeId,
    (MyRoutesRepository repo) => repo.completeTrip(routeId),
  );

  /// Says it was abandoned.
  ///
  /// No reason is sent, because none is stored and none is asked for. A reason
  /// taxonomy is a design nobody has made, and a free-text field would be
  /// somewhere one member writes about another.
  Future<RmFailure?> abortTrip(String routeId) =>
      _lifecycle(routeId, (MyRoutesRepository repo) => repo.abortTrip(routeId));

  /// One lifecycle command, and what it does to this screen.
  ///
  /// NEVER OPTIMISTIC
  ///
  /// The row changes only after the server has answered, and it changes to the
  /// lifecycle the server returned rather than to one assumed from which
  /// command was sent. A refusal leaves the row exactly as it was — a journey
  /// the backend would not start is not a journey that started.
  ///
  /// Returns the failure when there was one, in the idiom of [cancel], so the
  /// caller can say so without this screen owning the copy.
  Future<RmFailure?> _lifecycle(
    String routeId,
    Future<TripLifecycle> Function(MyRoutesRepository) command,
  ) async {
    final MyRoutesPage? page = state.value;

    // A repeated tap while the same journey is already transitioning is the
    // same intention arriving twice. Nothing is queued.
    if (page == null || page.isChangingTrip(routeId)) return null;

    state = AsyncData<MyRoutesPage>(
      page.copyWith(changingTrip: <String>{...page.changingTrip, routeId}),
    );

    try {
      final TripLifecycle trip = await command(
        ref.read(myRoutesRepositoryProvider),
      );

      // The one place this lifecycle is held, and it holds what the server
      // returned. My Seat Requests carries the same fact for journeys OTHER
      // members published — never for this one, because nobody can ask for a
      // seat in their own car — so there is nothing there to keep in step, and
      // a cross-feature refresh here would be coupling that buys nothing. Both
      // feeds auto-dispose and re-read the server on entry.
      state = AsyncData<MyRoutesPage>(
        _settled(routeId).withTripReplaced(routeId, trip),
      );

      return null;
    } on RmFailure catch (failure) {
      state = AsyncData<MyRoutesPage>(_settled(routeId));

      // A journey the server says has already ended means the row on screen is
      // stale, not that the command was wrong. The ending is re-read rather
      // than built from the reason that named it: `already_completed` says
      // WHICH ending happened and nothing about WHEN, and a `completed_at`
      // invented here would be a timestamp no server ever sent.
      //
      // The other three refusals are facts about the journey as it already is,
      // so nothing local changes for them.
      if (_isTerminal(failure.tripRefusal)) refresh();

      return failure;
    }
  }

  static bool _isTerminal(TripRefusal? refusal) => switch (refusal) {
    TripRefusal.alreadyCompleted || TripRefusal.alreadyAborted => true,
    TripRefusal.departureNotReached ||
    TripRefusal.serviceDatePassed ||
    TripRefusal.recurringRouteUnsupported ||
    TripRefusal.routeUnavailable ||
    TripRefusal.tripNotStarted ||
    null => false,
  };

  MyRoutesPage _settled(String routeId) {
    final MyRoutesPage page = state.value!;

    return page.copyWith(
      changingTrip: <String>{
        for (final String id in page.changingTrip)
          if (id != routeId) id,
      },
    );
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
