// ─────────────────────────────────────────────────────────────
// RideMate — the session
//
// Who is signed in, the credential that proves it, and what happens when the
// server stops accepting it.
//
// A plain class rather than a Riverpod notifier: every interesting behaviour
// here is asynchronous coordination — single-flight refresh, retry-once,
// fail-closed persistence — and those are far easier to hold correct when they
// can be driven directly by a test without a container. A provider wraps it.
//
// ROUTER POLICY IS NOT HERE. This exposes [state]; deciding what the app
// navigates to in response is a separate concern and a separate commit.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

import '../../app/error/rm_error_reporter.dart';
import '../api/rm_error_code.dart';
import '../api/rm_failure.dart';
import '../api/rm_response.dart';
import 'auth_api.dart';
import 'credential_store.dart';
import 'rm_credentials.dart';
import 'rm_token_pair.dart';

/// Why a member is signed out.
///
/// Transient and in memory only. None of this is written anywhere: a stored
/// "your session ended" would reappear after an unrelated restart, weeks later,
/// with no session to explain it.
enum RmSignedOutReason {
  /// A session that existed stopped working — the server refused the refresh
  /// token because it expired, was revoked, or was replayed.
  sessionEnded,

  /// The account is suspended. Kept apart from [sessionEnded] because signing
  /// in again is exactly what will not help.
  accountSuspended,
}

/// Whether there is a usable session.
///
/// "Refreshing" is deliberately not a case. A request in flight during a
/// rotation simply waits, and modelling it would invite UI that flickers
/// between signed-in and something else on every refresh.
///
/// [RmSessionUnresolved] is a different matter and is load-bearing: without it
/// the router cannot tell "not signed in" from "not looked yet", and a cold
/// start with a perfectly good stored credential would show a sign-in screen
/// for as long as the network took to answer.
@immutable
sealed class RmSessionState {
  const RmSessionState();
}

/// Startup, before the stored credential has been examined.
final class RmSessionUnresolved extends RmSessionState {
  const RmSessionUnresolved();
}

final class RmSignedOut extends RmSessionState {
  const RmSignedOut();
}

final class RmSignedIn extends RmSessionState {
  const RmSignedIn(this.sessionId);

  /// Identifies this device's session. Not a credential.
  final String sessionId;
}

/// Holds the session and performs authenticated work.
class RmSession {
  RmSession({required AuthApi api, required CredentialStore store})
    : _api = api,
      _store = store;

  final AuthApi _api;
  final CredentialStore _store;

  /// Starts UNRESOLVED, and that initial value is load-bearing.
  ///
  /// Signed-out would be a lie at launch: nothing has looked at the stored
  /// credential yet. The router reads this to decide between holding the
  /// startup surface and sending the member to sign in, so beginning
  /// signed-out makes it redirect to the sign-in screen for as long as
  /// restoration takes — a form that appears and vanishes on every cold start
  /// for anyone who is already signed in.
  final ValueNotifier<RmSessionState> _state = ValueNotifier<RmSessionState>(
    const RmSessionUnresolved(),
  );

  /// The access token, in memory and nowhere else.
  ///
  /// Not a field on any persisted type — see RmCredentials — so it cannot
  /// reach storage by being included in something that gets written.
  String? _accessToken;

  RmCredentials? _credentials;

  /// The single in-flight refresh, or null.
  ///
  /// This one field is the whole of single-flight. Without it, five requests
  /// that each hit a 401 would each call /auth/refresh with the same token —
  /// the first would rotate it and the other four would present a generation
  /// that had just been spent, which the backend treats as theft and answers
  /// by revoking the entire family. Concurrency on the client would look
  /// exactly like a stolen credential.
  Future<RmTokenPair>? _refreshing;

  /// Why the last sign-out happened, if it is worth telling the member.
  ///
  /// Transient and in memory only. A stored "your session ended" would
  /// reappear after an unrelated restart weeks later, with no session to
  /// explain it.
  RmSignedOutReason? _signedOutReason;

  /// Observed by the router in a later commit.
  ValueListenable<RmSessionState> get state => _state;

  bool get isSignedIn => _state.value is RmSignedIn;

  @visibleForTesting
  String? get accessTokenForTest => _accessToken;

  // ------------------------------------------------------------ sign-in

