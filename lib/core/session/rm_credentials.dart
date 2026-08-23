// ─────────────────────────────────────────────────────────────
// RideMate — the persisted credential
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

/// What survives a restart: the refresh token, and the session it belongs to.
///
/// THE ACCESS TOKEN IS NOT A FIELD HERE, AND THAT IS THE POINT
///
/// It could have been, with a comment asking nobody to persist it. Instead the
/// type that gets written to disk simply has nowhere to put one, so
/// "memory-only" is a property of the shape rather than a rule somebody has to
/// remember. An access token lives for fifteen minutes; a cold start exchanges
/// the refresh token for a new one before the first authenticated call, so
/// keeping it would buy a few hundred milliseconds and widen what a device
/// dump contains.
///
/// The session id is stored beside it because revocation is addressed by
/// session, and a refresh token whose session is unknown cannot be reasoned
/// about.
///
/// Passcodes appear nowhere in this file or any other. They are single-use and
/// live five minutes; persisting one would be storing a credential that exists
/// only to be spent immediately.
@immutable
final class RmCredentials {
  const RmCredentials({required this.refreshToken, required this.sessionId});

  final String refreshToken;
  final String sessionId;

  @override
  bool operator ==(Object other) =>
      other is RmCredentials &&
      other.refreshToken == refreshToken &&
      other.sessionId == sessionId;

  @override
  int get hashCode => Object.hash(refreshToken, sessionId);

  /// Redacted, deliberately.
  ///
  /// The error reporter writes what it is given to the developer log, and a
  /// credential reaching it by way of an interpolated object is the kind of
  /// leak nobody writes on purpose. The session id is not secret and is the
  /// only part worth seeing.
  @override
  String toString() => 'RmCredentials(session: $sessionId)';
}
