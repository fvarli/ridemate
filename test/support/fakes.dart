// ─────────────────────────────────────────────────────────────
// RideMate — Test doubles
//
// These live in `test/` on purpose. Production ships no fake implementations;
// `architecture.md` forbids building them "so the architecture looks
// complete".
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ridemate/app/data/app_preferences_repository.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/api/rm_response.dart';
import 'package:ridemate/core/places/place.dart';
import 'package:ridemate/core/session/rm_session.dart';
import 'package:ridemate/features/create_route/data/place_repository.dart';
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
