// ─────────────────────────────────────────────────────────────
// RideMate — Create route screen
//
// Both themes, both locales, RTL, 360dp and 393dp, and the maximum text scale
// the app allows.
//
// The behavioural assertions guard the phase's honesty rules: the cost share
// never moves, publishing publishes nothing, and the seat count has a floor
// but no invented ceiling.
//
// Real fonts are loaded — without them every glyph is a square em box far
// wider than Manrope, so a width assertion would measure the placeholder font
// rather than the product.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/a11y/rm_a11y.dart';
import 'package:ridemate/core/a11y/rm_tap_target.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/places/mock_places.dart';
import 'package:ridemate/core/places/place.dart';
import 'package:ridemate/core/theme/tokens/rm_sizing.dart';
import 'package:ridemate/core/widgets/rm_button.dart';
import 'package:ridemate/core/widgets/rm_chip.dart';
import 'package:ridemate/features/create_route/application/create_route_providers.dart';
import 'package:ridemate/features/create_route/application/place_catalogue_providers.dart';
import 'package:ridemate/features/create_route/application/publication_providers.dart';
import 'package:ridemate/features/create_route/domain/create_route_draft.dart';
import 'package:ridemate/features/create_route/domain/create_route_fixtures.dart';
import 'package:ridemate/features/create_route/domain/departure.dart';
import 'package:ridemate/features/create_route/presentation/create_route_screen.dart';
import 'package:ridemate/features/create_route/presentation/widgets/recurrence_card.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/pump.dart';

/// The narrow phone width where Phase 2's overflows appeared.
const Size kNarrowPhone = Size(360, 800);

/// The reference device the design targets.
const Size kStandardPhone = Size(393, 852);

