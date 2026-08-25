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
import 'departure.dart';

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
    required this.recurrence,
    required this.departureDate,
    required this.departureTime,
    required this.seats,
    required this.rules,
  });

  final Place origin;
  final Place destination;

  /// How often the journey happens.
  ///
  /// Exactly the one choice the design offers — `Her hafta içi tekrarla` — but
  /// held as the two named cases the API accepts rather than as a boolean.
  /// There is still no RRULE, no day picker, no exceptions and no background
  /// scheduling, because none of that is designed.
  final Recurrence recurrence;

  /// The day a one-off journey happens.
  ///
  /// Null for a weekday commute, and CLEARED when the driver switches to one —
  /// not merely ignored. A date that is off screen but still in the draft is
  /// state nobody can see and something a request could still carry.
  final DepartureDate? departureDate;

  /// The wall clock the driver chose. Needed in both modes.
  ///
  /// There is no default. The screen used to show a fixed 08:00 that no driver
  /// had picked, and publishing that would have recorded a choice nobody made.
  final DepartureTime? departureTime;

  /// Free seats the driver is offering.
  final int seats;

  /// The rules the driver publishes with the journey.
  final Set<RideRuleId> rules;

  bool isRuleSelected(RideRuleId id) => rules.contains(id);

  /// Whether a date is part of this draft at all.
  bool get needsDepartureDate => recurrence.needsDate;

  /// Whether the driver has said everything a journey needs.
  ///
  /// Deliberately narrow. It asks only whether the form has been filled in —
  /// not whether the departure is still in the future, which is read in a
  /// timezone the server owns and which this client must not second-guess.
  bool get isComplete =>
      departureTime != null && (!needsDepartureDate || departureDate != null);

  /// Whether the seat count can still go down.
  ///
  /// There is deliberately no matching `canIncrementSeats`: no ceiling exists.
  /// See [kSeatsFloor].
  bool get canDecrementSeats => seats > kSeatsFloor;

  /// A copy with the named fields replaced.
  ///
  /// `clearDepartureDate` exists because `departureDate: null` cannot mean
  /// "remove it" here — a null named argument is indistinguishable from an
  /// omitted one. Switching to a weekday commute has to say so explicitly.
  CreateRouteDraft copyWith({
    Place? origin,
    Place? destination,
    Recurrence? recurrence,
    DepartureDate? departureDate,
    DepartureTime? departureTime,
    bool clearDepartureDate = false,
    int? seats,
    Set<RideRuleId>? rules,
  }) {
    return CreateRouteDraft(
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      recurrence: recurrence ?? this.recurrence,
      departureDate: clearDepartureDate
          ? null
          : departureDate ?? this.departureDate,
      departureTime: departureTime ?? this.departureTime,
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
      other.recurrence == recurrence &&
      other.departureDate == departureDate &&
      other.departureTime == departureTime &&
      other.seats == seats &&
      setEquals(other.rules, rules);

  @override
  int get hashCode => Object.hash(
    origin,
    destination,
    recurrence,
    departureDate,
    departureTime,
    seats,
    Object.hashAllUnordered(rules),
  );
}
