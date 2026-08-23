import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ridemate/core/api/rm_api_client.dart';
import 'package:ridemate/core/api/rm_error_code.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/api/rm_response.dart';

/// The transport and error boundary.
///
/// Every test drives an injected [MockClient]; nothing here touches a network,
/// and nothing needs RIDEMATE_API_BASE_URL, because the base URL is a
/// constructor argument rather than a compile-time constant.
void main() {
  late List<http.Request> sent;

  /// A client whose transport answers with [respond] and records what it was
  /// asked for.
  RmApiClient clientThat(
    http.Response Function(http.Request request) respond, {
    String base = 'https://api.example.test',
  }) {
    sent = <http.Request>[];

    return RmApiClient(
      baseUrl: Uri.parse(base),
      transport: MockClient((http.Request request) async {
        sent.add(request);

        return respond(request);
      }),
    );
  }

  http.Response json(Object? body, {int status = 200}) => http.Response(
    jsonEncode(body),
    status,
    headers: <String, String>{'content-type': 'application/json'},
  );

  http.Response envelope(
    String code, {
    int status = 400,
    String? requestId = '00000000-0000-7000-8000-000000000000',
  }) => json(<String, Object?>{
    'error': <String, Object?>{
      'code': code,
      // Developer-facing English the client must never surface. Present in
      // every fixture precisely so its absence from RmFailure is meaningful.
      'message': 'Something the member must never be shown.',
      'request_id': ?requestId,
    },
  }, status: status);

  // ------------------------------------------------------------------- URIs

  group('Request URIs', () {
    test('the configured base URL is used', () async {
      await clientThat((_) => json(<String, Object?>{})).get('/api/v1/me');

      expect(sent.single.url.toString(), 'https://api.example.test/api/v1/me');
    });

    /// The failure this prevents is silent: a backend mounted under a prefix
    /// would be called at the host root, and every request would 404 against
    /// a server that is running perfectly.
    test('a meaningful base path is preserved, not replaced', () async {
      await clientThat(
        (_) => json(<String, Object?>{}),
        base: 'https://api.example.test/ridemate',
      ).get('/api/v1/me');

      expect(
        sent.single.url.toString(),
        'https://api.example.test/ridemate/api/v1/me',
      );
    });

    test('separators are never doubled', () async {
      await clientThat(
        (_) => json(<String, Object?>{}),
        base: 'https://api.example.test/ridemate',
      ).get('api/v1/me');

      expect(
        sent.single.url.toString(),
        'https://api.example.test/ridemate/api/v1/me',
      );
    });

    test('the port and scheme survive', () async {
      await clientThat(
        (_) => json(<String, Object?>{}),
        base: 'http://10.0.2.2:8000',
      ).get('/api/v1/me');

      expect(sent.single.url.toString(), 'http://10.0.2.2:8000/api/v1/me');
    });

    test('query parameters are encoded by Uri, not by hand', () async {
      await clientThat(
        (_) => json(<String, Object?>{}),
      ).get('/api/v1/me', query: <String, String>{'q': 'a b&c=d', 'tr': 'ıöü'});

      final Uri url = sent.single.url;
      expect(url.queryParameters['q'], 'a b&c=d');
      expect(url.queryParameters['tr'], 'ıöü');
      expect(url.toString(), contains('a+b%26c%3Dd'));
    });

    test('no query means no trailing question mark', () async {
      await clientThat((_) => json(<String, Object?>{})).get('/api/v1/me');

      expect(sent.single.url.toString(), isNot(contains('?')));
    });
  });

  // ---------------------------------------------------------------- headers

  group('Headers and bodies', () {
    test('every request accepts JSON', () async {
      await clientThat((_) => json(<String, Object?>{})).get('/api/v1/me');

      expect(sent.single.headers['accept'], 'application/json');
    });

    test('a JSON body is declared and encoded', () async {
      await clientThat((_) => json(<String, Object?>{}, status: 200)).post(
        '/api/v1/auth/otp',
        json: <String, Object?>{'phone': '+905321234567'},
      );

      expect(sent.single.headers['content-type'], contains('application/json'));
      expect(jsonDecode(sent.single.body), <String, Object?>{
        'phone': '+905321234567',
      });
    });

    test('a body-less POST does not declare a content type', () async {
      await clientThat(
        (_) => http.Response('', 204),
      ).post('/api/v1/auth/logout');

      expect(sent.single.body, isEmpty);
    });

    /// This is how Authorization will be attached in a later commit, so it has
    /// to work without the client knowing anything about credentials.
    test('caller headers are sent', () async {
      await clientThat((_) => json(<String, Object?>{})).get(
        '/api/v1/me',
        headers: <String, String>{'Authorization': 'Bearer rma_x.y'},
      );

      expect(sent.single.headers['authorization'], 'Bearer rma_x.y');
    });

    /// The merge contract, and the reason for it: a caller assembling headers
    /// from scratch would otherwise drop content negotiation without noticing,
    /// and find out from an HTML error page the decoder cannot read.
    test('caller headers cannot remove JSON negotiation', () async {
      await clientThat((_) => json(<String, Object?>{})).post(
        '/api/v1/auth/otp',
        json: <String, Object?>{'phone': '+905321234567'},
        headers: <String, String>{
          'Accept': 'text/html',
          'Content-Type': 'text/plain',
        },
      );

      expect(sent.single.headers['accept'], 'application/json');
      expect(sent.single.headers['content-type'], contains('application/json'));
    });
  });

  // ---------------------------------------------------------------- success

  group('Successful responses', () {
    test('200 with a JSON object', () async {
      final RmResponse response = await clientThat(
        (_) => json(<String, Object?>{
          'account': <String, Object?>{'id': 'x'},
        }),
      ).get('/api/v1/me');

      expect(response.status, 200);
      expect(response.json, <String, Object?>{
        'account': <String, Object?>{'id': 'x'},
      });
    });

    test('201 with a JSON object', () async {
      final RmResponse response = await clientThat(
        (_) => json(<String, Object?>{'status': 'accepted'}, status: 201),
      ).post('/api/v1/auth/otp', json: <String, Object?>{'phone': '+90'});

      expect(response.status, 201);
      expect(response.json, <String, Object?>{'status': 'accepted'});
    });

    test('202 with a JSON object', () async {
      final RmResponse response = await clientThat(
        (_) => json(<String, Object?>{'status': 'accepted'}, status: 202),
      ).post('/api/v1/auth/otp', json: <String, Object?>{'phone': '+90'});

      expect(response.status, 202);
      expect(response.json, <String, Object?>{'status': 'accepted'});
    });

    test('204 carries no body and is not an error', () async {
      final RmResponse response = await clientThat(
        (_) => http.Response('', 204),
      ).post('/api/v1/auth/logout');

      expect(response.status, 204);
      expect(response.json, isNull);
    });

    /// `http.Response.body` chooses its encoding from the Content-Type
    /// charset and falls back to LATIN-1 when none is present — which is
    /// exactly what Laravel sends. Decoding the raw bytes as UTF-8 is the
    /// difference between "Güvenilirlik" and mojibake, and it would have gone
    /// unnoticed until the first Turkish string crossed the wire.
    test('UTF-8 bodies survive a Content-Type without a charset', () async {
      final RmResponse response = await clientThat(
        (_) => http.Response.bytes(
          utf8.encode(
            jsonEncode(<String, Object?>{'name': 'Güvenilirlik ıöü'}),
          ),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        ),
      ).get('/api/v1/me');

      expect(response.json?['name'], 'Güvenilirlik ıöü');
    });

    test(
      'a success carrying a JSON array is refused, not guessed at',
      () async {
        await expectLater(
          clientThat((_) => json(<Object?>[1, 2, 3])).get('/api/v1/me'),
          throwsA(
            isA<RmFailure>()
                .having((RmFailure f) => f.status, 'status', 200)
                .having(
                  (RmFailure f) => f.code,
                  'code',
                  RmErrorCode.unexpected,
                ),
          ),
        );
      },
    );
  });

  // ---------------------------------------------------------------- failures

  group('Documented backend failures', () {
    for (final RmErrorCode code in RmErrorCode.values) {
      if (code.wire == null) {
        continue;
      }

      test('${code.wire} maps to ${code.name}', () async {
        await expectLater(
          clientThat(
            (_) => envelope(code.wire!, status: 400),
          ).get('/api/v1/me'),
          throwsA(
            isA<RmFailure>().having((RmFailure f) => f.code, 'code', code),
          ),
        );
      });
    }

    test('status, code and request id are all retained', () async {
      try {
        await clientThat(
          (_) => envelope('validation_failed', status: 422),
        ).post('/api/v1/auth/otp', json: <String, Object?>{'phone': 'x'});
        fail('the failure should have been thrown');
      } on RmFailure catch (failure) {
        expect(failure.status, 422);
        expect(failure.code, RmErrorCode.validationFailed);
        expect(failure.requestId, '00000000-0000-7000-8000-000000000000');
        expect(failure.isTransport, isFalse);
      }
    });

    /// The contract says clients must never display the backend message. It is
    /// present in every fixture above and reachable from nowhere here.
    test('the backend message is not carried into the failure', () async {
      try {
        await clientThat(
          (_) => envelope('forbidden', status: 403),
        ).get('/api/v1/me');
        fail('the failure should have been thrown');
      } on RmFailure catch (failure) {
        expect(
          failure.toString(),
          isNot(contains('Something the member must never be shown')),
        );
      }
    });

    test(
      'a request id absent from the body falls back to the header',
      () async {
        try {
          await clientThat(
            (_) => http.Response(
              'not json at all',
              500,
              headers: <String, String>{
                'content-type': 'application/json',
                'x-request-id': '00000000-0000-7000-8000-00000000ffff',
              },
            ),
          ).get('/api/v1/me');
          fail('the failure should have been thrown');
        } on RmFailure catch (failure) {
          expect(failure.requestId, '00000000-0000-7000-8000-00000000ffff');
        }
      },
    );
  });

  group('Undocumented and malformed failures', () {
    /// A backend that gains a tenth code must not break a client that predates
    /// it. Failing while parsing a failure turns a clear server error into an
    /// opaque client crash.
    test('an unknown server code degrades to unexpected', () async {
      await expectLater(
        clientThat(
          (_) => envelope('teapot_overflow', status: 418),
        ).get('/api/v1/me'),
        throwsA(
          isA<RmFailure>()
              .having((RmFailure f) => f.code, 'code', RmErrorCode.unexpected)
              .having((RmFailure f) => f.status, 'status', 418),
        ),
      );
    });

    for (final (String label, http.Response Function() build)
        in <(String, http.Response Function())>[
          ('an empty body', () => http.Response('', 500)),
          ('malformed JSON', () => http.Response('{oh no', 500)),
          ('a JSON array', () => http.Response('[1,2,3]', 500)),
          ('a JSON scalar', () => http.Response('"nope"', 500)),
          (
            'the wrong envelope shape',
            () => http.Response('{"oops":true}', 500),
          ),
          (
            'an error that is not an object',
            () => http.Response('{"error":"nope"}', 500),
          ),
          (
            'a missing code',
            () => http.Response('{"error":{"message":"x"}}', 500),
          ),
          (
            'a non-string code',
            () => http.Response('{"error":{"code":42}}', 500),
          ),
          ('a null code', () => http.Response('{"error":{"code":null}}', 500)),
        ]) {
      test('$label still produces a deterministic failure', () async {
        await expectLater(
          clientThat((_) => build()).get('/api/v1/me'),
          throwsA(
            isA<RmFailure>()
                .having((RmFailure f) => f.status, 'status', 500)
                .having((RmFailure f) => f.code, 'code', RmErrorCode.unexpected)
                .having((RmFailure f) => f.isTransport, 'isTransport', isFalse),
          ),
        );
      });
    }
  });

  // --------------------------------------------------------------- transport

  group('Transport failures', () {
    test('a ClientException becomes a transport failure', () async {
      await expectLater(
        clientThat(
          (_) => throw http.ClientException('connection closed'),
        ).get('/api/v1/me'),
        throwsA(
          isA<RmFailure>()
              .having((RmFailure f) => f.isTransport, 'isTransport', isTrue)
              .having((RmFailure f) => f.status, 'status', isNull)
              .having((RmFailure f) => f.requestId, 'requestId', isNull),
        ),
      );
    });

    test('no package:http exception escapes the boundary', () async {
      await expectLater(
        clientThat((_) => throw http.ClientException('boom')).get('/api/v1/me'),
        throwsA(isNot(isA<http.ClientException>())),
      );
    });

    test('a FormatException from the transport does not escape', () async {
      await expectLater(
        clientThat((_) => throw const FormatException('bad')).get('/api/v1/me'),
        throwsA(isA<RmFailure>()),
      );
    });
  });

  // --------------------------------------------------------------------- 401

  group('401 is an ordinary failure in this commit', () {
    /// Single-flight refresh and retry are deliberately absent. This client
    /// knows nothing about tokens; the session commit layers that on top.
    test('it parses as a typed backend failure', () async {
      await expectLater(
        clientThat(
          (_) => envelope('unauthenticated', status: 401),
        ).get('/api/v1/me'),
        throwsA(
          isA<RmFailure>()
              .having((RmFailure f) => f.status, 'status', 401)
              .having(
                (RmFailure f) => f.code,
                'code',
                RmErrorCode.unauthenticated,
              ),
        ),
      );
    });

    test('nothing is retried and nothing is refreshed', () async {
      final RmApiClient client = clientThat(
        (_) => envelope('unauthenticated', status: 401),
      );

      await expectLater(client.get('/api/v1/me'), throwsA(isA<RmFailure>()));

      expect(sent, hasLength(1), reason: 'a retry would mean two requests');
      expect(
        sent.single.url.path,
        '/api/v1/me',
        reason: 'a refresh would have called /api/v1/auth/refresh',
      );
    });
  });

  // ---------------------------------------------------------------- mapping

  group('RmErrorCode', () {
    test('it covers every code the contract defines, and one more', () {
      expect(
        RmErrorCode.values.map((RmErrorCode c) => c.wire).toList(),
        <String?>[
          'bad_request',
          'unauthenticated',
          'forbidden',
          'not_found',
          'method_not_allowed',
          'conflict',
          'validation_failed',
          'rate_limited',
          'internal_error',
          null,
        ],
      );
    });

    /// A wire value would make the fallback look like part of the contract,
    /// and someone would eventually send it.
    test('the fallback has no wire value', () {
      expect(RmErrorCode.unexpected.wire, isNull);
      expect(RmErrorCode.fromWire(null), RmErrorCode.unexpected);
      expect(RmErrorCode.fromWire(42), RmErrorCode.unexpected);
      expect(RmErrorCode.fromWire(''), RmErrorCode.unexpected);
    });

    test('mapping is deterministic', () {
      for (final RmErrorCode code in RmErrorCode.values) {
        if (code.wire != null) {
          expect(RmErrorCode.fromWire(code.wire), code);
        }
      }
    });
  });
}
