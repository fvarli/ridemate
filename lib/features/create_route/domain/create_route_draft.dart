// ─────────────────────────────────────────────────────────────
// RideMate — Create route draft
//
// What a driver has filled in so far on the Create Route screen. Local
// presentation state, nothing more.
//
// A driver here is sharing a journey they are ALREADY making. This is not
// commercial passenger transport: there is no customer acquisition, no
// earnings, no fare setting and no trip taken because someone requested it.
// The vocabulary in this feature stays on the design's own words —
// `KİŞİ BAŞI`, `maliyet paylaşımı` — and never becomes fare, price, income,
// payout or revenue.
//
// NOTHING IS COMPUTED. The suggested cost share is a fixture (see
// create_route_fixtures.dart); it is not derived from seats, distance,
// duration, recurrence, route or vehicle, and there is no total anywhere.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

import '../../../core/places/place.dart';
import 'create_route_fixtures.dart';

/// The ride rules the design offers, in the order it draws them.
///
/// These are a driver's PUBLISHED RULES. Search's [SearchFilterId] carries
/// some of the same words (`Sigara yok`) as a passenger's PREFERENCE, which is
/// the opposite side of the same conversation. The two stay separate types in
/// separate features on purpose; reconciling them is a backend concern.
enum RideRuleId {
  /// `Sigara yok`
  noSmoking,

  /// `Müzik OK`
  musicOk,

  /// `Evcil hayvan yok`
  noPets,

  /// `Sessiz`
  quiet,
}

/// A policy-sensitive preference.
///
/// The client renders it and stores it in the draft; it enforces no
/// eligibility from it. Connecting a "no pets" rule to real matching or
/// eligibility may raise accessibility and non-discrimination considerations,
/// and requires legal, accessibility and product review before any backend
/// enforcement.
///
/// This records a review requirement. It states no legal conclusion — how any
/// particular law applies to this use case is not the client layer's call.
const RideRuleId kRuleNeedingPolicyReview = RideRuleId.noPets;

/// The journey a driver is composing.
@immutable
final class CreateRouteDraft {
  const CreateRouteDraft({
    required this.origin,
    required this.destination,
    required this.repeatsOnWeekdays,
    required this.seats,
    required this.rules,
  });

  final Place origin;
  final Place destination;

  /// Whether the journey repeats every weekday.
  ///
  /// Named for exactly the one choice the design offers — `Her hafta içi
  /// tekrarla` — rather than a general `recurrenceRule`. There is no RRULE, no
  /// day picker, no calendar, no exceptions, no background scheduling and no
  /// reminders, because none of that is designed.
  final bool repeatsOnWeekdays;

  /// Free seats the driver is offering.
  final int seats;

  /// The rules the driver publishes with the journey.
  final Set<RideRuleId> rules;

  bool isRuleSelected(RideRuleId id) => rules.contains(id);

  /// Whether the seat count can still go down.
  ///
  /// There is deliberately no matching `canIncrementSeats`: no ceiling exists.
  /// See [kSeatsFloor].
  bool get canDecrementSeats => seats > kSeatsFloor;

  CreateRouteDraft copyWith({
    Place? origin,
    Place? destination,
    bool? repeatsOnWeekdays,
    int? seats,
    Set<RideRuleId>? rules,
  }) {
    return CreateRouteDraft(
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      repeatsOnWeekdays: repeatsOnWeekdays ?? this.repeatsOnWeekdays,
      seats: seats ?? this.seats,
      rules: rules ?? this.rules,
    );
  }

  /// The draft with [id] added if absent, removed if present.
  CreateRouteDraft withRuleToggled(RideRuleId id) {
    final Set<RideRuleId> next = <RideRuleId>{...rules};
    if (!next.remove(id)) next.add(id);
    return copyWith(rules: next);
  }

  @override
  bool operator ==(Object other) =>
      other is CreateRouteDraft &&
      other.origin == origin &&
      other.destination == destination &&
      other.repeatsOnWeekdays == repeatsOnWeekdays &&
      other.seats == seats &&
      setEquals(other.rules, rules);

  @override
  int get hashCode => Object.hash(
    origin,
    destination,
    repeatsOnWeekdays,
    seats,
    Object.hashAllUnordered(rules),
  );
}
