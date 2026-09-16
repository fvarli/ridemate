// ─────────────────────────────────────────────────────────────
// RideMate — Test doubles
//
// These live in `test/` on purpose. Production ships no fake implementations;
// `architecture.md` forbids building them "so the architecture looks
// complete".
// ─────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ridemate/app/data/app_preferences_repository.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/api/rm_response.dart';
import 'package:ridemate/core/id/rm_uuid.dart';
import 'package:ridemate/core/places/place.dart';
import 'package:ridemate/core/profile/profile.dart';
import 'package:ridemate/core/reviews/review.dart';
import 'package:ridemate/core/reviews/review_decoder.dart';
import 'package:ridemate/core/routes/departure.dart';
import 'package:ridemate/core/routes/discovered_route.dart';
import 'package:ridemate/core/routes/my_route.dart';
import 'package:ridemate/core/routes/published_route.dart';
import 'package:ridemate/core/routes/ride_rule.dart';
import 'package:ridemate/core/routes/route_decoder.dart';
import 'package:ridemate/core/session/rm_session.dart';
import 'package:ridemate/core/trips/trip_decoder.dart';
import 'package:ridemate/core/trips/trip_lifecycle.dart';
import 'package:ridemate/features/create_route/data/place_repository.dart';
import 'package:ridemate/features/create_route/data/route_repository.dart';
import 'package:ridemate/features/create_route/domain/create_route_draft.dart';
import 'package:ridemate/features/discovery/application/discovery_search_providers.dart';
import 'package:ridemate/features/discovery/data/discovery_repository.dart';
import 'package:ridemate/features/my_routes/data/my_routes_repository.dart';
import 'package:ridemate/features/onboarding/data/onboarding_repository.dart';
import 'package:ridemate/features/profile/data/profile_repository.dart';
import 'package:ridemate/features/reviews/data/review_repository.dart';

/// In-memory [OnboardingRepository].
///
/// Records how many times the intro was marked complete, so a test can prove
/// an action did NOT touch persistence.
class InMemoryOnboardingRepository implements OnboardingRepository {
  InMemoryOnboardingRepository({bool seen = false}) : _seen = seen;

  bool _seen;

  /// How many times [markOnboardingSeen] was called.
  int markCallCount = 0;

  bool get seen => _seen;

  @override
  Future<bool> hasSeenOnboarding() async => _seen;

  @override
  Future<void> markOnboardingSeen() async {
    markCallCount++;
    _seen = true;
  }
}

/// An [AppPreferencesRepository] whose writes can be made to fail.
///
/// The in-memory repository in `lib/` is production degraded-mode behaviour,
/// not a double, so it cannot grow test affordances. This one wraps it to add
/// the two things a test needs: a failing store, and a record of what was
/// written.
class RecordingAppPreferencesRepository implements AppPreferencesRepository {
  RecordingAppPreferencesRepository({
    ThemeMode? themeMode,
    Locale? locale,
    this.failWrites = false,
  }) : _themeMode = themeMode,
       _locale = locale;

  /// When true, every write throws — the "storage is broken" case.
  final bool failWrites;

  ThemeMode? _themeMode;
  Locale? _locale;

  /// Every value handed to a write, in order, including failed attempts.
  final List<Object?> writes = <Object?>[];

  @override
  ThemeMode? themeMode() => _themeMode;

  @override
  Locale? locale() => _locale;

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    writes.add(mode);
    if (failWrites) throw StateError('preference store unavailable');
    _themeMode = mode;
  }

  @override
  Future<void> setLocale(Locale? locale) async {
    writes.add(locale);
    if (failWrites) throw StateError('preference store unavailable');
    _locale = locale;
  }
}

/// A session in a fixed state, for tests about everything except signing in.
///
/// The router now gates on session state, so every flow test that pumps the
/// application needs one — otherwise the redirect sends it to the sign-in
/// screen and the test asserts against a form. Signed in is the default,
/// because that is the state the rest of the product is designed for.
///
/// Implements [RmSession] rather than extending it: the real class talks to a
/// backend, and a fake that inherited any of that could reach one.
class FakeSession implements RmSession {
  FakeSession([RmSessionState initial = const RmSignedIn('SESSION_TEST')])
    : _state = ValueNotifier<RmSessionState>(initial);

