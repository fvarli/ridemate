// ─────────────────────────────────────────────────────────────
// RideMate — The driver's dated journeys, and the commands that move them
//
// EVERY METHOD NAMES THE DAY
//
// A journey is a route on a date, so nothing here takes a route alone. There is
// no `current`, no `today`, no `next` and no `latest`: each would be this client
// choosing a journey on the driver's behalf, and the one it chose would
// sometimes be the wrong one — silently, because a route id and a plausible
// answer look exactly like a correct one.
//
// WHY THE COMMANDS LIVE HERE AND NOT BESIDE MY ROUTES
//
// `MyRoutesRepository` keeps the three route-only commands Phase 14 shipped.
// They are the compatibility form and address a one-off route's single journey;
// a plan is refused there with `recurring_route_unsupported` rather than
// guessed at. These are the dated form, and they are journey-scoped in the same
// way the reads above them are. Keeping them apart is what stops a caller
// reaching for the route-only one when it has a date in hand.
//
// THE CURSOR IS OPAQUE, AND THAT IS LOAD-BEARING
//
// `next_cursor` is a string this client received and sends back unchanged.
// Nothing here decodes, parses, trims, validates, compares or stores one. It
// belongs to this feed alone — one from another list is refused by the server
// rather than resumed.
//
// NULL IS THE END, AN EMPTY PAGE IS NOT
//
// Only `next_cursor == null` means there is nothing after. Stopping on an empty
// list would sometimes hide a driver's own journeys from them.
//
// ORDER BELONGS TO THE SERVER
//
// Rows arrive by `(service_date, route_id)` descending. Nothing here sorts,
// reverses or re-ranks: the keyset only works if the client reads the list in
// the order the cursor was cut from. That order is deterministic and is NOT a
// global chronology — routes carry their own timezones — so nothing may present
// it as one.
// ─────────────────────────────────────────────────────────────

import '../../../core/api/rm_api_client.dart';
import '../../../core/api/rm_error_code.dart';
import '../../../core/api/rm_failure.dart';
import '../../../core/api/rm_response.dart';
import '../../../core/journeys/journey.dart';
import '../../../core/journeys/journey_decoder.dart';
import '../../../core/routes/departure.dart';
import '../../../core/session/rm_session.dart';
import '../../../core/trips/trip_decoder.dart';
import '../../../core/trips/trip_lifecycle.dart';

/// How many journeys a page asks for. The contract's own default, stated so
/// the request does not rely on a server default that could move.
const int kMyJourneysPageSize = 20;

/// One page of the driver's dated journeys.
final class MyJourneysResult {
  const MyJourneysResult({required this.journeys, required this.nextCursor});

  final List<Journey> journeys;

  /// The token that continues the list, or null when there is nothing after.
  final String? nextCursor;
}

abstract interface class JourneysRepository {
  /// The journeys the driver can act on now.
  ///
  /// **Bounded, and not a history.** The server returns today's journey of each
  /// published route that runs today, plus any journey of theirs still under
  /// way whatever its date. Yesterday's finished journeys are not here and
  /// neither is tomorrow's; [journey] reads any other day.
  ///
  /// [cursor] is a token from a previous [MyJourneysResult.nextCursor], passed
  /// back verbatim. Throws [RmFailure].
  Future<MyJourneysResult> page({String? cursor, int limit});

  /// One dated journey of the caller's own route.
  ///
  /// Unbounded, unlike [page]: any day the route runs on can be read, ahead or
  /// behind, started or not. A day with no trip answers `notStarted`.
  ///
  /// A route that is not the caller's, and a day this route does not run on,
  /// both answer 404 — they are indistinguishable on purpose.
  Future<Journey> journey({
    required String routeId,
    required DepartureDate serviceDate,
  });

  /// Says the journey on that day is under way.
  Future<TripLifecycle> startTrip({
    required String routeId,
    required DepartureDate serviceDate,
  });

  /// Says the journey on that day was made.
  Future<TripLifecycle> completeTrip({
    required String routeId,
    required DepartureDate serviceDate,
  });

