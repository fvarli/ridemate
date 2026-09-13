// ─────────────────────────────────────────────────────────────
// RideMate — The six things a member can do about a seat
//
// One repository, because they are one contract: a passenger asks, lists and
// withdraws; the driver who owns the journey lists, accepts and declines. The
// commands answer with the resource they changed, so nothing here has to guess
// what the new state is.
//
// CURSORS ARE OPAQUE AND STAY THAT WAY
//
// Received and sent back unchanged. Nothing parses, decodes, times, persists or
// orders by one — the server owns the position, and two feeds tag their cursors
// so neither accepts the other's.
// ─────────────────────────────────────────────────────────────

import '../../../core/api/rm_api_client.dart';
import '../../../core/api/rm_error_code.dart';
import '../../../core/api/rm_failure.dart';
import '../../../core/api/rm_response.dart';
import '../../../core/routes/departure.dart';
import '../../../core/seat_requests/seat_request.dart';
import '../../../core/seat_requests/seat_request_decoder.dart';
import '../../../core/session/rm_session.dart';

/// One page of a member's own askings.
class MySeatRequestsResult {
  const MySeatRequestsResult({
    required this.requests,
    required this.nextCursor,
  });

  final List<MySeatRequest> requests;

  /// Null means the end of the list — an empty page does not.
  final String? nextCursor;
}

/// One page of the askings on a journey the caller published.
class IncomingSeatRequestsResult {
  const IncomingSeatRequestsResult({
    required this.requests,
    required this.nextCursor,
  });

  final List<IncomingSeatRequest> requests;
  final String? nextCursor;
}

/// The outcome of asking, with the one distinction the wire draws.
///
/// [wasAlreadyRequested] separates `201` from `200`. **The resource is the same
/// either way** — a retry returns the asking that already landed, not a
/// different one — so this says how it arrived and never what it is.
class SeatRequested {
  const SeatRequested({
    required this.request,
    required this.wasAlreadyRequested,
  });

  final MySeatRequest request;
  final bool wasAlreadyRequested;
}

abstract interface class SeatRequestRepository {
  /// Asks for a seat on one dated journey.
  ///
  /// [requestId] is a client-generated UUIDv7 and is the idempotency key: the
  /// same id is the same asking.
  ///
  /// [serviceDate] says which of the route's journeys. It is REQUIRED by the
  /// server for a recurring plan, which has one per day it runs, and optional
  /// for a one-off route — where, if sent, it must be that route's own day.
  /// Sending it either way keeps one call shape: the caller already knows which
  /// journey it means, and a client that omitted it would be asking the server
  /// to guess on a surface where guessing is exactly what Phase 16b removed.
  Future<SeatRequested> ask({
    required String routeId,
    required String requestId,
    DepartureDate? serviceDate,
  });

  Future<MySeatRequestsResult> mine({String? cursor, int limit});

  Future<MySeatRequest> withdraw(String requestId);

  Future<IncomingSeatRequestsResult> forRoute(
    String routeId, {
    String? cursor,
    int limit,
  });

  Future<IncomingSeatRequest> accept(String requestId);

  Future<IncomingSeatRequest> decline(String requestId);
}

/// The contract's default page size, and its ceiling.
const int kSeatRequestPageSize = 20;

class ApiSeatRequestRepository implements SeatRequestRepository {
  const ApiSeatRequestRepository({
    required RmApiClient client,
    required RmSession session,
  }) : _client = client,
       _session = session;

  final RmApiClient _client;
  final RmSession _session;