  /// A signed-out session, optionally carrying why.
  factory FakeSession.signedOut([RmSignedOutReason? reason]) =>
      FakeSession(const RmSignedOut())..signedOutReason = reason;

  /// Startup, before restoration has resolved.
  factory FakeSession.unresolved() => FakeSession(const RmSessionUnresolved());

  final ValueNotifier<RmSessionState> _state;

  /// Mirrors the real session: a plain field, not part of the routed state.
  RmSignedOutReason? signedOutReason;

  /// Lets a test move the session mid-flight, which is how a revocation is
  /// simulated without a server.
  void become(RmSessionState next) => _state.value = next;

  @override
  ValueListenable<RmSessionState> get state => _state;

  @override
  bool get isSignedIn => _state.value is RmSignedIn;

  @override
  String? get accessTokenForTest => isSignedIn ? 'rma_FAKE' : null;

  @override
  RmSignedOutReason? consumeSignedOutReason() {
    final RmSignedOutReason? reason = signedOutReason;
    signedOutReason = null;

    return reason;
  }

  /// Ends the session the way a server revocation would.
  void endSession(RmSignedOutReason reason) {
    signedOutReason = reason;
    become(const RmSignedOut());
  }

  @override
  Future<void> restore() async {}

  @override
  Future<void> requestPasscode(String phone) async {}

  @override
  Future<void> verifyPasscode({
    required String phone,
    required String code,
  }) async => become(const RmSignedIn('SESSION_TEST'));

  @override
  Future<void> signOut() async {
    signedOutReason = null;
    become(const RmSignedOut());
  }

  @override
  Future<RmResponse> send(
    Future<RmResponse> Function(Map<String, String> headers) request,
  ) => request(<String, String>{'Authorization': 'Bearer rma_FAKE'});
}

/// A place catalogue that answers however a test needs it to.
///
/// Deliberately capable of failing. The Phase 10 invariant is that a failure
/// leaves the picker empty rather than falling back to fixtures, and that can
/// only be proven by a repository that actually refuses.
/// A profile endpoint a test can steer.
///
/// Defaults to a member who HAS a profile, because that is the state most tests
/// are not about: a signed-in app should reach its normal surfaces without every
/// unrelated test having to say so. Tests that care drive the other outcomes.
/// A discovery endpoint a test can steer.
///
/// Pages are consumed in order, so a test can describe a multi-page traversal
/// by listing what each request should answer.
class FakeDiscoveryRepository implements DiscoveryRepository {
  FakeDiscoveryRepository({List<DiscoveryResult>? pages, this.failure})
    : pages = pages ?? <DiscoveryResult>[];

  /// A search that fails the way an unreachable backend does.
  factory FakeDiscoveryRepository.offline() =>
      FakeDiscoveryRepository(failure: const RmFailure.transport());

  List<DiscoveryResult> pages;
  RmFailure? failure;

  int callCount = 0;
  final List<String?> cursors = <String?>[];

  @override
  Future<DiscoveryResult> between({
    required String originPlaceId,
    required String destinationPlaceId,
    String? cursor,
    int limit = kDiscoveryPageSize,
  }) async {
    callCount++;
    cursors.add(cursor);

    final RmFailure? failure = this.failure;
    if (failure != null) throw failure;

    return pages.isEmpty
        ? const DiscoveryResult(routes: <DiscoveredRoute>[], nextCursor: null)
        : pages.removeAt(0);
  }
}

