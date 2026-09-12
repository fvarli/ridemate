import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ridemate/core/api/rm_api_client.dart';
import 'package:ridemate/core/api/rm_error_code.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/reviews/review.dart';
import 'package:ridemate/core/reviews/review_decoder.dart';
import 'package:ridemate/features/reviews/data/review_repository.dart';

import '../../support/fakes.dart';

/// Rating a journey, and reading what was said about you, over the wire.
///
/// The property worth the most here is the retry one. The review id is the
/// idempotency key, so a second attempt after a lost response must carry the
/// SAME id — a fresh one would make the backend answer `already_reviewed` for a
/// submission that actually landed.
void main() {
  const String kRequestId = '01991d00-0000-7000-8000-000000000001';
  const String kReviewId = '01993a00-0000-7000-8000-000000000001';

  late List<http.Request> sent;

  ApiReviewRepository repositoryOver(
    Future<http.Response> Function(http.Request) handler,
  ) {
    sent = <http.Request>[];

    return ApiReviewRepository(
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

  http.Response ok(Object? body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: <String, String>{'content-type': 'application/json'},
  );

  http.Response conflict(String reason) => http.Response(
    jsonEncode(<String, Object?>{
      'error': <String, Object?>{
        'code': 'conflict',
        'message': 'developer facing',
        'details': <String, Object?>{'reason': reason},
        'request_id': '00000000-0000-7000-8000-000000000009',
      },
    }),
    409,
    headers: <String, String>{'content-type': 'application/json'},
  );

  http.Response failure(int status, String code) => http.Response(
    jsonEncode(<String, Object?>{
      'error': <String, Object?>{
        'code': code,
        'message': 'developer facing',
        'request_id': '00000000-0000-7000-8000-000000000009',
      },
    }),
    status,
    headers: <String, String>{'content-type': 'application/json'},
  );

  group('Submitting', () {
    /// CARRIES WEIGHT. Two fields, and the role is not one of them.
    test('posts to the documented path with exactly id and rating', () async {
      final ApiReviewRepository repository = repositoryOver(
        (_) async => ok(<String, Object?>{'review': fakeReviewJson()}, 201),
      );

      await repository.submitReview(
        requestId: kRequestId,
        reviewId: kReviewId,
        rating: 5,
      );

      expect(sent, hasLength(1));
      expect(sent.single.method, 'POST');
      expect(sent.single.url.path, '/api/v1/seat-requests/$kRequestId/review');

      final Object? body = jsonDecode(sent.single.body);
      expect(body, isA<Map<String, Object?>>());
      expect((body! as Map<String, Object?>).keys, <String>['id', 'rating']);
      expect((body as Map<String, Object?>)['id'], kReviewId);
      expect(body['rating'], 5);

      // Which side the caller is, is the server's to derive. Sending it would
      // let a passenger file a review as the driver.
      expect(sent.single.body, isNot(contains('role')));
    });

    test('a created answer and a replayed one decode the same', () async {
      for (final int status in <int>[201, 200]) {
        final ApiReviewRepository repository = repositoryOver(
          (_) async =>
              ok(<String, Object?>{'review': fakeReviewJson()}, status),
        );

        final MyReview review = await repository.submitReview(
          requestId: kRequestId,
          reviewId: kReviewId,
          rating: 5,
        );

        expect(review.id, kReviewId, reason: '$status');
        expect(review.rating, 5, reason: '$status');
      }
    });

    /// CARRIES WEIGHT. The whole point of the client-generated id.
    ///
    /// A retry after a lost response carries the SAME id, so the backend
    /// recognises it as the same review and replays. Minting a fresh one would
    /// turn a submission that landed into `already_reviewed`.
    test('a retry carries the id it was given, not a new one', () async {
      int call = 0;
      final ApiReviewRepository repository = repositoryOver((_) async {
        call++;

        // The first response is lost; the second is the server replaying.
        return ok(<String, Object?>{
          'review': fakeReviewJson(),
        }, call == 1 ? 201 : 200);
      });

      final MyReview first = await repository.submitReview(
        requestId: kRequestId,
        reviewId: kReviewId,
        rating: 5,
      );
      final MyReview again = await repository.submitReview(
        requestId: kRequestId,
        reviewId: kReviewId,
        rating: 5,
      );

      expect(sent, hasLength(2));
      for (final http.Request request in sent) {
        expect(jsonDecode(request.body), containsPair('id', kReviewId));
      }
      expect(first.id, again.id);
      expect(first, again, reason: 'one review, observed twice');
    });

    /// A 2xx the contract does not document is not this contract.
    test('an undocumented success is refused', () async {
      final ApiReviewRepository repository = repositoryOver(
        (_) async => ok(<String, Object?>{'review': fakeReviewJson()}, 202),
      );

      await expectLater(
        repository.submitReview(
          requestId: kRequestId,
          reviewId: kReviewId,
          rating: 5,
        ),
        throwsA(isA<RmFailure>()),
      );
    });

    test('a malformed success fails rather than filling in blanks', () async {
      final ApiReviewRepository repository = repositoryOver(
        (_) async => ok(<String, Object?>{'review': 'gone'}, 201),
      );

      await expectLater(
        repository.submitReview(
          requestId: kRequestId,
          reviewId: kReviewId,
          rating: 5,
        ),
        throwsA(isA<RmFailure>()),
      );
    });
  });

  group('What a refusal says', () {
    /// CARRIES WEIGHT. All five arrive as the same 409, so the reason is the
    /// only thing that distinguishes them — and it is read from `details`,
    /// never from the message.
    test('every documented reason maps to its own value', () async {
      for (final ReviewRefusal expected in ReviewRefusal.values) {
        final ApiReviewRepository repository = repositoryOver(
          (_) async => conflict(expected.wire),
        );

        await expectLater(
          repository.submitReview(
            requestId: kRequestId,
            reviewId: kReviewId,
            rating: 5,
          ),
          throwsA(
            isA<RmFailure>()
                .having((RmFailure f) => f.status, 'status', 409)
                .having((RmFailure f) => f.code, 'code', RmErrorCode.conflict)
                .having((RmFailure f) => f.reviewRefusal, 'refusal', expected),
          ),
          reason: expected.wire,
        );
      }
    });

    /// CARRIES WEIGHT. A 404 is not a refusal, and never becomes one.
    test('a non-party stays not-found', () async {
      final ApiReviewRepository repository = repositoryOver(
        (_) async => failure(404, 'not_found'),
      );

      await expectLater(
        repository.submitReview(
          requestId: kRequestId,
          reviewId: kReviewId,
          rating: 5,
        ),
        throwsA(
          isA<RmFailure>()
              .having((RmFailure f) => f.code, 'code', RmErrorCode.notFound)
              .having((RmFailure f) => f.reviewRefusal, 'refusal', isNull),
        ),
      );
    });

    test('the other documented failures keep their own meaning', () async {
      for (final (int status, String code, RmErrorCode expected)
          in <(int, String, RmErrorCode)>[
            (401, 'unauthenticated', RmErrorCode.unauthenticated),
            (403, 'forbidden', RmErrorCode.forbidden),
            (422, 'validation_failed', RmErrorCode.validationFailed),
          ]) {
        final ApiReviewRepository repository = repositoryOver(
          (_) async => failure(status, code),
        );

        await expectLater(
          repository.submitReview(
            requestId: kRequestId,
            reviewId: kReviewId,
            rating: 5,
          ),
          throwsA(
            isA<RmFailure>()
                .having((RmFailure f) => f.code, 'code', expected)
                .having((RmFailure f) => f.reviewRefusal, 'refusal', isNull),
          ),
          reason: '$status',
        );
      }
    });

    test('a reason from another domain is not a review refusal', () async {
      final ApiReviewRepository repository = repositoryOver(
        (_) async => conflict('already_requested'),
      );

      await expectLater(
        repository.submitReview(
          requestId: kRequestId,
          reviewId: kReviewId,
          rating: 5,
        ),
        throwsA(
          isA<RmFailure>().having(
            (RmFailure f) => f.reviewRefusal,
            'refusal',
            isNull,
          ),
        ),
      );
    });

    test('an unreachable backend is a transport failure', () async {
      final ApiReviewRepository repository = repositoryOver(
        (_) async => throw http.ClientException('no route to host'),
      );

      await expectLater(
        repository.submitReview(
          requestId: kRequestId,
          reviewId: kReviewId,
          rating: 5,
        ),
        throwsA(
          isA<RmFailure>().having(
            (RmFailure f) => f.isTransport,
            'transport',
            isTrue,
          ),
        ),
      );
    });
  });

  group('Reading what was said about me', () {
    test('uses the documented path and the contract default', () async {
      final ApiReviewRepository repository = repositoryOver(
        (_) async =>
            ok(<String, Object?>{'reviews': <Object?>[], 'next_cursor': null}),
      );

      await repository.mine();

      expect(sent.single.method, 'GET');
      expect(sent.single.url.path, '/api/v1/me/reviews');
      expect(sent.single.url.queryParameters['limit'], '20');
      expect(kMyReviewsPageSize, 20);
      expect(sent.single.url.queryParameters.containsKey('cursor'), isFalse);
    });

    test('the cursor goes back exactly as it arrived', () async {
      final ApiReviewRepository repository = repositoryOver(
        (_) async => ok(<String, Object?>{
          'reviews': <Object?>[fakeReceivedReviewJson()],
          'next_cursor': 'opaque-token',
        }),
      );

      final MyReviewsResult first = await repository.mine();
      expect(first.nextCursor, 'opaque-token');

      await repository.mine(cursor: first.nextCursor);
      expect(sent.last.url.queryParameters['cursor'], 'opaque-token');
    });

    test('decodes the projection completely', () async {
      final ApiReviewRepository repository = repositoryOver(
        (_) async => ok(<String, Object?>{
          'reviews': <Object?>[
            fakeReceivedReviewJson(
              rating: 4,
              role: 'passenger',
              displayName: 'Ayşe Demir',
            ),
          ],
          'next_cursor': null,
        }),
      );

      final ReceivedReview review = (await repository.mine()).reviews.single;

      expect(review.rating, 4);
      expect(review.reviewer.role, ReviewerRole.passenger);
      expect(review.reviewer.displayName, 'Ayşe Demir');
      expect(review.journey.origin, 'Kadıköy, Vapur İskelesi');
      expect(review.journey.departureTime.hhMm, '08:25');
    });

    /// Absent is not the same as null: a response missing the key is not this
    /// contract, and reading it as "the end" would silently truncate the list.
    test('a page without a cursor key is refused', () async {
      final ApiReviewRepository repository = repositoryOver(
        (_) async => ok(<String, Object?>{'reviews': <Object?>[]}),
      );

      await expectLater(repository.mine(), throwsA(isA<RmFailure>()));
    });

    test('a row that will not decode fails the page', () async {
      final ApiReviewRepository repository = repositoryOver(
        (_) async => ok(<String, Object?>{
          'reviews': <Object?>[fakeReceivedReviewJson(), 'gone'],
          'next_cursor': null,
        }),
      );

      await expectLater(repository.mine(), throwsA(isA<RmFailure>()));
    });
  });
}
