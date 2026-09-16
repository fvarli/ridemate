// ─────────────────────────────────────────────────────────────
// RideMate — Reading a route the server sent
//
// ONE DECODER, THREE PROJECTIONS
//
// `POST /routes` and `POST /routes/{id}/cancel` return a plain route.
// `GET /me/routes` returns the same route plus the lifecycle of its journey,
// and discovery returns a different projection again. They share every field
// they have in common by sharing this reader — decoding them in two places
// would mean fixing a strictness bug in one and not the other, and the half
// that kept the bug would be the one nobody was looking at.
//
// What the owner's list adds is composed on top rather than folded in. See
// `MyRoute`.
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
import '../seat_requests/seat_request_decoder.dart';
import '../trips/trip_decoder.dart';
import 'departure.dart';
import 'discovered_route.dart';
import 'my_route.dart';
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
    if (value is! Map<String, Object?>) throw malformed(status);

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
      throw malformed(status);
    }

    return PublishedRoute(
      id: id,
      origin: place(value['origin'], status),
      destination: place(value['destination'], status),
      recurrence: byName(Recurrence.values, recurrence, status),
      departureDate: date(value['departure_date'], status),
      departureTime: RouteDecoder.time(time, status),
      timezone: timezone,
      departureState: byName(DepartureState.values, state, status),
      seatsOffered: seats,
      rules: rules(value['rules'], status),
      status: byName(RouteStatus.values, routeStatus, status),
      publishedAt: publishedAt,
      cancelledAt: switch (value['cancelled_at']) {
        final String value => value,
        null => null,
        _ => throw malformed(status),
      },
    );
  }

  /// Decodes a route as its own member sees it, lifecycle included.
  ///
  /// `trip` is required here and absent from [route], which mirrors the
  /// contract exactly: the owner's list is the only route projection that says
  /// whether the journey was made — and since Phase 16b it says `null` for a
  /// recurring plan, which has a journey per day it runs and so has no
  /// lifecycle of its own.
  static MyRoute myRoute(Object? value, int status) {
    if (value is! Map<String, Object?>) throw malformed(status);

    return MyRoute(
      route: route(value, status),
      // Required key, nullable value: a plan has no single journey, so its
      // lifecycle is null rather than `not_started`. See TripDecoder.
      trip: TripDecoder.withinNullable(value, status),
    );
  }

  /// Decodes the DISCOVERY projection of a route, which is not the owner's.
  ///
  /// Narrower on purpose: no `status`, no `published_at`, no `cancelled_at` —
  /// every route in a discovery response is published and upcoming by
  /// construction, and when a row was written is not a fact about the journey.
  /// It gains a driver, which the owner's view has no need of.
  ///
  /// It lives here rather than in the feature so that a DepartureState is built
  /// from a response in exactly one place, which a boundary guard asserts.
  static DiscoveredRoute discovered(Object? value, int status) {
    if (value is! Map<String, Object?>) throw malformed(status);

    final Object? id = value['id'];
    final Object? recurrence = value['recurrence'];
    final Object? departureTime = value['departure_time'];
    final Object? timezone = value['timezone'];
    final Object? state = value['departure_state'];
    final Object? seats = value['seats_offered'];

    if (id is! String ||
        recurrence is! String ||
        departureTime is! String ||
        timezone is! String ||
        state is! String ||
        seats is! int ||
        // Always present on the wire, null for a recurring journey. A missing
        // key is drift, not a weekday route, so it is refused rather than read
        // as one.
        !value.containsKey('departure_date')) {
      throw malformed(status);
    }

    return DiscoveredRoute(
      id: id,
      origin: place(value['origin'], status),
      destination: place(value['destination'], status),
      recurrence: byName(Recurrence.values, recurrence, status),
      departureDate: date(value['departure_date'], status),
      departureTime: time(departureTime, status),
      timezone: timezone,
      departureState: byName(DepartureState.values, state, status),
      seatsOffered: seats,
      rules: rules(value['rules'], status),
      driver: driver(value['driver'], status),
      // Required on the wire and possibly empty, never absent, and never
      // computed here. See DiscoveredRoute.requestableServiceDates.
      requestableServiceDates: serviceDates(value, status),
      // Required on the wire and possibly empty, never absent. See
      // SeatRequestDecoder.
      mySeatRequests: SeatRequestDecoder.summaries(value, status),
    );
  }

  /// The days a route may be asked about, as the server ordered them.
  ///
  /// **Required, and absence is refused rather than read as none.** A backend
  /// that stopped sending the key would silently take every recurring plan's
  /// action away, and the screen would look like a product decision instead of
  /// a contract break. Empty is a real answer and arrives as an empty list.
  ///
  /// **The order is the server's and is not re-derived.** Sorting here would
  /// hide a backend that stopped sorting, and a client that sorted differently
  /// would show a different first option to the same member on two builds.
  ///
  /// Each entry goes through [date], so a value that is not a calendar day is a
  /// malformed response rather than a date nobody can act on: these are path
  /// identities now, and `2026-02-30` would be sent straight back to an
  /// endpoint that would refuse it.
  static List<DepartureDate> serviceDates(
    Map<String, Object?> value,
    int status,
  ) {
    final Object? days = value['requestable_service_dates'];

    if (days is! List) throw malformed(status);

    return <DepartureDate>[
      for (final Object? day in days) _serviceDate(day, status),
    ];
  }

  static DepartureDate _serviceDate(Object? value, int status) {
    final DepartureDate? day = date(value, status);

    // `date` answers null for an absent day, which is meaningful where a
    // departure date is nullable. An entry of this list is never absent: a
    // null here is a hole in a list of days, and a hole cannot be asked about.
    if (day == null) throw malformed(status);

    return day;
  }

  /// The two fields a profile has, both taken as given.
  ///
  /// Initials are the server's. Deriving them here would be a second
  /// implementation of a rule the backend owns, and Turkish casing is where the
  /// two would part company.
  static DiscoveredDriver driver(Object? value, int status) {
    if (value is! Map<String, Object?>) throw malformed(status);

    final Object? name = value['display_name'];
    final Object? initials = value['initials'];

    if (name is! String ||
        initials is! String ||
        name.isEmpty ||
        initials.isEmpty) {
      throw malformed(status);
    }

    return DiscoveredDriver(displayName: name, initials: initials);
  }

  /// Decodes a place as the contract publishes it: an id and a label, nothing
  /// else. The catalogue behind it also holds coordinates and a slug; they are
  /// not on the wire and there is nowhere here for them to land.
  static Place place(Object? value, int status) {
    if (value is! Map<String, Object?>) throw malformed(status);

    final Object? id = value['id'];
    final Object? label = value['label'];

    if (id is! String || label is! String) throw malformed(status);

    return Place(id: id, label: label);
  }

  /// The failure an unreadable response produces.
  ///
  /// Public, with the helpers below, because Discovery decodes a DIFFERENT
  /// projection of the same route fields. Restating how a date, a time or a
  /// rule set is read would be a second answer to a question this file already
  /// answers — and the two would drift on the day one of them is corrected.
  ///
  /// Carries the status deliberately. A body that will not decode on a 201 may
  /// be a route that now exists, while the same code on a 404 is the server
  /// saying no — and only the status separates them.
  static RmFailure malformed(int status) =>
      RmFailure.fromBackend(status: status, code: RmErrorCode.unexpected);

  /// A calendar day in `YYYY-MM-DD`, or null where the contract allows one.
  ///
  /// STRICT ABOUT THE SHAPE, AND ABOUT THE CALENDAR
  ///
  /// The contract's own pattern is four digits, two, two. Splitting on `-` and
  /// parsing each part accepts `16-09-2026` as the year 16 — a value that then
  /// travels back out in a path and 404s, with nothing in between to say why.
  /// It also accepts `2026-02-30`, which is not a day; a client that held one
  /// would address a journey the server has no row for.
  ///
  /// So the shape is checked, and then the parse is checked by writing the
  /// result back and requiring it to equal what arrived — the only way to tell
  /// "parsed" from "parsed into something else". This mirrors what the backend
  /// does on the way in, which is the point: two ends of one contract should
  /// refuse the same values.
  static DepartureDate? date(Object? value, int status) {
    if (value == null) return null;
    if (value is! String) throw malformed(status);
    if (!_dayShape.hasMatch(value)) throw malformed(status);

    final List<String> parts = value.split('-');
    final int? year = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? day = int.tryParse(parts[2]);

    if (year == null || month == null || day == null) {
      throw malformed(status);
    }

    final DepartureDate parsed = DepartureDate(
      year: year,
      month: month,
      day: day,
    );

    // A rollover is a different day, not a typo fixed: February the 30th
    // becomes March the 2nd in a permissive reader, and nothing downstream
    // could tell.
    if (DateTime(year, month, day).day != day ||
        DateTime(year, month, day).month != month) {
      throw malformed(status);
    }

    return parsed;
  }

  static final RegExp _dayShape = RegExp(r'^[0-9]{4}-[0-9]{2}-[0-9]{2}$');

  static DepartureTime time(String value, int status) {
    final List<String> parts = value.split(':');
    if (parts.length != 2) throw malformed(status);

    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) throw malformed(status);

    return DepartureTime(hour: hour, minute: minute);
  }

  /// Read back through the same key mapping that writes them.
  ///
  /// Every one of the four must be present and boolean. A missing rule is not
  /// the same as a rule set to false, and treating it as one would quietly
  /// invent an answer on the driver's behalf.
  static Set<RideRuleId> rules(Object? value, int status) {
    if (value is! Map<String, Object?>) throw malformed(status);

    for (final RideRuleId id in RideRuleId.values) {
      if (value[rideRuleWireKey(id)] is! bool) throw malformed(status);
    }

    return rideRulesFromFlags((String key) => value[key] == true);
  }

  static T byName<T extends Enum>(List<T> values, String name, int status) {
    for (final T value in values) {
      if (value.name == name) return value;
    }

    // A value this build has never heard of.
    throw malformed(status);
  }
}