/// A query controller that starts already searched, for screens that assume a
/// search has happened.
class SearchedQueryController extends DiscoveryQueryController {
  @override
  DiscoveryQuery? build() =>
      const DiscoveryQuery(originPlaceId: 'p1', destinationPlaceId: 'p2');
}

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({Profile? profile, this.readError})
    : profile =
          profile ?? const Profile(displayName: 'Ayşe Demir', initials: 'AD');

  /// A member who has not chosen a name yet.
  factory FakeProfileRepository.missing() =>
      FakeProfileRepository(readError: const ProfileNotFound());

  /// A read that fails the way an unreachable backend does.
  factory FakeProfileRepository.offline() =>
      FakeProfileRepository(readError: const RmFailure.transport());

  Profile profile;
  Object? readError;
  Object? saveError;

  int readCount = 0;
  int saveCount = 0;
  final List<String> saved = <String>[];

  @override
  Future<Profile> read() async {
    readCount++;

    final Object? error = readError;
    if (error != null) throw error;

    return profile;
  }

  @override
  Future<Profile> save(String displayName) async {
    saveCount++;
    saved.add(displayName);

    final Object? error = saveError;
    if (error != null) throw error;

    // The server trims and derives the initials; this mirrors that so a test
    // can tell the server's answer from the input.
    profile = Profile(displayName: displayName.trim(), initials: 'SV');
    readError = null;

    return profile;
  }
}

class FakePlaceRepository implements PlaceRepository {
  FakePlaceRepository({List<Place>? places, this.failure})
    : places = places ?? kFakePlaces;

  /// Fails every call with a transport error, the way an unreachable backend
  /// does.
  factory FakePlaceRepository.offline() =>
      FakePlaceRepository(failure: const RmFailure.transport());

  List<Place> places;
  RmFailure? failure;

  int callCount = 0;

  @override
  Future<List<Place>> catalogue() async {
    callCount++;
    final RmFailure? failure = this.failure;
    if (failure != null) throw failure;

    return places;
  }
}

/// Places shaped like the server's: opaque ids, and labels that appear in no
/// fixture. If one of these turns up in a test that expected a failure, the
/// catalogue was read; if a MockPlaces label turns up, something fell back.
const List<Place> kFakePlaces = <Place>[
  Place(id: '01991a00-0000-7000-8000-000000000001', label: 'Sunucu Yeri Bir'),
  Place(id: '01991a00-0000-7000-8000-000000000002', label: 'Sunucu Yeri İki'),
  Place(id: '01991a00-0000-7000-8000-000000000003', label: 'Sunucu Yeri Üç'),
];

/// A publication endpoint a test can steer.
///
/// It records every command it receives, so a test can prove that a retry
/// carried the SAME id — which is the whole point of the client minting one.
class FakeRouteRepository implements RouteRepository {
  FakeRouteRepository({this.failure});

  /// Fails as an unreachable backend does: the outcome is unknown, so the id
  /// must survive for the retry.
  factory FakeRouteRepository.offline() =>
      FakeRouteRepository(failure: const RmFailure.transport());

  /// Set to make the next call fail; clear it to let the next one succeed.
  RmFailure? failure;

  /// Every command, in order.
  final List<RoutePublicationCommand> commands = <RoutePublicationCommand>[];

  List<String> get routeIds => <String>[
    for (final RoutePublicationCommand c in commands) c.id,
  ];

  int get callCount => commands.length;

  /// The body that actually went out, as the repository would have sent it.
  Map<String, Object?> get lastBody => commands.last.toJson();

  Completer<void>? _gate;

  /// Holds every request open until [release], the way a real network does.
  ///
  /// Without this the fake answers within a microtask, and a test about what
  /// happens WHILE a request is in flight would have no in-flight to observe —
  /// which would quietly turn the double-submit guard into an untested claim.
  void hold() => _gate ??= Completer<void>();

  /// Lets the held requests finish.
  void release() {
    _gate?.complete();
    _gate = null;
  }

  @override
  Future<PublishedRoute> publish(RoutePublicationCommand command) async {
    commands.add(command);

    await _gate?.future;

    final RmFailure? failure = this.failure;
    if (failure != null) throw failure;

    return publishedRouteFrom(command);
  }
}