  /// Asks the backend to send a passcode.
  ///
  /// Throws [RmFailure] on refusal — a malformed number, or too many requests.
  Future<void> requestPasscode(String phone) => _api.requestPasscode(phone);

  /// Exchanges a passcode for a session.
  ///
  /// Throws [RmFailure]: `unauthenticated` for any passcode problem, and
  /// `forbidden` when the account is suspended. The two stay distinct because
  /// the member can act on one and not the other.
  Future<void> verifyPasscode({
    required String phone,
    required String code,
  }) async {
    final RmTokenPair pair = await _api.verifyPasscode(
      phone: phone,
      code: code,
    );

    if (!await _adopt(pair)) {
      throw const RmFailure.fromBackend(
        status: 200,
        code: RmErrorCode.unexpected,
      );
    }
  }

  // ------------------------------------------------------------ cold start

  /// Restores a stored session, if there is one that still works.
  ///
  /// Never throws: this runs during startup, where there is nobody to catch.
  /// It always ends signed in or signed out — never still unresolved, which
  /// would leave the router holding the launch surface forever.
  ///
  /// THE CREDENTIAL IS DELETED ONLY WHEN THE SERVER PROVES IT UNUSABLE.
  ///
  /// A timeout, a refused connection, a DNS failure or a 500 all mean the same
  /// thing: nothing was learned about the credential. Deleting it on that basis
  /// costs the member an SMS for opening the app in a tunnel, and the app had
  /// no evidence to justify it. Those outcomes sign this PROCESS out and leave
  /// the stored credential alone, so the next launch tries again.
  Future<void> restore() async {
    final RmCredentials? stored = await _store.read();

    if (stored == null) {
      await _forgetLocally();

      return;
    }

    _credentials = stored;

    try {
      await _refresh();
    } on RmFailure catch (failure, stack) {
      // Every outcome ends signed out. What differs is whether the credential
      // survives it.
      //
      // 401 and 403 were already handled inside _performRefresh, which cleared
      // the credential and recorded why. Reaching here for those means the
      // work is done; forgetting again would erase the reason.
      //
      // Everything else is INDETERMINATE — a timeout, a refused connection, a
      // 500, a rate limit. None of them says the credential is bad, and the
      // earlier version of this branch deleted it anyway. That turned a tunnel
      // into a re-authentication by SMS, on evidence the app never had.
      if (failure.code != RmErrorCode.unauthenticated &&
          failure.code != RmErrorCode.forbidden) {
        reportError(failure, stack, hint: 'restoring the session');
        _standDown();
      }
    }
  }

  // ------------------------------------------------------- authenticated work

  /// Runs an authenticated request, refreshing once if the token has expired.
  ///
  /// The caller supplies a closure taking headers rather than a path, so this
  /// class never needs to know about routes — and so the retry re-sends the
  /// caller's own request with a new token rather than an approximation of it.
  Future<RmResponse> send(
    Future<RmResponse> Function(Map<String, String> headers) request,
  ) async {
    final String? token = _accessToken;

    if (token == null) {
      throw const RmFailure.fromBackend(
        status: 401,
        code: RmErrorCode.unauthenticated,
      );
    }

    try {
      return await request(AuthApi.bearer(token));
    } on RmFailure catch (failure) {
      // Only an expired credential is worth retrying. A 403 is a decision
      // about the account and would produce the same answer forever.
      if (failure.status != 401) {
        rethrow;
      }
    }

    // Throws if refreshing fails, so a dead session surfaces as one failure
    // rather than a second, more confusing one from the retry.
    final RmTokenPair pair = await _refresh();

    // Exactly once. A retry that 401s again propagates: the alternative is a
    // loop that hammers the backend with a credential it has already refused.
    return request(AuthApi.bearer(pair.accessToken));
  }

  // ------------------------------------------------------------ sign-out

  /// Ends the session, server-side when possible and locally regardless.
  ///
  /// Local clearing is not conditional on the request succeeding. A member who
  /// asked to sign out on a train with no signal must not stay signed in on
  /// the device in front of them; the server session outlives it until its own
  /// expiry, which is the lesser of the two problems.
  Future<void> signOut() async {
    final String? token = _accessToken;

    if (token != null) {
      try {
        await _api.logout(token);
      } on RmFailure catch (failure, stack) {
        reportError(failure, stack, hint: 'revoking the session');
      }
    }

    // No reason. The member asked for this, and being told their session
    // ended would be the app explaining an event they caused.
    await _forgetLocally();
  }

