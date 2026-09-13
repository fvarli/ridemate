import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/api/rm_error_code.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/reviews/review.dart';
import 'package:ridemate/core/reviews/review_decoder.dart';
import 'package:ridemate/core/routes/departure.dart';
import 'package:ridemate/core/seat_requests/seat_request.dart';
import 'package:ridemate/core/seat_requests/seat_request_decoder.dart';

import '../../support/fakes.dart';

/// Reading a review off the wire.
///
/// Mostly negative, for the reason the route and trip decoders' tests are: a
/// decoder that accepts everything passes every positive test written against
/// it. A rating attributed to the wrong person is worse than a visible failure.
void main() {
  Map<String, Object?> mine({
    Object? id = '01993a00-0000-7000-8000-000000000001',
    Object? rating = 5,
    Object? submittedAt = '2026-09-25T09:14:00Z',
  }) => <String, Object?>{
    'id': id,
    'rating': rating,
    'submitted_at': submittedAt,
  };

  Map<String, Object?> received({
    Object? role = 'driver',
    Object? displayName = 'İrem Yılmaz',
    Object? initials = 'İY',
    Object? origin = 'Kadıköy, Vapur İskelesi',
    Object? destination = 'Levent, Metro İstasyonu',
    Object? departureDate = '2026-09-24',
    Object? departureTime = '08:25',
  }) => <String, Object?>{
    ...mine(),
    'reviewer': <String, Object?>{
      'display_name': displayName,
      'initials': initials,
      'role': role,
    },
    'journey': <String, Object?>{
      'origin': origin,
      'destination': destination,
      'departure_date': departureDate,
      'departure_time': departureTime,
    },
  };

  void expectMalformed(Object? Function() decode, String why) {
    expect(
      decode,
      throwsA(
        isA<RmFailure>()
            .having((RmFailure f) => f.code, 'code', RmErrorCode.unexpected)
            .having((RmFailure f) => f.status, 'status', 409),
      ),
      reason: why,
    );
  }

  group('The caller own review', () {
    test('three fields, and the instant is the one the server sent', () {
      final MyReview review = ReviewDecoder.mine(mine(), 200);

      expect(review.id, '01993a00-0000-7000-8000-000000000001');
      expect(review.rating, 5);
      expect(review.submittedAt, DateTime.utc(2026, 9, 25, 9, 14));
    });

    test('anything that is not the documented shape is refused', () {
      expectMalformed(() => ReviewDecoder.mine('5', 409), 'a bare string');
      expectMalformed(() => ReviewDecoder.mine(null, 409), 'nothing at all');
      expectMalformed(
        () => ReviewDecoder.mine(mine(id: 7), 409),
        'a numeric id',
      );
      expectMalformed(
        () => ReviewDecoder.mine(mine(id: ''), 409),
        'an empty id',
      );
      expectMalformed(
        () => ReviewDecoder.mine(mine(rating: '5'), 409),
        'a rating that is not a number',
      );
      expectMalformed(
        () => ReviewDecoder.mine(mine(submittedAt: 'yesterday'), 409),
        'an unreadable instant',
      );
      expectMalformed(
        () => ReviewDecoder.mine(mine(submittedAt: null), 409),
        'no instant at all',
      );
    });

    /// CARRIES WEIGHT. Absent and null are different things.
    ///
    /// The server always sends the key — null when the caller has written
    /// nothing. Reading a missing one as null would let an older backend claim
    /// every relationship is still open to rate, and would offer the control on
    /// a journey this member has already rated.
    test('a missing my_review key is drift, not an unreviewed journey', () {
      expect(
        ReviewDecoder.within(<String, Object?>{'my_review': null}, 200),
        isNull,
      );
      expect(
        ReviewDecoder.within(<String, Object?>{
          'my_review': mine(),
        }, 200)?.rating,
        5,
      );
      expectMalformed(
        () => ReviewDecoder.within(<String, Object?>{}, 409),
        'the key absent entirely',
      );
    });
  });

  group('A review about me', () {
    test('the rating, the author and the journey it belongs to', () {
      final ReceivedReview review = ReviewDecoder.received(received(), 200);

      expect(review.rating, 5);
      expect(review.submittedAt, DateTime.utc(2026, 9, 25, 9, 14));
      expect(review.reviewer.displayName, 'İrem Yılmaz');
      expect(review.reviewer.initials, 'İY');
      expect(review.reviewer.role, ReviewerRole.driver);
      expect(review.journey.origin, 'Kadıköy, Vapur İskelesi');
      expect(review.journey.destination, 'Levent, Metro İstasyonu');
      expect(
        review.journey.departureDate,
        const DepartureDate(year: 2026, month: 9, day: 24),
      );
      expect(
        review.journey.departureTime,
        const DepartureTime(hour: 8, minute: 25),
      );
    });

    test('both sides of a journey can have written it', () {
      for (final ReviewerRole role in ReviewerRole.values) {
        expect(
          ReviewDecoder.received(received(role: role.wire), 200).reviewer.role,
          role,
          reason: role.wire,
        );
      }
    });

    /// CARRIES WEIGHT. A third side is not rendered as one of the two.
    test('a role this build has never heard of is refused', () {
      for (final Object? role in <Object?>[
        'member',
        'both',
        'DRIVER',
        '',
        null,
        7,
      ]) {
        expectMalformed(
          () => ReviewDecoder.received(received(role: role), 409),
          'role: $role',
        );
      }
    });

    /// The date is required here, unlike everywhere else a departure appears: a
    /// recurring route cannot have a trip, so every reviewable journey is dated.
    test('a journey with no date is refused rather than left open', () {
      expectMalformed(
        () => ReviewDecoder.received(received(departureDate: null), 409),
        'a null date',
      );
      expectMalformed(
        () => ReviewDecoder.received(received(departureDate: '2026'), 409),
        'an unreadable date',
      );
    });

    test('an incomplete author or journey is refused', () {
      for (final Map<String, Object?> broken in <Map<String, Object?>>[
        received(displayName: ''),
        received(initials: ''),
        received(origin: ''),
        received(destination: 7),
        received(departureTime: null),
      ]) {
        expectMalformed(() => ReviewDecoder.received(broken, 409), '$broken');
      }
    });
  });

  group('What a failure names', () {
    test('each documented reason, and nothing else', () {
      for (final ReviewRefusal refusal in ReviewRefusal.values) {
        expect(
          RmFailure.fromBackend(
            status: 409,
            code: RmErrorCode.conflict,
            reason: refusal.wire,
          ).reviewRefusal,
          refusal,
          reason: refusal.wire,
        );
      }
    });

    /// CARRIES WEIGHT. A reason from another domain is not a review refusal.
    test('a reason nobody documented here stays unknown', () {
      for (final String? reason in <String?>[
        null,
        '',
        'already_requested',
        'route_full',
        'departure_not_reached',
        'trip_already_started',
        'self_review',
      ]) {
        expect(
          RmFailure.fromBackend(
            status: 409,
            code: RmErrorCode.conflict,
            reason: reason,
          ).reviewRefusal,
          isNull,
          reason: '$reason',
        );
      }
    });

    /// The one string two domains share, and it means the same in both.
    test('id_already_used resolves in both vocabularies', () {
      const RmFailure failure = RmFailure.fromBackend(
        status: 409,
        code: RmErrorCode.conflict,
        reason: 'id_already_used',
      );

      expect(failure.reviewRefusal, ReviewRefusal.idAlreadyUsed);
      expect(failure.seatRequestRefusal, SeatRequestRefusal.idAlreadyUsed);
    });
  });

  group('Where my_review appears', () {
    test('a passenger asking carries it, null or not', () {
      final MySeatRequest unreviewed = SeatRequestDecoder.mine(
        fakeMySeatRequestJson(),
        200,
      );
      final MySeatRequest reviewed = SeatRequestDecoder.mine(
        fakeMySeatRequestJson(myReview: mine()),
        200,
      );

      expect(unreviewed.myReview, isNull);
      expect(reviewed.myReview?.rating, 5);
    });

    test('a driver incoming asking carries it too', () {
      final IncomingSeatRequest incoming = SeatRequestDecoder.incoming(
        fakeIncomingSeatRequestJson(myReview: mine(rating: 3)),
        200,
      );

      expect(incoming.myReview?.rating, 3);
    });

    /// CARRIES WEIGHT. It reached only the two listings.
    test('no other projection gained it', () {
      // Each of these decodes from a fixture with no `my_review` anywhere, so a
      // decoder that had started requiring one would fail here.
      expect(fakeDiscoveredRoute().id, isNotEmpty);
      expect(fakeRoute().id, isNotEmpty);
      expect(fakeMyRoute().trip!.state, isNotNull);
    });
  });
}
