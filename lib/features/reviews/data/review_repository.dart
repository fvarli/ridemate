// ─────────────────────────────────────────────────────────────
// RideMate — Rating a completed journey, and reading what was said about you
//
// TWO OPERATIONS, AND THE SERVER DECIDES BOTH
//
// Whether a relationship may be rated is the backend's answer, given as a
// machine-readable reason this client maps to its own copy. Whether a review
// about this member may be read is also the backend's: a review stays hidden
// until the other side writes one too or the window closes, and **nothing here
// recomputes that**. A client that worked it out would need to know whether a
// review it may not see exists, which is precisely what the rule withholds.
//
// THE ID IS A PARAMETER, NOT SOMETHING THIS MINTS
//
// It is the idempotency key, so a retry after a lost response must carry the
// SAME id or the backend cannot recognise it as the same review — it would
// answer `already_reviewed` for a submission that actually landed. Minting it
// here would make every retry a new review. The id is minted once per intent by
// the controller that owns the attempt, exactly as asking for a seat does.
//
// CURSORS ARE OPAQUE AND STAY THAT WAY
//
// Received and sent back unchanged. Nothing parses, decodes, times, persists or
// orders by one, and a cursor from another feed is refused by the server.
// ─────────────────────────────────────────────────────────────

import '../../../core/api/rm_api_client.dart';
import '../../../core/api/rm_error_code.dart';
import '../../../core/api/rm_failure.dart';
import '../../../core/api/rm_response.dart';
import '../../../core/reviews/review.dart';
import '../../../core/reviews/review_decoder.dart';
import '../../../core/session/rm_session.dart';

/// The contract's default page size, and its ceiling.
const int kMyReviewsPageSize = 20;

/// One page of reviews about this member.
final class MyReviewsResult {
  const MyReviewsResult({required this.reviews, required this.nextCursor});

  /// Only reviews the server has released. Never a count — RideMate publishes
  /// no aggregate, not even to the member the reviews are about.
  final List<ReceivedReview> reviews;

  /// Null means the end of the list — an empty page does not.
  final String? nextCursor;
}

abstract interface class ReviewRepository {
  /// Rates the relationship [requestId] names.
  ///
  /// [reviewId] is a client-generated UUIDv7 and is the idempotency key: the
  /// same id is the same review, so a retry must reuse it. Throws [RmFailure].
  Future<MyReview> submitReview({
    required String requestId,
    required String reviewId,
    required int rating,
  });

  /// Released reviews about this member, newest first.
  Future<MyReviewsResult> mine({String? cursor, int limit});
}

class ApiReviewRepository implements ReviewRepository {
  const ApiReviewRepository({
    required RmApiClient client,
    required RmSession session,
  }) : _client = client,
       _session = session;

  final RmApiClient _client;
  final RmSession _session;

  @override
  Future<MyReview> submitReview({
    required String requestId,
    required String reviewId,
    required int rating,
  }) async {
    final RmResponse response = await _session.send(
      (Map<String, String> headers) => _client.post(
        '/api/v1/seat-requests/$requestId/review',
        // Exactly two fields. **The role is never sent**: which side the caller
        // is, is the server's to derive from the relationship, and letting a
        // client say would let a passenger file a review as the driver.
        json: <String, Object?>{'id': reviewId, 'rating': rating},
        headers: headers,
      ),
    );

    // 201 created it, 200 found it already there. Both describe the same
    // review, so neither is surfaced: the distinction exists on the wire and
    // means nothing to a member. Any other 2xx is not this contract and is
    // refused rather than read as one of the two.
    if (response.status != 201 && response.status != 200) {
      throw _malformed(response);
    }

    return ReviewDecoder.mine(response.json?['review'], response.status);
  }

  @override
  Future<MyReviewsResult> mine({
    String? cursor,
    int limit = kMyReviewsPageSize,
  }) async {
    final RmResponse response = await _session.send(
      (Map<String, String> headers) => _client.get(
        '/api/v1/me/reviews',
        query: <String, String>{
          'limit': '$limit',
          // Absent on the first page. Sending an empty cursor would be a
          // different request, and the server validates the value it gets.
          'cursor': ?cursor,
        },
        headers: headers,
      ),
    );

    final Object? reviews = response.json?['reviews'];

    if (reviews is! List) throw _malformed(response);

    // `next_cursor` is required by the contract and may be null. Absent is not
    // the same as null: a response missing the key is not this contract, and
    // reading a missing key as "the end" would silently truncate the list.
    if (response.json?.containsKey('next_cursor') != true) {
      throw _malformed(response);
    }

    final Object? next = response.json?['next_cursor'];
    if (next != null && next is! String) throw _malformed(response);

    return MyReviewsResult(
      reviews: <ReceivedReview>[
        // A row that will not decode fails the page. Skipping it would leave a
        // list quietly short, and the member is the one person who would notice
        // a review missing and have no way to explain it.
        for (final Object? entry in reviews)
          ReviewDecoder.received(entry, response.status),
      ],
      nextCursor: next as String?,
    );
  }

  RmFailure _malformed(RmResponse response) => RmFailure.fromBackend(
    status: response.status,
    code: RmErrorCode.unexpected,
  );
}
