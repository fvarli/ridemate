// ─────────────────────────────────────────────────────────────
// RideMate — Reading a dated journey off the wire
//
// Strict, in the same idiom as RouteDecoder and SeatRequestDecoder: a field
// that is missing, null where it must not be, or of the wrong type refuses the
// whole response rather than producing a partial object.
//
// `service_date` IS NOT `departure_date`
//
// A route's departure date is null for a plan. A journey's service date never
// is: a journey is one day by definition, so a null here is drift rather than a
// recurring case to handle. They are read by the same parser and checked
// differently, which is the point.
// ─────────────────────────────────────────────────────────────

import '../routes/departure.dart';
import '../routes/published_route.dart';
import '../routes/route_decoder.dart';
import '../trips/trip_decoder.dart';
import 'journey.dart';

abstract final class JourneyDecoder {
  const JourneyDecoder._();

  /// One dated journey, or throws [RmFailure].
  static Journey journey(Object? value, int status) {
    if (value is! Map<String, Object?>) throw RouteDecoder.malformed(status);

    final Object? routeId = value['route_id'];
    final Object? departureTime = value['departure_time'];
    final Object? timezone = value['timezone'];
    final Object? routeStatus = value['route_status'];

    if (routeId is! String ||
        routeId.isEmpty ||
        departureTime is! String ||
        timezone is! String ||
        routeStatus is! String) {
      throw RouteDecoder.malformed(status);
    }

    final DepartureDate? serviceDate = RouteDecoder.date(
      value['service_date'],
      status,
    );
    if (serviceDate == null) throw RouteDecoder.malformed(status);

    return Journey(
      routeId: routeId,
      serviceDate: serviceDate,
      origin: RouteDecoder.place(value['origin'], status),
      destination: RouteDecoder.place(value['destination'], status),
      departureTime: RouteDecoder.time(departureTime, status),
      timezone: timezone,
      // The PLAN's status, read with the same vocabulary a route's is: a value
      // this build has never heard of refuses the response.
      routeStatus: RouteDecoder.byName(RouteStatus.values, routeStatus, status),
      // Required and never null on this surface, unlike `MyRoute.trip`.
      trip: TripDecoder.within(value, status),
    );
  }
}