/// A route shaped the way the server returns one.
PublishedRoute publishedRouteFrom(RoutePublicationCommand command) {
  final CreateRouteDraft draft = command.draft;

  return PublishedRoute(
    id: command.id,
    origin: draft.origin!,
    destination: draft.destination!,
    recurrence: draft.recurrence,
    departureDate: draft.departureDate,
    departureTime: draft.departureTime!,
    // Server-owned, and the client never computes either of these.
    timezone: 'Europe/Istanbul',
    departureState: DepartureState.upcoming,
    seatsOffered: draft.seats,
    rules: draft.rules,
    status: RouteStatus.published,
    publishedAt: '2026-08-28T09:41:00+00:00',
    cancelledAt: null,
  );
}

/// Hands out ids a test can predict, so "the same id" is provable.
class FakeUuidGenerator implements RmUuidGenerator {
  FakeUuidGenerator();

  int _next = 0;
  final List<String> minted = <String>[];

  @override
  String v7() {
    // Shaped like a real v7 — version nibble 7, variant 8 — so anything that
    // validates the version still accepts it.
    final String id =
        '01991b00-0000-7000-8000-${_next.toString().padLeft(12, '0')}';
    _next++;
    minted.add(id);

    return id;
  }
}

/// A My Routes endpoint a test can steer, page by page.
///
/// Answers BY CURSOR, not by call count. A real server does the same, and it
/// matters here: Riverpod retries a failed provider on its own, so a fake that
/// served "the next page in a list" would hand out page two because of a retry
/// nobody asked for. Keyed by cursor, a repeated request simply returns the
/// same page — which is exactly what a keyset endpoint does.
///
/// Records every cursor it was handed, which is how "the token went back
/// exactly as it arrived" becomes provable rather than assumed.
class FakeMyRoutesRepository implements MyRoutesRepository {
  FakeMyRoutesRepository({List<MyRoutesResult>? pages, this.failure}) {
    chain(pages ?? <MyRoutesResult>[]);
  }

  /// Fails every call the way an unreachable backend does.
  factory FakeMyRoutesRepository.offline() =>
      FakeMyRoutesRepository(failure: const RmFailure.transport());

  /// Pages keyed by the cursor that asks for them; the first is keyed null.
  final Map<String?, MyRoutesResult> pages = <String?, MyRoutesResult>{};

  /// Links [pages] together: the first answers no cursor, and each subsequent
  /// one answers the cursor its predecessor returned.
  void chain(List<MyRoutesResult> ordered) {
    pages.clear();

    String? key;
    for (final MyRoutesResult page in ordered) {
      pages[key] = page;
      key = page.nextCursor;
    }
  }

  /// Set to make calls fail; clear it to let them succeed.
  RmFailure? failure;

  /// What cancel answers with, when it is allowed to answer.
  PublishedRoute? cancelResult;
  RmFailure? cancelFailure;

  /// Every cursor handed to [page], in order. The first is null.
  final List<String?> cursors = <String?>[];

  /// Every limit asked for.
  final List<int> limits = <int>[];

  /// Every route id handed to [cancel].
  final List<String> cancelled = <String>[];

  /// What the lifecycle commands answer with, when they are allowed to answer.
  TripLifecycle? tripResult;
  RmFailure? tripFailure;

  /// Every lifecycle command sent, as `'<verb> <routeId>'` in order.
  final List<String> tripCommands = <String>[];

  int get callCount => cursors.length;

  Completer<void>? _gate;

  /// Holds every request open until [release], the way a real network does.
  void hold() => _gate ??= Completer<void>();

  void release() {
    _gate?.complete();
    _gate = null;
  }

  @override
  Future<MyRoutesResult> page({String? cursor, int limit = 20}) async {
    cursors.add(cursor);
    limits.add(limit);

    await _gate?.future;

    final RmFailure? failure = this.failure;
    if (failure != null) throw failure;

    final MyRoutesResult? page = pages[cursor];
    if (page == null) {
      throw StateError('no page scripted for cursor $cursor');
    }

    return page;
  }

