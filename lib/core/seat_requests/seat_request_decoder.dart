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
import '../reviews/review_decoder.dart';
import '../routes/departure.dart';
import '../routes/published_route.dart';
import '../routes/route_decoder.dart';
import '../trips/trip_decoder.dart';
import 'seat_request.dart';

abstract final class SeatRequestDecoder {
  const SeatRequestDecoder._();

  /// The caller's own askings on a discovered route's journeys.
  ///
  /// **A required, possibly-empty list.** A response without the key is not
  /// this contract, and reading absence as "asked about none" would make an
  /// older backend silently claim every journey is still askable. Empty is the
  /// ordinary case and says exactly that.
  ///
  /// **Nothing here collapses the list.** A route is a plan and may run on many
  /// days, so a member may hold one asking per day; taking the first would be
  /// picking a journey nobody named. Order is the server's — `service_date`
  /// ascending — and is preserved rather than re-derived.
  ///
  /// The singleton `my_seat_request` this replaced is gone from the wire, so a
  /// backend still sending it fails here rather than being read as an empty
  /// list. That is deliberate: a silently empty card would offer to ask again
  /// on a journey the member has already asked about.
  static List<MySeatRequestSummary> summaries(
    Map<String, Object?> route,
    int status,
  ) {
    final Object? value = route['my_seat_requests'];
    if (value is! List) throw RouteDecoder.malformed(status);

    return <MySeatRequestSummary>[
      for (final Object? entry in value) _summary(entry, status),
    ];
  }

  static MySeatRequestSummary _summary(Object? value, int status) {
    if (value is! Map<String, Object?>) throw RouteDecoder.malformed(status);

    final Object? id = value['id'];
    if (id is! String || id.isEmpty) throw RouteDecoder.malformed(status);

    return MySeatRequestSummary(
      serviceDate: _serviceDate(value, status),
      id: id,
      status: _status(value['status'], status),
    );
  }

  /// The day an asking is for, which is never absent and never null.
  ///
  /// Unlike a route's `departure_date`, which is null for a plan. An asking is
  /// always for one journey, so a missing or null value here is drift rather
  /// than a recurring case to handle.
  static DepartureDate _serviceDate(Map<String, Object?> value, int status) {
    final DepartureDate? date = RouteDecoder.date(
      value['service_date'],
      status,
    );
    if (date == null) throw RouteDecoder.malformed(status);

    return date;
  }

  /// One of the caller's own askings.
  static MySeatRequest mine(Object? value, int status) {
    if (value is! Map<String, Object?>) throw RouteDecoder.malformed(status);

    final Object? id = value['id'];
    if (id is! String || id.isEmpty) throw RouteDecoder.malformed(status);

    return MySeatRequest(
      id: id,
      serviceDate: _serviceDate(value, status),
      status: _status(value['status'], status),
      requestedAt: _instant(value['requested_at'], status),
      decidedAt: _optionalInstant(value, 'decided_at', status),
      withdrawnAt: _optionalInstant(value, 'withdrawn_at', status),
      route: _route(value['route'], status),
      // Required and nullable: a response without the key is not this
      // contract, and reading absence as "not reviewed" would offer the
      // control on a journey this member has already rated.
      myReview: ReviewDecoder.within(value, status),
    );
  }

  /// One asking on a journey the caller published.
  static IncomingSeatRequest incoming(Object? value, int status) {
    if (value is! Map<String, Object?>) throw RouteDecoder.malformed(status);

    final Object? id = value['id'];
    if (id is! String || id.isEmpty) throw RouteDecoder.malformed(status);

    return IncomingSeatRequest(
      id: id,
      serviceDate: _serviceDate(value, status),
      status: _status(value['status'], status),
      requestedAt: _instant(value['requested_at'], status),
      decidedAt: _optionalInstant(value, 'decided_at', status),
      withdrawnAt: _optionalInstant(value, 'withdrawn_at', status),
      passenger: member(value['passenger'], status),
      // Required and nullable: a response without the key is not this
      // contract, and reading absence as "not reviewed" would offer the
      // control on a journey this member has already rated.
      myReview: ReviewDecoder.within(value, status),
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
