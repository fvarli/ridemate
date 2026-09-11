import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/api/rm_error_code.dart';
import 'package:ridemate/core/api/rm_error_copy.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/l10n/app_localizations.dart';

/// Failures become copy the member can read, in their language, and never the
/// English the backend sent.
void main() {
  late AppLocalizations tr;
  late AppLocalizations en;

  setUpAll(() async {
    tr = await AppLocalizations.delegate.load(const Locale('tr'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  RmFailure backend(RmErrorCode code, {int status = 400}) =>
      RmFailure.fromBackend(
        status: status,
        code: code,
        requestId: '00000000-0000-7000-8000-0000000000ff',
      );

  test('every code produces non-empty Turkish copy', () {
    for (final RmErrorCode code in RmErrorCode.values) {
      expect(backend(code).copy(tr), isNotEmpty, reason: code.name);
    }
    expect(const RmFailure.transport().copy(tr), isNotEmpty);
  });

  test('English parity: every code produces copy there too', () {
    for (final RmErrorCode code in RmErrorCode.values) {
      expect(backend(code).copy(en), isNotEmpty, reason: code.name);
    }
    expect(const RmFailure.transport().copy(en), isNotEmpty);
  });

  /// Signing in again is exactly what a suspended member cannot do, so
  /// telling them to would be advice that fails forever.
  test('forbidden reads differently from unauthenticated', () {
    expect(
      backend(RmErrorCode.forbidden, status: 403).copy(tr),
      isNot(backend(RmErrorCode.unauthenticated, status: 401).copy(tr)),
    );
  });

  test('a transport failure is not described as a server error', () {
    expect(
      const RmFailure.transport().copy(tr),
      isNot(backend(RmErrorCode.internalError, status: 500).copy(tr)),
    );
  });

  /// Forward compatibility: a code this build has never heard of already
  /// became `unexpected` at the wire boundary, and lands on safe copy here.
  test('an unknown server code lands on the safe fallback', () {
    expect(
      backend(RmErrorCode.unexpected, status: 418).copy(tr),
      tr.errorUnexpected,
    );
    expect(RmErrorCode.fromWire('teapot_overflow'), RmErrorCode.unexpected);
  });

  /// The contract says the backend message must never be displayed, and
  /// RmFailure does not carry one — so there is nothing to leak.
  test('no copy can contain a backend message', () {
    for (final RmErrorCode code in RmErrorCode.values) {
      final RmFailure failure = backend(code);
      expect(failure.toString(), isNot(contains('message')));
    }
  });

  /// request_id is diagnostics. A UUID in a sentence tells a member nothing
  /// and makes the app look broken.
  test('the request id never appears in member-facing copy', () {
    for (final RmErrorCode code in RmErrorCode.values) {
      final RmFailure failure = backend(code);

      expect(failure.requestId, isNotNull, reason: 'retained for diagnostics');
      expect(failure.copy(tr), isNot(contains(failure.requestId!)));
      expect(failure.copy(en), isNot(contains(failure.requestId!)));
    }
  });

  /// The mapping has no `_` branch, so a tenth server code stops it compiling
  /// and forces a decision rather than joining the "something went wrong" pile.
  test('the mapping is exhaustive over the enum', () {
    expect(RmErrorCode.values, hasLength(10));
  });

  /// CARRIES WEIGHT. The last-resort 409 sentence names no domain.
  ///
  /// It used to say a route had already been published, which was true while
  /// publication was the only command that could conflict. Three domains reach
  /// it now — publication, seat requests and trip lifecycle — and a member
  /// abandoning a journey should not be told something about publishing.
  ///
  /// Every reason the server names and this build knows has its own sentence,
  /// so what lands here is a 409 carrying no reason, or one from a backend
  /// newer than this app.
  test('the generic conflict copy belongs to no domain', () {
    const RmFailure unknown = RmFailure.fromBackend(
      status: 409,
      code: RmErrorCode.conflict,
      // A reason a later backend might add. `tripRefusal` and
      // `seatRequestRefusal` both answer null for it, so the fallback is what
      // the member sees.
      reason: 'trip_already_started',
    );

    for (final (AppLocalizations l10n, List<String> forbidden)
        in <(AppLocalizations, List<String>)>[
          (
            tr,
            <String>[
              'rota',
              'yayın',
              'koltuk',
              'istek',
              'yolculuk',
              'sürücü',
              'yolcu',
            ],
          ),
          (
            en,
            <String>[
              'route',
              'publish',
              'seat',
              'request',
              'trip',
              'driver',
              'passenger',
            ],
          ),
        ]) {
      final String copy = unknown.copy(l10n).toLowerCase();

      expect(copy, isNotEmpty);
      for (final String word in forbidden) {
        expect(
          copy.contains(word),
          isFalse,
          reason: '"$word" names a domain the server did not name: $copy',
        );
      }
    }
  });

  /// And it still says something a member can act on, rather than shrugging.
  test('the generic conflict copy is not the unexpected-error sentence', () {
    final RmFailure conflict = backend(RmErrorCode.conflict, status: 409);

    expect(
      conflict.copy(tr),
      isNot(backend(RmErrorCode.internalError).copy(tr)),
    );
    expect(
      conflict.copy(en),
      isNot(backend(RmErrorCode.internalError).copy(en)),
    );
  });
}
