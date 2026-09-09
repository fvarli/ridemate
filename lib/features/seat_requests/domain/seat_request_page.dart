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
  });

  final List<T> requests;

  /// The server's position, opaque and passed back untouched. Null is the end.
  final String? nextCursor;

  final bool isLoadingMore;

  /// Why the page after this one did not arrive, if it did not.
  ///
  /// Held beside the rows rather than replacing them: losing what the member
  /// could already read, to report that there was more, is the worse trade.
  final RmFailure? loadMoreFailure;

  bool get hasMore => nextCursor != null;

  bool get isEmpty => requests.isEmpty;

  SeatRequestPage<T> copyWith({
    bool? isLoadingMore,
    RmFailure? loadMoreFailure,
    bool clearLoadMoreFailure = false,
  }) => SeatRequestPage<T>(
    requests: requests,
    nextCursor: nextCursor,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailure: clearLoadMoreFailure
        ? null
        : loadMoreFailure ?? this.loadMoreFailure,
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
    );
  }
}
