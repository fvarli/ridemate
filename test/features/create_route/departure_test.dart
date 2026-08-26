import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/places/place.dart';
import 'package:ridemate/features/create_route/application/create_route_providers.dart';
import 'package:ridemate/features/create_route/domain/create_route_draft.dart';
import 'package:ridemate/features/create_route/domain/create_route_fixtures.dart';
import 'package:ridemate/features/create_route/domain/departure.dart';

/// The departure a driver states, and the things the client must not decide.
///
/// The whole point of these value types is what they CANNOT express. A
/// DepartureDate is a day on a calendar and a DepartureTime is a reading on a
/// clock; neither is an instant, because turning them into one needs a timezone
/// this client does not own and must not guess.
void main() {
  /// Two places the way the server returns them.
  const Place from = Place(
    id: '01991a00-0000-7000-8000-00000000000a',
    label: 'Sunucu Yeri A',
  );
  const Place to = Place(
    id: '01991a00-0000-7000-8000-00000000000b',
    label: 'Sunucu Yeri B',
  );

  ProviderContainer container() {
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);

    return c;
  }

  group('The departure types carry no timezone', () {
    test('a date is three numbers and writes itself unambiguously', () {
      const DepartureDate date = DepartureDate(year: 2026, month: 9, day: 14);

      expect(date.iso, '2026-09-14');
      expect(date.year, 2026);
      expect(date.month, 9);
      expect(date.day, 14);
    });

    test('single-digit parts are padded, so the value is sortable text', () {
      expect(
        const DepartureDate(year: 2026, month: 1, day: 5).iso,
        '2026-01-05',
      );
      expect(const DepartureTime(hour: 7, minute: 5).hhMm, '07:05');
    });

    test('a time is minutes only, matching what the API accepts', () {
      expect(const DepartureTime(hour: 8, minute: 25).hhMm, '08:25');
      expect(const DepartureTime(hour: 0, minute: 0).hhMm, '00:00');
      expect(const DepartureTime(hour: 23, minute: 59).hhMm, '23:59');
    });

    test('a picker hands back an instant; only the calendar part survives', () {
      // The DateTime a picker returns carries a time of day and a local flag.
      // Keeping either would smuggle a timezone into a value that has none.
      final DepartureDate date = DepartureDate.from(
        DateTime(2026, 9, 14, 23, 59, 59),
      );

      expect(date, const DepartureDate(year: 2026, month: 9, day: 14));
      expect(date.iso, '2026-09-14');
    });

    test('values with the same parts are the same value', () {
      expect(
        const DepartureDate(year: 2026, month: 9, day: 14),
        const DepartureDate(year: 2026, month: 9, day: 14),
      );
      expect(
        const DepartureTime(hour: 8, minute: 25),
        const DepartureTime(hour: 8, minute: 25),
      );
      expect(
        const DepartureTime(hour: 8, minute: 25),
        isNot(const DepartureTime(hour: 8, minute: 26)),
      );
    });

    test('neither type offers a way to ask whether it has passed', () {
      // Structural. `past` and `upcoming` are read in the pilot's timezone on
      // the server, and a client that answered the question locally would
      // eventually disagree with the service about whether a journey can still
      // be cancelled.
      const DepartureDate date = DepartureDate(year: 1990, month: 1, day: 1);

      expect(date.toString(), '1990-01-01');
      expect(
        date.toString().toLowerCase(),
        isNot(anyOf(contains('past'), contains('upcoming'))),
      );
    });
  });

  group('Recurrence', () {
    test('exactly two cases, named the way the contract names them', () {
      expect(Recurrence.values, <Recurrence>[
        Recurrence.once,
        Recurrence.weekdays,
      ]);
    });

    test('only a one-off journey carries a date', () {
      expect(Recurrence.once.needsDate, isTrue);
      expect(Recurrence.weekdays.needsDate, isFalse);
    });
  });

  group('A draft is complete only when the driver has said enough', () {
    test('the designed starting state is not complete', () {
      expect(kInitialCreateRouteDraft.isComplete, isFalse);
    });

    test('a weekday commute needs a time and nothing else', () {
      final ProviderContainer c = container();
      final CreateRouteDraftController controller = c.read(
        createRouteDraftProvider.notifier,
      );

      controller.setOrigin(from);
      controller.setDestination(to);
      controller.setRecurrence(Recurrence.weekdays);
      expect(c.read(createRouteDraftProvider).isComplete, isFalse);

      controller.setDepartureTime(const DepartureTime(hour: 8, minute: 25));
      expect(c.read(createRouteDraftProvider).isComplete, isTrue);
    });

    test('a one-off journey needs a date as well', () {
      final ProviderContainer c = container();
      final CreateRouteDraftController controller = c.read(
        createRouteDraftProvider.notifier,
      );

      controller.setOrigin(from);
      controller.setDestination(to);
      controller.setRecurrence(Recurrence.once);
      controller.setDepartureTime(const DepartureTime(hour: 8, minute: 25));
      expect(c.read(createRouteDraftProvider).isComplete, isFalse);

      controller.setDepartureDate(
        const DepartureDate(year: 2099, month: 4, day: 1),
      );
      expect(c.read(createRouteDraftProvider).isComplete, isTrue);
    });

    test('a time alone never completes a one-off journey', () {
      final ProviderContainer c = container();
      final CreateRouteDraftController controller = c.read(
        createRouteDraftProvider.notifier,
      );

      controller.setDepartureTime(const DepartureTime(hour: 8, minute: 0));
      controller.setRecurrence(Recurrence.once);

      expect(c.read(createRouteDraftProvider).departureDate, isNull);
      expect(c.read(createRouteDraftProvider).isComplete, isFalse);
    });
  });

  group('Switching recurrence', () {
    /// CARRIES WEIGHT. A hidden date is state nobody can see.
    test('choosing a weekday commute clears the date', () {
      final ProviderContainer c = container();
      final CreateRouteDraftController controller = c.read(
        createRouteDraftProvider.notifier,
      );

      controller.setRecurrence(Recurrence.once);
      controller.setDepartureDate(
        const DepartureDate(year: 2099, month: 4, day: 1),
      );
      expect(c.read(createRouteDraftProvider).departureDate, isNotNull);

      controller.setRecurrence(Recurrence.weekdays);

      // Not merely ignored at mapping time. The row is off the screen, so a
      // value left behind would be invisible and could still be published.
      expect(c.read(createRouteDraftProvider).departureDate, isNull);
    });

    test('switching back does not invent a date', () {
      final ProviderContainer c = container();
      final CreateRouteDraftController controller = c.read(
        createRouteDraftProvider.notifier,
      );

      controller.setRecurrence(Recurrence.once);
      controller.setDepartureDate(
        const DepartureDate(year: 2099, month: 4, day: 1),
      );
      controller.setRecurrence(Recurrence.weekdays);
      controller.setRecurrence(Recurrence.once);

      expect(c.read(createRouteDraftProvider).departureDate, isNull);
      expect(c.read(createRouteDraftProvider).isComplete, isFalse);
    });

    test('the chosen time survives a change of recurrence', () {
      // The time is needed in both modes, so losing it would make the driver
      // state it twice for no reason.
      final ProviderContainer c = container();
      final CreateRouteDraftController controller = c.read(
        createRouteDraftProvider.notifier,
      );

      controller.setDepartureTime(const DepartureTime(hour: 8, minute: 25));
      controller.setRecurrence(Recurrence.once);
      controller.setRecurrence(Recurrence.weekdays);

      expect(
        c.read(createRouteDraftProvider).departureTime,
        const DepartureTime(hour: 8, minute: 25),
      );
    });

    test('nothing else on the draft moves', () {
      final ProviderContainer c = container();
      final CreateRouteDraftController controller = c.read(
        createRouteDraftProvider.notifier,
      );
      final CreateRouteDraft before = c.read(createRouteDraftProvider);

      controller.setRecurrence(Recurrence.once);
      final CreateRouteDraft after = c.read(createRouteDraftProvider);

      expect(after.origin, before.origin);
      expect(after.destination, before.destination);
      expect(after.seats, before.seats);
      expect(after.rules, before.rules);
    });
  });

  group('The draft is free of things the server owns', () {
    test('no timezone anywhere in the draft or its departure', () {
      final ProviderContainer c = container();
      c
          .read(createRouteDraftProvider.notifier)
          .setDepartureTime(const DepartureTime(hour: 8, minute: 25));

      final CreateRouteDraft draft = c.read(createRouteDraftProvider);
      final String rendered =
          '${draft.departureDate} ${draft.departureTime} ${draft.recurrence}';

      for (final String forbidden in <String>[
        'Istanbul',
        'UTC',
        '+03',
        'Z',
        'tz',
      ]) {
        expect(rendered, isNot(contains(forbidden)), reason: forbidden);
      }
    });
  });

  group('A refreshed catalogue is reconciled by identity', () {
    /// CARRIES WEIGHT. A place that has gone cannot stay selected.
    test('a selection survives only if its exact id is still there', () {
      final ProviderContainer c = container();
      final CreateRouteDraftController controller = c.read(
        createRouteDraftProvider.notifier,
      );

      controller.setOrigin(from);
      controller.setDestination(to);

      // The same places come back, unchanged.
      controller.reconcileWith(<Place>[from, to]);
      expect(c.read(createRouteDraftProvider).origin, from);
      expect(c.read(createRouteDraftProvider).destination, to);
    });

    test('a disappearing place clears that endpoint and only that one', () {
      final ProviderContainer c = container();
      final CreateRouteDraftController controller = c.read(
        createRouteDraftProvider.notifier,
      );

      controller.setOrigin(from);
      controller.setDestination(to);

      controller.reconcileWith(<Place>[to]);

      expect(c.read(createRouteDraftProvider).origin, isNull);
      expect(c.read(createRouteDraftProvider).destination, to);
    });

    /// A label is what a place is called; the id is what it is.
    test('a renamed place keeps its selection, a re-labelled id does not', () {
      final ProviderContainer c = container();
      final CreateRouteDraftController controller = c.read(
        createRouteDraftProvider.notifier,
      );

      controller.setOrigin(from);

      // Same id, new name: still the same place, so the choice stands.
      const Place renamed = Place(
        id: '01991a00-0000-7000-8000-00000000000a',
        label: 'Sunucu Yeri A (yeni ad)',
      );
      controller.reconcileWith(<Place>[renamed]);
      expect(c.read(createRouteDraftProvider).origin?.id, from.id);

      // Same NAME, different id: a different place wearing the old name, and
      // matching on the label would have silently moved the journey.
      const Place impostor = Place(
        id: '01991a00-0000-7000-8000-0000000000ff',
        label: 'Sunucu Yeri A',
      );
      controller.reconcileWith(<Place>[impostor]);
      expect(c.read(createRouteDraftProvider).origin, isNull);
    });

    test('an empty catalogue clears both endpoints', () {
      final ProviderContainer c = container();
      final CreateRouteDraftController controller = c.read(
        createRouteDraftProvider.notifier,
      );

      controller.setOrigin(from);
      controller.setDestination(to);
      controller.reconcileWith(const <Place>[]);

      expect(c.read(createRouteDraftProvider).origin, isNull);
      expect(c.read(createRouteDraftProvider).destination, isNull);
    });

    test('nothing else about the draft is touched', () {
      final ProviderContainer c = container();
      final CreateRouteDraftController controller = c.read(
        createRouteDraftProvider.notifier,
      );

      controller.setOrigin(from);
      controller.setDepartureTime(const DepartureTime(hour: 8, minute: 25));
      controller.incrementSeats();

      controller.reconcileWith(const <Place>[]);
      final CreateRouteDraft after = c.read(createRouteDraftProvider);

      expect(after.departureTime, const DepartureTime(hour: 8, minute: 25));
      expect(after.seats, 4);
      expect(after.rules, isNotEmpty);
    });
  });
}
