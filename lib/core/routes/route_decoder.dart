// ─────────────────────────────────────────────────────────────
// RideMate — Reading a route the server sent
//
// ONE DECODER, TWO ENDPOINTS
//
// `POST /routes` returns a route and `GET /me/routes` returns a page of them,
// and they are the same shape because they are the same projection. Decoding
// them in two places would mean fixing a strictness bug in one and not the
// other, and the half that kept the bug would be the one nobody was looking at.
//
// STRICT, AND WHOLE
//
// A field that is missing, null where it must not be, or of the wrong type
// fails the response. Nothing is defaulted, nothing is skipped, and a value
// this build has never heard of — a fifth status, a third departure state — is
// a failure rather than a guess, because guessing puts a journey into a state
// the app cannot reason about and shows it to the person who published it.
// ─────────────────────────────────────────────────────────────

import '../api/rm_error_code.dart';
import '../api/rm_failure.dart';
import '../places/place.dart';
import 'departure.dart';
import 'published_route.dart';
import 'ride_rule.dart';

/// Turns the contract's `Route` object into a [PublishedRoute].
///
/// [status] is the HTTP status the response arrived with; it is carried onto
/// any [RmFailure] this throws so callers can tell an unreadable success from
/// a deterministic refusal.
abstract final class RouteDecoder {
  const RouteDecoder._();

  /// Decodes one route, or throws [RmFailure].
  static PublishedRoute route(Object? value, int status) {
    if (value is! Map<String, Object?>) throw _malformed(status);

    final Object? id = value['id'];
    final Object? recurrence = value['recurrence'];
    final Object? time = value['departure_time'];
    final Object? timezone = value['timezone'];
    final Object? state = value['departure_state'];
    final Object? seats = value['seats_offered'];
    final Object? routeStatus = value['status'];
    final Object? publishedAt = value['published_at'];

    if (id is! String ||
        recurrence is! String ||
        time is! String ||
        timezone is! String ||
        state is! String ||
        seats is! int ||
        routeStatus is! String ||
        publishedAt is! String) {
      throw _malformed(status);
    }

    return PublishedRoute(
      id: id,
      origin: place(value['origin'], status),
      destination: place(value['destination'], status),
      recurrence: _byName(Recurrence.values, recurrence, status),
      departureDate: _date(value['departure_date'], status),
      departureTime: _time(time, status),
      timezone: timezone,
      departureState: _byName(DepartureState.values, state, status),
      seatsOffered: seats,
      rules: _rules(value['rules'], status),
      status: _byName(RouteStatus.values, routeStatus, status),
      publishedAt: publishedAt,
      cancelledAt: switch (value['cancelled_at']) {
        final String value => value,
        null => null,
        _ => throw _malformed(status),
      },
    );
  }

  /// Decodes a place as the contract publishes it: an id and a label, nothing
  /// else. The catalogue behind it also holds coordinates and a slug; they are
  /// not on the wire and there is nowhere here for them to land.
  static Place place(Object? value, int status) {
    if (value is! Map<String, Object?>) throw _malformed(status);

    final Object? id = value['id'];
    final Object? label = value['label'];

    if (id is! String || label is! String) throw _malformed(status);

    return Place(id: id, label: label);
  }

  /// The failure an unreadable response produces.
  ///
  /// Carries the status deliberately. A body that will not decode on a 201 may
  /// be a route that now exists, while the same code on a 404 is the server
  /// saying no — and only the status separates them.
  static RmFailure _malformed(int status) =>
      RmFailure.fromBackend(status: status, code: RmErrorCode.unexpected);

  static DepartureDate? _date(Object? value, int status) {
    if (value == null) return null;
    if (value is! String) throw _malformed(status);

    final List<String> parts = value.split('-');
    if (parts.length != 3) throw _malformed(status);

    final int? year = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? day = int.tryParse(parts[2]);

    if (year == null || month == null || day == null) {
      throw _malformed(status);
    }

    return DepartureDate(year: year, month: month, day: day);
  }

  static DepartureTime _time(String value, int status) {
    final List<String> parts = value.split(':');
    if (parts.length != 2) throw _malformed(status);

    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) throw _malformed(status);

    return DepartureTime(hour: hour, minute: minute);
  }

  /// Read back through the same key mapping that writes them.
  ///
  /// Every one of the four must be present and boolean. A missing rule is not
  /// the same as a rule set to false, and treating it as one would quietly
  /// invent an answer on the driver's behalf.
  static Set<RideRuleId> _rules(Object? value, int status) {
    if (value is! Map<String, Object?>) throw _malformed(status);

    for (final RideRuleId id in RideRuleId.values) {
      if (value[rideRuleWireKey(id)] is! bool) throw _malformed(status);
    }

    return rideRulesFromFlags((String key) => value[key] == true);
  }

  static T _byName<T extends Enum>(List<T> values, String name, int status) {
    for (final T value in values) {
      if (value.name == name) return value;
    }

    // A value this build has never heard of.
    throw _malformed(status);
  }
}
