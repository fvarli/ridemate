// ─────────────────────────────────────────────────────────────
// RideMate — Reading a seat request off the wire
//
// Strict, in the same idiom as RouteDecoder: a field of the wrong type, a
// status this build has never heard of, or a required key that is absent all
// refuse the whole response rather than producing a partial object. A screen
// that shows four of five journeys is a screen nobody can explain.
//
// The three projections decode separately, because they are separate shapes.
// ─────────────────────────────────────────────────────────────

import '../api/rm_failure.dart';
import '../routes/departure.dart';
import '../routes/published_route.dart';
import '../routes/route_decoder.dart';
import '../trips/trip_decoder.dart';
import 'seat_request.dart';

abstract final class SeatRequestDecoder {
  const SeatRequestDecoder._();

  /// The caller's own asking on a discovered journey, or null.
  ///
  /// **The key is required and its value may be null**, which are different
  /// things: a response without it is not this contract, and reading absence as
  /// "not requested" would make an older backend silently claim every journey
  /// is still askable.
  static MySeatRequestSummary? summary(Map<String, Object?> route, int status) {
    if (!route.containsKey('my_seat_request')) {
      throw RouteDecoder.malformed(status);
    }

    final Object? value = route['my_seat_request'];
    if (value == null) return null;
    if (value is! Map<String, Object?>) throw RouteDecoder.malformed(status);

    final Object? id = value['id'];
    if (id is! String || id.isEmpty) throw RouteDecoder.malformed(status);

    return MySeatRequestSummary(
      id: id,
      status: _status(value['status'], status),
    );
  }

  /// One of the caller's own askings.
  static MySeatRequest mine(Object? value, int status) {
    if (value is! Map<String, Object?>) throw RouteDecoder.malformed(status);

    final Object? id = value['id'];
    if (id is! String || id.isEmpty) throw RouteDecoder.malformed(status);

    return MySeatRequest(
      id: id,
      status: _status(value['status'], status),
      requestedAt: _instant(value['requested_at'], status),
      decidedAt: _optionalInstant(value, 'decided_at', status),
      withdrawnAt: _optionalInstant(value, 'withdrawn_at', status),
      route: _route(value['route'], status),
    );
  }

  /// One asking on a journey the caller published.
  static IncomingSeatRequest incoming(Object? value, int status) {
    if (value is! Map<String, Object?>) throw RouteDecoder.malformed(status);

    final Object? id = value['id'];
    if (id is! String || id.isEmpty) throw RouteDecoder.malformed(status);

    return IncomingSeatRequest(
      id: id,
      status: _status(value['status'], status),
      requestedAt: _instant(value['requested_at'], status),
      decidedAt: _optionalInstant(value, 'decided_at', status),
      withdrawnAt: _optionalInstant(value, 'withdrawn_at', status),
      passenger: member(value['passenger'], status),
    );
  }

  /// A member's public identity, as the server derived it.
  static SeatRequestMember member(Object? value, int status) {
    if (value is! Map<String, Object?>) throw RouteDecoder.malformed(status);

    final Object? name = value['display_name'];
    final Object? initials = value['initials'];

    if (name is! String ||
        initials is! String ||
        name.isEmpty ||
        initials.isEmpty) {
      throw RouteDecoder.malformed(status);
    }

    return SeatRequestMember(displayName: name, initials: initials);
  }

  /// The journey, including the `status` discovery has no vocabulary for.
  static SeatRequestRoute _route(Object? value, int status) {
    if (value is! Map<String, Object?>) throw RouteDecoder.malformed(status);

    final Object? id = value['id'];
    final Object? recurrence = value['recurrence'];
    final Object? departureTime = value['departure_time'];
    final Object? timezone = value['timezone'];
    final Object? routeStatus = value['status'];
    final Object? departureState = value['departure_state'];
    final Object? seats = value['seats_offered'];

    if (id is! String ||
        recurrence is! String ||
        departureTime is! String ||
        timezone is! String ||
        routeStatus is! String ||
        departureState is! String ||
        seats is! int ||
        // Always present, null for a recurring plan. A missing key is drift,
        // not a weekday journey.
        !value.containsKey('departure_date')) {
      throw RouteDecoder.malformed(status);
    }

    return SeatRequestRoute(
      id: id,
      origin: RouteDecoder.place(value['origin'], status),
      destination: RouteDecoder.place(value['destination'], status),
      recurrence: RouteDecoder.byName(Recurrence.values, recurrence, status),
      departureDate: RouteDecoder.date(value['departure_date'], status),
      departureTime: RouteDecoder.time(departureTime, status),
      timezone: timezone,
      // Decoded independently of the request's own status, and never derived
      // from it: a cancelled journey and an accepted asking are both true.
      status: RouteDecoder.byName(RouteStatus.values, routeStatus, status),
      departureState: RouteDecoder.byName(
        DepartureState.values,
        departureState,
        status,
      ),
      seatsOffered: seats,
      rules: RouteDecoder.rules(value['rules'], status),
      driver: member(value['driver'], status),
      // Required, like the route's own status: this projection always carries
      // it. Discovery's does not, and neither does the plain route.
      trip: TripDecoder.within(value, status),
    );
  }

  static SeatRequestStatus _status(Object? value, int status) {
    for (final SeatRequestStatus candidate in SeatRequestStatus.values) {
      if (candidate.wire == value) return candidate;
    }

    // A fifth status this build has never heard of refuses the response rather
    // than being rendered as something plausible.
    throw RouteDecoder.malformed(status);
  }

  static DateTime _instant(Object? value, int status) {
    if (value is! String) throw RouteDecoder.malformed(status);

    final DateTime? parsed = DateTime.tryParse(value);
    if (parsed == null) throw RouteDecoder.malformed(status);

    return parsed;
  }

  /// A nullable timestamp whose key must still be present.
  static DateTime? _optionalInstant(
    Map<String, Object?> value,
    String key,
    int status,
  ) {
    if (!value.containsKey(key)) throw RouteDecoder.malformed(status);

    return value[key] == null ? null : _instant(value[key], status);
  }
}

/// The refusal a failure names, when it names one this build knows.
extension SeatRequestFailure on RmFailure {
  SeatRequestRefusal? get seatRequestRefusal =>
      SeatRequestRefusal.fromWire(reason);

  /// The state the server says the resource is actually in, when it said.
  SeatRequestStatus? get seatRequestCurrentStatus {
    for (final SeatRequestStatus candidate in SeatRequestStatus.values) {
      if (candidate.wire == currentStatus) return candidate;
    }

    return null;
  }
}
