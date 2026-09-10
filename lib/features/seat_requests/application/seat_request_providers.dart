// ─────────────────────────────────────────────────────────────
// RideMate — Seat request state
//
// TWO READ SURFACES, AND NO STATE MACHINERY FOR THE COMMANDS
//
// A passenger's own history and a driver's incoming list are paginated reads
// that a screen watches, so each gets a controller. Asking, withdrawing,
// accepting and declining are not: each answers with the resource it changed,
// and inventing a notifier per verb would be four state machines maintained
// on the chance a screen someday wants one. The screens that need them call
// the repository and act on what comes back.
//
// THE SERVER IS THE READ AUTHORITY
//
// Nothing here is optimistic. A command's result is the server's version of
// the row, not a locally edited copy, and neither list is amended from a
// command's return value — a screen that needs to see the change refreshes.
// Nothing is cached, nothing is persisted, and no cursor survives the screen.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
// `AsyncNotifierProviderFamily` is the declared type of a `.family` provider
// and lives in `misc` rather than the main export, the same reason `main.dart`
// already imports from here.
import 'package:flutter_riverpod/misc.dart';

import '../../../app/providers/api_client_provider.dart';
import '../../../app/providers/session_provider.dart';
import '../../../core/api/rm_failure.dart';
import '../../../core/api/rm_retry.dart';
import '../../../core/seat_requests/seat_request.dart';
import '../../../core/seat_requests/seat_request_decoder.dart';
import '../data/seat_request_repository.dart';
import '../domain/seat_request_page.dart';

final Provider<SeatRequestRepository> seatRequestRepositoryProvider =
    Provider<SeatRequestRepository>(
      (Ref ref) => ApiSeatRequestRepository(
        client: ref.watch(rmApiClientProvider),
        session: ref.watch(rmSessionProvider),
      ),
    );

/// What the member has asked for.
///
/// Auto-disposing for the reason My Routes is: a list held across screens is a
/// list that has gone stale by the time it is shown again, and here the thing
/// that goes stale is somebody else's answer to a question the member asked.
///
/// `retry` is stated rather than defaulted. Riverpod would otherwise retry a
/// failed page ten times on a backoff and leave the member watching a spinner
/// while the app asked a broken backend eleven times. See [noAutomaticRetry].
final AsyncNotifierProvider<
  MySeatRequestsController,
  SeatRequestPage<MySeatRequest>
>
mySeatRequestsProvider =
    AsyncNotifierProvider<
      MySeatRequestsController,
      SeatRequestPage<MySeatRequest>
    >(
      MySeatRequestsController.new,
      isAutoDispose: true,
      retry: noAutomaticRetry,
    );

class MySeatRequestsController
    extends AsyncNotifier<SeatRequestPage<MySeatRequest>> {
  @override
  Future<SeatRequestPage<MySeatRequest>> build() async {
    final MySeatRequestsResult result = await ref
        .watch(seatRequestRepositoryProvider)
        .mine(limit: kSeatRequestPageSize);

    return SeatRequestPage<MySeatRequest>(
      requests: result.requests,
      nextCursor: result.nextCursor,
    );
  }

  /// Starts again from the most recent asking.
  ///
  /// `invalidateSelf` rather than assigning state by hand: re-running build is
  /// what produces the loading state, the request and the answer as one step,
  /// and it discards the old cursor by construction.
  void refresh() => ref.invalidateSelf();

  Future<void> loadMore() => _loadMore(state, (String cursor) async {
    final MySeatRequestsResult result = await ref
        .read(seatRequestRepositoryProvider)
        .mine(cursor: cursor, limit: kSeatRequestPageSize);

    return (result.requests, result.nextCursor);
  }, (AsyncValue<SeatRequestPage<MySeatRequest>> next) => state = next);

  /// Takes back one asking, replacing it with what the server returns.
  ///
  /// NEVER OPTIMISTIC. The row changes only after the server has said it is
  /// withdrawn, and it changes to the server's own version of the request
  /// rather than to a locally edited copy — the rule My Routes applies to
  /// cancellation, for the same reason.
  ///
  /// Repeating it is safe by the endpoint's own shape: withdrawing something
  /// already withdrawn is that withdrawal observed again, so it answers with
  /// the request unchanged and this replaces the row with an identical one.
  /// There is no second event to show.
  ///
  /// Returns the failure when there was one, so the caller can say so; the row
  /// is left exactly as it was.
  Future<RmFailure?> withdraw(String requestId) async {
    final SeatRequestPage<MySeatRequest>? page = state.value;

    // A repeated tap while this row is already withdrawing is the same
    // intention arriving twice.
    if (page == null || page.isWithdrawing(requestId)) return null;

    state = AsyncData<SeatRequestPage<MySeatRequest>>(
      page.copyWith(withdrawing: <String>{...page.withdrawing, requestId}),
    );

    try {
      final MySeatRequest withdrawn = await ref
          .read(seatRequestRepositoryProvider)
          .withdraw(requestId);

      _settle(requestId, replaceWith: withdrawn);

      return null;
    } on RmFailure catch (failure) {
      _settle(requestId);

      // The server has an opinion about this asking that this client's copy
      // does not share — it was accepted, decided, or already withdrawn from
      // somewhere else. None of those can be applied locally without inventing
      // a transition nobody performed, so the list is re-read and whatever
      // comes back is what is shown.
      final SeatRequestRefusal? refusal = failure.seatRequestRefusal;

      if (refusal == SeatRequestRefusal.alreadyAccepted ||
          refusal == SeatRequestRefusal.alreadyDecided ||
          refusal == SeatRequestRefusal.withdrawn) {
        refresh();
      }

      return failure;
    }
  }

  /// Clears the in-flight mark, and replaces the row when there is one.
  void _settle(String requestId, {MySeatRequest? replaceWith}) {
    final SeatRequestPage<MySeatRequest>? page = state.value;

    if (page == null) return;

    final SeatRequestPage<MySeatRequest> cleared = page.copyWith(
      withdrawing: <String>{...page.withdrawing}..remove(requestId),
    );

    state = AsyncData<SeatRequestPage<MySeatRequest>>(
      replaceWith == null ? cleared : cleared.withRowReplaced(replaceWith),
    );
  }
}

