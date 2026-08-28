import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/api/rm_error_code.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/id/rm_uuid.dart';
import 'package:ridemate/core/places/place.dart';
import 'package:ridemate/features/create_route/application/create_route_providers.dart';
import 'package:ridemate/features/create_route/application/publication_providers.dart';
import 'package:ridemate/features/create_route/data/route_repository.dart';
import 'package:ridemate/features/create_route/domain/create_route_draft.dart';
import 'package:ridemate/features/create_route/domain/departure.dart';

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
        final Map<String, bool> wire = RoutePublicationCommand.rulesToJson(
          rules,
        );

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
        for (final RideRuleId id in RideRuleId.values)
          RoutePublicationCommand.wireKey(id),
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
