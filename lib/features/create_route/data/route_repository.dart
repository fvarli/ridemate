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
import '../../../core/api/rm_response.dart';
import '../../../core/places/place.dart';
import '../../../core/routes/departure.dart';
import '../../../core/routes/published_route.dart';
import '../../../core/routes/ride_rule.dart';
import '../../../core/routes/route_decoder.dart';
import '../../../core/session/rm_session.dart';
import '../domain/create_route_draft.dart';

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
      'rules': rideRulesToJson(draft.rules),
    };
  }
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

  /// Decoded by the shared reader, because `GET /me/routes` returns exactly
  /// this shape and two decoders would drift.
  PublishedRoute _decode(RmResponse response) =>
      RouteDecoder.route(response.json?['route'], response.status);
}
