// ─────────────────────────────────────────────────────────────
// RideMate — What the router is allowed to know about the profile
//
// WHY ANYTHING SITS BETWEEN THE ROUTER AND THE PROVIDER AT ALL
//
// `redirect` runs on every navigation, and it must be a pure decision: read
// some state, return a destination. `myProfileProvider` is auto-dispose, so
// reading it from inside a redirect would CREATE it, start a request, dispose
// it when nothing kept it alive, and start another on the next redirect —
// a request storm and a redirect loop from one innocent-looking line.
//
// So this gate owns the subscription and the router reads a value. The I/O
// happens here, once, outside the redirect; the redirect only ever looks at
// [state].
//
// AND WHY THE SUBSCRIPTION IS CONDITIONAL
//
// A profile belongs to a signed-in member. Subscribing before sign-in would
// send a request with no credential, land the provider in an error state, and
// leave it there — so the member who then signed in would never be routed to
// setup, because the answer had already been decided by a request that never
// had a chance. The gate therefore opens its subscription when the session
// becomes RmSignedIn and closes it when it stops being.
//
// It reads the session and never writes it. Signing out is Phase 9's, and a
// profile that will not load is not a reason to take a member's credential
// away.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/rm_session.dart';
import 'my_profile_providers.dart';

/// The only thing the router asks about a profile.
///
/// Four cases, because collapsing any two of them produces a real defect:
/// treating [undecided] as [missing] flashes a setup screen at somebody who
/// has a name, and treating [unavailable] as [missing] asks them to choose a
/// second one because the network was down.
enum ProfileGateState {
  /// Nobody is signed in, or the read has not answered yet. Decide nothing.
  undecided,

  /// The server said this member has no profile. Setup is required.
  missing,

  /// The member has a profile.
  ready,

  /// The read failed. Routing must not act on it — see [ProfileGate].
  unavailable,
}

/// Bridges the profile provider to the router.
///
/// A [ChangeNotifier] because that is what `GoRouter.refreshListenable` takes,
/// and because the router already merges one for onboarding — this is the same
/// shape, kept separate so the two dimensions stay independent.
class ProfileGate extends ChangeNotifier {
  ProfileGate({required Ref ref, required RmSession session})
    : _ref = ref,
      _session = session {
    _session.state.addListener(_onSessionChanged);
    _onSessionChanged();
  }

  final Ref _ref;
  final RmSession _session;

  ProviderSubscription<AsyncValue<ProfileState>>? _subscription;
  ProfileGateState _state = ProfileGateState.undecided;

  /// What the router should act on. Synchronous, and never triggers a request.
  ProfileGateState get state => _state;

  /// Opens or closes the subscription to follow the session.
  ///
  /// Closing on sign-out matters as much as opening on sign-in: a held
  /// subscription would keep one member's profile alive across a sign-out, and
  /// the next member to sign in on the device would be routed by it.
  void _onSessionChanged() {
    if (_session.state.value is RmSignedIn) {
      _open();
    } else {
      _close();
    }
  }

  void _open() {
    if (_subscription != null) return;

    // `fireImmediately` delivers the current value — AsyncLoading on the first
    // open, which maps to `undecided` and holds the launch surface rather than
    // guessing.
    _subscription = _ref.listen<AsyncValue<ProfileState>>(
      myProfileProvider,
      (AsyncValue<ProfileState>? _, AsyncValue<ProfileState> next) =>
          _adopt(_classify(next)),
      fireImmediately: true,
    );
  }

  void _close() {
    _subscription?.close();
    _subscription = null;
    _adopt(ProfileGateState.undecided);
  }

  void _adopt(ProfileGateState next) {
    if (_state == next) return;

    _state = next;
    notifyListeners();
  }

  /// The provider's three outcomes, mapped onto the router's four.
  ///
  /// `hasError` is tested before `isLoading` for the reason the read surfaces
  /// already test it that way: a failed build carries its error while still
  /// reporting loading, and matching loading first would leave the gate
  /// undecided for ever on a failure.
  static ProfileGateState _classify(AsyncValue<ProfileState> value) =>
      switch (value) {
        AsyncValue<ProfileState>(hasError: true) =>
          ProfileGateState.unavailable,
        AsyncValue<ProfileState>(:final ProfileState? value)
            when value != null =>
          switch (value) {
            ProfileReady() => ProfileGateState.ready,
            ProfileMissing() => ProfileGateState.missing,
          },
        _ => ProfileGateState.undecided,
      };

  @override
  void dispose() {
    _session.state.removeListener(_onSessionChanged);
    _subscription?.close();
    _subscription = null;
    super.dispose();
  }
}