void main() {
  setUpAll(loadRideMateFonts);

  late FakePlaceRepository places;
  late FakeRouteRepository routes;
  late FakeUuidGenerator ids;

  setUp(() {
    places = FakePlaceRepository();
    routes = FakeRouteRepository();
    ids = FakeUuidGenerator();
  });

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    TextDirection textDirection = TextDirection.ltr,
    Locale locale = kDefaultTestLocale,
    Size size = kStandardPhone,
    double textScale = 1,
    FakePlaceRepository? repository,
  }) async {
    await tester.pumpRmScreen(
      const CreateRouteScreen(),
      brightness: brightness,
      textDirection: textDirection,
      locale: locale,
      surfaceSize: size,
      textScaler: TextScaler.linear(textScale),
      overrides: <Override>[
        placeRepositoryProvider.overrideWithValue(repository ?? places),
        routeRepositoryProvider.overrideWithValue(routes),
        uuidGeneratorProvider.overrideWithValue(ids),
      ],
    );
    // Twice: the catalogue is fetched asynchronously, so the first frame is
    // the loading state and the second is the answer.
    await tester.pump();
    await tester.pump();
  }

  /// The live draft, read from the pumped screen's own scope.
  CreateRouteDraft draftOf(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(CreateRouteScreen)),
  ).read(createRouteDraftProvider);

  CreateRouteDraftController controllerOf(WidgetTester tester) =>
      ProviderScope.containerOf(
        tester.element(find.byType(CreateRouteScreen)),
      ).read(createRouteDraftProvider.notifier);

  /// Chooses both endpoints from the loaded catalogue, the way a driver would.
  Future<void> chooseEndpoints(WidgetTester tester) async {
    await tester.tap(find.text('Kalkış noktası seç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(kFakePlaces[0].label).last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Varış noktası seç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(kFakePlaces[1].label).last);
    await tester.pumpAndSettle();
  }

  /// Fills in the departure the way a driver would, without a picker.
  ///
  /// The pickers are platform surfaces; what these tests care about is the
  /// screen's reaction to a draft that is or is not finished.
  Future<void> chooseDeparture(
    WidgetTester tester, {
    DepartureDate? date,
    DepartureTime time = const DepartureTime(hour: 8, minute: 25),
  }) async {
    final CreateRouteDraftController controller = controllerOf(tester);
    if (date != null) controller.setDepartureDate(date);
    controller.setDepartureTime(time);
    await tester.pump();
  }

  group('CreateRouteScreen', () {
    testBothThemes('renders the approved copy', (
      WidgetTester tester,
      Brightness brightness,
    ) async {
      await pump(tester, brightness: brightness);

      expect(tester.takeException(), isNull);
      expect(find.text('Rota oluştur'), findsOneWidget);
      expect(find.text('Sürücü olarak koltuk paylaş'), findsOneWidget);
      expect(find.text('Kalkış noktası seç'), findsOneWidget);
      expect(find.text('Varış noktası seç'), findsOneWidget);
      expect(find.text('Her hafta içi tekrarla'), findsOneWidget);
      expect(find.text('Pzt–Cum'), findsOneWidget);
      expect(find.text('BOŞ KOLTUK'), findsOneWidget);
      // The departure the driver has to state, and its empty prompts.
      expect(find.text('GİDİŞ SAATİ'), findsOneWidget);
      expect(find.text('Saat seç'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('YOLCULUK KURALLARI'), findsOneWidget);
      expect(find.text('Rotayı yayınla'), findsOneWidget);
    });

    testBothThemes('renders every designed ride rule', (
      WidgetTester tester,
      Brightness brightness,
    ) async {
      await pump(tester, brightness: brightness);

      for (final String label in <String>[
        'Sigara yok',
        'Müzik OK',
        'Evcil hayvan yok',
        'Sessiz',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.byType(RmChip), findsNWidgets(4));
      // The design selects exactly one, and gives it no leading check.
      final Iterable<RmChip> chips = tester.widgetList<RmChip>(
        find.byType(RmChip),
      );
      expect(chips.where((RmChip chip) => chip.selected).length, 1);
      expect(chips.every((RmChip chip) => chip.icon == null), isTrue);
    });

    testWidgets('has no date or time control, as designed', (
      WidgetTester tester,
    ) async {
      // The approved screen carries no departure picker. Its absence is a
      // recorded product gap, not something to quietly invent.
      await pump(tester);

      expect(find.text('NE ZAMAN'), findsNothing);
      expect(find.byIcon(Icons.calendar_today), findsNothing);
      expect(find.byType(EditableText), findsNothing);
    });
  });

  group('Endpoints come from the server, or from nowhere', () {
    testWidgets('both endpoints start unselected', (WidgetTester tester) async {
      await pump(tester);

      expect(draftOf(tester).origin, isNull);
      expect(draftOf(tester).destination, isNull);
      expect(find.text('Kalkış noktası seç'), findsOneWidget);
      expect(find.text('Varış noktası seç'), findsOneWidget);
      expect(draftOf(tester).isComplete, isFalse);
    });

    testWidgets('the picker offers the catalogue the server returned', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('Kalkış noktası seç'));
      await tester.pumpAndSettle();

      expect(find.text('Nereden yola çıkıyorsun?'), findsOneWidget);
      for (final Place place in kFakePlaces) {
        expect(find.text(place.label), findsWidgets, reason: place.label);
      }
    });

    testWidgets('selecting stores the exact place the server sent', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      await chooseEndpoints(tester);

      expect(draftOf(tester).origin, kFakePlaces[0]);
      expect(draftOf(tester).destination, kFakePlaces[1]);
      // The stored id is the server's, verbatim.
      expect(draftOf(tester).origin?.id, kFakePlaces[0].id);
    });

    testWidgets('each row says which end of the journey it is', (
      WidgetTester tester,
    ) async {
      // The comp drops the NEREDEN/NEREYE eyebrows, so the semantic label is
      // the only thing carrying the role.
      await pump(tester);

      expect(find.bySemanticsLabel('Kalkış noktası seç'), findsOneWidget);
      expect(find.bySemanticsLabel('Varış noktası seç'), findsOneWidget);

      await chooseEndpoints(tester);

      expect(
        find.bySemanticsLabel('Kalkış: ${kFakePlaces[0].label}'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Varış: ${kFakePlaces[1].label}'),
        findsOneWidget,
      );
    });

    /// CARRIES WEIGHT. A failure must leave the picker empty, not fixture-full.
    testWidgets('an unreachable backend offers no places at all', (
      WidgetTester tester,
    ) async {
      await pump(tester, repository: FakePlaceRepository.offline());

      expect(find.text('Yer listesi alınamadı.'), findsOneWidget);
      expect(find.text('Yeniden dene'), findsOneWidget);

      // Not one fixture leaked in.
      for (final Place place in MockPlaces.all) {
        expect(find.text(place.label), findsNothing, reason: place.label);
      }
      expect(find.text('Ataşehir, Palladium'), findsNothing);
      expect(find.text('Maslak, 42 Maslak'), findsNothing);

      // And the endpoints cannot be chosen, rather than being chosen wrongly.
      await tester.tap(find.text('Kalkış noktası seç'));
      await tester.pumpAndSettle();
      expect(find.text('Nereden yola çıkıyorsun?'), findsNothing);
      expect(draftOf(tester).origin, isNull);
    });

    testWidgets('retrying asks the server again', (WidgetTester tester) async {
      final FakePlaceRepository repository = FakePlaceRepository.offline();
      await pump(tester, repository: repository);
      expect(repository.callCount, 1);

      // The backend comes back.
      repository.failure = null;
      await tester.tap(find.text('Yeniden dene'));
      await tester.pumpAndSettle();

      // Exactly one more request. A retry that doubled the load on a server
      // that had just failed would be the worst possible moment to do it.
      expect(repository.callCount, 2);
      expect(find.text('Yer listesi alınamadı.'), findsNothing);

      await tester.tap(find.text('Kalkış noktası seç'));
      await tester.pumpAndSettle();
      expect(find.text(kFakePlaces[0].label), findsWidgets);
    });

    testWidgets('an empty catalogue says so and invents nothing', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        repository: FakePlaceRepository(places: const <Place>[]),
      );

      expect(find.text('Şu anda desteklenen bir yer yok.'), findsOneWidget);
      for (final Place place in MockPlaces.all) {
        expect(find.text(place.label), findsNothing, reason: place.label);
      }
    });

    testWidgets('two endpoints must be different places', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('Kalkış noktası seç'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(kFakePlaces[0].label).last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Varış noktası seç'));
      await tester.pumpAndSettle();
      // The same place is still offered — the driver has not finished
      // choosing, and silently withholding it would be correcting them.
      await tester.tap(find.text(kFakePlaces[0].label).last);
      await tester.pumpAndSettle();

      expect(draftOf(tester).hasDistinctEndpoints, isFalse);

      await tester.tap(find.text('Rotayı yayınla'));
      await tester.pump();
      expect(find.text('Kalkış ve varış aynı yer olamaz.'), findsOneWidget);
    });
  });

  group('Recurrence', () {
    testWidgets('the summary hides when off and returns unchanged when on', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      expect(find.text('Pzt–Cum'), findsOneWidget);

      await tester.tap(find.text('Her hafta içi tekrarla'));
      await tester.pumpAndSettle();

      expect(draftOf(tester).recurrence == Recurrence.weekdays, isFalse);
      expect(find.text('Pzt–Cum'), findsNothing);
      // No invented replacement copy — the line is simply absent.
      expect(find.text('Her hafta içi tekrarla'), findsOneWidget);

      await tester.tap(find.text('Her hafta içi tekrarla'));
      await tester.pumpAndSettle();

      expect(draftOf(tester).recurrence == Recurrence.weekdays, isTrue);
      expect(find.text('Pzt–Cum'), findsOneWidget);
    });

    testWidgets('announces as a switch, not a button', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      final SemanticsNode node = tester.getSemantics(
        find.bySemanticsLabel('Her hafta içi tekrarla'),
      );
      // Non-null means the node carries a toggled state at all; true means it
      // is currently on.
      expect(node.flagsCollection.isToggled.toBoolOrNull(), isTrue);
      expect(
        node.flagsCollection.isButton,
        isFalse,
        reason: 'a switch must not announce itself as a button',
      );

      await tester.tap(find.text('Her hafta içi tekrarla'));
      await tester.pumpAndSettle();
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Her hafta içi tekrarla'))
            .flagsCollection
            .isToggled
            .toBoolOrNull(),
        isFalse,
      );
    });

    testWidgets('the knob sits at the trailing edge in both directions', (
      WidgetTester tester,
    ) async {
      // A plain Alignment.centerRight would not mirror, and the switch would
      // read backwards in RTL.
      Future<double> knobCentre(TextDirection direction) async {
        await pump(tester, textDirection: direction);
        final Rect track = tester.getRect(find.byType(RecurrenceSwitch));
        final Rect knob = tester.getRect(
          find
              .descendant(
                of: find.byType(RecurrenceSwitch),
                matching: find.byType(Container),
              )
              .last,
        );
        return knob.center.dx - track.center.dx;
      }

      expect(await knobCentre(TextDirection.ltr), greaterThan(0));
      expect(await knobCentre(TextDirection.rtl), lessThan(0));
    });
  });

  group('Seats', () {
    testWidgets('increments and decrements', (WidgetTester tester) async {
      await pump(tester);
      expect(draftOf(tester).seats, 3);

      await tester.tap(find.text('+'));
      await tester.pump();
      expect(draftOf(tester).seats, 4);
      expect(find.text('4'), findsOneWidget);

      await tester.tap(find.text('−'));
      await tester.pump();
      expect(draftOf(tester).seats, 3);
    });

    testWidgets('stops at the floor with a disabled decrement', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('−'));
        await tester.pump();
      }

      expect(draftOf(tester).seats, kSeatsFloor);
      // The adjustable node drops its decrease action at the floor, so
      // assistive tech agrees with the muted control.
      final SemanticsNode node = tester.getSemantics(
        find.bySemanticsLabel('Boş koltuk'),
      );
      expect(node.getSemanticsData().value, '1 koltuk');
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.decrease),
        isFalse,
      );
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.increase),
        isTrue,
      );
    });

    testWidgets('has no ceiling', (WidgetTester tester) async {
      // Any maximum would invent a vehicle-capacity rule the design never
      // states.
      await pump(tester);

      for (int i = 0; i < 8; i++) {
        await tester.tap(find.text('+'));
        await tester.pump();
      }

      expect(draftOf(tester).seats, 11);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Boş koltuk'))
            .getSemanticsData()
            .hasAction(SemanticsAction.increase),
        isTrue,
      );
    });

    testWidgets('both controls meet the touch floor', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      for (final String glyph in <String>['−', '+']) {
        final Size tapArea = tester.getSize(
          find.ancestor(
            of: find.text(glyph),
            matching: find.byType(RmTapTarget),
          ),
        );
        expect(
          tapArea.height,
          greaterThanOrEqualTo(RmA11y.minTouchTarget),
          reason: '$glyph is too short to tap',
        );
        expect(
          tapArea.width,
          greaterThanOrEqualTo(RmA11y.minTouchTarget),
          reason: '$glyph is too narrow to tap',
        );

        // The visual box stays on-design: the hit area grows, the control
        // itself does not.
        final Size visual = tester.getSize(
          find
              .ancestor(of: find.text(glyph), matching: find.byType(Container))
              .first,
        );
        expect(visual.height, RmSizing.stepperButton, reason: glyph);
        expect(visual.width, RmSizing.stepperButton, reason: glyph);
      }
    });
  });

  group('The publication surface carries no cost at all', () {
    testWidgets('no amount is rendered, at any seat count', (
      WidgetTester tester,
    ) async {
      // The signature test for this commit, and it is an ABSENCE test. The
      // screen used to show a fixture ₺18 captioned "suggested", which was
      // honest while nothing was published. It is not honest on a form whose
      // other fields are about to become server-owned.
      await pump(tester);

      expect(find.textContaining('₺'), findsNothing);
      expect(find.textContaining('18'), findsNothing);
      expect(find.text('KİŞİ BAŞI'), findsNothing);
      expect(find.text('Önerilen · maliyet paylaşımı'), findsNothing);

      for (int i = 0; i < 4; i++) {
        await tester.tap(find.text('+'));
        await tester.pump();
      }
      expect(draftOf(tester).seats, 7);

      // Not merely unchanged — absent. And still no total: 7 x 18 = 126.
      expect(find.textContaining('₺'), findsNothing);
      expect(find.textContaining('126'), findsNothing);
    });

    testWidgets('no edit anywhere on the screen brings one back', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('Her hafta içi tekrarla'));
      await tester.pump();
      expect(find.textContaining('₺'), findsNothing);

      await tester.tap(find.text('Evcil hayvan yok'));
      await tester.pump();
      expect(find.textContaining('₺'), findsNothing);

      await chooseEndpoints(tester);
      expect(find.textContaining('₺'), findsNothing);
    });
  });

  group('Ride rules', () {
    testWidgets('toggling a rule changes only that chip', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      final Finder chip = find.ancestor(
        of: find.text('Evcil hayvan yok'),
        matching: find.byType(RmChip),
      );
      expect(tester.widget<RmChip>(chip).selected, isFalse);

      await tester.tap(find.text('Evcil hayvan yok'));
      await tester.pump();

      expect(tester.widget<RmChip>(chip).selected, isTrue);
      expect(draftOf(tester).isRuleSelected(kRuleNeedingPolicyReview), isTrue);
      // Nothing else on the screen reacted.
      expect(draftOf(tester).seats, 3);
    });
  });

  group('The departure the driver states', () {
    testWidgets('a weekday commute asks for a time and no date', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      expect(draftOf(tester).recurrence, Recurrence.weekdays);
      expect(find.text('GİDİŞ SAATİ'), findsOneWidget);
      expect(find.text('Saat seç'), findsOneWidget);

      // A commute has no single day, so no date is offered — and none can be
      // published.
      expect(find.text('GİDİŞ TARİHİ'), findsNothing);
      expect(find.text('Tarih seç'), findsNothing);
      expect(draftOf(tester).departureDate, isNull);
    });

    testWidgets('a one-off journey asks for both', (WidgetTester tester) async {
      await pump(tester);

      await tester.tap(find.text('Her hafta içi tekrarla'));
      await tester.pumpAndSettle();

      expect(draftOf(tester).recurrence, Recurrence.once);
      expect(find.text('GİDİŞ TARİHİ'), findsOneWidget);
      expect(find.text('Tarih seç'), findsOneWidget);
      expect(find.text('GİDİŞ SAATİ'), findsOneWidget);
    });

    testWidgets('no fixture departure is shown before one is chosen', (
      WidgetTester tester,
    ) async {
      // The screen used to display 08:00 because it could not ask. It asks now.
      await pump(tester);

      expect(find.textContaining('08:00'), findsNothing);
      expect(draftOf(tester).departureTime, isNull);
    });

    testWidgets('a chosen departure is what the tiles show', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      await tester.tap(find.text('Her hafta içi tekrarla'));
      await tester.pumpAndSettle();

      await chooseDeparture(
        tester,
        date: const DepartureDate(year: 2099, month: 4, day: 1),
        time: const DepartureTime(hour: 7, minute: 45),
      );

      expect(find.text('07:45'), findsOneWidget);
      expect(find.text('1 Nisan 2099'), findsOneWidget);
      expect(find.text('Saat seç'), findsNothing);
      expect(find.text('Tarih seç'), findsNothing);
    });

    testWidgets('the date disappears with the mode that needed it', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      await tester.tap(find.text('Her hafta içi tekrarla'));
      await tester.pumpAndSettle();
      await chooseDeparture(
        tester,
        date: const DepartureDate(year: 2099, month: 4, day: 1),
      );
      expect(find.text('1 Nisan 2099'), findsOneWidget);

      await tester.tap(find.text('Her hafta içi tekrarla'));
      await tester.pumpAndSettle();

      expect(find.text('1 Nisan 2099'), findsNothing);
      expect(draftOf(tester).departureDate, isNull);
      // The time is needed in both modes and stays.
      expect(find.text('08:25'), findsOneWidget);
    });

    testWidgets('both tiles announce themselves as buttons', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      await tester.tap(find.text('Her hafta içi tekrarla'));
      await tester.pumpAndSettle();

      for (final String label in <String>[
        'GİDİŞ TARİHİ: Tarih seç',
        'GİDİŞ SAATİ: Saat seç',
      ]) {
        final SemanticsNode node = tester.getSemantics(
          find.bySemanticsLabel(label),
        );
        expect(node.flagsCollection.isButton, isTrue, reason: label);
      }
    });
  });

  group('An unfinished form is told what is missing', () {
    testWidgets('publishing without a time names the time', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      await chooseEndpoints(tester);

      await tester.tap(find.text('Rotayı yayınla'));
      await tester.pump();

      expect(find.text('Gidiş saati seç.'), findsOneWidget);
      // And it does not claim anything about publishing.
      expect(find.textContaining('Rota henüz yayınlanmadı'), findsNothing);
    });

    testWidgets('publishing a dated journey without a date names the date', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      await chooseEndpoints(tester);
      await tester.tap(find.text('Her hafta içi tekrarla'));
      await tester.pumpAndSettle();
      await chooseDeparture(tester);

      await tester.tap(find.text('Rotayı yayınla'));
      await tester.pump();

      expect(find.text('Gidiş tarihi seç.'), findsOneWidget);
    });
  });

  group('Publishing says only what the server said', () {
    testWidgets('a finished journey goes to the server, once', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      await chooseEndpoints(tester);
      await chooseDeparture(tester);

      await tester.tap(find.text('Rotayı yayınla'));
      await tester.pump();
      await tester.pump();

      expect(routes.callCount, 1);
      // Exactly the two places the driver chose from the server catalogue.
      expect(routes.lastBody['origin_place_id'], kFakePlaces[0].id);
      expect(routes.lastBody['destination_place_id'], kFakePlaces[1].id);
      expect(routes.lastBody['id'], ids.minted.single);
      expect(find.text('Rotan yayınlandı.'), findsOneWidget);
    });

    /// CARRIES WEIGHT. Success is stated after the server confirms it, never
    /// while the request is still in the air.
    testWidgets('nothing claims success before the answer arrives', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      await chooseEndpoints(tester);
      await chooseDeparture(tester);
      routes.hold();

      await tester.tap(find.text('Rotayı yayınla'));
      // The request is in the air and nothing has come back.
      await tester.pump();

      expect(find.text('Rotan yayınlandı.'), findsNothing);
      for (final String forbidden in <String>[
        'Rota oluşturuldu',
        'yayınlandı',
        'başarıyla',
      ]) {
        expect(find.textContaining(forbidden), findsNothing, reason: forbidden);
      }

      routes.release();
      await tester.pump();
      await tester.pump();
      expect(find.text('Rotan yayınlandı.'), findsOneWidget);
    });

    testWidgets('a failure is stated as a failure and keeps the draft', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      await chooseEndpoints(tester);
      await chooseDeparture(tester);
      routes.failure = const RmFailure.transport();
      final CreateRouteDraft before = draftOf(tester);

      await tester.tap(find.text('Rotayı yayınla'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Rotan yayınlandı.'), findsNothing);
      expect(find.textContaining('bağlan'), findsOneWidget);
      // Nothing the driver wrote is lost to a dropped connection.
      expect(draftOf(tester), before);
      expect(find.text('Rotayı yayınla'), findsOneWidget);
    });

    /// CARRIES WEIGHT. Two taps are one intention arriving twice.
    testWidgets('tapping twice publishes one journey under one id', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      await chooseEndpoints(tester);
      await chooseDeparture(tester);
      // The first request is still in the air when the second tap lands,
      // which is exactly the case an impatient driver produces.
      routes.hold();

      await tester.tap(find.text('Rotayı yayınla'));
      await tester.tap(find.text('Rotayı yayınla'));
      await tester.pump();

      expect(routes.callCount, 1);
      expect(ids.minted, hasLength(1));

      routes.release();
      await tester.pump();
      await tester.pump();

      expect(routes.callCount, 1);
    });

    testWidgets('the button shows it is working, and stops', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      await chooseEndpoints(tester);
      await chooseDeparture(tester);

      // By type, not by label: a loading button replaces its label with a
      // spinner, so a finder that goes through the text stops finding it at
      // exactly the moment this test is about.
      final Finder cta = find.byType(RmButton);

      expect(cta, findsOneWidget);
      expect(tester.widget<RmButton>(cta).loading, isFalse);

      routes.hold();
      await tester.tap(find.text('Rotayı yayınla'));
      await tester.pump();

      expect(tester.widget<RmButton>(cta).loading, isTrue);

      routes.release();
      await tester.pump();
      await tester.pump();

      expect(tester.widget<RmButton>(cta).loading, isFalse);
    });

    /// A retry after an indeterminate failure carries the same id, so the
    /// server can recognise it rather than publishing the journey twice.
    testWidgets('retrying reuses the id the first attempt used', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      await chooseEndpoints(tester);
      await chooseDeparture(tester);
      routes.failure = const RmFailure.transport();

      await tester.tap(find.text('Rotayı yayınla'));
      await tester.pump();
      await tester.pump();

      routes.failure = null;
      await tester.tap(find.text('Rotayı yayınla'));
      await tester.pump();
      await tester.pump();

      expect(routes.callCount, 2);
      expect(routes.routeIds.toSet(), hasLength(1));
      expect(find.text('Rotan yayınlandı.'), findsOneWidget);
    });

    testWidgets('an unfinished journey reaches no server at all', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      await chooseEndpoints(tester);

      await tester.tap(find.text('Rotayı yayınla'));
      await tester.pump();
      await tester.pump();

      expect(routes.callCount, 0);
      expect(find.text('Rotan yayınlandı.'), findsNothing);
    });
  });

  group('Responsiveness', () {
    /// The one-off layout is two tiles in a row, and no golden captures it.
    ///
    /// The goldens photograph the screen's default state, which is a weekday
    /// commute with a single tile. The dated variant only exists after a tap,
    /// so the narrow and mirrored cases have to be asserted here or nowhere —
    /// and a two-tile row at 360dp with a long localized date is exactly the
    /// shape that has overflowed on this project before.
    testWidgets('the dated layout survives RTL, English and 360dp', (
      WidgetTester tester,
    ) async {
      // September is the longest month name a Turkish date carries here, so
      // this is the widest the tile ever gets.
      Future<void> fillDatedForm() async {
        // Driven through the controller rather than the switch: what is under
        // test here is the two-tile layout, and the toggle has its own tests.
        controllerOf(tester).setRecurrence(Recurrence.once);
        await tester.pumpAndSettle();
        await chooseDeparture(
          tester,
          date: const DepartureDate(year: 2099, month: 9, day: 28),
          time: const DepartureTime(hour: 23, minute: 45),
        );

        // A layout test that never reached the layout would pass for the
        // wrong reason, so prove the two-tile row is actually on screen.
        expect(draftOf(tester).recurrence, Recurrence.once);
        expect(find.text('23:45'), findsOneWidget);
      }

      await pump(tester, textDirection: TextDirection.rtl);
      await fillDatedForm();
      expect(tester.takeException(), isNull, reason: 'TR RTL, dated');

      await pump(tester, size: kNarrowPhone);
      await fillDatedForm();
      expect(tester.takeException(), isNull, reason: 'TR at 360dp, dated');

      await pump(tester, locale: const Locale('en'), size: kNarrowPhone);
      await fillDatedForm();
      expect(tester.takeException(), isNull, reason: 'EN at 360dp, dated');
    });

    testWidgets('renders in English, RTL and at the narrow width', (
      WidgetTester tester,
    ) async {
      await pump(tester, textDirection: TextDirection.rtl);
      expect(tester.takeException(), isNull, reason: 'TR RTL');

      await pump(tester, size: kNarrowPhone);
      expect(tester.takeException(), isNull, reason: 'TR at 360dp');

      await pump(tester, locale: const Locale('en'));
      expect(tester.takeException(), isNull, reason: 'EN');
      expect(find.text('Create route'), findsOneWidget);
      expect(find.text('Share a seat as a driver'), findsOneWidget);
      expect(find.text('Mon–Fri'), findsOneWidget);
      expect(find.text('Publish route'), findsOneWidget);

      await pump(tester, locale: const Locale('en'), size: kNarrowPhone);
      expect(tester.takeException(), isNull, reason: 'EN at 360dp');
    });

    testWidgets('survives the maximum text scale at the narrow width', (
      WidgetTester tester,
    ) async {
      await pump(tester, size: kNarrowPhone, textScale: RmA11y.maxTextScale);

      expect(tester.takeException(), isNull);
      expect(find.text('Rota oluştur'), findsOneWidget);
      expect(find.text('Rotayı yayınla'), findsOneWidget);
    });
  });
}