  /// Says the journey on that day was abandoned. No reason is sent; none is
  /// stored.
  Future<TripLifecycle> abortTrip({
    required String routeId,
    required DepartureDate serviceDate,
  });
}

class ApiJourneysRepository implements JourneysRepository {
  const ApiJourneysRepository({
    required RmApiClient client,
    required RmSession session,
  }) : _client = client,
       _session = session;

  final RmApiClient _client;
  final RmSession _session;

  @override
  Future<MyJourneysResult> page({
    String? cursor,
    int limit = kMyJourneysPageSize,
  }) async {
    final RmResponse response = await _session.send(
      (Map<String, String> headers) => _client.get(
        '/api/v1/me/journeys',
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
  Future<Journey> journey({
    required String routeId,
    required DepartureDate serviceDate,
  }) async {
    final RmResponse response = await _session.send(
      (Map<String, String> headers) =>
          _client.get(_path(routeId, serviceDate), headers: headers),
    );

    return JourneyDecoder.journey(response.json, response.status);
  }

  @override
  Future<TripLifecycle> startTrip({
    required String routeId,
    required DepartureDate serviceDate,
  }) =>
      // 201 the first time, 200 for a repeat. Both are successes describing the
      // same trip, and which one arrived is not product truth: the lifecycle in
      // the body is.
      _command(routeId, serviceDate, 'start', accepting: const <int>{201, 200});

  @override
  Future<TripLifecycle> completeTrip({
    required String routeId,
    required DepartureDate serviceDate,
  }) =>
      // No 201: nothing is created. The trip already exists and this names the
      // state it should end in.
      _command(routeId, serviceDate, 'complete', accepting: const <int>{200});

  @override
  Future<TripLifecycle> abortTrip({
    required String routeId,
    required DepartureDate serviceDate,
  }) => _command(routeId, serviceDate, 'abort', accepting: const <int>{200});

  /// One of the three dated lifecycle commands.
  ///
  /// All bodyless. Each names its own target state, so repeating it is the same
  /// command observed again and needs nothing to make it safe: no
  /// `Idempotency-Key`, no `expected_status`, no client timestamp, no
  /// coordinates. The journey in the PATH is what makes it idempotent.
  Future<TripLifecycle> _command(
    String routeId,
    DepartureDate serviceDate,
    String verb, {
    required Set<int> accepting,
  }) async {
    final RmResponse response = await _session.send(
      (Map<String, String> headers) => _client.post(
        '${_path(routeId, serviceDate)}/trip/$verb',
        headers: headers,
      ),
    );

    // A 2xx the contract does not document is not this contract, and is
    // refused rather than read as one of the ones that are.
    if (!accepting.contains(response.status)) throw _malformed(response);

    return TripDecoder.lifecycle(response.json?['trip'], response.status);
  }

  /// The journey's address, which every read and command here is built on.
  ///
  /// One place spells it, so a command cannot come to name the day differently
  /// from the read beside it — or omit it, which would silently fall back to
  /// the route-only endpoints and their one-off-only meaning.
  String _path(String routeId, DepartureDate serviceDate) =>
      '/api/v1/routes/$routeId/journeys/${serviceDate.iso}';

  MyJourneysResult _decodePage(RmResponse response) {
    final Object? journeys = response.json?['journeys'];

    if (journeys is! List) throw _malformed(response);

    // `next_cursor` is required by the contract and may be null. Absent is not
    // the same as null: a response missing the key is not this contract, and
    // reading a missing key as "the end" would silently truncate the list.
    if (response.json?.containsKey('next_cursor') != true) {
      throw _malformed(response);
    }

    final Object? cursor = response.json?['next_cursor'];
    if (cursor != null && cursor is! String) throw _malformed(response);

    return MyJourneysResult(
      journeys: <Journey>[
        // A row that will not decode fails the page. Skipping it would leave a
        // list quietly short — and the driver is the one person who would
        // notice a journey missing and have no way to explain it.
        for (final Object? entry in journeys)
          JourneyDecoder.journey(entry, response.status),
      ],
      nextCursor: cursor as String?,
    );
  }

  RmFailure _malformed(RmResponse response) => RmFailure.fromBackend(
    status: response.status,
    code: RmErrorCode.unexpected,
  );
}
