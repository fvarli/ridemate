// ─────────────────────────────────────────────────────────────
// RideMate — Reading a trip lifecycle off the wire
//
// Strict, in the same idiom as RouteDecoder and SeatRequestDecoder: a field of
// the wrong type, a state this build has never heard of, or a required key that
// is absent all refuse the whole response rather than producing a partial
// object. A lifecycle is the difference between a journey that happened and one
// that did not, and a plausible guess is worse here than a visible failure.
//
// THE THREE TIMESTAMPS ARE REQUIRED AND NULLABLE
//
// Which are different things. The server always sends all three — null for the
// ones that have not happened — so a missing key is drift rather than a journey
// nobody started. Reading absence as null would let an older backend claim
// every journey is still unstarted.
// ─────────────────────────────────────────────────────────────

import '../api/rm_failure.dart';
import '../routes/route_decoder.dart';
import 'trip_lifecycle.dart';

abstract final class TripDecoder {
  const TripDecoder._();

  /// The lifecycle object, wherever it appears.
  ///
  /// One reader for all three surfaces that publish it — the owner's routes,
  /// the passenger's nested journey, and the body of a lifecycle command — so
  /// the same wire shape cannot be read two ways.
  static TripLifecycle lifecycle(Object? value, int status) {
    if (value is! Map<String, Object?>) throw RouteDecoder.malformed(status);

    return TripLifecycle(
      state: _state(value['state'], status),
      startedAt: _optionalInstant(value, 'started_at', status),
      completedAt: _optionalInstant(value, 'completed_at', status),
      abortedAt: _optionalInstant(value, 'aborted_at', status),
    );
  }

  /// The lifecycle under a required `trip` key on some larger object.
  ///
  /// Required rather than optional: the surfaces that carry it always do, and
  /// treating a missing key as `not_started` would be the client inventing the
  /// one fact this whole type exists to stop it inventing.
  static TripLifecycle within(Map<String, Object?> owner, int status) {
    if (!owner.containsKey('trip')) throw RouteDecoder.malformed(status);

    return lifecycle(owner['trip'], status);
  }

  static TripState _state(Object? value, int status) {
    for (final TripState candidate in TripState.values) {
      if (candidate.wire == value) return candidate;
    }

    // A fifth state this build has never heard of refuses the response rather
    // than being rendered as something plausible.
    throw RouteDecoder.malformed(status);
  }

  /// A nullable timestamp whose key must still be present.
  static DateTime? _optionalInstant(
    Map<String, Object?> value,
    String key,
    int status,
  ) {
    if (!value.containsKey(key)) throw RouteDecoder.malformed(status);

    final Object? raw = value[key];
    if (raw == null) return null;
    if (raw is! String) throw RouteDecoder.malformed(status);

    final DateTime? parsed = DateTime.tryParse(raw);
    if (parsed == null) throw RouteDecoder.malformed(status);

    return parsed;
  }
}

/// The trip refusal a failure names, when it names one this build knows.
///
/// Reads `details.reason` and nothing else. **Never `message`**, which is
/// developer-facing English the contract forbids clients to display, and never
/// the status, which all six refusals share.
extension TripFailure on RmFailure {
  TripRefusal? get tripRefusal => TripRefusal.fromWire(reason);
}
