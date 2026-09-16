// ─────────────────────────────────────────────────────────────
// RideMate — What the driver's journey feed currently knows
//
// The My Routes shape, for the same reasons: AsyncValue answers loading, loaded
// or failed, and this answers what a paginated list adds — is there more, is
// more on its way, and did fetching it fail without losing what is already
// here. Blanking the feed to fetch page two would take away the journeys the
// driver can act on right now.
//
// NO LIFECYCLE-IN-FLIGHT SET, UNLIKE MyRoutesPage
//
// Commands are run from the journey's own screen, where the state that belongs
// to one journey is held by that journey's own provider. A set here would be a
// second place for the same fact, and the two would disagree the first time a
// command outlived the feed.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

import '../../../core/api/rm_failure.dart';
import '../../../core/journeys/journey.dart';
import '../../../core/trips/trip_lifecycle.dart';

@immutable
final class MyJourneysPage {
  const MyJourneysPage({
    required this.journeys,
    required this.nextCursor,
    this.isLoadingMore = false,
    this.loadMoreFailure,
  });

  /// The journeys loaded so far, in the order the server returned them.
  ///
  /// `(service_date, route_id)` descending, and NOT a global chronology —
  /// routes carry their own timezones. Nothing here sorts, reverses or ranks:
  /// the keyset only works read in the order the cursor was cut from.
  final List<Journey> journeys;

  /// The opaque token that continues the list. Null means the end.
  final String? nextCursor;

  final bool isLoadingMore;

  /// Why the last attempt at another page failed, if it did.
  final RmFailure? loadMoreFailure;

  bool get hasMore => nextCursor != null;

  bool get isEmpty => journeys.isEmpty;

  /// This page and the next one after it.
  ///
  /// A journey already held is replaced rather than repeated. The server
  /// deduplicates `(route_id, service_date)` within a page, and a keyset read
  /// concurrent with a command can still hand back a row that was already
  /// above — appending blindly would show one journey twice, with two Start
  /// controls addressing the same day.
  MyJourneysPage appended(List<Journey> more, String? cursor) {
    final Map<JourneyRef, Journey> byRef = <JourneyRef, Journey>{
      for (final Journey journey in journeys) journey.ref: journey,
    };

    return copyWith(
      journeys: <Journey>[
        for (final Journey journey in journeys) journey,
        for (final Journey journey in more)
          if (!byRef.containsKey(journey.ref)) journey,
      ],
      nextCursor: cursor,
      clearNextCursor: cursor == null,
      isLoadingMore: false,
      clearLoadMoreFailure: true,
    );
  }

  /// The feed with one journey's lifecycle replaced by what the server said.
  ///
  /// EXACTLY ONE, ADDRESSED BY DAY
  ///
  /// A plan may have several journeys in this feed, and starting Monday says
  /// nothing about Tuesday. Matching on the route alone would move every day of
  /// a plan to the state one of them reached.
  ///
  /// A journey that is not held is left alone rather than added: this records
  /// an answer about something already on screen, and inventing a row from a
  /// lifecycle would be a journey with no origin, no destination and no day but
  /// the one the caller happened to pass.
  MyJourneysPage withTripReplaced(JourneyRef ref, TripLifecycle lifecycle) =>
      copyWith(
        journeys: <Journey>[
          for (final Journey journey in journeys)
            if (journey.ref == ref) journey.withTrip(lifecycle) else journey,
        ],
      );

  MyJourneysPage copyWith({
    List<Journey>? journeys,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? isLoadingMore,
    RmFailure? loadMoreFailure,
    bool clearLoadMoreFailure = false,
  }) => MyJourneysPage(
    journeys: journeys ?? this.journeys,
    nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailure: clearLoadMoreFailure
        ? null
        : (loadMoreFailure ?? this.loadMoreFailure),
  );
}
