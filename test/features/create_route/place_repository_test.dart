import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ridemate/core/api/rm_api_client.dart';
import 'package:ridemate/core/api/rm_error_code.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/places/mock_places.dart';
import 'package:ridemate/core/places/place.dart';
import 'package:ridemate/features/create_route/data/place_repository.dart';

import '../../support/fakes.dart';

/// Reading the catalogue: the request, the shape, and the refusals.
void main() {
  late List<http.Request> sent;

  ApiPlaceRepository repositoryOver(
    Future<http.Response> Function(http.Request) handler,
  ) {
    sent = <http.Request>[];

    return ApiPlaceRepository(
      client: RmApiClient(
        transport: MockClient((http.Request request) {
          sent.add(request);

          return handler(request);
        }),
        baseUrl: Uri.parse('https://ridemate.test'),
      ),
      session: FakeSession(),
    );
  }

  http.Response ok(Object? body) => http.Response(
    jsonEncode(body),
    200,
    headers: <String, String>{'content-type': 'application/json'},
  );

  group('The request', () {
    test('asks for exactly the documented path, with nothing added', () async {
      final ApiPlaceRepository repository = repositoryOver(
        (_) async => ok(<String, Object?>{'places': <Object?>[]}),
      );

      await repository.catalogue();

      expect(sent, hasLength(1));
      expect(sent.single.method, 'GET');
      expect(sent.single.url.path, '/api/v1/places');
      // No pagination, no filter: this is a bounded catalogue, and a cursor
      // over five rows would be ceremony the server does not offer.
      expect(sent.single.url.queryParameters, isEmpty);
    });

    /// The session owns the credential lifecycle, and F3 does not re-open it.
    test('travels through the authenticated seam', () async {
      final ApiPlaceRepository repository = repositoryOver(
        (_) async => ok(<String, Object?>{'places': <Object?>[]}),
      );

      await repository.catalogue();

      expect(sent.single.headers['Authorization'], startsWith('Bearer '));
    });
  });

  group('The shape', () {
    test('decodes exactly id and label', () async {
      final ApiPlaceRepository repository = repositoryOver(
        (_) async => ok(<String, Object?>{
          'places': <Object?>[
            <String, Object?>{
              'id': '01991a00-0000-7000-8000-000000000001',
              'label': 'Kadıköy, Vapur İskelesi',
            },
            <String, Object?>{
              'id': '01991a00-0000-7000-8000-000000000002',
              'label': 'Levent, Metro İstasyonu',
            },
          ],
        }),
      );

      final List<Place> places = await repository.catalogue();

      expect(places, hasLength(2));
      expect(places.first.id, '01991a00-0000-7000-8000-000000000001');
      expect(places.first.label, 'Kadıköy, Vapur İskelesi');
      // Order is the server's; nothing is sorted or reordered here.
      expect(places.last.label, 'Levent, Metro İstasyonu');
    });

    /// The server also holds coordinates. They are not on the wire, and there
    /// is nowhere in this client for them to land if they ever were.
    test('a place carries no location, even when one is sent', () async {
      final ApiPlaceRepository repository = repositoryOver(
        (_) async => ok(<String, Object?>{
          'places': <Object?>[
            <String, Object?>{
              'id': '01991a00-0000-7000-8000-000000000001',
              'label': 'Kadıköy, Vapur İskelesi',
              'latitude': '40.991397',
              'longitude': '29.020443',
              'slug': 'kadikoy-iskele',
            },
          ],
        }),
      );

      final Place place = (await repository.catalogue()).single;

      expect(place.id, '01991a00-0000-7000-8000-000000000001');
      expect(place.label, 'Kadıköy, Vapur İskelesi');
      expect(place.toString(), isNot(contains('40.99')));
      expect(place.toString(), isNot(contains('kadikoy-iskele')));
    });

    test('an empty catalogue is a catalogue, not a failure', () async {
      final ApiPlaceRepository repository = repositoryOver(
        (_) async => ok(<String, Object?>{'places': <Object?>[]}),
      );

      expect(await repository.catalogue(), isEmpty);
    });
  });

  group('What it refuses', () {
    /// CARRIES WEIGHT. A bad row fails the request rather than being skipped.
    test('one malformed place fails the whole catalogue', () async {
      for (final Object? broken in <Object?>[
        <String, Object?>{'id': 'x'},
        <String, Object?>{'label': 'Somewhere'},
        <String, Object?>{'id': 42, 'label': 'Somewhere'},
        <String, Object?>{'id': 'x', 'label': ''},
        'not an object',
      ]) {
        final ApiPlaceRepository repository = repositoryOver(
          (_) async => ok(<String, Object?>{
            'places': <Object?>[
              <String, Object?>{
                'id': '01991a00-0000-7000-8000-000000000001',
                'label': 'A real one',
              },
              broken,
            ],
          }),
        );

        // Skipping it would leave a catalogue that is quietly short, and a
        // place missing from a picker is invisible to everyone.
        await expectLater(
          repository.catalogue(),
          throwsA(
            isA<RmFailure>().having(
              (RmFailure f) => f.code,
              'code',
              RmErrorCode.unexpected,
            ),
          ),
          reason: '$broken',
        );
      }
    });

    test('a body that is not a catalogue fails', () async {
      final ApiPlaceRepository repository = repositoryOver(
        (_) async => ok(<String, Object?>{'places': 'lots'}),
      );

      await expectLater(repository.catalogue(), throwsA(isA<RmFailure>()));
    });

    test('a server error surfaces as one', () async {
      final ApiPlaceRepository repository = repositoryOver(
        (_) async => http.Response(
          jsonEncode(<String, Object?>{
            'error': <String, Object?>{
              'code': 'internal_error',
              'message': 'x',
              'request_id': '00000000-0000-7000-8000-000000000001',
            },
          }),
          500,
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );

      await expectLater(
        repository.catalogue(),
        throwsA(
          isA<RmFailure>().having(
            (RmFailure f) => f.code,
            'code',
            RmErrorCode.internalError,
          ),
        ),
      );
    });

    test('an unreachable backend surfaces as a transport failure', () async {
      final ApiPlaceRepository repository = repositoryOver(
        (_) async => throw const SocketException('no route to host'),
      );

      await expectLater(
        repository.catalogue(),
        throwsA(
          isA<RmFailure>().having(
            (RmFailure f) => f.isTransport,
            'isTransport',
            isTrue,
          ),
        ),
      );
    });

    /// No failure produces places. There is no fallback to fall back to.
    test('no failure ever yields a fixture', () async {
      final ApiPlaceRepository repository = repositoryOver(
        (_) async => throw const SocketException('down'),
      );

      try {
        final List<Place> places = await repository.catalogue();
        for (final Place fixture in MockPlaces.all) {
          expect(places, isNot(contains(fixture)));
        }
        fail('a failing catalogue must not return places');
      } on RmFailure {
        // Refused, which is the only honest outcome.
      }
    });
  });
}