  @override
  Future<PublishedRoute> cancel(String routeId) async {
    cancelled.add(routeId);

    await _gate?.future;

    final RmFailure? failure = cancelFailure;
    if (failure != null) throw failure;

    return cancelResult ??
        fakeRoute(id: routeId, status: RouteStatus.cancelled);
  }

  @override
  Future<TripLifecycle> startTrip(String routeId) =>
      _trip('start', routeId, TripState.inProgress);

  @override
  Future<TripLifecycle> completeTrip(String routeId) =>
      _trip('complete', routeId, TripState.completed);

  @override
  Future<TripLifecycle> abortTrip(String routeId) =>
      _trip('abort', routeId, TripState.aborted);

  Future<TripLifecycle> _trip(
    String verb,
    String routeId,
    TripState reached,
  ) async {
    tripCommands.add('$verb $routeId');

    await _gate?.future;

    final RmFailure? failure = tripFailure;
    if (failure != null) throw failure;

    return tripResult ??
        fakeTrip(
          state: reached,
          startedAt: '2026-09-11T07:05:00Z',
          completedAt: reached == TripState.completed
              ? '2026-09-11T07:45:00Z'
              : null,
          abortedAt: reached == TripState.aborted
              ? '2026-09-11T07:45:00Z'
              : null,
        );
  }
}

/// A route shaped exactly as the server sends one.
///
/// Built through the real decoder rather than by calling the constructor, so a
/// test double can never be a shape the API could not actually produce.
PublishedRoute fakeRoute({
  String id = '01991b00-0000-7000-8000-000000000001',
  String originLabel = 'Sunucu Yeri Bir',
  String destinationLabel = 'Sunucu Yeri İki',
  Recurrence recurrence = Recurrence.weekdays,
  String? departureDate,
  String departureTime = '08:25',
  DepartureState departureState = DepartureState.upcoming,
  int seatsOffered = 3,
  Set<RideRuleId> rules = const <RideRuleId>{RideRuleId.noSmoking},
  RouteStatus status = RouteStatus.published,
  String? cancelledAt,
}) => RouteDecoder.route(
  fakeRouteJson(
    id: id,
    originLabel: originLabel,
    destinationLabel: destinationLabel,
    recurrence: recurrence,
    departureDate: departureDate,
    departureTime: departureTime,
    departureState: departureState,
    seatsOffered: seatsOffered,
    rules: rules,
    status: status,
    cancelledAt: cancelledAt,
  ),
  200,
);

/// The wire object a route arrives as.
///
/// Shared by [fakeRoute] and [fakeMyRoute] so the two projections cannot drift
/// apart in a fixture the way they must not drift apart on the wire.
Map<String, Object?> fakeRouteJson({
  String id = '01991b00-0000-7000-8000-000000000001',
  String originLabel = 'Sunucu Yeri Bir',
  String destinationLabel = 'Sunucu Yeri İki',
  Recurrence recurrence = Recurrence.weekdays,
  String? departureDate,
  String departureTime = '08:25',
  DepartureState departureState = DepartureState.upcoming,
  int seatsOffered = 3,
  Set<RideRuleId> rules = const <RideRuleId>{RideRuleId.noSmoking},
  RouteStatus status = RouteStatus.published,
  String? cancelledAt,
}) => <String, Object?>{
  'id': id,
  'origin': <String, Object?>{
    'id': '01991a00-0000-7000-8000-00000000000a',
    'label': originLabel,
  },
  'destination': <String, Object?>{
    'id': '01991a00-0000-7000-8000-00000000000b',
    'label': destinationLabel,
  },
  'recurrence': recurrence.name,
  'departure_date': departureDate,
  'departure_time': departureTime,
  'timezone': 'Europe/Istanbul',
  'departure_state': departureState.name,
  'seats_offered': seatsOffered,
  'rules': rideRulesToJson(rules),
  'status': status.name,
  'published_at': '2026-08-28T09:41:00+00:00',
  'cancelled_at': cancelledAt,
};

