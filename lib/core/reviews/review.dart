// ─────────────────────────────────────────────────────────────
// RideMate — What one member said about a shared journey
//
// A REVIEW IS A CLAIM, NOT A RECORD OF EVENTS
//
// One member's self-declared rating about one completed relationship. It is not
// evidence that anybody boarded, was picked up, or travelled: every fact the
// service holds about a journey is the driver's own declaration, and a rating
// is one member's opinion of it. Nothing here may be rendered as proof.
//
// WHAT IS NOT IN THIS FILE
//
// No seat request, route or trip id — the server publishes none, and a field
// here is the first place one gets invented. No account or profile id, no
// phone. No counterpart or release state: whether the other side has written
// anything is a fact the backend deliberately withholds until it releases both,
// so a client type that could hold it would be a place to leak it. No average,
// count or distribution — RideMate publishes no reputation. No text and no
// tags: Phase 15 is rating-only.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

import '../routes/departure.dart';

/// Which side of a shared journey wrote a review.
///
/// Sides of one seat request rather than kinds of member: the same account is a
/// driver on journeys it published and a passenger on journeys it asked to
/// join, sometimes on the same day.
enum ReviewerRole {
  driver('driver'),
  passenger('passenger');

  const ReviewerRole(this.wire);

  final String wire;
}

/// Why a review was refused.
///
/// The stable machine strings the backend publishes at `error.details.reason`.
/// Matched, never parsed out of a message and never guessed from a status code
/// — all five arrive as `409 conflict`, so the status distinguishes none.
///
/// DELIBERATELY NOT [SeatRequestRefusal]
///
/// `id_already_used` is spelled the same in both, because it means the same
/// thing on the same kind of create path — the same wire string for the same
/// meaning keeps a client's mapping simple. Sharing one enum across three
/// domains would be a different thing and a worse one.
enum ReviewRefusal {
  seatRequestNotAccepted('seat_request_not_accepted'),
  tripNotCompleted('trip_not_completed'),
  reviewWindowClosed('review_window_closed'),
  alreadyReviewed('already_reviewed'),
  idAlreadyUsed('id_already_used');

  const ReviewRefusal(this.wire);

  final String wire;

  /// The refusal a failure names, or null when it names none of them.
  ///
  /// Null covers a failure that carried no reason, one from another domain, and
  /// one naming a value this build has never heard of. A later backend may add
  /// a sixth, and a client that coerced it into one of these would act on a
  /// state nobody described.
  static ReviewRefusal? fromWire(String? value) {
    for (final ReviewRefusal refusal in values) {
      if (refusal.wire == value) return refusal;
    }

    return null;
  }
}

/// A review the caller wrote themselves.
///
/// Three fields, and the caller already owns every one: this answers *did it
/// land, and what did I say*, which is what a submission response and the
/// `my_review` projection are both for.
///
/// There is no `role` — the caller knows which side they are, having opened the
/// screen from their own asking or their own journey.
@immutable
final class MyReview {
  const MyReview({
    required this.id,
    required this.rating,
    required this.submittedAt,
  });

  /// The client-generated UUIDv7 this review was submitted under. It is the
  /// idempotency key: the same id is the same review.
  final String id;

  /// One to five, whole.
  final int rating;

  /// When the member submitted it. A review is never edited, so the server
  /// sends one instant and this is it.
  final DateTime submittedAt;

  @override
  bool operator ==(Object other) =>
      other is MyReview &&
      other.id == id &&
      other.rating == rating &&
      other.submittedAt == submittedAt;

  @override
  int get hashCode => Object.hash(id, rating, submittedAt);
}

/// The member who wrote a review, as the server describes them.
///
/// A display name and the initials the server derived from it. Turkish casing
/// makes those a rule rather than a formatting detail, so deriving them here
/// would be authoring a rule the backend owns.
@immutable
final class ReviewReviewer {
  const ReviewReviewer({
    required this.displayName,
    required this.initials,
    required this.role,
  });

  final String displayName;
  final String initials;

  /// Which side they were on the journey this review is about.
  final ReviewerRole role;

  @override
  bool operator ==(Object other) =>
      other is ReviewReviewer &&
      other.displayName == displayName &&
      other.initials == initials &&
      other.role == role;

  @override
  int get hashCode => Object.hash(displayName, initials, role);
}

/// Which shared journey a rating belongs to.
///
/// ATTRIBUTION, NOT PROOF
///
/// A member holding several ratings from the same person needs to know which
/// journey each refers to. It says nothing about whether either of them
/// travelled, and carries no identifier — nothing on this screen addresses a
/// route, a trip or a seat request.
///
/// [departureDate] is never null. A recurring route cannot have a trip, so
/// every reviewable journey is one-off and dated.
@immutable
final class ReviewJourney {
  const ReviewJourney({
    required this.origin,
    required this.destination,
    required this.departureDate,
    required this.departureTime,
  });

  /// The place's label, as the server sends it. Not a `Place`: that carries an
  /// id which addresses a place in discovery, and this has no use for one.
  final String origin;
  final String destination;

  final DepartureDate departureDate;
  final DepartureTime departureTime;

  @override
  bool operator ==(Object other) =>
      other is ReviewJourney &&
      other.origin == origin &&
      other.destination == destination &&
      other.departureDate == departureDate &&
      other.departureTime == departureTime;

  @override
  int get hashCode =>
      Object.hash(origin, destination, departureDate, departureTime);
}

/// A released review, as the member it is about reads it.
///
/// Released means the other side has written one too, or the window has closed.
/// **That decision is the server's**: this list holds what the backend returned
/// and nothing here recomputes it, because a client that worked it out would
/// need to know whether a review it may not see exists.
@immutable
final class ReceivedReview {
  const ReceivedReview({
    required this.id,
    required this.rating,
    required this.submittedAt,
    required this.reviewer,
    required this.journey,
  });

  final String id;
  final int rating;
  final DateTime submittedAt;
  final ReviewReviewer reviewer;
  final ReviewJourney journey;

  @override
  bool operator ==(Object other) => other is ReceivedReview && other.id == id;

  @override
  int get hashCode => id.hashCode;

  /// Says nothing about who or where. A rating beside a name in a log line is
  /// somebody's opinion of a real person, and a toString is the easiest way for
  /// that to reach one by accident.
  @override
  String toString() => 'ReceivedReview($id)';
}
