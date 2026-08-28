// ─────────────────────────────────────────────────────────────
// RideMate — Publishing a journey
//
// THE ID ARRIVES; IT IS NOT MADE HERE
//
// A publication command carries the id the caller already minted. That is
// deliberate: the id IS the idempotency mechanism, so whoever owns the
// intention to publish must own the id, and it has to survive a retry. A
// repository that generated one per call would mint a fresh id for every
// attempt and publish the same journey twice over a flaky connection.
//
// 201 AND 200 MEAN THE SAME THING
//
// 201 is "created now", 200 is "this exact journey already exists under this
// id". After a request that timed out, a retry legitimately returns 200 — and
// treating that as anything other than success would tell a driver their
// journey had failed while it sat published on the server.
// ─────────────────────────────────────────────────────────────

import '../../../core/api/rm_api_client.dart';
import '../../../core/api/rm_error_code.dart';
import '../../../core/api/rm_failure.dart';
import '../../../core/api/rm_response.dart';
import '../../../core/places/place.dart';
import '../../../core/session/rm_session.dart';
import '../domain/create_route_draft.dart';
import '../domain/departure.dart';
import '../domain/published_route.dart';

/// One intention to publish, with the id that identifies it.
final class RoutePublicationCommand {
  const RoutePublicationCommand({required this.id, required this.draft});

  /// The client-generated UUIDv7. The same intention keeps the same id.
  final String id;
  final CreateRouteDraft draft;

  /// The request body, and nothing but the request body.
  ///
  /// Notice what is not here. No timezone: the server owns the pilot's zone
  /// and a client that named one could move its own deadline. No account id:
  /// ownership comes from the credential, and a field naming an owner could
  /// publish in somebody else's name. No coordinates, slug or label: the
  /// endpoints are ids the server issued. No cost: RideMate charges nobody.
  /// No status, timestamps or departure state: those are answers, not
  /// requests.
  Map<String, Object?> toJson() {
    final Place? origin = draft.origin;
    final Place? destination = draft.destination;
    final DepartureTime? time = draft.departureTime;

    if (origin == null || destination == null || time == null) {
      // Unreachable through the UI, which will not publish an unfinished
      // draft. Stated as an error rather than a silent default, because a
      // default here would invent part of somebody's journey.
      throw StateError('A publication needs both endpoints and a time.');
    }

    return <String, Object?>{
      'id': id,
      'origin_place_id': origin.id,
      'destination_place_id': destination.id,
      'recurrence': draft.recurrence.name,
      // Present only for a one-off journey. The contract's oneOf refuses a
      // weekday commute that carries a date, and so does the database.
      if (draft.recurrence.needsDate && draft.departureDate != null)
        'departure_date': draft.departureDate!.iso,
      'departure_time': time.hhMm,
      'seats_offered': draft.seats,
      'rules': rulesToJson(draft.rules),
    };
  }

  /// The one place a rule's wire name is decided.
  ///
  /// Exhaustive on purpose: adding a RideRuleId stops this compiling rather
  /// than silently sending `false` for a preference the driver expressed.
  /// Serializing by enum name would have been shorter and would have broken
  /// the day somebody renamed a case.
  static String wireKey(RideRuleId id) => switch (id) {
    RideRuleId.noSmoking => 'no_smoking',
    RideRuleId.musicOk => 'music_ok',
    RideRuleId.noPets => 'no_pets',
    RideRuleId.quiet => 'quiet',
  };

  /// Every rule, always — the contract requires all four booleans.
  static Map<String, bool> rulesToJson(Set<RideRuleId> rules) => <String, bool>{
    for (final RideRuleId id in RideRuleId.values)
      wireKey(id): rules.contains(id),
  };
}

abstract interface class RouteRepository {
  /// Publishes [command], or throws [RmFailure].
  Future<PublishedRoute> publish(RoutePublicationCommand command);
}

class ApiRouteRepository implements RouteRepository {
  const ApiRouteRepository({
    required RmApiClient client,
    required RmSession session,
  }) : _client = client,
       _session = session;

  final RmApiClient _client;
  final RmSession _session;

  @override
  Future<PublishedRoute> publish(RoutePublicationCommand command) async {
    final RmResponse response = await _session.send(
      (Map<String, String> headers) => _client.post(
        '/api/v1/routes',
        json: command.toJson(),
        headers: headers,
      ),
    );

    return _decode(response);
  }

  PublishedRoute _decode(RmResponse response) {
    final Object? route = response.json?['route'];

    if (route is! Map<String, Object?>) throw _malformed(response);

    final Object? id = route['id'];
    final Object? recurrence = route['recurrence'];
    final Object? time = route['departure_time'];
    final Object? timezone = route['timezone'];
    final Object? state = route['departure_state'];
    final Object? seats = route['seats_offered'];
    final Object? status = route['status'];
    final Object? publishedAt = route['published_at'];

    if (id is! String ||
        recurrence is! String ||
        time is! String ||
        timezone is! String ||
        state is! String ||
        seats is! int ||
        status is! String ||
        publishedAt is! String) {
      throw _malformed(response);
    }

    return PublishedRoute(
      id: id,
      origin: _place(route['origin'], response),
      destination: _place(route['destination'], response),
      recurrence: _enumByName(Recurrence.values, recurrence, response),
      departureDate: _date(route['departure_date'], response),
      departureTime: _time(time, response),
      timezone: timezone,
      departureState: _enumByName(DepartureState.values, state, response),
      seatsOffered: seats,
      rules: _rules(route['rules'], response),
      status: _enumByName(RouteStatus.values, status, response),
      publishedAt: publishedAt,
      cancelledAt: switch (route['cancelled_at']) {
        final String value => value,
        null => null,
        _ => throw _malformed(response),
      },
    );
  }

  Place _place(Object? value, RmResponse response) {
    if (value is! Map<String, Object?>) throw _malformed(response);

    final Object? id = value['id'];
    final Object? label = value['label'];

    if (id is! String || label is! String) throw _malformed(response);

    return Place(id: id, label: label);
  }

  DepartureDate? _date(Object? value, RmResponse response) {
    if (value == null) return null;
    if (value is! String) throw _malformed(response);

    final List<String> parts = value.split('-');
    if (parts.length != 3) throw _malformed(response);

    final int? year = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? day = int.tryParse(parts[2]);

    if (year == null || month == null || day == null)
      throw _malformed(response);

    return DepartureDate(year: year, month: month, day: day);
  }

  DepartureTime _time(String value, RmResponse response) {
    final List<String> parts = value.split(':');
    if (parts.length != 2) throw _malformed(response);

    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) throw _malformed(response);

    return DepartureTime(hour: hour, minute: minute);
  }

  /// Read back through the same key mapping that wrote them.
  Set<RideRuleId> _rules(Object? value, RmResponse response) {
    if (value is! Map<String, Object?>) throw _malformed(response);

    final Set<RideRuleId> selected = <RideRuleId>{};

    for (final RideRuleId id in RideRuleId.values) {
      final Object? flag = value[RoutePublicationCommand.wireKey(id)];
      if (flag is! bool) throw _malformed(response);

      if (flag) selected.add(id);
    }

    return selected;
  }

  T _enumByName<T extends Enum>(
    List<T> values,
    String name,
    RmResponse response,
  ) {
    for (final T value in values) {
      if (value.name == name) return value;
    }

    // A value this build has never heard of. Guessing would put a route into a
    // state the app cannot reason about.
    throw _malformed(response);
  }

  RmFailure _malformed(RmResponse response) => RmFailure.fromBackend(
    status: response.status,
    code: RmErrorCode.unexpected,
  );
}
