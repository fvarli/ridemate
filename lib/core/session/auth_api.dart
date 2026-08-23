// ─────────────────────────────────────────────────────────────
// RideMate — the authentication endpoints
//
// A typed call per documented operation, and nothing else. No endpoint is
// invented here and no field is sent that the contract does not describe.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

import '../api/rm_api_client.dart';
import '../api/rm_error_code.dart';
import '../api/rm_failure.dart';
import '../api/rm_response.dart';
import 'rm_token_pair.dart';

/// The five operations the backend serves.
class AuthApi {
  const AuthApi(this._client);

  final RmApiClient _client;

  /// Sends a passcode. The response is the same whether or not an account
  /// exists, so nothing is returned and nothing can be inferred.
  Future<void> requestPasscode(String phone) async {
    await _client.post(
      '/api/v1/auth/otp',
      json: <String, Object?>{'phone': phone},
    );
  }

  /// Exchanges a passcode for a session, creating the account if this number
  /// has never signed in.
  ///
  /// Registration and sign-in are the same call by design; the client cannot
  /// tell which happened, and does not need to.
  Future<RmTokenPair> verifyPasscode({
    required String phone,
    required String code,
  }) => _pair(
    _client.post(
      '/api/v1/auth/otp/verify',
      json: <String, Object?>{
        'phone': phone,
        'code': code,
        // The contract also allows device_name and app_version. Neither is
        // sent: there is no honest source for them without another dependency,
        // and a fabricated device name is invented data shown back to the
        // member as if it were true. The platform is known for free.
        'platform': defaultTargetPlatform.name,
      },
    ),
  );

  /// Exchanges a refresh token for a new generation.
  ///
  /// Uses the raw client deliberately. Routing this through the authenticated
  /// path would let a 401 here trigger a refresh, which would call this again.
  Future<RmTokenPair> refresh(String refreshToken) => _pair(
    _client.post(
      '/api/v1/auth/refresh',
      json: <String, Object?>{'refresh_token': refreshToken},
    ),
  );

  /// Ends the session server-side. Both credentials die with it.
  Future<void> logout(String accessToken) async {
    await _client.post('/api/v1/auth/logout', headers: bearer(accessToken));
  }

  /// The caller's own account.
  ///
  /// Returned raw. Decoding it into a profile type would mean inventing a
  /// profile domain, and nothing in this phase has one.
  Future<RmResponse> me(String accessToken) =>
      _client.get('/api/v1/me', headers: bearer(accessToken));

  static Map<String, String> bearer(String accessToken) => <String, String>{
    'Authorization': 'Bearer $accessToken',
  };

  Future<RmTokenPair> _pair(Future<RmResponse> request) async {
    final RmResponse response = await request;
    final RmTokenPair? pair = RmTokenPair.fromJson(response.json);

    if (pair == null) {
      // A success that is not the documented shape is as unusable as an
      // error, and it becomes the same kind of failure.
      throw RmFailure.fromBackend(
        status: response.status,
        code: RmErrorCode.unexpected,
      );
    }

    return pair;
  }
}
