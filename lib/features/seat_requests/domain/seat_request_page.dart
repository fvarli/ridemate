// ─────────────────────────────────────────────────────────────
// RideMate — A page of askings, and what is happening to it
//
// One generic page rather than two nearly identical ones: the passenger's
// history and a driver's incoming list differ in what a row IS, not in how a
// page behaves. Paging, load-more failure and de-duplication are the same
// problem twice, and solving it twice is how the two drift apart.
//
// FAILURE IS NOT EMPTY
//
// A page that arrived and held nothing, and a page that never arrived, are
// different facts and are never collapsed. `AsyncError` carries the second;
// `isEmpty` on loaded data is the first.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

import '../../../core/api/rm_failure.dart';
import '../../../core/seat_requests/seat_request.dart';

@immutable
final class SeatRequestPage<T extends SeatRequestRow> {
  const SeatRequestPage({
    required this.requests,
    required this.nextCursor,
    this.isLoadingMore = false,
    this.loadMoreFailure,
    this.busy = const <String>{},
  });

  final List<T> requests;

  /// The server's position, opaque and passed back untouched. Null is the end.
  final String? nextCursor;

  final bool isLoadingMore;

  /// The rows with a command in flight.
  ///
  /// Keyed by request id rather than a single flag, so one row being decided
  /// leaves every other row usable — and kept on the page rather than in a
  /// widget, so the control stays disabled while the member scrolls past it
  /// and back.
  ///
  /// Neutral about which command: a passenger withdraws, a driver accepts or
  /// declines, and the page only cares that this row is busy.
  final Set<String> busy;

  /// Why the page after this one did not arrive, if it did not.
  ///
  /// Held beside the rows rather than replacing them: losing what the member
  /// could already read, to report that there was more, is the worse trade.
  final RmFailure? loadMoreFailure;

  bool get hasMore => nextCursor != null;

  bool get isEmpty => requests.isEmpty;

  bool isBusy(String requestId) => busy.contains(requestId);

  SeatRequestPage<T> copyWith({
    List<T>? requests,
    bool? isLoadingMore,
    RmFailure? loadMoreFailure,
    bool clearLoadMoreFailure = false,
    Set<String>? busy,
  }) => SeatRequestPage<T>(
    requests: requests ?? this.requests,
    nextCursor: nextCursor,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailure: clearLoadMoreFailure
        ? null
        : loadMoreFailure ?? this.loadMoreFailure,
    busy: busy ?? this.busy,
  );

  /// One row replaced by the server's own version of it.
  ///
  /// By id, and only that row: the list keeps its order and every other row
  /// keeps whatever the server last said about it.
  SeatRequestPage<T> withRowReplaced(T row) => copyWith(
    requests: <T>[
      for (final T existing in requests)
        if (existing.id == row.id) row else existing,
    ],
  );

  /// The next page, with anything already held dropped.
  ///
  /// Keyset pagination should not overlap, but a row published between two
  /// reads can land twice, and a list that renders the same asking twice looks
  /// broken in a way nobody can explain. Defensive, and cheap.
  SeatRequestPage<T> appended(List<T> next, String? cursor) {
    final Set<String> known = <String>{for (final T row in requests) row.id};

    return SeatRequestPage<T>(
      requests: <T>[
        ...requests,
        for (final T row in next)
          if (known.add(row.id)) row,
      ],
      nextCursor: cursor,
      busy: busy,
    );
  }
}
