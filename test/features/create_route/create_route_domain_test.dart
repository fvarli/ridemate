import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/places/mock_places.dart';
import 'package:ridemate/features/create_route/application/create_route_providers.dart';
import 'package:ridemate/features/create_route/domain/create_route_draft.dart';
import 'package:ridemate/features/create_route/domain/create_route_fixtures.dart';

void main() {
  ProviderContainer container() {
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  group('CreateRouteDraft', () {
    test('starts from the journey the design shows', () {
      const CreateRouteDraft d = kInitialCreateRouteDraft;
      expect(d.origin, MockPlaces.atasehir);
      expect(d.destination, MockPlaces.maslak);
      expect(d.seats, 3);
      expect(d.repeatsOnWeekdays, isTrue);
      // The design selects exactly one rule.
      expect(d.rules, <RideRuleId>{RideRuleId.noSmoking});
    });

    test('toggling a rule adds then removes it', () {
      const RideRuleId id = RideRuleId.quiet;
      final CreateRouteDraft on = kInitialCreateRouteDraft.withRuleToggled(id);
      expect(on.isRuleSelected(id), isTrue);

      final CreateRouteDraft off = on.withRuleToggled(id);
      expect(off.isRuleSelected(id), isFalse);
      expect(off, kInitialCreateRouteDraft);
    });

    test('toggling one rule leaves the others alone', () {
      final CreateRouteDraft d = kInitialCreateRouteDraft.withRuleToggled(
        RideRuleId.musicOk,
      );
      expect(d.isRuleSelected(RideRuleId.noSmoking), isTrue);
      expect(d.isRuleSelected(RideRuleId.musicOk), isTrue);
      expect(d.rules.length, 2);
    });

    test('compares by value, so provider rebuilds are meaningful', () {
      expect(kInitialCreateRouteDraft, kInitialCreateRouteDraft.copyWith());
      expect(
        kInitialCreateRouteDraft,
        isNot(kInitialCreateRouteDraft.copyWith(seats: 2)),
      );
      expect(
        kInitialCreateRouteDraft.hashCode,
        kInitialCreateRouteDraft.copyWith().hashCode,
      );
    });
  });

  group('Seats have a floor and no ceiling', () {
    test('the floor is the only bound the draft knows about', () {
      expect(kSeatsFloor, 1);
      expect(kInitialCreateRouteDraft.canDecrementSeats, isTrue);
      expect(
        kInitialCreateRouteDraft.copyWith(seats: kSeatsFloor).canDecrementSeats,
        isFalse,
      );
    });

    test('decrementing stops at the floor', () {
      final ProviderContainer c = container();
      final CreateRouteDraftController controller = c.read(
        createRouteDraftProvider.notifier,
      );

      for (int i = 0; i < 10; i++) {
        controller.decrementSeats();
      }
      expect(c.read(createRouteDraftProvider).seats, kSeatsFloor);
    });

    test('incrementing has no ceiling', () {
      // Any maximum would invent a vehicle-capacity or product rule the design
      // does not state. A real limit arrives later as vehicle domain data.
      final ProviderContainer c = container();
      final CreateRouteDraftController controller = c.read(
        createRouteDraftProvider.notifier,
      );

      for (int i = 0; i < 20; i++) {
        controller.incrementSeats();
      }
      expect(c.read(createRouteDraftProvider).seats, 23);
    });
  });

  group('The cost share is displayed, never computed', () {
    test('the amount is a fixture the draft cannot reach', () {
      // The guarantee here is structural: the suggested share is a top-level
      // compile-time constant, and CreateRouteDraft carries no cost field for
      // anything to derive one into. Deriving it from seats, endpoints or
      // recurrence would author a pricing rule the client may not author, and
      // multiplying it by seats would be a driver-earnings claim.
      //
      // The behavioural half of this guarantee — the screen still shows ₺18
      // after the seat count changes — lives in create_route_screen_test.dart,
      // where it has teeth.
      expect(kSuggestedCostSharePerPerson, 18);
    });

    test('the departure fixtures are declared, not scheduled', () {
      // The approved screen has no date or time control, so these are the only
      // departure values it can express. They are constants, not a schedule.
      expect(kRecurrenceDepartureHour, 8);
      expect(kRecurrenceDepartureMinute, 0);
    });
  });

  group('Ride rules are published rules, not eligibility', () {
    test('the policy-sensitive rule is flagged', () {
      expect(kRuleNeedingPolicyReview, RideRuleId.noPets);
    });

    test('toggling any rule changes nothing but the draft', () {
      final ProviderContainer c = container();
      final CreateRouteDraftController controller = c.read(
        createRouteDraftProvider.notifier,
      );

      for (final RideRuleId id in RideRuleId.values) {
        final CreateRouteDraft before = c.read(createRouteDraftProvider);
        controller.toggleRule(id);
        final CreateRouteDraft after = c.read(createRouteDraftProvider);

        expect(after.isRuleSelected(id), !before.isRuleSelected(id));
        expect(after.origin, before.origin, reason: '$id changed the origin');
        expect(after.seats, before.seats, reason: '$id changed the seats');
        expect(
          after.repeatsOnWeekdays,
          before.repeatsOnWeekdays,
          reason: '$id changed the recurrence',
        );
      }
    });

    test('the design draws exactly four rules', () {
      expect(RideRuleId.values, <RideRuleId>[
        RideRuleId.noSmoking,
        RideRuleId.musicOk,
        RideRuleId.noPets,
        RideRuleId.quiet,
      ]);
    });
  });

  group('CreateRouteDraftController', () {
    test('editing endpoints and recurrence updates the draft', () {
      final ProviderContainer c = container();
      final CreateRouteDraftController controller = c.read(
        createRouteDraftProvider.notifier,
      );

      controller.setOrigin(MockPlaces.kadikoy);
      expect(c.read(createRouteDraftProvider).origin, MockPlaces.kadikoy);

      controller.setDestination(MockPlaces.levent);
      expect(c.read(createRouteDraftProvider).destination, MockPlaces.levent);

      controller.setRepeatsOnWeekdays(false);
      expect(c.read(createRouteDraftProvider).repeatsOnWeekdays, isFalse);

      controller.setRepeatsOnWeekdays(true);
      expect(c.read(createRouteDraftProvider).repeatsOnWeekdays, isTrue);
    });

    test('a fresh container starts from the designed defaults', () {
      // The in-session draft survives closing the screen, but nothing is
      // persisted — a new process starts here again.
      final ProviderContainer first = container();
      first.read(createRouteDraftProvider.notifier).incrementSeats();
      expect(first.read(createRouteDraftProvider).seats, 4);

      final ProviderContainer second = container();
      expect(second.read(createRouteDraftProvider), kInitialCreateRouteDraft);
    });
  });
}
