// ─────────────────────────────────────────────────────────────
// RideMate — Reading a review off the wire
//
// Strict, in the same idiom as RouteDecoder and SeatRequestDecoder: a field of
// the wrong type, a role this build has never heard of, or a required key that
// is absent all refuse the whole response rather than producing a partial
// object. A rating attributed to the wrong person, or to nobody in particular,
// is worse than a screen that says it could not load.
//
// `my_review` IS REQUIRED AND NULLABLE
//
// Which are different things. The server always sends the key — null when the
// caller has written nothing — so a missing one is drift, not an unreviewed
// relationship. Reading absence as null would let an older backend claim every
// relationship is still open to rate, and would offer the control twice.
//
// NOTHING HERE ASKS ABOUT THE OTHER SIDE
//
// Null is also the answer when the counterpart has written one and the caller
// has not. The two are identical on the wire, deliberately, and this decoder
// has no way to tell them apart — which is the point.
// ─────────────────────────────────────────────────────────────

import '../api/rm_failure.dart';
import '../routes/departure.dart';
import '../routes/route_decoder.dart';
import 'review.dart';

abstract final class ReviewDecoder {
  const ReviewDecoder._();

  /// The caller's own review, from a submission response or a projection.
  static MyReview mine(Object? value, int status) {
    if (value is! Map<String, Object?>) throw RouteDecoder.malformed(status);

    final Object? id = value['id'];
    final Object? rating = value['rating'];

    if (id is! String || id.isEmpty || rating is! int) {
      throw RouteDecoder.malformed(status);
    }

    return MyReview(
      id: id,
      rating: rating,
      submittedAt: _instant(value['submitted_at'], status),
    );
  }

  /// The caller's own review under a required `my_review` key, or null.
  static MyReview? within(Map<String, Object?> owner, int status) {
    if (!owner.containsKey('my_review')) throw RouteDecoder.malformed(status);

    final Object? value = owner['my_review'];

    return value == null ? null : mine(value, status);
  }

  /// One review about the caller, from the released feed.
  static ReceivedReview received(Object? value, int status) {
    if (value is! Map<String, Object?>) throw RouteDecoder.malformed(status);

    final Object? id = value['id'];
    final Object? rating = value['rating'];

    if (id is! String || id.isEmpty || rating is! int) {
      throw RouteDecoder.malformed(status);
    }

    return ReceivedReview(
      id: id,
      rating: rating,
      submittedAt: _instant(value['submitted_at'], status),
      reviewer: _reviewer(value['reviewer'], status),
      journey: _journey(value['journey'], status),
    );
  }

  static ReviewReviewer _reviewer(Object? value, int status) {
    if (value is! Map<String, Object?>) throw RouteDecoder.malformed(status);

    final Object? name = value['display_name'];
    final Object? initials = value['initials'];

    if (name is! String ||
        initials is! String ||
        name.isEmpty ||
        initials.isEmpty) {
      throw RouteDecoder.malformed(status);
    }

    return ReviewReviewer(
      displayName: name,
      initials: initials,
      role: _role(value['role'], status),
    );
  }

  static ReviewerRole _role(Object? value, int status) {
    for (final ReviewerRole candidate in ReviewerRole.values) {
      if (candidate.wire == value) return candidate;
    }

    // A third side this build has never heard of refuses the response rather
    // than being rendered as one of the two.
    throw RouteDecoder.malformed(status);
  }

  static ReviewJourney _journey(Object? value, int status) {
    if (value is! Map<String, Object?>) throw RouteDecoder.malformed(status);

    final Object? origin = value['origin'];
    final Object? destination = value['destination'];
    final Object? time = value['departure_time'];

    if (origin is! String ||
        destination is! String ||
        origin.isEmpty ||
        destination.isEmpty ||
        time is! String) {
      throw RouteDecoder.malformed(status);
    }

    // Required here, unlike everywhere else a departure appears: a recurring
    // route cannot have a trip, so every reviewable journey is dated. The two
    // readers are the route decoder's, so reviews introduce no second date or
    // time format.
    final DepartureDate? date = RouteDecoder.date(
      value['departure_date'],
      status,
    );
    if (date == null) throw RouteDecoder.malformed(status);

    return ReviewJourney(
      origin: origin,
      destination: destination,
      departureDate: date,
      departureTime: RouteDecoder.time(time, status),
    );
  }

  static DateTime _instant(Object? value, int status) {
    if (value is! String) throw RouteDecoder.malformed(status);

    final DateTime? parsed = DateTime.tryParse(value);
    if (parsed == null) throw RouteDecoder.malformed(status);

    return parsed;
  }
}

/// The review refusal a failure names, when it names one this build knows.
///
/// Reads `details.reason` and nothing else. **Never `message`**, which is
/// developer-facing English the contract forbids clients to display, and never
/// the status, which all five refusals share.
extension ReviewFailure on RmFailure {
  ReviewRefusal? get reviewRefusal => ReviewRefusal.fromWire(reason);
}