/// Who has asked for a seat on one of the caller's journeys.
///
/// A family keyed by route: a driver may hold several journeys, and each has
/// its own list and its own position in it. The route id reaches the
/// controller through its constructor, so nothing has to be selected
/// elsewhere and no screen can watch the wrong list by forgetting to set one.
final AsyncNotifierProviderFamily<
  IncomingSeatRequestsController,
  SeatRequestPage<IncomingSeatRequest>,
  String
>
incomingSeatRequestsProvider = AsyncNotifierProvider.family(
  IncomingSeatRequestsController.new,
  isAutoDispose: true,
  retry: noAutomaticRetry,
);

class IncomingSeatRequestsController
    extends AsyncNotifier<SeatRequestPage<IncomingSeatRequest>> {
  IncomingSeatRequestsController(this.routeId);

  final String routeId;

  @override
  Future<SeatRequestPage<IncomingSeatRequest>> build() async {
    final IncomingSeatRequestsResult result = await ref
        .watch(seatRequestRepositoryProvider)
        .forRoute(routeId, limit: kSeatRequestPageSize);

    return SeatRequestPage<IncomingSeatRequest>(
      requests: result.requests,
      nextCursor: result.nextCursor,
    );
  }

  void refresh() => ref.invalidateSelf();

  Future<void> loadMore() => _loadMore(state, (String cursor) async {
    final IncomingSeatRequestsResult result = await ref
        .read(seatRequestRepositoryProvider)
        .forRoute(routeId, cursor: cursor, limit: kSeatRequestPageSize);

    return (result.requests, result.nextCursor);
  }, (AsyncValue<SeatRequestPage<IncomingSeatRequest>> next) => state = next);
}

/// Fetching the page after the one already held.
///
/// Shared by both surfaces because the sequence is identical and the rows are
/// the only difference. Existing rows stay on screen throughout, **including
/// when this fails**: taking away what the member could already read, in order
/// to report that there was more, is the worse trade. The cursor is untouched
/// on failure, so retrying asks for the same page again.
Future<void> _loadMore<T extends SeatRequestRow>(
  AsyncValue<SeatRequestPage<T>> current,
  Future<(List<T>, String?)> Function(String cursor) fetch,
  void Function(AsyncValue<SeatRequestPage<T>> next) emit,
) async {
  final SeatRequestPage<T>? page = current.value;

  // Nothing to continue, no cursor to continue with, or a request already in
  // flight. A second tap joins the first rather than sending the cursor twice
  // and appending the same page to itself.
  if (page == null || !page.hasMore || page.isLoadingMore) return;

  final String cursor = page.nextCursor!;

  emit(
    AsyncData<SeatRequestPage<T>>(
      page.copyWith(isLoadingMore: true, clearLoadMoreFailure: true),
    ),
  );

  try {
    final (List<T> rows, String? next) = await fetch(cursor);

    emit(AsyncData<SeatRequestPage<T>>(page.appended(rows, next)));
  } on RmFailure catch (failure) {
    emit(
      AsyncData<SeatRequestPage<T>>(
        page.copyWith(isLoadingMore: false, loadMoreFailure: failure),
      ),
    );
  }
}
