// ─────────────────────────────────────────────────────────────
// RideMate — API failures
//
// Everything that can go wrong between calling the backend and holding a
// decoded response, expressed as one type.
// ─────────────────────────────────────────────────────────────

import 'rm_error_code.dart';

/// A request that did not produce a usable response.
///
/// WHAT IS NOT HERE, AND WHY
///
/// The backend's `message`. It is developer-facing English, the contract says
/// clients must never display it, and the surest way to honour that is to make
/// it unavailable rather than to rely on nobody reaching for it. Presentation
/// maps [code] to its own localized copy; there is no second source of truth
/// to fork.
///
/// Also absent: any `package:http` type. A caller outside core/api never sees
/// a ClientException, a SocketException or a FormatException, so swapping the
/// transport is a change inside this directory.
final class RmFailure implements Exception {
  /// The backend answered, and said no.
  const RmFailure.fromBackend({
    required int this.status,
    required this.code,
    this.requestId,
  });

  /// The backend never answered: no connection, a dropped socket, a timeout.
  ///
  /// Deliberately one case. Distinguishing "DNS failed" from "connection
  /// refused" would be more information than any caller can act on — the
  /// answer to all of them is the same, and it is not a retry loop.
  const RmFailure.transport()
    : status = null,
      code = RmErrorCode.unexpected,
      requestId = null;

  /// The HTTP status, or `null` when nothing was received.
  final int? status;

  /// The contract code, or [RmErrorCode.unexpected] for anything undocumented.
  final RmErrorCode code;

  /// The backend's correlation id, when it supplied one.
  ///
  /// The only diagnostic that survives. It is not a credential and carries
  /// nothing about the member, so it is safe to show in a copyable "report
  /// this" affordance — which is what makes a screenshot enough to find the
  /// matching server log line.
  final String? requestId;

  /// Whether the request never reached the backend.
  ///
  /// Derived rather than stored: a status arrives if and only if there was a
  /// response, so a separate flag would be a second way to say the same thing
  /// and a chance for the two to disagree.
  bool get isTransport => status == null;

  @override
  String toString() => isTransport
      ? 'RmFailure(transport)'
      : 'RmFailure($status, ${code.name}${requestId == null ? '' : ', $requestId'})';
}
