// ─────────────────────────────────────────────────────────────
// RideMate — Reading and writing the member's own profile, at the wire
//
// The distinction under test everywhere below: a 404 is a PRODUCT STATE and
// everything else is a FAILURE. Nothing may turn one into the other, because
// the app routes on the difference — a member sent to setup by a timeout would
// be asked to invent a second name.
// ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ridemate/core/api/rm_api_client.dart';
import 'package:ridemate/core/api/rm_error_code.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/profile/profile.dart';
import 'package:ridemate/features/profile/data/profile_repository.dart';

import '../../support/fakes.dart';

void main() {
  late List<http.Request> sent;
  late FakeSession session;

  ApiProfileRepository repositoryOver(
    Future<http.Response> Function(http.Request) handler,
  ) {
    sent = <http.Request>[];
    session = FakeSession();

    return ApiProfileRepository(
      client: RmApiClient(
        transport: MockClient((http.Request request) {
          sent.add(request);

          return handler(request);
        }),
        baseUrl: Uri.parse('https://ridemate.test'),
      ),
      session: session,
    );
  }

  http.Response json(Object? body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: <String, String>{'content-type': 'application/json'},
  );

  Map<String, Object?> profileBody([
    String name = 'İrem Yılmaz',
    String initials = 'İY',
  ]) => <String, Object?>{
    'profile': <String, Object?>{'display_name': name, 'initials': initials},
  };

  group('The read request', () {
    test('asks for exactly the documented path', () async {
      final ApiProfileRepository repository = repositoryOver(
        (_) async => json(profileBody()),
      );

      await repository.read();

      expect(sent, hasLength(1));
      expect(sent.single.method, 'GET');
      expect(sent.single.url.path, '/api/v1/me/profile');
      expect(sent.single.url.queryParameters, isEmpty);
    });

    test('travels through the authenticated seam', () async {
      final ApiProfileRepository repository = repositoryOver(
        (_) async => json(profileBody()),
      );

      await repository.read();

      expect(sent.single.headers['Authorization'], startsWith('Bearer '));
    });
  });

  group('The read result', () {
    test('decodes exactly the two documented fields', () async {
      final ApiProfileRepository repository = repositoryOver(
        (_) async => json(profileBody()),
      );

      expect(
        await repository.read(),
        const Profile(displayName: 'İrem Yılmaz', initials: 'İY'),
      );
    });

    /// CARRIES WEIGHT. The one status that is not a failure.
    test('a 404 is ProfileNotFound, not an RmFailure', () async {
      final ApiProfileRepository repository = repositoryOver(
        (_) async => json(<String, Object?>{
          'error': <String, Object?>{'code': 'not_found'},
        }, 404),
      );

      await expectLater(repository.read(), throwsA(isA<ProfileNotFound>()));
    });

    /// CARRIES WEIGHT. And every other failure stays a failure.
    ///
    /// If any of these produced ProfileNotFound, a member with a profile would
    /// be routed to setup because the network was down.
    for (final (String label, Future<http.Response> Function() respond)
        in <(String, Future<http.Response> Function())>[
          (
            'a 500',
            () async => json(<String, Object?>{
              'error': <String, Object?>{'code': 'internal_error'},
            }, 500),
          ),
          (
            'a 403',
            () async => json(<String, Object?>{
              'error': <String, Object?>{'code': 'forbidden'},
            }, 403),
          ),
          (
            'a 409',
            () async => json(<String, Object?>{
              'error': <String, Object?>{'code': 'conflict'},
            }, 409),
          ),
        ]) {
      test('$label is a failure, never ProfileNotFound', () async {
        final ApiProfileRepository repository = repositoryOver(
          (_) async => respond(),
        );

        await expectLater(
          repository.read(),
          throwsA(
            isA<RmFailure>().having(
              (RmFailure f) => f is ProfileNotFound,
              'is not ProfileNotFound',
              isFalse,
            ),
          ),
        );
      });
    }

    test('an unreachable backend is a transport failure', () async {
      final ApiProfileRepository repository = repositoryOver(
        (_) async => throw const SocketException('down'),
      );

      await expectLater(
        repository.read(),
        throwsA(
          isA<RmFailure>().having(
            (RmFailure f) => f.isTransport,
            'isTransport',
            isTrue,
          ),
        ),
      );
    });
  });

  group('Strict decoding', () {
    /// Each of these is a 200 the client must refuse. A response that will not
    /// decode is not a profile, and reading two fields out of it anyway would
    /// hide exactly the drift worth noticing.
    final Map<String, Object?> bad = <String, Object?>{
      'no envelope': <String, Object?>{'display_name': 'A', 'initials': 'A'},
      'profile is not an object': <String, Object?>{'profile': 'İrem'},
      'display_name missing': <String, Object?>{
        'profile': <String, Object?>{'initials': 'İY'},
      },
      'initials missing': <String, Object?>{
        'profile': <String, Object?>{'display_name': 'İrem Yılmaz'},
      },
      'display_name is not a string': <String, Object?>{
        'profile': <String, Object?>{'display_name': 42, 'initials': 'İY'},
      },
      'initials is not a string': <String, Object?>{
        'profile': <String, Object?>{'display_name': 'İrem', 'initials': 7},
      },
      'display_name is empty': <String, Object?>{
        'profile': <String, Object?>{'display_name': '', 'initials': 'İY'},
      },
      'initials is empty': <String, Object?>{
        'profile': <String, Object?>{'display_name': 'İrem', 'initials': ''},
      },
      // Stricter than the catalogue decoder, on purpose: an extra key means
      // this is not the representation the contract publishes.
      'an extra field inside the profile': <String, Object?>{
        'profile': <String, Object?>{
          'display_name': 'İrem Yılmaz',
          'initials': 'İY',
          'id': '00000000-0000-7000-8000-000000000001',
        },
      },
      'an extra field beside the profile': <String, Object?>{
        'profile': <String, Object?>{
          'display_name': 'İrem Yılmaz',
          'initials': 'İY',
        },
        'account': <String, Object?>{'id': 'x'},
      },
    };

    bad.forEach((String label, Object? body) {
      test('$label fails the whole response', () async {
        final ApiProfileRepository repository = repositoryOver(
          (_) async => json(body),
        );

        await expectLater(repository.read(), throwsA(isA<RmFailure>()));
      });
    });

    /// CARRIES WEIGHT. A malformed 2xx keeps its real status, which is what
    /// makes it distinguishable from a deterministic 4xx despite both being
    /// `unexpected`. F4.1's classifier depends on exactly this.
    test('a malformed 200 keeps its status and reads as unexpected', () async {
      final ApiProfileRepository repository = repositoryOver(
        (_) async => json(<String, Object?>{'profile': <String, Object?>{}}),
      );

      await expectLater(
        repository.read(),
        throwsA(
          isA<RmFailure>()
              .having((RmFailure f) => f.status, 'status', 200)
              .having((RmFailure f) => f.code, 'code', RmErrorCode.unexpected),
        ),
      );
    });
  });

  group('The write', () {
    test('PUTs exactly the documented field to the documented path', () async {
      final ApiProfileRepository repository = repositoryOver(
        (_) async => json(profileBody('Ayşe Demir', 'AD'), 201),
      );

      await repository.save('Ayşe Demir');

      expect(sent, hasLength(1));
      expect(sent.single.method, 'PUT');
      expect(sent.single.url.path, '/api/v1/me/profile');
      // One field. `initials` is the server's to derive and would be refused.
      expect(jsonDecode(sent.single.body), <String, Object?>{
        'display_name': 'Ayşe Demir',
      });
      expect(sent.single.headers['Authorization'], startsWith('Bearer '));
    });

    /// 201 and 200 decode identically — the status is the caller's business,
    /// not the decoder's.
    for (final int status in <int>[200, 201]) {
      test('a $status decodes to the same profile shape', () async {
        final ApiProfileRepository repository = repositoryOver(
          (_) async => json(profileBody('Ayşe Demir', 'AD'), status),
        );

        expect(
          await repository.save('Ayşe Demir'),
          const Profile(displayName: 'Ayşe Demir', initials: 'AD'),
        );
      });
    }

    /// The server trims and the client adopts what came back, so the two can
    /// never disagree about what was stored.
    test('the profile returned is the server\'s, not what was sent', () async {
      final ApiProfileRepository repository = repositoryOver(
        (_) async => json(profileBody('Ayşe Demir', 'AD'), 201),
      );

      final Profile saved = await repository.save('   Ayşe Demir   ');

      expect(saved.displayName, 'Ayşe Demir');
      expect(saved.initials, 'AD');
    });

    test('a 422 is a failure carrying the validation code', () async {
      final ApiProfileRepository repository = repositoryOver(
        (_) async => json(<String, Object?>{
          'error': <String, Object?>{'code': 'validation_failed'},
        }, 422),
      );

      await expectLater(
        repository.save(''),
        throwsA(
          isA<RmFailure>().having(
            (RmFailure f) => f.code,
            'code',
            RmErrorCode.validationFailed,
          ),
        ),
      );
    });

    /// A write cannot find nothing — it creates. A 404 here is an ordinary
    /// failure and must not be mistaken for "no profile yet".
    test('a 404 on write is a failure, not ProfileNotFound', () async {
      final ApiProfileRepository repository = repositoryOver(
        (_) async => json(<String, Object?>{
          'error': <String, Object?>{'code': 'not_found'},
        }, 404),
      );

      await expectLater(
        repository.save('Ayşe Demir'),
        throwsA(isA<RmFailure>()),
      );
      await expectLater(
        repository.save('Ayşe Demir'),
        throwsA(isNot(isA<ProfileNotFound>())),
      );
    });
  });

  group('The session is never disturbed', () {
    /// CARRIES WEIGHT. Failing to read a profile says nothing about the
    /// credential that read it. Phase 9 owns sign-out; this feature does not.
    for (final (String label, Future<http.Response> Function() respond)
        in <(String, Future<http.Response> Function())>[
          (
            '404',
            () async => json(<String, Object?>{
              'error': <String, Object?>{'code': 'not_found'},
            }, 404),
          ),
          (
            '500',
            () async => json(<String, Object?>{
              'error': <String, Object?>{'code': 'internal_error'},
            }, 500),
          ),
          (
            'a malformed 200',
            () async => json(<String, Object?>{'nope': true}),
          ),
          (
            'an unreachable backend',
            () async => throw const SocketException('x'),
          ),
        ]) {
      test('a $label leaves the member signed in', () async {
        final ApiProfileRepository repository = repositoryOver(
          (_) async => respond(),
        );

        await repository.read().then<void>((_) {}, onError: (Object _) {});

        expect(session.isSignedIn, isTrue);
        expect(session.signedOutReason, isNull);
      });
    }
  });
}
