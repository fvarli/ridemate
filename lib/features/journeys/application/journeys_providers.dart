// ─────────────────────────────────────────────────────────────
// RideMate — Dated journey access
//
// TWO PROVIDERS, BECAUSE THERE ARE TWO QUESTIONS
//
// `myJourneysProvider` is the driver's feed: which journeys can be acted on
// now. `journeyProvider` is one journey, read by its own identity, and is where
// the lifecycle commands live.
//
// They are not one provider with a filter. The feed is BOUNDED — today's
// journey of each published route that runs today, plus anything of theirs
// still under way — and a single journey is not: any day a route runs can be
// read, ahead or behind, started or not. A screen that selected its journey out
// of the feed would be a screen that says "not found" for every day the feed
// does not happen to carry, which is most of them.
//
// THE COMMANDS ARE KEYED BY JOURNEY, NOT BY ROUTE
//
// `journeyProvider` is a family over `(routeId, serviceDate)`, so starting
// Monday and starting Tuesday are two pieces of state that cannot be mistaken
// for one another — including while both are in flight. Keyed by route, the
// second tap would disable the first day's control and then write the second
// day's answer onto it.
//
// AND THE SCREEN HOLDS THE SUBSCRIPTION
//
// These are auto-disposed. A widget that reached for a notifier inside a
// callback, without watching it, would be asking a provider that is thrown away
// underneath the command it just started — the defect F2 found, and the reason
// every command below is run from a screen that watches the same family member
// it commands.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
// `AsyncNotifierProviderFamily` is the family's own type and lives here rather
// than in the main export. Named explicitly so the provider declares what it
// is, in the idiom every other provider in this app uses.
import 'package:flutter_riverpod/misc.dart';

import '../../../app/providers/api_client_provider.dart';
import '../../../app/providers/session_provider.dart';
import '../../../core/api/rm_failure.dart';
import '../../../core/api/rm_retry.dart';
import '../../../core/journeys/journey.dart';
import '../../../core/trips/trip_decoder.dart';
import '../../../core/trips/trip_lifecycle.dart';
import '../data/journeys_repository.dart';
import '../domain/journey_detail.dart';
import '../domain/my_journeys_page.dart';

final Provider<JourneysRepository> journeysRepositoryProvider =
    Provider<JourneysRepository>(
      (Ref ref) => ApiJourneysRepository(
        client: ref.watch(rmApiClientProvider),
        session: ref.watch(rmSessionProvider),
      ),
    );

/// The journeys this driver can act on, newest service date first.
///
/// Re-read on entry rather than cached across visits: its whole purpose is to
/// say what the server currently holds, and a stale feed is a driver looking at
/// a journey somebody already ended on another device.
final AsyncNotifierProvider<MyJourneysController, MyJourneysPage>
myJourneysProvider =
    AsyncNotifierProvider<MyJourneysController, MyJourneysPage>(
      MyJourneysController.new,
      isAutoDispose: true,
      retry: noAutomaticRetry,
    );

class MyJourneysController extends AsyncNotifier<MyJourneysPage> {
  @override
  Future<MyJourneysPage> build() async {
    final MyJourneysResult result = await ref
        .watch(journeysRepositoryProvider)
        .page(limit: kMyJourneysPageSize);

    return MyJourneysPage(
      journeys: result.journeys,
      nextCursor: result.nextCursor,
    );
  }

  /// Starts again from the newest journey.
  ///
  /// `invalidateSelf` rather than assigning state, in the My Routes idiom:
  /// re-running build is what produces the loading state, the request and the
  /// answer as one step, and it discards the old cursor by construction.
  void refresh() => ref.invalidateSelf();

  /// Fetches the page after the one already held.
  ///
  /// Existing journeys stay on screen throughout, including when this fails.
  Future<void> loadMore() async {
    final MyJourneysPage? page = state.value;

    if (page == null || !page.hasMore || page.isLoadingMore) return;

    // Sent back exactly as it arrived. Nothing here decodes, trims, validates
    // or compares it — it belongs to this feed and the server owns its meaning.
    final String cursor = page.nextCursor!;

    state = AsyncData<MyJourneysPage>(
      page.copyWith(isLoadingMore: true, clearLoadMoreFailure: true),
    );

    try {
      final MyJourneysResult result = await ref
          .read(journeysRepositoryProvider)
          .page(cursor: cursor, limit: kMyJourneysPageSize);

      final MyJourneysPage current = state.value ?? page;

      state = AsyncData<MyJourneysPage>(
        current.appended(result.journeys, result.nextCursor),
      );
    } on RmFailure catch (failure) {
      final MyJourneysPage current = state.value ?? page;

      state = AsyncData<MyJourneysPage>(
        current.copyWith(isLoadingMore: false, loadMoreFailure: failure),
      );
    }
  }

