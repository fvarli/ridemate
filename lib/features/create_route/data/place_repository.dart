// ─────────────────────────────────────────────────────────────
// RideMate — The pilot place catalogue
//
// The places a driver may start and end at, as the server publishes them.
//
// WHY THERE IS NO FIXTURE FALLBACK
//
// If this request fails, the picker has nothing to show, and that is the
// honest outcome. Falling back to the five mock places would put a list in
// front of a driver that the server does not recognise: they would choose one,
// publishing would fail on an id nobody has ever heard of, and the failure
// would surface three screens later as something unrelated. A visible error
// with a retry is a worse moment and a better product.
//
// WHY A BAD ROW FAILS THE WHOLE REQUEST
//
// Skipping malformed entries would leave a catalogue that is quietly short.
// Nobody would see the gap — not the driver, who cannot know what should have
// been there, and not the logs, because nothing went wrong as far as the loop
// was concerned. A place that will not decode means this response is not the
// catalogue, and saying so is the only thing that stays true.
// ─────────────────────────────────────────────────────────────

import '../../../core/api/rm_api_client.dart';
import '../../../core/api/rm_error_code.dart';
import '../../../core/api/rm_failure.dart';
import '../../../core/api/rm_response.dart';
import '../../../core/places/place.dart';
import '../../../core/session/rm_session.dart';

/// Reads the catalogue a route's endpoints must come from.
abstract interface class PlaceRepository {
  /// Every place the pilot supports, in the order the server returns them.
  ///
  /// Throws [RmFailure] — transport, server or malformed — and never returns a
  /// partial list.
  Future<List<Place>> catalogue();
}

class ApiPlaceRepository implements PlaceRepository {
  const ApiPlaceRepository({
    required RmApiClient client,
    required RmSession session,
  }) : _client = client,
       _session = session;

  final RmApiClient _client;
  final RmSession _session;

  @override
  Future<List<Place>> catalogue() async {
    // Through the session, not the client directly: that is what refreshes an
    // expired credential once and retries, and re-implementing it here would
    // be a second answer to a question Phase 9 already settled.
    final RmResponse response = await _session.send(
      (Map<String, String> headers) =>
          _client.get('/api/v1/places', headers: headers),
    );

    return _decode(response);
  }

  List<Place> _decode(RmResponse response) {
    final Object? places = response.json?['places'];

    if (places is! List) {
      throw _malformed(response);
    }

    final List<Place> catalogue = <Place>[];

    for (final Object? entry in places) {
      if (entry is! Map<String, Object?>) {
        throw _malformed(response);
      }

      final Object? id = entry['id'];
      final Object? label = entry['label'];

      if (id is! String || label is! String || id.isEmpty || label.isEmpty) {
        throw _malformed(response);
      }

      // Only the two documented fields are read. The catalogue behind them
      // also holds coordinates and a slug; the contract does not publish them
      // and this client has never needed to know where a place is.
      catalogue.add(Place(id: id, label: label));
    }

    return catalogue;
  }

  RmFailure _malformed(RmResponse response) => RmFailure.fromBackend(
    status: response.status,
    code: RmErrorCode.unexpected,
  );
}
