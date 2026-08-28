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
import 'package:ridemate/core/session/rm_session.dart';
import 'package:ridemate/features/create_route/data/place_repository.dart';
import 'package:ridemate/features/create_route/data/route_repository.dart';
import 'package:ridemate/features/create_route/domain/create_route_draft.dart';
import 'package:ridemate/features/create_route/domain/published_route.dart';
import 'package:ridemate/features/onboarding/data/onboarding_repository.dart';

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