  /// Records, on the feed, a lifecycle a command has just returned.
  ///
  /// One journey, addressed by day. A journey the feed does not hold is left
  /// alone: this keeps what is on screen in step with what the server said, and
  /// it is not a way to add rows the server did not send.
  void recordTrip(JourneyRef ref_, TripLifecycle lifecycle) {
    final MyJourneysPage? page = state.value;

    if (page == null) return;

    state = AsyncData<MyJourneysPage>(page.withTripReplaced(ref_, lifecycle));
  }
}

/// One dated journey, read by its own identity.
///
/// `(routeId, serviceDate)` is the argument because it is the identity. There
/// is no `current`, no `today` and no `latest`: each would be this client
/// choosing a journey on the driver's behalf.
final AsyncNotifierProviderFamily<JourneyController, JourneyDetail, JourneyRef>
journeyProvider = AsyncNotifierProvider.family(
  JourneyController.new,
  isAutoDispose: true,
  retry: noAutomaticRetry,
);

class JourneyController extends AsyncNotifier<JourneyDetail> {
  JourneyController(this.target);

  /// Which journey this controller is for. Named `target` rather than `ref`
  /// because a notifier's `ref` is Riverpod's, and two `ref`s in one class is
  /// how the wrong one gets passed.
  final JourneyRef target;

  @override
  Future<JourneyDetail> build() async {
    final Journey journey = await ref
        .watch(journeysRepositoryProvider)
        .journey(routeId: target.routeId, serviceDate: target.serviceDate);

    return JourneyDetail(journey: journey);
  }

  void refresh() => ref.invalidateSelf();

  /// Says this journey is under way.
  Future<RmFailure?> start() => _command(
    (JourneysRepository repo) => repo.startTrip(
      routeId: target.routeId,
      serviceDate: target.serviceDate,
    ),
  );

  /// Says this journey was made.
  Future<RmFailure?> complete() => _command(
    (JourneysRepository repo) => repo.completeTrip(
      routeId: target.routeId,
      serviceDate: target.serviceDate,
    ),
  );

  /// Says this journey was abandoned.
  Future<RmFailure?> abort() => _command(
    (JourneysRepository repo) => repo.abortTrip(
      routeId: target.routeId,
      serviceDate: target.serviceDate,
    ),
  );

  /// One lifecycle command, and what it does to this screen.
  ///
  /// NEVER OPTIMISTIC, AND NEVER LOCAL
  ///
  /// The journey changes only after the server answers, and it changes to the
  /// lifecycle the server returned rather than to one assumed from which
  /// command was sent. Nothing here decides whether the command was allowed:
  /// whether the departure has been reached, whether the service date has
  /// passed, what today is in the route's timezone and whether a cancelled plan
  /// may still be ended are all the backend's, and it answers each by name.
  ///
  /// Returns the failure when there was one, in the My Routes idiom, so the
  /// caller can say so without this layer owning the copy.
  Future<RmFailure?> _command(
    Future<TripLifecycle> Function(JourneysRepository) command,
  ) async {
    final JourneyDetail? detail = state.value;

    // A repeated tap while this journey is already transitioning is the same
    // intention arriving twice. Nothing is queued, and the OTHER days of this
    // plan are untouched — they are different members of this family.
    if (detail == null || detail.isChangingTrip) return null;

    state = AsyncData<JourneyDetail>(detail.changing());

    try {
      final TripLifecycle trip = await command(
        ref.read(journeysRepositoryProvider),
      );

      state = AsyncData<JourneyDetail>(detail.withTrip(trip));

      // The feed shows the same journey when it happens to hold it, so it is
      // told the same answer rather than left to go stale behind this screen.
      // Exactly this day: the other days of the plan did not move.
      ref.read(myJourneysProvider.notifier).recordTrip(target, trip);

      return null;
    } on RmFailure catch (failure) {
      state = AsyncData<JourneyDetail>(detail.settled());

      // A journey the server says has already ended means this screen is
      // stale, not that the command was wrong. The ending is RE-READ rather
      // than built from the reason that named it: `already_completed` says
      // WHICH ending happened and nothing about WHEN, and a `completed_at`
      // invented here would be a timestamp no server ever sent.
      //
      // The other refusals are facts about the journey as it already is, so
      // nothing local changes for them.
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
}
