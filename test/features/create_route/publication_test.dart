import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/api/rm_error_code.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/id/rm_uuid.dart';
import 'package:ridemate/core/places/place.dart';
import 'package:ridemate/core/routes/departure.dart';
import 'package:ridemate/core/routes/ride_rule.dart';
import 'package:ridemate/features/create_route/application/create_route_providers.dart';
import 'package:ridemate/features/create_route/application/publication_providers.dart';
import 'package:ridemate/features/create_route/domain/create_route_draft.dart';

import '../../support/fakes.dart';

/// Publishing: the id that survives a retry, and the one that must not.
void main() {
  const Place from = Place(
    id: '01991a00-0000-7000-8000-00000000000a',
    label: 'Sunucu Yeri A',
  );
  const Place to = Place(
    id: '01991a00-0000-7000-8000-00000000000b',
    label: 'Sunucu Yeri B',
  );

  late FakeRouteRepository routes;
  late FakeUuidGenerator ids;

  ProviderContainer container() {
    routes = FakeRouteRepository();
    ids = FakeUuidGenerator();

    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        routeRepositoryProvider.overrideWithValue(routes),
        uuidGeneratorProvider.overrideWithValue(ids),
      ],
    );
    addTearDown(c.dispose);

    return c;
  }

  /// A draft complete enough to publish.
  void fillDraft(
    ProviderContainer c, {
    Recurrence recurrence = Recurrence.weekdays,
    DepartureDate? date,
    DepartureTime time = const DepartureTime(hour: 8, minute: 25),
    int seats = 3,
    Set<RideRuleId> rules = const <RideRuleId>{RideRuleId.noSmoking},
  }) {
    final CreateRouteDraftController controller = c.read(
      createRouteDraftProvider.notifier,
    );

    controller.setOrigin(from);
    controller.setDestination(to);
    controller.setRecurrence(recurrence);
    if (date != null) controller.setDepartureDate(date);
    controller.setDepartureTime(time);

    for (final RideRuleId id in RideRuleId.values) {
      final bool wanted = rules.contains(id);
      final bool current = c.read(createRouteDraftProvider).isRuleSelected(id);
      if (wanted != current) controller.toggleRule(id);
    }

    while (c.read(createRouteDraftProvider).seats < seats) {
      controller.incrementSeats();
    }
    while (c.read(createRouteDraftProvider).seats > seats) {
      controller.decrementSeats();
    }
  }

  group('The id is the client’s, and it is a v7', () {
    test('the real generator mints version 7 uuids', () {
      const RmUuidGenerator generator = UuidV7Generator();
      final String id = generator.v7();

      expect(
        id,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      // Distinct every time, or two journeys would collide.
      expect(generator.v7(), isNot(id));
    });

    test('the fake is shaped like one too', () {
      final FakeUuidGenerator fake = FakeUuidGenerator();

      expect(
        fake.v7(),
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    });
  });

  group('The request body', () {
    test('carries exactly the documented fields', () async {
      final ProviderContainer c = container();
      fillDraft(c);

      await c.read(publicationProvider.notifier).publish();

      expect(routes.lastBody.keys.toSet(), <String>{
        'id',
        'origin_place_id',
        'destination_place_id',
        'recurrence',
        'departure_time',
        'seats_offered',
        'rules',
      });
      expect(routes.lastBody['origin_place_id'], from.id);
      expect(routes.lastBody['destination_place_id'], to.id);
      expect(routes.lastBody['recurrence'], 'weekdays');
      expect(routes.lastBody['departure_time'], '08:25');
      expect(routes.lastBody['seats_offered'], 3);
    });

    /// CARRIES WEIGHT. Everything the server owns stays the server's.
    test('sends nothing the backend decides for itself', () async {
      final ProviderContainer c = container();
      fillDraft(
        c,
        recurrence: Recurrence.once,
        date: const DepartureDate(year: 2099, month: 4, day: 1),
      );

      await c.read(publicationProvider.notifier).publish();

      for (final String forbidden in <String>[
        'timezone',
        'account_id',
        'latitude',
        'longitude',
        'slug',
        'label',
        'origin_label',
        'cost_share_per_person',
        'cost',
        'departure_state',
        'status',
        'published_at',
        'created_at',
        'updated_at',
      ]) {
        expect(
          routes.lastBody.containsKey(forbidden),
          isFalse,
          reason: forbidden,
        );
      }
    });

    test('a one-off journey states its date', () async {
      final ProviderContainer c = container();
      fillDraft(
        c,
        recurrence: Recurrence.once,
        date: const DepartureDate(year: 2099, month: 4, day: 1),
      );

      await c.read(publicationProvider.notifier).publish();

      expect(routes.lastBody['recurrence'], 'once');
      expect(routes.lastBody['departure_date'], '2099-04-01');
    });

    test('a weekday commute omits the date entirely', () async {
      final ProviderContainer c = container();
      fillDraft(c);

      await c.read(publicationProvider.notifier).publish();

      // Absent, not null: the contract's oneOf refuses a weekday commute that
      // carries a date at all.
      expect(routes.lastBody.containsKey('departure_date'), isFalse);
    });
  });

  group('Ride rules map completely', () {
    test('every combination sends all four booleans', () {
      const List<Set<RideRuleId>> combinations = <Set<RideRuleId>>[
        <RideRuleId>{},
        <RideRuleId>{RideRuleId.noSmoking},
        <RideRuleId>{RideRuleId.musicOk, RideRuleId.quiet},
        <RideRuleId>{
          RideRuleId.noSmoking,
          RideRuleId.musicOk,
          RideRuleId.noPets,
          RideRuleId.quiet,
        },
      ];

      for (final Set<RideRuleId> rules in combinations) {
        final Map<String, bool> wire = rideRulesToJson(rules);

        expect(wire.keys.toSet(), <String>{
          'no_smoking',
          'music_ok',
          'no_pets',
          'quiet',
        }, reason: '$rules');

        expect(wire['no_smoking'], rules.contains(RideRuleId.noSmoking));
        expect(wire['music_ok'], rules.contains(RideRuleId.musicOk));
        expect(wire['no_pets'], rules.contains(RideRuleId.noPets));
        expect(wire['quiet'], rules.contains(RideRuleId.quiet));
      }
    });

    /// Every rule has a name, and the mapping is total by construction.
    test('no rule is missing a wire name', () {
      final Set<String> keys = <String>{
        for (final RideRuleId id in RideRuleId.values) rideRuleWireKey(id),
      };

      expect(keys, hasLength(RideRuleId.values.length));
    });
  });

  group('Success', () {
    test('a created route is confirmed', () async {
      final ProviderContainer c = container();
      fillDraft(c);

      await c.read(publicationProvider.notifier).publish();

      final PublicationState state = c.read(publicationProvider);
      expect(state, isA<PublicationConfirmed>());
      expect((state as PublicationConfirmed).route.id, ids.minted.single);
    });

    /// CARRIES WEIGHT. A timeout then a retry that returns "already published"
    /// must land in exactly the same place as a first-attempt success.
    test(
      'an indeterminate attempt then a retry reaches the same state',
      () async {
        final ProviderContainer c = container();
        fillDraft(c);

        routes.failure = const RmFailure.transport();
        await c.read(publicationProvider.notifier).publish();

        final PublicationState failed = c.read(publicationProvider);
        expect(failed, isA<PublicationRetryable>());
        final String pending = (failed as PublicationRetryable).routeId;

        // The server had it all along; the answer just never arrived.
        routes.failure = null;
        await c.read(publicationProvider.notifier).publish();

        expect(c.read(publicationProvider), isA<PublicationConfirmed>());

        // Two requests, ONE id. A second id here would have published the same
        // journey twice.
        expect(routes.callCount, 2);
        expect(routes.routeIds, <String>[pending, pending]);
        expect(ids.minted, hasLength(1));
      },
    );
  });

  group('The id survives a retry, and only the right one', () {
    test('an unchanged draft keeps the pending id', () async {
      final ProviderContainer c = container();
      fillDraft(c);
      routes.failure = const RmFailure.transport();

      await c.read(publicationProvider.notifier).publish();
      await c.read(publicationProvider.notifier).publish();
      await c.read(publicationProvider.notifier).publish();

      expect(ids.minted, hasLength(1));
      expect(routes.routeIds.toSet(), hasLength(1));
    });

    /// CARRIES WEIGHT. A changed journey is a different journey.
    test('any semantic change mints a new id', () async {
      for (final void Function(ProviderContainer) change
          in <void Function(ProviderContainer)>[
            (ProviderContainer c) => c
                .read(createRouteDraftProvider.notifier)
                .setDepartureTime(const DepartureTime(hour: 9, minute: 0)),
            (ProviderContainer c) =>
                c.read(createRouteDraftProvider.notifier).incrementSeats(),
            (ProviderContainer c) => c
                .read(createRouteDraftProvider.notifier)
                .toggleRule(RideRuleId.quiet),
            (ProviderContainer c) => c
                .read(createRouteDraftProvider.notifier)
                .setRecurrence(Recurrence.once),
            (ProviderContainer c) => c
                .read(createRouteDraftProvider.notifier)
                .setDestination(
                  const Place(
                    id: '01991a00-0000-7000-8000-00000000000c',
                    label: 'Sunucu Yeri C',
                  ),
                ),
          ]) {
        final ProviderContainer c = container();
        fillDraft(c);
        routes.failure = const RmFailure.transport();

        await c.read(publicationProvider.notifier).publish();
        final String first = ids.minted.single;

        change(c);
        // The draft may now be incomplete (switching to `once` drops the
        // date), so make it publishable again without undoing the change.
        if (c.read(createRouteDraftProvider).needsDepartureDate &&
            c.read(createRouteDraftProvider).departureDate == null) {
          c
              .read(createRouteDraftProvider.notifier)
              .setDepartureDate(
                const DepartureDate(year: 2099, month: 4, day: 1),
              );
        }

        await c.read(publicationProvider.notifier).publish();

        expect(ids.minted, hasLength(2), reason: 'a changed journey');
        expect(routes.routeIds.last, isNot(first));
      }
    });

    test('a relabelled place is the same intention', () async {
      final ProviderContainer c = container();
      fillDraft(c);
      routes.failure = const RmFailure.transport();
      await c.read(publicationProvider.notifier).publish();

      // Same id, new name — Place equality is id-only, and the server stores
      // the id.
      c
          .read(createRouteDraftProvider.notifier)
          .setOrigin(Place(id: from.id, label: 'Yeni ad'));

      await c.read(publicationProvider.notifier).publish();

      expect(ids.minted, hasLength(1));
    });
  });

  group('Retry semantics decide the state', () {
    /// The matrix, stated once.
    ///
    /// Retryable means the outcome is unknown or a later attempt could
    /// legitimately succeed. Refused means the server has decided, and sending
    /// the same bytes again produces the same decision.
    ///
    /// Notice the two rows that share a code and disagree: a 201 that would
    /// not decode and a 404 are both `unexpected`, and they are opposites. The
    /// status is what separates them.
    const List<(String, RmFailure, bool)> matrix = <(String, RmFailure, bool)>[
      ('nothing came back at all', RmFailure.transport(), true),
      (
        'the server broke',
        RmFailure.fromBackend(status: 500, code: RmErrorCode.internalError),
        true,
      ),
      (
        'the server was unavailable',
        RmFailure.fromBackend(status: 503, code: RmErrorCode.unexpected),
        true,
      ),
      (
        'a 201 whose body would not decode',
        RmFailure.fromBackend(status: 201, code: RmErrorCode.unexpected),
        true,
      ),
      (
        'a 200 whose body would not decode',
        RmFailure.fromBackend(status: 200, code: RmErrorCode.unexpected),
        true,
      ),
      (
        'come back later',
        RmFailure.fromBackend(status: 429, code: RmErrorCode.rateLimited),
        true,
      ),
      (
        'the id already means something else',
        RmFailure.fromBackend(status: 409, code: RmErrorCode.conflict),
        false,
      ),
      (
        'the journey was refused',
        RmFailure.fromBackend(status: 422, code: RmErrorCode.validationFailed),
        false,
      ),
      (
        'the account is suspended',
        RmFailure.fromBackend(status: 403, code: RmErrorCode.forbidden),
        false,
      ),
      (
        'a 401 that escaped the session',
        RmFailure.fromBackend(status: 401, code: RmErrorCode.unauthenticated),
        false,
      ),
      (
        'the request was malformed',
        RmFailure.fromBackend(status: 400, code: RmErrorCode.badRequest),
        false,
      ),
      (
        'the endpoint was not found',
        RmFailure.fromBackend(status: 404, code: RmErrorCode.notFound),
        false,
      ),
      (
        'the method was wrong',
        RmFailure.fromBackend(status: 405, code: RmErrorCode.methodNotAllowed),
        false,
      ),
    ];

    for (final (String label, RmFailure failure, bool retryable) in matrix) {
      test('$label → ${retryable ? 'Retryable' : 'Refused'}', () async {
        final ProviderContainer c = container();
        fillDraft(c);
        routes.failure = failure;

        await c.read(publicationProvider.notifier).publish();

        final PublicationState state = c.read(publicationProvider);

        expect(
          state,
          retryable ? isA<PublicationRetryable>() : isA<PublicationRefused>(),
          reason: label,
        );

        // Whichever way it landed, the attempt keeps its identity.
        expect(
          switch (state) {
            PublicationRetryable(:final String routeId) => routeId,
            PublicationRefused(:final String routeId) => routeId,
            _ => null,
          },
          ids.minted.single,
          reason: label,
        );
      });
    }

    /// CARRIES WEIGHT. A refusal is not a reason to mint a replacement id.
    ///
    /// If it were, a driver who tapped again after a 409 would publish a
    /// second copy of the journey the 409 was telling them about.
    test('no failure silently regenerates the id', () async {
      for (final (String label, RmFailure failure, _) in matrix) {
        final ProviderContainer c = container();
        fillDraft(c);
        routes.failure = failure;

        await c.read(publicationProvider.notifier).publish();
        // A second deliberate tap, with nothing edited in between.
        await c.read(publicationProvider.notifier).publish();

        expect(ids.minted, hasLength(1), reason: label);
        expect(routes.routeIds.toSet(), hasLength(1), reason: label);
        expect(routes.callCount, 2, reason: label);
      }
    });

    /// And a changed journey still gets a new identity, whatever went wrong.
    test('editing after any failure mints a new id', () async {
      for (final (String label, RmFailure failure, _) in matrix) {
        final ProviderContainer c = container();
        fillDraft(c);
        routes.failure = failure;

        await c.read(publicationProvider.notifier).publish();
        final String first = ids.minted.single;

        c
            .read(createRouteDraftProvider.notifier)
            .setDepartureTime(const DepartureTime(hour: 9, minute: 15));

        await c.read(publicationProvider.notifier).publish();

        expect(ids.minted, hasLength(2), reason: label);
        expect(routes.routeIds.last, isNot(first), reason: label);
      }
    });

    /// CARRIES WEIGHT, and the reason the predicate reads the status.
    ///
    /// The server said 201. The body was unreadable. The route probably
    /// exists, so this must be the retryable case and the retry must carry the
    /// id the first attempt used — otherwise the recovery publishes a
    /// duplicate of the journey it was trying to confirm.
    test('an unreadable success is indeterminate, and keeps its id', () async {
      final ProviderContainer c = container();
      fillDraft(c);
      routes.failure = const RmFailure.fromBackend(
        status: 201,
        code: RmErrorCode.unexpected,
      );

      await c.read(publicationProvider.notifier).publish();

      final PublicationState state = c.read(publicationProvider);
      expect(state, isA<PublicationRetryable>());
      final String pending = (state as PublicationRetryable).routeId;

      routes.failure = null;
      await c.read(publicationProvider.notifier).publish();

      expect(c.read(publicationProvider), isA<PublicationConfirmed>());
      expect(routes.routeIds, <String>[pending, pending]);
      expect(ids.minted, hasLength(1));
    });

    /// The same code, the opposite verdict. This is the pair the old
    /// code-only classifier could not tell apart.
    test('unexpected is not one answer: 201 retries, 404 does not', () async {
      final ProviderContainer unreadable = container();
      fillDraft(unreadable);
      routes.failure = const RmFailure.fromBackend(
        status: 201,
        code: RmErrorCode.unexpected,
      );
      await unreadable.read(publicationProvider.notifier).publish();
      expect(unreadable.read(publicationProvider), isA<PublicationRetryable>());

      final ProviderContainer missing = container();
      fillDraft(missing);
      routes.failure = const RmFailure.fromBackend(
        status: 404,
        code: RmErrorCode.unexpected,
      );
      await missing.read(publicationProvider.notifier).publish();
      expect(missing.read(publicationProvider), isA<PublicationRefused>());
    });
  });

  group('Refusals are not retried behind the driver', () {
    test('a conflict does not mint a replacement id', () async {
      final ProviderContainer c = container();
      fillDraft(c);
      routes.failure = const RmFailure.fromBackend(
        status: 409,
        code: RmErrorCode.conflict,
      );

      await c.read(publicationProvider.notifier).publish();

      final PublicationState state = c.read(publicationProvider);
      expect(state, isA<PublicationRefused>());
      expect(routes.callCount, 1, reason: 'no automatic second attempt');
      expect(ids.minted, hasLength(1), reason: 'no replacement id');
    });

    test('a validation failure is the server’s answer, not a glitch', () async {
      final ProviderContainer c = container();
      fillDraft(c);
      routes.failure = const RmFailure.fromBackend(
        status: 422,
        code: RmErrorCode.validationFailed,
      );

      await c.read(publicationProvider.notifier).publish();

      expect(c.read(publicationProvider), isA<PublicationRefused>());
    });

    test('a server error stays retryable with its id', () async {
      final ProviderContainer c = container();
      fillDraft(c);
      routes.failure = const RmFailure.fromBackend(
        status: 500,
        code: RmErrorCode.internalError,
      );

      await c.read(publicationProvider.notifier).publish();

      final PublicationState state = c.read(publicationProvider);
      expect(state, isA<PublicationRetryable>());
      expect((state as PublicationRetryable).routeId, ids.minted.single);
    });

    /// The draft is never touched by a failure — nothing typed is lost.
    test('a failure leaves the draft exactly as written', () async {
      final ProviderContainer c = container();
      fillDraft(c);
      final CreateRouteDraft before = c.read(createRouteDraftProvider);

      routes.failure = const RmFailure.transport();
      await c.read(publicationProvider.notifier).publish();

      expect(c.read(createRouteDraftProvider), before);
    });
  });

  group('One intention, one request', () {
    /// Two taps in the same frame are one intention arriving twice.
    test('concurrent publishes share a single attempt', () async {
      final ProviderContainer c = container();
      fillDraft(c);

      final PublicationController controller = c.read(
        publicationProvider.notifier,
      );

      await Future.wait<void>(<Future<void>>[
        controller.publish(),
        controller.publish(),
        controller.publish(),
      ]);

      expect(routes.callCount, 1);
      expect(ids.minted, hasLength(1));
    });

    test('an incomplete draft sends nothing at all', () async {
      final ProviderContainer c = container();
      // Endpoints only: no time, so nothing to publish.
      c.read(createRouteDraftProvider.notifier).setOrigin(from);
      c.read(createRouteDraftProvider.notifier).setDestination(to);

      await c.read(publicationProvider.notifier).publish();

      expect(routes.callCount, 0);
      expect(ids.minted, isEmpty);
      expect(c.read(publicationProvider), isA<PublicationIdle>());
    });
  });
}