/// The `trip` object, exactly as the backend sends it.
///
/// All three timestamps are always present; the ones that have not happened are
/// null. A fixture that omitted a key would be a shape the API never produces.
Map<String, Object?> fakeTripJson({
  TripState state = TripState.notStarted,
  String? startedAt,
  String? completedAt,
  String? abortedAt,
}) => <String, Object?>{
  'state': state.wire,
  'started_at': startedAt,
  'completed_at': completedAt,
  'aborted_at': abortedAt,
};

/// The lifecycle, through the real decoder.
TripLifecycle fakeTrip({
  TripState state = TripState.notStarted,
  String? startedAt,
  String? completedAt,
  String? abortedAt,
}) => TripDecoder.lifecycle(
  fakeTripJson(
    state: state,
    startedAt: startedAt,
    completedAt: completedAt,
    abortedAt: abortedAt,
  ),
  200,
);

/// A route as its own member sees it: the journey plus whether it was made.
///
/// Decoder-backed like [fakeRoute], so a row here is always a shape
/// `GET /me/routes` could actually return — `trip` included, which that
/// endpoint always sends and publication never does.
MyRoute fakeMyRoute({
  String id = '01991b00-0000-7000-8000-000000000001',
  String originLabel = 'Sunucu Yeri Bir',
  String destinationLabel = 'Sunucu Yeri İki',
  Recurrence recurrence = Recurrence.weekdays,
  String? departureDate,
  String departureTime = '08:25',
  DepartureState departureState = DepartureState.upcoming,
  int seatsOffered = 3,
  Set<RideRuleId> rules = const <RideRuleId>{RideRuleId.noSmoking},
  RouteStatus status = RouteStatus.published,
  String? cancelledAt,

  /// Null builds the plan shape: `"trip": null`, which the backend sends for
  /// every recurring route and which is NOT `not_started`.
  TripState? trip = TripState.notStarted,
  String? startedAt,
  String? completedAt,
  String? abortedAt,
}) => RouteDecoder.myRoute(<String, Object?>{
  ...fakeRouteJson(
    id: id,
    originLabel: originLabel,
    destinationLabel: destinationLabel,
    recurrence: recurrence,
    departureDate: departureDate,
    departureTime: departureTime,
    departureState: departureState,
    seatsOffered: seatsOffered,
    rules: rules,
    status: status,
    cancelledAt: cancelledAt,
  ),
  'trip': trip == null
      ? null
      : fakeTripJson(
          state: trip,
          startedAt: startedAt,
          completedAt: completedAt,
          abortedAt: abortedAt,
        ),
}, 200);

/// The wire object one of a member's own askings arrives as.
///
/// `my_review` is required on this projection and may be null — absent is
/// drift, not an unreviewed relationship.
Map<String, Object?> fakeMySeatRequestJson({
  String id = '01991d00-0000-7000-8000-000000000001',
  String serviceDate = '2026-09-24',
  String status = 'accepted',
  Map<String, Object?>? myReview,
}) => <String, Object?>{
  'id': id,
  'service_date': serviceDate,
  'status': status,
  'requested_at': '2026-09-10T08:00:00Z',
  'decided_at': '2026-09-10T09:00:00Z',
  'withdrawn_at': null,
  'my_review': myReview,
  'route': <String, Object?>{
    ...fakeRouteJson(recurrence: Recurrence.once, departureDate: '2026-09-24'),
    'driver': <String, Object?>{
      'display_name': 'İrem Yılmaz',
      'initials': 'İY',
    },
    'trip': fakeTripJson(),
  },
};

/// The wire object one asking on the caller's own journey arrives as.
Map<String, Object?> fakeIncomingSeatRequestJson({
  String id = '01991d00-0000-7000-8000-000000000001',
  String serviceDate = '2026-09-24',
  String status = 'accepted',
  Map<String, Object?>? myReview,
}) => <String, Object?>{
  'id': id,
  'service_date': serviceDate,
  'status': status,
  'requested_at': '2026-09-10T08:00:00Z',
  'decided_at': '2026-09-10T09:00:00Z',
  'withdrawn_at': null,
  'passenger': <String, Object?>{
    'display_name': 'Ayşe Demir',
    'initials': 'AD',
  },
  'my_review': myReview,
};

