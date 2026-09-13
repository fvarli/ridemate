// ─────────────────────────────────────────────────────────────
// RideMate — Asking for a seat, as an action
//
// ONE CONTROLLER FOR THE WHOLE LIST, KEYED BY JOURNEY
//
// Not one per card and not one per verb. A member taps one card at a time, but
// a failed asking has to keep its state while they scroll past it, so the
// attempt is held here rather than in the widget.
//
// A JOURNEY IS A ROUTE ON A DATE, AND THE KEY SAYS SO
//
// Not the route id alone. A route is a plan and may run on many days, so two
// askings about one plan are two askings — and sharing a key would make the
// second tap a RETRY of the first: the same minted id would go out for a
// different journey, which the backend answers `id_already_used`, or worse it
// would replay and hand back the wrong asking. The day now travels on the wire
// too, so the server and this client agree about which journey an id belongs
// to. Nothing can reach the recurring case yet — the gate still stands in front
// of the control, and F2 removes it.
//
// THE ID IS MINTED ONCE PER INTENT, AND EVERY RETRY REUSES IT
//
// This is the whole point of the client generating it. The passenger taps, the
// server records the asking, the response is lost — and the retry must carry
// the SAME id, or the backend cannot recognise it as the same asking. Minting
// a fresh one per attempt would turn tier-1 idempotency into an
// `already_requested` refusal the member has to be told about, for a request
// that actually succeeded.
//
// Phase 10 answered the same question for publication; this is that answer,
// keyed by journey instead of by draft.
//
// NOTHING IS OPTIMISTIC
//
// A card says "requested" only after the server has said so, and it says it
// with the id and status the server returned. See `DiscoveryController.
// markRequested`.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/rm_failure.dart';
import '../../../core/routes/departure.dart';
import '../../../core/seat_requests/seat_request.dart';
import '../../../core/seat_requests/seat_request_decoder.dart';
import '../../create_route/application/publication_providers.dart'
    show uuidGeneratorProvider;
import '../../discovery/application/discovery_search_providers.dart';
import '../data/seat_request_repository.dart';
import 'seat_request_providers.dart' show seatRequestRepositoryProvider;

/// Where one journey's asking has got to, from this screen's point of view.
///
/// Deliberately not a copy of [SeatRequestStatus]: that is what the server says
/// about a request that exists, and this is what is happening to an attempt to
/// create one. Conflating them is how a screen ends up claiming a state the
/// backend never confirmed.
@immutable
sealed class SeatRequestAttempt {
  const SeatRequestAttempt();
}

/// In flight. The action is disabled and no second tap is sent.
final class SeatRequestSending extends SeatRequestAttempt {
  const SeatRequestSending();
}

/// It did not land, and trying again could still change the answer.
///
/// The id is kept, so the retry is the same asking arriving again.
final class SeatRequestFailed extends SeatRequestAttempt {
  const SeatRequestFailed(this.failure);

  final RmFailure failure;

  /// The refusal the server named, when it named one this build knows.
  SeatRequestRefusal? get refusal => failure.seatRequestRefusal;
}

/// Which journey an asking is for: a plan, and the day it runs.
///
/// A record rather than a joined string, so two keys compare by what they mean
/// instead of by how they were spelled — and so nothing has to agree on a
/// separator that a place label or an id could contain.
typedef JourneyKey = ({String routeId, DepartureDate serviceDate});

/// What every journey's attempt is doing right now.
final NotifierProvider<
  SeatRequestActionController,
  Map<JourneyKey, SeatRequestAttempt>
>
seatRequestActionProvider =
    NotifierProvider<
      SeatRequestActionController,
      Map<JourneyKey, SeatRequestAttempt>
    >(SeatRequestActionController.new, isAutoDispose: true);

