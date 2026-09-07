// ─────────────────────────────────────────────────────────────
// RideMate — The member's own profile, as the server holds it
//
// MISSING IS NOT THE SAME AS UNAVAILABLE
//
// This is the distinction the whole feature turns on. A 404 means the member
// has genuinely not chosen a name yet, and the app must take them to setup. A
// timeout, a 500 or an unreadable body mean the app does not KNOW, and sending
// somebody to a setup screen on that basis would ask a member who already has a
// profile to invent a second one — while the server, when it came back, would
// answer 201 or 200 for a name they never meant to change.
//
// So the two never share a type: [ProfileNotFound] is thrown only for a 404, and
// every other failure stays an ordinary [RmFailure]. Nothing here catches one
// and re-throws the other.
//
// AND NEITHER OF THEM IS A SIGN-OUT
//
// Failing to read a profile says nothing about the credential that read it.
// Phase 9 owns session recovery: RmSession.send refreshes once and retries once
// inside a single call here, and if it still fails that is a failure to report,
// not a reason to discard a member's session. Nothing in this file touches
// RmSession's state.
// ─────────────────────────────────────────────────────────────

import '../../../core/api/rm_api_client.dart';
import '../../../core/api/rm_error_code.dart';
import '../../../core/api/rm_failure.dart';
import '../../../core/api/rm_response.dart';
import '../../../core/profile/profile.dart';
import '../../../core/session/rm_session.dart';

/// The server said, definitively, that this member has no profile.
///
/// Deliberately its own type rather than an [RmFailure] carrying a 404. A
/// caller writing a general failure branch must not be able to absorb this by
/// accident: "has not chosen a name" is a product state, not an error, and it
/// leads somewhere completely different from every other outcome. The state
/// layer turns it into [ProfileMissing]; nothing turns it into an error.
final class ProfileNotFound implements Exception {
  const ProfileNotFound();

  @override
  String toString() => 'ProfileNotFound';
}

/// Reads and writes the signed-in member's own profile.
abstract interface class ProfileRepository {
  /// The member's profile.
  ///
  /// Throws [ProfileNotFound] when the server answers 404, and [RmFailure] for
  /// everything else — transport, server, or a body that will not decode.
  Future<Profile> read();

  /// Sets the profile to say [displayName].
  ///
  /// A target-state write: sending the same name twice leaves the same profile,
  /// so a retry after an indeterminate failure is safe and carries no key. The
  /// server answers 201 the first time and 200 afterwards; both decode to the
  /// same shape, and this returns what the server stored rather than what was
  /// sent — trimming happens there.
  ///
  /// Throws [RmFailure]. Never [ProfileNotFound]: a write cannot find nothing,
  /// because it creates.
  Future<Profile> save(String displayName);
}

class ApiProfileRepository implements ProfileRepository {
  const ApiProfileRepository({
    required RmApiClient client,
    required RmSession session,
  }) : _client = client,
       _session = session;

  static const String _path = '/api/v1/me/profile';

  final RmApiClient _client;
  final RmSession _session;

  @override
  Future<Profile> read() async {
    try {
      // Through the session, so an expired credential refreshes once and
      // retries once inside this single call. That recovery is Phase 9's and
      // is not re-implemented, second-guessed or bypassed here.
      final RmResponse response = await _session.send(
        (Map<String, String> headers) => _client.get(_path, headers: headers),
      );

      return _decode(response);
    } on RmFailure catch (failure) {
      if (failure.status == 404) {
        // The one status that is a product state rather than a failure.
        throw const ProfileNotFound();
      }

      rethrow;
    }
  }

  @override
  Future<Profile> save(String displayName) async {
    final RmResponse response = await _session.send(
      (Map<String, String> headers) => _client.put(
        _path,
        // Exactly the documented field. The server refuses unknown keys, so
        // sending more would fail the request rather than be ignored — and
        // `initials` in particular is the server's to derive.
        json: <String, Object?>{'display_name': displayName},
        headers: headers,
      ),
    );

    return _decode(response);
  }

  /// Strict, and stricter than the catalogue decoder on purpose.
  ///
  /// The profile is the one representation another member will eventually see,
  /// and the contract fixes it at exactly two fields. An extra key means this
  /// is not that representation — a different version, a proxy rewriting the
  /// body, or a server that grew a field nobody reviewed — and reading the two
  /// fields out of it anyway would hide exactly the drift worth noticing.
  Profile _decode(RmResponse response) {
    final Object? profile = response.json?['profile'];

    if (profile is! Map<String, Object?>) {
      throw _malformed(response);
    }

    final Object? displayName = profile['display_name'];
    final Object? initials = profile['initials'];

    if (displayName is! String ||
        initials is! String ||
        displayName.isEmpty ||
        initials.isEmpty) {
      throw _malformed(response);
    }

    // The envelope carries `profile` and nothing beside it, and the profile
    // carries those two fields and nothing beside them.
    if (response.json?.length != 1 || profile.length != 2) {
      throw _malformed(response);
    }

    return Profile(displayName: displayName, initials: initials);
  }

  /// Keeps the real status, so a malformed 2xx stays distinguishable from a
  /// deterministic 4xx even though both are [RmErrorCode.unexpected] — the
  /// discriminator F4.1 depends on.
  RmFailure _malformed(RmResponse response) => RmFailure.fromBackend(
    status: response.status,
    code: RmErrorCode.unexpected,
  );
}
