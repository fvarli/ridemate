// ─────────────────────────────────────────────────────────────
// RideMate — API error codes
//
// The machine half of the backend's error contract.
//
// The server sends `code` and `message`. `code` is the contract — a stable
// string the client maps to its own copy — and `message` is developer-facing
// English the client must never display. So this enum exists and no equivalent
// exists for the message.
//
// Source of truth: openapi/openapi.yaml, components.schemas.ErrorCode.
// ─────────────────────────────────────────────────────────────

/// A failure the backend named, or the fallback for one it did not.
enum RmErrorCode {
  badRequest('bad_request'),
  unauthenticated('unauthenticated'),
  forbidden('forbidden'),
  notFound('not_found'),
  methodNotAllowed('method_not_allowed'),
  conflict('conflict'),
  validationFailed('validation_failed'),
  rateLimited('rate_limited'),
  internalError('internal_error'),

  /// Not a server code. Nothing sends this.
  ///
  /// It covers everything the contract cannot describe: a response that was
  /// not the documented envelope, a body that would not parse, and any code a
  /// future backend adds that this build has never heard of.
  ///
  /// Its wire value is deliberately `null` rather than a plausible string like
  /// `'unknown'`. A string would look like part of the contract, and someone
  /// would eventually send it.
  unexpected(null);

  const RmErrorCode(this.wire);

  /// The string the backend sends, or `null` for [unexpected].
  final String? wire;

  /// Maps a wire value onto a code. Total: never throws.
  ///
  /// Forward compatibility is the point. A backend that gains a tenth code
  /// must not break a client that predates it, so anything unrecognised —
  /// including a missing or non-string value — becomes [unexpected] instead of
  /// raising during error handling. Failing while parsing a failure is how a
  /// clear server error turns into an opaque client crash.
  static RmErrorCode fromWire(Object? value) {
    if (value is! String) {
      return unexpected;
    }

    for (final RmErrorCode code in values) {
      if (code.wire == value) {
        return code;
      }
    }

    return unexpected;
  }
}