  @override
  Future<SeatRequested> ask({
    required String routeId,
    required String requestId,
    DepartureDate? serviceDate,
  }) async {
    final RmResponse response = await _session.send(
      (Map<String, String> headers) => _client.post(
        '/api/v1/routes/$routeId/seat-requests',
        json: <String, Object?>{
          'id': requestId,
          // Absent rather than null when the caller names no day: the server
          // refuses the key with a null value, and a one-off route derives its
          // own.
          if (serviceDate != null) 'service_date': serviceDate.iso,
        },
        headers: headers,
      ),
    );

    return SeatRequested(
      request: SeatRequestDecoder.mine(
        response.json?['seat_request'],
        response.status,
      ),
      // 201 created it, 200 found it already there. Any other 2xx is not this
      // contract and is refused rather than read as one of the two.
      wasAlreadyRequested: switch (response.status) {
        201 => false,
        200 => true,
        _ => throw _malformed(response),
      },
    );
  }

  @override
  Future<MySeatRequestsResult> mine({
    String? cursor,
    int limit = kSeatRequestPageSize,
  }) async {
    final RmResponse response = await _session.send(
      (Map<String, String> headers) => _client.get(
        '/api/v1/me/seat-requests',
        query: _page(cursor, limit),
        headers: headers,
      ),
    );

    return MySeatRequestsResult(
      requests: <MySeatRequest>[
        for (final Object? entry in _rows(response))
          SeatRequestDecoder.mine(entry, response.status),
      ],
      nextCursor: _cursor(response),
    );
  }

  @override
  Future<MySeatRequest> withdraw(String requestId) async {
    final RmResponse response = await _session.send(
      (Map<String, String> headers) => _client.post(
        '/api/v1/seat-requests/$requestId/withdraw',
        // No body: the transition names its own target state, so repeating it
        // is the same withdrawal observed again.
        headers: headers,
      ),
    );

    return SeatRequestDecoder.mine(
      response.json?['seat_request'],
      response.status,
    );
  }

  @override
  Future<IncomingSeatRequestsResult> forRoute(
    String routeId, {
    String? cursor,
    int limit = kSeatRequestPageSize,
  }) async {
    final RmResponse response = await _session.send(
      (Map<String, String> headers) => _client.get(
        '/api/v1/routes/$routeId/seat-requests',
        query: _page(cursor, limit),
        headers: headers,
      ),
    );

    return IncomingSeatRequestsResult(
      requests: <IncomingSeatRequest>[
        for (final Object? entry in _rows(response))
          SeatRequestDecoder.incoming(entry, response.status),
      ],
      nextCursor: _cursor(response),
    );
  }

  @override
  Future<IncomingSeatRequest> accept(String requestId) =>
      _decide(requestId, 'accept');

  @override
  Future<IncomingSeatRequest> decline(String requestId) =>
      _decide(requestId, 'decline');

  Future<IncomingSeatRequest> _decide(String requestId, String verb) async {
    final RmResponse response = await _session.send(
      (Map<String, String> headers) => _client.post(
        '/api/v1/seat-requests/$requestId/$verb',
        headers: headers,
      ),
    );

    return SeatRequestDecoder.incoming(
      response.json?['seat_request'],
      response.status,
    );
  }

  Map<String, String> _page(String? cursor, int limit) => <String, String>{
    'limit': '$limit',
    // Sent back exactly as received. Nothing here builds or inspects one.
    ...?cursor == null ? null : <String, String>{'cursor': cursor},
  };

  List<Object?> _rows(RmResponse response) {
    final Object? rows = response.json?['seat_requests'];
    if (rows is! List) throw _malformed(response);

    return rows;
  }

  String? _cursor(RmResponse response) {
    // Required by the contract and may be null. Absent is not the same as
    // null: a response missing the key is not this contract, and reading a
    // missing key as "the end" would silently truncate the list.
    if (response.json?.containsKey('next_cursor') != true) {
      throw _malformed(response);
    }

    final Object? cursor = response.json?['next_cursor'];
    if (cursor != null && cursor is! String) throw _malformed(response);

    return cursor as String?;
  }

  RmFailure _malformed(RmResponse response) => RmFailure.fromBackend(
    status: response.status,
    code: RmErrorCode.unexpected,
  );
}