/// The `review` object a submission response carries.
Map<String, Object?> fakeReviewJson({
  String id = '01993a00-0000-7000-8000-000000000001',
  int rating = 5,
  String submittedAt = '2026-09-25T09:14:00Z',
}) => <String, Object?>{
  'id': id,
  'rating': rating,
  'submitted_at': submittedAt,
};

/// One released review about the caller, as the feed sends it.
Map<String, Object?> fakeReceivedReviewJson({
  String id = '01993a00-0000-7000-8000-000000000001',
  int rating = 5,
  String role = 'driver',
  String displayName = 'İrem Yılmaz',
  String initials = 'İY',
}) => <String, Object?>{
  ...fakeReviewJson(id: id, rating: rating),
  'reviewer': <String, Object?>{
    'display_name': displayName,
    'initials': initials,
    'role': role,
  },
  'journey': <String, Object?>{
    'origin': 'Kadıköy, Vapur İskelesi',
    'destination': 'Levent, Metro İstasyonu',
    'departure_date': '2026-09-24',
    'departure_time': '08:25',
  },
};

/// A discovered route shaped exactly as the discovery endpoint sends one.
///
/// Decoder-backed for the same reason [fakeRoute] is: a double that skipped the
/// decoder could carry a shape the API cannot produce. The fields are the whole
/// of what the endpoint returns — there is deliberately no rating, badge, trip
/// count, trust score or cost to pass, because none of them exists on the wire.
DiscoveredRoute fakeDiscoveredRoute({
  String id = '01991c00-0000-7000-8000-000000000001',
  String originId = '01991a00-0000-7000-8000-00000000000a',
  String originLabel = 'Sunucu Yeri Bir',
  String destinationId = '01991a00-0000-7000-8000-00000000000b',
  String destinationLabel = 'Sunucu Yeri İki',
  Recurrence recurrence = Recurrence.weekdays,
  String? departureDate,
  String departureTime = '08:25',
  DepartureState departureState = DepartureState.upcoming,
  int seatsOffered = 3,
  Set<RideRuleId> rules = const <RideRuleId>{RideRuleId.noSmoking},
  String displayName = 'Ayşe Demir',
  String initials = 'AD',

  /// The days the SERVER says may be asked about — never derived from the
  /// fixture's other fields, because the client never derives them either.
  List<String> requestableServiceDates = const <String>['2026-09-14'],
  List<Map<String, Object?>> mySeatRequests = const <Map<String, Object?>>[],
}) => RouteDecoder.discovered(<String, Object?>{
  'id': id,
  'origin': <String, Object?>{'id': originId, 'label': originLabel},
  'destination': <String, Object?>{
    'id': destinationId,
    'label': destinationLabel,
  },
  'recurrence': recurrence.name,
  'departure_date': departureDate,
  'departure_time': departureTime,
  'timezone': 'Europe/Istanbul',
  'departure_state': departureState.name,
  'seats_offered': seatsOffered,
  'rules': rideRulesToJson(rules),
  'driver': <String, Object?>{
    'display_name': displayName,
    'initials': initials,
  },
  // Required on the wire and possibly empty. Server-derived: which of this
  // route's journeys may be asked about now, identical for every viewer.
  'requestable_service_dates': requestableServiceDates,
  // Required on the wire and possibly empty, which is the ordinary case.
  'my_seat_requests': mySeatRequests,
}, 200);

/// One entry of a discovered route's `my_seat_requests`.
///
/// The service date is required: an asking is always for one journey, so a
/// fixture without one would be a shape the API never produces.
Map<String, Object?> fakeMySeatRequestSummaryJson({
  String serviceDate = '2026-09-24',
  String id = '01991d00-0000-7000-8000-000000000001',
  String status = 'pending',
}) => <String, Object?>{
  'service_date': serviceDate,
  'id': id,
  'status': status,
};

