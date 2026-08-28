// ─────────────────────────────────────────────────────────────
// RideMate — The publication attempt
//
// A DRAFT AND AN ATTEMPT ARE NOT THE SAME THING
//
// The draft is what the driver has said. An attempt is one try at telling the
// server, and it has an identity of its own: the UUIDv7 that makes a retry a
// retry rather than a second journey.
//
// WHAT SURVIVES A FAILURE, AND WHY
//
// After an indeterminate outcome — a timeout, a refused connection, a 500 —
// the request may already have reached the server. Retrying with a NEW id
// would publish the same journey twice, and the member would find two
// identical commutes with no way to tell which one anybody had seen. So the id
// is kept, and the retry sends exactly the same body.
//
// WHAT DOES NOT SURVIVE
//
// A changed intention. If the driver edits anything the server would store,
// the pending id no longer describes what they now mean, and reusing it would
// either be refused as a conflict or — worse, if the first attempt had landed
// — silently publish the older version. So the id is discarded and the next
// publish mints a fresh one.
//
// Nothing here is persisted. There is no queue, no background retry and no
// local database: an attempt lives as long as the screen does.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/api_client_provider.dart';
import '../../../app/providers/session_provider.dart';
import '../../../core/api/rm_error_code.dart';
import '../../../core/api/rm_failure.dart';
import '../../../core/id/rm_uuid.dart';
import '../../../core/routes/published_route.dart';
import '../data/route_repository.dart';
import '../domain/create_route_draft.dart';
import 'create_route_providers.dart';

final Provider<RmUuidGenerator> uuidGeneratorProvider =
    Provider<RmUuidGenerator>((Ref ref) => const UuidV7Generator());

final Provider<RouteRepository> routeRepositoryProvider =
    Provider<RouteRepository>(
      (Ref ref) => ApiRouteRepository(
        client: ref.watch(rmApiClientProvider),
        session: ref.watch(rmSessionProvider),
      ),
    );

/// Where one attempt to publish currently stands.
@immutable
sealed class PublicationState {
  const PublicationState();
}

/// Nothing has been submitted.
final class PublicationIdle extends PublicationState {
  const PublicationIdle();
}

/// A request is in flight. Further taps join this one rather than starting another.
final class PublicationInFlight extends PublicationState {
  const PublicationInFlight(this.routeId);

  final String routeId;
}

/// The outcome was indeterminate, so the id is kept for the retry.
///
/// The request may or may not have reached the server. Sending it again with
/// the same id is the only way to find out without risking a duplicate.
final class PublicationRetryable extends PublicationState {
  const PublicationRetryable(this.routeId, this.failure);

  final String routeId;
  final RmFailure failure;
}

/// The server refused, and repeating the same request would be refused again.
///
/// A conflict or a validation failure. Deliberately NOT retried automatically
/// and deliberately NOT given a fresh id: a 409 means this id already means
/// something else, and minting another behind the driver's back would hide
/// exactly the defect the idempotency contract exists to expose.
final class PublicationRefused extends PublicationState {
  const PublicationRefused(this.routeId, this.failure);

  final String routeId;
  final RmFailure failure;
}

/// The server has the journey. 201 and 200 both arrive here.
final class PublicationConfirmed extends PublicationState {
  const PublicationConfirmed(this.route);

  final PublishedRoute route;
}

final NotifierProvider<PublicationController, PublicationState>
publicationProvider = NotifierProvider<PublicationController, PublicationState>(
  PublicationController.new,
);

class PublicationController extends Notifier<PublicationState> {
  @override
  PublicationState build() => const PublicationIdle();

  /// The id of the attempt in progress or awaiting retry, and the draft it
  /// describes. Held together because one without the other cannot answer
  /// "is this still the same intention?".
  String? _attemptId;
  CreateRouteDraft? _attemptDraft;

  /// Visible for tests: the id a retry would reuse, if any.
  @visibleForTesting
  String? get pendingRouteId => _attemptId;

  /// Publishes the current draft, or joins the attempt already running.
  Future<void> publish() async {
    if (state is PublicationInFlight) {
      // A second tap is the same intention arriving twice. Starting another
      // request would mint another id and publish the journey twice.
      return;
    }

    final CreateRouteDraft draft = ref.read(createRouteDraftProvider);

    if (!draft.isComplete) return;

    final String routeId = _idFor(draft);
    state = PublicationInFlight(routeId);

    try {
      final PublishedRoute route = await ref
          .read(routeRepositoryProvider)
          .publish(RoutePublicationCommand(id: routeId, draft: draft));

      // 201 and 200 are indistinguishable by design: both mean the server has
      // this journey under this id.
      _attemptId = null;
      _attemptDraft = null;
      state = PublicationConfirmed(route);
    } on RmFailure catch (failure) {
      state = _isRetryable(failure)
          ? PublicationRetryable(routeId, failure)
          : PublicationRefused(routeId, failure);
    }
  }

  /// The id this intention should carry.
  ///
  /// The same one while the draft is unchanged — and CreateRouteDraft's
  /// equality is exactly the set of fields the server stores, because the
  /// draft holds no presentation state. So "the same journey" and "the same
  /// draft" are the same question.
  String _idFor(CreateRouteDraft draft) {
    final String? pending = _attemptId;

    if (pending != null && _attemptDraft == draft) return pending;

    final String minted = ref.read(uuidGeneratorProvider).v7();
    _attemptId = minted;
    _attemptDraft = draft;

    return minted;
  }

  /// Whether sending this exact request again could still change the answer.
  ///
  /// Retryable means the outcome is unknown, or a later attempt could
  /// legitimately succeed. Refused means the server has decided, and repeating
  /// the same bytes produces the same decision.
  ///
  /// CLASSIFIED BY STATUS, NOT BY CODE ALONE. A body this build cannot read
  /// and a 404 both arrive as [RmErrorCode.unexpected] — the code says only
  /// that the contract could not describe the answer — and they are opposites.
  /// An unreadable 201 may be a route that now exists; a 404 is the server
  /// saying no in a way repetition will not change. The status is what tells
  /// them apart, and RmApiClient preserves it on every path it can produce.
  bool _isRetryable(RmFailure failure) {
    // Nothing came back at all. The request may already have reached the
    // server, so the outcome is unknown rather than negative.
    if (failure.isTransport) return true;

    final int status = failure.status!;

    // The server accepted the publication and this build could not read the
    // answer. A route may exist under this id, which is exactly why the retry
    // has to carry the same one.
    if (status >= 200 && status < 300) return true;

    // The server broke. It never said anything about this journey.
    if (status >= 500) return true;

    // Come back later is an instruction to retry, not a refusal. 429 and
    // `rate_limited` are one and the same in the backend's error renderer.
    if (status == 429) return true;

    // Everything left is the server deciding: 400, 401, 403, 404, 405, 409,
    // 422. A 403 is a suspended account and would answer identically forever —
    // RmSession.send says so in as many words and refuses to retry it. A 401
    // has already survived Phase 9's single refresh-and-retry, so publication
    // is not the layer that recovers it: the session owns signing out and the
    // router owns where that lands. Retrying any of these would be an action
    // dressed up as hope.
    return false;
  }

  /// Returns to a state where the driver can edit and try again.
  ///
  /// Keeps the pending id: dismissing a message is not a change of intention.
  void acknowledge() {
    if (state is PublicationConfirmed) {
      _attemptId = null;
      _attemptDraft = null;
    }

    state = const PublicationIdle();
  }
}
