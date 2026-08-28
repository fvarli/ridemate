// ─────────────────────────────────────────────────────────────
// RideMate — The journeys a member has published
//
// THE CURSOR IS OPAQUE, AND THAT IS LOAD-BEARING
//
// `next_cursor` is a string this client received and sends back unchanged. It
// is not a date, an id, an offset or a page number, and nothing here decodes,
// parses, trims, validates, compares or stores one. The server says plainly
// that what it encodes is free to change; a client that read it would be
// depending on the ordering of a query it cannot see, and would break quietly
// the day that query was tuned.
//
// NULL IS THE END, AN EMPTY PAGE IS NOT
//
// The contract is explicit: only `next_cursor == null` means there is nothing
// after. A page can legitimately come back empty and still have more behind it,
// so stopping on an empty list would sometimes hide a member's own routes from
// them.
//
// ORDER BELONGS TO THE SERVER
//
// Rows arrive newest first by `(created_at desc, id desc)`, keyed on the
// SERVER's clock. Nothing here sorts, reverses or re-ranks: the keyset only
// works if the client reads the list in the order the cursor was cut from.
// ─────────────────────────────────────────────────────────────

import '../../../core/api/rm_api_client.dart';
import '../../../core/api/rm_error_code.dart';
import '../../../core/api/rm_failure.dart';
import '../../../core/api/rm_response.dart';
import '../../../core/routes/published_route.dart';
import '../../../core/routes/route_decoder.dart';
import '../../../core/session/rm_session.dart';

/// How many routes a page asks for.
///
/// The contract's own default. Stated here so the request is explicit rather
/// than relying on a server default that could move underneath the client.
const int kMyRoutesPageSize = 20;

/// One page of the member's routes.
final class MyRoutesResult {
  const MyRoutesResult({required this.routes, required this.nextCursor});

  final List<PublishedRoute> routes;

  /// The token that continues the list, or null when there is nothing after.
  final String? nextCursor;
}

abstract interface class MyRoutesRepository {
  /// The member's own routes, newest first.
  ///
  /// [cursor] is a token from a previous [MyRoutesResult.nextCursor], passed
  /// back verbatim. Throws [RmFailure].
  Future<MyRoutesResult> page({String? cursor, int limit});

  /// Withdraws [routeId], returning the route as the server now holds it.
  ///
  /// Naturally idempotent: cancelling something already cancelled is the same
  /// cancellation observed again, and answers 200 with the same route.
  Future<PublishedRoute> cancel(String routeId);
}

class ApiMyRoutesRepository implements MyRoutesRepository {
  const ApiMyRoutesRepository({
    required RmApiClient client,
    required RmSession session,
  }) : _client = client,
       _session = session;

  final RmApiClient _client;
  final RmSession _session;

  @override
  Future<MyRoutesResult> page({
    String? cursor,
    int limit = kMyRoutesPageSize,
  }) async {
    final RmResponse response = await _session.send(
      (Map<String, String> headers) => _client.get(
        '/api/v1/me/routes',
        headers: headers,
        query: <String, String>{
          'limit': '$limit',
          // Absent on the first page. Sending an empty cursor would be a
          // different request, and the server validates the value it gets.
          'cursor': ?cursor,
        },
      ),
    );

    return _decodePage(response);
  }

  @override
  Future<PublishedRoute> cancel(String routeId) async {
    final RmResponse response = await _session.send(
      (Map<String, String> headers) => _client.post(
        '/api/v1/routes/$routeId/cancel',
        // No body, no `expected_status`, no `Idempotency-Key`. The transition
        // names its own target state, so re-running it is not a second
        // cancellation and needs nothing to make it safe.
        headers: headers,
      ),
    );

    return RouteDecoder.route(response.json?['route'], response.status);
  }

  MyRoutesResult _decodePage(RmResponse response) {
    final Object? routes = response.json?['routes'];

    if (routes is! List) throw _malformed(response);

    // `next_cursor` is required by the contract and may be null. Absent is not
    // the same as null: a response missing the key is not this contract, and
    // reading a missing key as "the end" would silently truncate the list.
    if (response.json?.containsKey('next_cursor') != true) {
      throw _malformed(response);
    }

    final Object? cursor = response.json?['next_cursor'];
    if (cursor != null && cursor is! String) throw _malformed(response);

    return MyRoutesResult(
      routes: <PublishedRoute>[
        // A row that will not decode fails the page. Skipping it would leave a
        // list quietly short — and the member is the one person who would
        // notice a journey missing and have no way to explain it.
        for (final Object? entry in routes)
          RouteDecoder.route(entry, response.status),
      ],
      nextCursor: cursor as String?,
    );
  }

  RmFailure _malformed(RmResponse response) => RmFailure.fromBackend(
    status: response.status,
    code: RmErrorCode.unexpected,
  );
}
