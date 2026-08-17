// ─────────────────────────────────────────────────────────────
// RideMate — Create route providers
//
// One notifier holding the driver's draft. No repository, no service, no
// engine: there is no API to model yet, and inventing one would be the
// ceremony architecture.md forbids.
//
// The draft is app-scoped rather than autoDispose, so backing out of the
// screen by accident does not discard the driver's edits — reopening from the
// centre action shows it as they left it. It is held in memory only: nothing
// is written to SharedPreferences or any local store, so a process restart
// returns to the designed defaults. When publishing is real, drafts become
// persisted entities and this scope is revisited.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/places/place.dart';
import '../domain/create_route_draft.dart';
import '../domain/create_route_fixtures.dart';

/// The journey the driver is composing.
final NotifierProvider<CreateRouteDraftController, CreateRouteDraft>
createRouteDraftProvider =
    NotifierProvider<CreateRouteDraftController, CreateRouteDraft>(
      CreateRouteDraftController.new,
    );

/// Edits the draft. Every method is a plain state replacement — nothing here
/// validates, prices, schedules or publishes.
class CreateRouteDraftController extends Notifier<CreateRouteDraft> {
  @override
  CreateRouteDraft build() => kInitialCreateRouteDraft;

  void setOrigin(Place place) => state = state.copyWith(origin: place);

  void setDestination(Place place) =>
      state = state.copyWith(destination: place);

  void setRepeatsOnWeekdays(bool value) =>
      state = state.copyWith(repeatsOnWeekdays: value);

  /// No ceiling: see [kSeatsFloor] for why only one bound exists.
  void incrementSeats() => state = state.copyWith(seats: state.seats + 1);

  void decrementSeats() {
    if (!state.canDecrementSeats) return;
    state = state.copyWith(seats: state.seats - 1);
  }

  void toggleRule(RideRuleId id) => state = state.withRuleToggled(id);
}