/// A scripted [ReviewRepository], in the [FakeMyRoutesRepository] idiom.
///
/// Pages keyed by the cursor that asks for them, so a test says what the server
/// would answer rather than how many times it was called — and so a cursor the
/// controller invented instead of echoing back fails loudly with a
/// `StateError` rather than quietly returning the first page again.
class FakeReviewRepository implements ReviewRepository {
  FakeReviewRepository({List<MyReviewsResult>? pages, this.failure}) {
    chain(pages ?? <MyReviewsResult>[]);
  }

  /// Fails every call the way an unreachable backend does.
  factory FakeReviewRepository.offline() =>
      FakeReviewRepository(failure: const RmFailure.transport());

  /// One page holding nothing and offering no position — what the backend
  /// answers a member nothing has been released about.
  factory FakeReviewRepository.empty() => FakeReviewRepository(
    pages: <MyReviewsResult>[
      const MyReviewsResult(reviews: <ReceivedReview>[], nextCursor: null),
    ],
  );

  /// Pages keyed by the cursor that asks for them; the first is keyed null.
  final Map<String?, MyReviewsResult> pages = <String?, MyReviewsResult>{};

  /// Links [pages] together: the first answers no cursor, and each subsequent
  /// one answers the cursor its predecessor returned.
  void chain(List<MyReviewsResult> ordered) {
    pages.clear();

    String? key;
    for (final MyReviewsResult page in ordered) {
      pages[key] = page;
      key = page.nextCursor;
    }
  }

  /// Set to make reads fail; clear it to let them succeed.
  RmFailure? failure;

  /// Every cursor handed to [mine], in order. The first is null.
  final List<String?> cursors = <String?>[];

  /// Every limit asked for.
  final List<int> limits = <int>[];

  int get callCount => cursors.length;

  /// What submitting answers with. F3 touches no command; this exists so the
  /// one fake can stand in for the whole interface.
  MyReview? submitResult;
  RmFailure? submitFailure;

  Completer<void>? _gate;

  /// Holds every request open until [release], the way a real network does.
  void hold() => _gate ??= Completer<void>();

  void release() {
    _gate?.complete();
    _gate = null;
  }

  @override
  Future<MyReviewsResult> mine({String? cursor, int limit = 20}) async {
    cursors.add(cursor);
    limits.add(limit);

    await _gate?.future;

    final RmFailure? failure = this.failure;
    if (failure != null) throw failure;

    final MyReviewsResult? page = pages[cursor];
    if (page == null) {
      throw StateError('no page scripted for cursor $cursor');
    }

    return page;
  }

  @override
  Future<MyReview> submitReview({
    required String requestId,
    required String reviewId,
    required int rating,
  }) async {
    final RmFailure? failure = submitFailure;
    if (failure != null) throw failure;

    final MyReview? result = submitResult;
    if (result == null) throw StateError('no submit result scripted');

    return result;
  }
}

/// A released review, built from the wire shape so the decoder stays in the
/// loop: a fake constructed field by field would keep passing after the server
/// changed a key.
ReceivedReview fakeReceivedReview({
  String id = '01993a00-0000-7000-8000-000000000001',
  int rating = 5,
  String role = 'driver',
  String displayName = 'İrem Yılmaz',
  String initials = 'İY',
  String origin = 'Kadıköy, Vapur İskelesi',
  String destination = 'Levent, Metro İstasyonu',
  String departureDate = '2026-09-24',
  String departureTime = '08:25',
}) => ReviewDecoder.received(<String, Object?>{
  ...fakeReceivedReviewJson(
    id: id,
    rating: rating,
    role: role,
    displayName: displayName,
    initials: initials,
  ),
  'journey': <String, Object?>{
    'origin': origin,
    'destination': destination,
    'departure_date': departureDate,
    'departure_time': departureTime,
  },
}, 200);
