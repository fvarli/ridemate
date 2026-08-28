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
import '../data/route_repository.dart';
import '../domain/create_route_draft.dart';
import '../domain/published_route.dart';
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
      state = _isTerminal(failure)
          ? PublicationRefused(routeId, failure)
          : PublicationRetryable(routeId, failure);
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

  /// Whether repeating this request unchanged would be pointless.
  ///
  /// A conflict and a validation failure are answers, not accidents. Everything
  /// else — a timeout, a dropped connection, a 500, a body that would not
  /// decode — leaves the outcome unknown, and unknown means retry with the
  /// same id.
  bool _isTerminal(RmFailure failure) =>
      failure.code == RmErrorCode.conflict ||
      failure.code == RmErrorCode.validationFailed;

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
