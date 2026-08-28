// ─────────────────────────────────────────────────────────────
// WHEN A JOURNEY LEAVES, IN THE TERMS THE DRIVER CHOSE.
//
// Two value types and an enum, all of them deliberately smaller than DateTime.
//
// WHY NOT DateTime
//
// A DateTime is an instant. It carries a time of day and a flag saying whether
// it is UTC or "local", and "local" means the device's zone. A calendar day
// stored in one therefore acquires a timezone the app does not own and cannot
// answer questions about: RideMate's departures are read in the pilot's zone,
// which is the SERVER's configuration, and the client has no timezone
// capability at all — no tz package, no offset table, nothing.
//
// Keeping the date and the time as what they are — a day on a calendar, and a
// reading on a clock — means the client cannot accidentally imply an instant it
// is not entitled to compute. Turning them into one is the server's job, and so
// is deciding whether that instant has passed.
//
// WHY NOT TimeOfDay
//
// It would do the job, and it lives in package:flutter/material.dart. This
// layer imports only `foundation`, and a domain that reaches for material to
// describe a departure has started keeping its rules where its widgets are.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

/// How often a published journey happens.
///
/// Two cases, matching the two the approved screen offers and the two the API
/// accepts. Replaces the earlier `bool repeatsOnWeekdays`: the same information,
/// but named the way the contract names it, so mapping a draft to a request is
/// reading rather than translating.
enum Recurrence {
  /// A single journey on a stated date.
  once,

  /// The same departure every weekday, until cancelled.
  weekdays;

  /// Whether this recurrence carries a calendar date.
  ///
  /// Exactly one does. A weekday commute has no single day to name, and naming
  /// one would claim a specificity it does not have.
  bool get needsDate => this == Recurrence.once;
}

/// A day on a calendar. No time, no zone.
@immutable
final class DepartureDate {
  const DepartureDate({
    required this.year,
    required this.month,
    required this.day,
  });

  /// The day a picker returned.
  ///
  /// Takes the three fields and drops everything else, which is the point: a
  /// picker hands back a DateTime, and only its calendar part means anything
  /// here.
  factory DepartureDate.from(DateTime value) =>
      DepartureDate(year: value.year, month: value.month, day: value.day);

  final int year;
  final int month;
  final int day;

  /// `2026-09-14` — the unambiguous way to write this value down.
  String get iso => '${_pad(year, 4)}-${_pad(month, 2)}-${_pad(day, 2)}';

  /// Midday, purely so a picker can be reopened where it was left.
  ///
  /// Midday rather than midnight because a date rendered at 00:00 is one
  /// daylight-saving hour away from being the previous day, and this value
  /// exists only to position a control.
  DateTime toPickerValue() => DateTime(year, month, day, 12);

  @override
  bool operator ==(Object other) =>
      other is DepartureDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => iso;
}

/// A reading on a clock. No date, no zone.
@immutable
final class DepartureTime {
  const DepartureTime({required this.hour, required this.minute});

  final int hour;
  final int minute;

  /// `08:25` — minutes only, which is exactly what the API accepts.
  String get hhMm => '${_pad(hour, 2)}:${_pad(minute, 2)}';

  @override
  bool operator ==(Object other) =>
      other is DepartureTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => hhMm;
}

String _pad(int value, int width) => value.toString().padLeft(width, '0');