class SeatRequestActionController
    extends Notifier<Map<JourneyKey, SeatRequestAttempt>> {
  /// The id each unresolved intent is carrying.
  ///
  /// Kept outside `state` because it is not something the UI renders: it is the
  /// identity of an attempt, and putting it on screen would invite a widget to
  /// show it.
  final Map<JourneyKey, String> _minted = <JourneyKey, String>{};

  @override
  Map<JourneyKey, SeatRequestAttempt> build() =>
      const <JourneyKey, SeatRequestAttempt>{};

  SeatRequestAttempt? attemptFor(JourneyKey journey) => state[journey];

  /// Asks for a seat on one journey.
  ///
  /// Safe to call again after a failure: the same id goes back out, so the
  /// server answers about the same asking rather than being asked a second
  /// question.
  Future<void> request(JourneyKey journey) async {
    // Already in flight. A second tap joins the first rather than sending a
    // duplicate — and the backend would recognise it, but the member would
    // have watched two spinners to find that out.
    if (state[journey] is SeatRequestSending) return;

    final String requestId = _idFor(journey);

    _set(journey, const SeatRequestSending());

    try {
      final SeatRequested result = await ref
          .read(seatRequestRepositoryProvider)
          // The day is sent as well as keyed on. Phase 16b's backend requires
          // it for a plan and accepts it for a one-off route, where it must be
          // that route's own day — which is exactly where this key came from.
          // Omitting it would ask the server to guess on the one surface where
          // guessing is what this phase removed.
          .ask(
            routeId: journey.routeId,
            requestId: requestId,
            serviceDate: journey.serviceDate,
          );

      // Resolved: the id has done its job and this intent is over.
      _minted.remove(journey);
      _clear(journey);

      // The server's own id and status, put on the one card it belongs to.
      ref
          .read(discoveryProvider.notifier)
          .markRequested(
            journey.routeId,
            MySeatRequestSummary(
              // The server's own day, not the key's: they are the same journey,
              // and taking it from the response keeps the card describing what
              // the backend recorded rather than what this client asked for.
              serviceDate: result.request.serviceDate,
              id: result.request.id,
              status: result.request.status,
            ),
          );
    } on RmFailure catch (failure) {
      _set(journey, SeatRequestFailed(failure));

      // Two refusals mean the client's picture of this journey is out of date,
      // and neither can be repaired locally.
      //
      // `already_requested` says an asking exists that this client did not
      // make — another device, or an intent from an older session under a
      // different id. `current_status` alone cannot build one: the request's
      // real id is unknown here, and inventing one would put a fabricated
      // identifier on a card that is supposed to address a real resource.
      //
      // `route_unavailable` says the journey was cancelled or departed between
      // the search and the tap. Neither is a seat-request state, and neither
      // may be dressed up as one.
      //
      // So the search is re-read, and whatever comes back is what is shown.
      final SeatRequestRefusal? refusal = failure.seatRequestRefusal;

      if (refusal == SeatRequestRefusal.alreadyRequested ||
          refusal == SeatRequestRefusal.routeUnavailable) {
        // The id is spent either way: the server has an opinion about this
        // journey that a repeat of this attempt cannot change.
        _minted.remove(journey);
        ref.read(discoveryProvider.notifier).refresh();
      }
    }
  }

  /// Forgets a failed attempt without sending anything.
  ///
  /// The id is deliberately kept: dismissing a message is not abandoning the
  /// intent, and a later retry must still be the same asking.
  void dismiss(JourneyKey journey) => _clear(journey);

  /// The id this journey's intent is carrying.
  ///
  /// One per journey, minted on the first attempt and returned unchanged to
  /// every retry until the intent resolves.
  String _idFor(JourneyKey journey) =>
      _minted[journey] ??= ref.read(uuidGeneratorProvider).v7();

  void _set(JourneyKey journey, SeatRequestAttempt attempt) {
    state = <JourneyKey, SeatRequestAttempt>{...state, journey: attempt};
  }

  void _clear(JourneyKey journey) {
    state = <JourneyKey, SeatRequestAttempt>{...state}..remove(journey);
  }
}
