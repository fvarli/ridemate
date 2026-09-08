// ─────────────────────────────────────────────────────────────
// RideMate — Journeys other members have published
//
// WHAT THIS REQUEST DOES NOT SEND
//
// The Search screen collects seats, filters and a sort order. None of them
// reaches the wire, because the endpoint accepts none of them and refuses
// unknown parameters outright. That refusal is the honest arrangement: a
// parameter the server ignored would leave a member believing a filter worked.
//
// Two place ids, and a position in the result. No coordinates, no radius, no
// distance — the client has no geography and the query performs none.
//
// NO FIXTURE FALLBACK
//
// A failure here means the member sees a failure. Falling back to the mock
// offers would put invented people in front of somebody deciding who to travel
// with, which is the exact lie this phase exists to remove.
// ─────────────────────────────────────────────────────────────

import '../../../core/api/rm_api_client.dart';
import '../../../core/api/rm_failure.dart';
import '../../../core/api/rm_response.dart';
import '../../../core/routes/discovered_route.dart';
import '../../../core/routes/route_decoder.dart';
import '../../../core/session/rm_session.dart';

/// One page of discovery results, as the server returned it.
class DiscoveryResult {
  const DiscoveryResult({required this.routes, required this.nextCursor});

  final List<DiscoveredRoute> routes;

  /// Passed back verbatim and never inspected. Null means there is nothing
  /// after this page — the ONLY end-of-list signal, since an empty list is not
  /// one.
  final String? nextCursor;
}

/// Reads journeys between two places.
abstract interface class DiscoveryRepository {
  /// Journeys from [originPlaceId] to [destinationPlaceId], newest first.
  ///
  /// Throws [RmFailure] — transport, server, or a body that will not decode.
  Future<DiscoveryResult> between({
    required String originPlaceId,
    required String destinationPlaceId,
    String? cursor,
    int limit,
  });
}

/// The page size the contract documents as its default.
const int kDiscoveryPageSize = 20;

class ApiDiscoveryRepository implements DiscoveryRepository {
  const ApiDiscoveryRepository({
    required RmApiClient client,
    required RmSession session,
  }) : _client = client,
       _session = session;

  final RmApiClient _client;
  final RmSession _session;

  @override
  Future<DiscoveryResult> between({
    required String originPlaceId,
    required String destinationPlaceId,
    String? cursor,
    int limit = kDiscoveryPageSize,
  }) async {
    // Through the session, so an expired credential refreshes once and retries
    // once inside this single call. A failure to read journeys is never a
    // reason to take somebody's credential away.
    final RmResponse response = await _session.send(
      (Map<String, String> headers) => _client.get(
        '/api/v1/routes/discover',
        query: <String, String>{
          'origin_place_id': originPlaceId,
          'destination_place_id': destinationPlaceId,
          'limit': '$limit',
          // Absent rather than empty when there is no position to resume from.
          ...?cursor == null ? null : <String, String>{'cursor': cursor},
        },
        headers: headers,
      ),
    );

    return _decode(response);
  }

  /// Strict: a body that will not decode is not a page of results.
  ///
  /// Skipping a malformed row would leave a list quietly short — nobody would
  /// see the gap, least of all the member, who cannot know what should have
  /// been there.
  DiscoveryResult _decode(RmResponse response) {
    final int status = response.status;
    final Object? routes = response.json?['routes'];

    if (routes is! List) throw RouteDecoder.malformed(status);

    final List<DiscoveredRoute> found = <DiscoveredRoute>[];

    for (final Object? entry in routes) {
      found.add(RouteDecoder.discovered(entry, status));
    }

    return DiscoveryResult(
      routes: found,
      nextCursor: switch (response.json?['next_cursor']) {
        final String cursor => cursor,
        null => null,
        _ => throw RouteDecoder.malformed(status),
      },
    );
  }
}