  // ------------------------------------------------------------ internals

  Future<RmTokenPair> _refresh() {
    // Every concurrent caller receives this same future, so exactly one
    // request reaches /auth/refresh and every waiter sees the same outcome.
    return _refreshing ??= _performRefresh().whenComplete(() {
      _refreshing = null;
    });
  }

  Future<RmTokenPair> _performRefresh() async {
    final RmCredentials? credentials = _credentials;

    if (credentials == null) {
      await _forgetLocally();

      throw const RmFailure.fromBackend(
        status: 401,
        code: RmErrorCode.unauthenticated,
      );
    }

    final RmTokenPair pair;

    try {
      pair = await _api.refresh(credentials.refreshToken);
    } on RmFailure catch (failure) {
      // The server has refused the refresh token: it is spent, expired, or
      // its session was revoked. Keeping it would mean retrying a credential
      // that can only fail.
      // A session that existed has stopped working, which is the one case
      // worth telling the member about. A first launch never reaches here,
      // because there is no credential to refresh.
      if (failure.code == RmErrorCode.unauthenticated) {
        await _forgetLocally(RmSignedOutReason.sessionEnded);
      } else if (failure.code == RmErrorCode.forbidden) {
        await _forgetLocally(RmSignedOutReason.accountSuspended);
      }

      rethrow;
    }

    if (!await _adopt(pair)) {
      throw const RmFailure.fromBackend(
        status: 401,
        code: RmErrorCode.unauthenticated,
      );
    }

    return pair;
  }

  /// Takes on a new pair, persisting it before treating it as durable.
  ///
  /// FAIL CLOSED. The order matters and the failure path more so: rotation has
  /// already invalidated the previous refresh token server-side, so if the new
  /// one cannot be written the app is holding a session that works until the
  /// process ends and is unrecoverable afterwards. Continuing would sign the
  /// member out silently at the next launch, having spent a generation they
  /// can no longer present. Signing out now costs one passcode and is honest.
  Future<bool> _adopt(RmTokenPair pair) async {
    final RmCredentials credentials = RmCredentials(
      refreshToken: pair.refreshToken,
      sessionId: pair.sessionId,
    );

    if (!await _store.write(credentials)) {
      await _forgetLocally();

      return false;
    }

    _credentials = credentials;
    _accessToken = pair.accessToken;
    _signedOutReason = null;
    _state.value = RmSignedIn(pair.sessionId);

    return true;
  }

  /// Ends the session for THIS PROCESS without destroying the stored
  /// credential.
  ///
  /// The counterpart to [_forgetLocally], and the distinction is the whole
  /// point of this pair: one is used when the credential has been proven
  /// unusable or the member asked to leave, the other when the app simply
  /// could not find out. Synchronous because it touches no storage.
  void _standDown() {
    _accessToken = null;
    _credentials = null;
    _signedOutReason = null;
    _state.value = const RmSignedOut();
  }

  /// Ends the session AND deletes the stored credential.
  ///
  /// Reserved for the three cases that justify it: the server refused the
  /// credential, the member signed out, or a rotated credential could not be
  /// written durably.
  Future<void> _forgetLocally([RmSignedOutReason? reason]) async {
    _accessToken = null;
    _credentials = null;
    _signedOutReason = reason;
    await _store.clear();
    _state.value = const RmSignedOut();
  }

  /// Reads the reason once and forgets it.
  ///
  /// Consumed rather than observed, and deliberately NOT part of
  /// [RmSessionState]. Two reasons, and the second is not stylistic:
  ///
  /// The router only cares whether there is a session, so a reason on the
  /// state would be a field it re-evaluates and ignores. More importantly the
  /// screen consumes this from initState, and clearing an observed value there
  /// notifies the router's refresh listener DURING a build — which throws
  /// "setState() called during build" and takes the frame with it.
  ///
  /// A plain field has neither problem: reading it changes nothing anyone is
  /// watching.
  RmSignedOutReason? consumeSignedOutReason() {
    final RmSignedOutReason? reason = _signedOutReason;
    _signedOutReason = null;

    return reason;
  }
}
