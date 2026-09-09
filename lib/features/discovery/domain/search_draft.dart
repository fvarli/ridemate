// ─────────────────────────────────────────────────────────────
// RideMate — What a member is searching for
//
// Two endpoints, and nothing else.
//
// WHAT THIS USED TO CARRY, AND WHY IT NO LONGER DOES
//
// A seat count, five trust filters and a sort order — all real, editable state
// that changed a chip and changed nothing else. That was honest enough while
// the results were a fixture: a control that reorders an invented list is not
// lying to anybody, because there is nothing to lie about.
//
// Phase 12 made the results real. A `Doğrulanmış` filter beside journeys the
// server actually returned reads as a filter the server applied, and it did
// not — the endpoint accepts two place ids and refuses everything else. A sort
// labelled `En iyi eşleşme` reads as a ranking, and the only ordering that
// exists is the order things were published in.
//
// So the controls left with the fixture rather than being kept and ignored.
// Collecting a value and discarding it is how a member comes to believe a
// filter works, which is worse than not offering one.
//
// ENDPOINTS START UNSELECTED
//
// They are server-owned places now, chosen from the catalogue the backend
// publishes. There is no honest default: a place the client made up would not
// match any route, and picking one from the catalogue on the member's behalf
// would be choosing where they are travelling from.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

import '../../../core/places/place.dart';

/// The journey a member is looking for.
@immutable
final class SearchDraft {
  const SearchDraft({this.origin, this.destination});

  /// Both null until the member picks from the server's catalogue.
  final Place? origin;
  final Place? destination;

  /// Whether this describes a journey the server could be asked about.
  ///
  /// Both endpoints chosen, and different: a journey from a place to itself is
  /// not a journey, and the endpoint refuses it for the same reason.
  bool get isComplete =>
      origin != null && destination != null && origin!.id != destination!.id;

  SearchDraft copyWith({Place? origin, Place? destination}) => SearchDraft(
    origin: origin ?? this.origin,
    destination: destination ?? this.destination,
  );

  /// Exchanges the two endpoints, whichever of them are set.
  SearchDraft swapped() =>
      SearchDraft(origin: destination, destination: origin);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchDraft &&
          other.origin == origin &&
          other.destination == destination;

  @override
  int get hashCode => Object.hash(origin, destination);
}
