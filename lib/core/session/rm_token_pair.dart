// ─────────────────────────────────────────────────────────────
// RideMate — the credential pair the backend issues
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

/// What `/auth/otp/verify` and `/auth/refresh` both return.
///
/// The two endpoints return the same shape by contract, so they decode through
/// the same type — which is what keeps them from drifting apart one field at a
/// time.
@immutable
final class RmTokenPair {
  const RmTokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.sessionId,
    required this.expiresIn,
  });

  /// Null when the body is not the documented shape.
  ///
  /// Returning null rather than throwing keeps decoding total; the caller
  /// turns it into the same `unexpected` failure every other malformed
  /// response produces, instead of a FormatException escaping as itself.
  static RmTokenPair? fromJson(Map<String, Object?>? json) {
    final Object? access = json?['access_token'];
    final Object? refresh = json?['refresh_token'];
    final Object? session = json?['session_id'];
    final Object? expires = json?['expires_in'];

    if (access is! String ||
        refresh is! String ||
        session is! String ||
        expires is! int ||
        access.isEmpty ||
        refresh.isEmpty ||
        session.isEmpty) {
      return null;
    }

    return RmTokenPair(
      accessToken: access,
      refreshToken: refresh,
      sessionId: session,
      expiresIn: expires,
    );
  }

  /// Memory only. Never written to storage — see RmCredentials.
  final String accessToken;

  /// Persisted, with [sessionId], before this pair is treated as durable.
  final String refreshToken;
  final String sessionId;

  /// Seconds until [accessToken] expires. Retained for a future proactive
  /// refresh; nothing schedules on it yet.
  final int expiresIn;

  /// Redacted. Both tokens are credentials and neither belongs in a log.
  @override
  String toString() => 'RmTokenPair(session: $sessionId)';
}
