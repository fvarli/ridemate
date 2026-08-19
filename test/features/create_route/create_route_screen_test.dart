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
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/a11y/rm_a11y.dart';
import 'package:ridemate/core/a11y/rm_tap_target.dart';
import 'package:ridemate/core/places/mock_places.dart';
import 'package:ridemate/core/theme/tokens/rm_sizing.dart';
import 'package:ridemate/core/widgets/rm_chip.dart';
import 'package:ridemate/features/create_route/application/create_route_providers.dart';
import 'package:ridemate/features/create_route/domain/create_route_draft.dart';
import 'package:ridemate/features/create_route/domain/create_route_fixtures.dart';
import 'package:ridemate/features/create_route/presentation/create_route_screen.dart';
import 'package:ridemate/features/create_route/presentation/widgets/recurrence_card.dart';

import '../../support/fonts.dart';
import '../../support/pump.dart';

/// The narrow phone width where Phase 2's overflows appeared.
const Size kNarrowPhone = Size(360, 800);

/// The reference device the design targets.
const Size kStandardPhone = Size(393, 852);

void main() {
  setUpAll(loadRideMateFonts);

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    TextDirection textDirection = TextDirection.ltr,
    Locale locale = kDefaultTestLocale,
    Size size = kStandardPhone,
    double textScale = 1,
  }) async {
    await tester.pumpRmScreen(
      const CreateRouteScreen(),
      brightness: brightness,
      textDirection: textDirection,
      locale: locale,
      surfaceSize: size,
      textScaler: TextScaler.linear(textScale),
    );
    await tester.pump();
  }

  /// The live draft, read from the pumped screen's own scope.
  CreateRouteDraft draftOf(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(CreateRouteScreen)),
  ).read(createRouteDraftProvider);

  group('CreateRouteScreen', () {
    testBothThemes('renders the approved copy', (
      WidgetTester tester,
      Brightness brightness,
    ) async {
      await pump(tester, brightness: brightness);

      expect(tester.takeException(), isNull);
      expect(find.text('Rota oluştur'), findsOneWidget);
      expect(find.text('Sürücü olarak koltuk paylaş'), findsOneWidget);
      expect(find.text('Ataşehir, Palladium'), findsOneWidget);
      expect(find.text('Maslak, 42 Maslak'), findsOneWidget);
      expect(find.text('Her hafta içi tekrarla'), findsOneWidget);
      expect(find.text('Pzt–Cum · 08:00 kalkış'), findsOneWidget);
      expect(find.text('BOŞ KOLTUK'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('KİŞİ BAŞI'), findsOneWidget);
      expect(find.text('₺18'), findsOneWidget);
      expect(find.text('Önerilen · maliyet paylaşımı'), findsOneWidget);
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

  group('Endpoints', () {
    testWidgets('tapping an endpoint opens the picker', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('Ataşehir, Palladium'));
      await tester.pumpAndSettle();

      expect(find.text('Nereden yola çıkıyorsun?'), findsOneWidget);
      expect(find.text('Kadıköy, İskele Meydanı'), findsOneWidget);
    });

    testWidgets('selecting a place updates the draft', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('Maslak, 42 Maslak'));
      await tester.pumpAndSettle();
      expect(find.text('Nereye gidiyorsun?'), findsOneWidget);

      await tester.tap(find.text('Üniversite').last);
      await tester.pumpAndSettle();

      expect(draftOf(tester).destination, MockPlaces.university);
      expect(find.text('Üniversite'), findsOneWidget);
    });

    testWidgets('each row says which end of the journey it is', (
      WidgetTester tester,
    ) async {
      // The comp drops the NEREDEN/NEREYE eyebrows, so the semantic label is
      // the only thing carrying the role.
      await pump(tester);

      expect(
        find.bySemanticsLabel('Kalkış: Ataşehir, Palladium'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Varış: Maslak, 42 Maslak'), findsOneWidget);
    });
  });

  group('Recurrence', () {
    testWidgets('the summary hides when off and returns unchanged when on', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      expect(find.text('Pzt–Cum · 08:00 kalkış'), findsOneWidget);

      await tester.tap(find.text('Her hafta içi tekrarla'));
      await tester.pumpAndSettle();

      expect(draftOf(tester).repeatsOnWeekdays, isFalse);
      expect(find.text('Pzt–Cum · 08:00 kalkış'), findsNothing);
      // No invented replacement copy — the line is simply absent.
      expect(find.text('Her hafta içi tekrarla'), findsOneWidget);

      await tester.tap(find.text('Her hafta içi tekrarla'));
      await tester.pumpAndSettle();

      expect(draftOf(tester).repeatsOnWeekdays, isTrue);
      expect(find.text('Pzt–Cum · 08:00 kalkış'), findsOneWidget);
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

  group('The cost share never moves', () {
    testWidgets('changing seats leaves it at ₺18', (WidgetTester tester) async {
      // The signature test for this phase. Deriving the amount from the seat
      // count would author a pricing rule, and a total would be an earnings
      // claim. Neither exists.
      await pump(tester);
      expect(find.text('₺18'), findsOneWidget);

      await tester.tap(find.text('+'));
      await tester.pump();
      expect(draftOf(tester).seats, 4);
      expect(find.text('₺18'), findsOneWidget);

      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('+'));
        await tester.pump();
      }
      expect(draftOf(tester).seats, 7);
      expect(find.text('₺18'), findsOneWidget);
      // No total anywhere: 7 x 18 = 126.
      expect(find.textContaining('126'), findsNothing);
      expect(find.textContaining('₺126'), findsNothing);
    });

    testWidgets('no other edit moves it either', (WidgetTester tester) async {
      await pump(tester);

      await tester.tap(find.text('Her hafta içi tekrarla'));
      await tester.pump();
      expect(find.text('₺18'), findsOneWidget);

      await tester.tap(find.text('Evcil hayvan yok'));
      await tester.pump();
      expect(find.text('₺18'), findsOneWidget);

      await tester.tap(find.text('Ataşehir, Palladium'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kadıköy, İskele Meydanı').last);
      await tester.pumpAndSettle();
      expect(find.text('₺18'), findsOneWidget);
    });

    testWidgets('reads as data, not as an unfinished control', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      final SemanticsNode node = tester.getSemantics(
        find.bySemanticsLabel('Kişi başı önerilen maliyet paylaşımı: ₺18'),
      );
      expect(node.flagsCollection.isReadOnly, isTrue);
      expect(node.flagsCollection.isButton, isFalse);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
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
      expect(find.text('₺18'), findsOneWidget);
    });
  });

  group('Publishing is honest', () {
    testWidgets('shows a message that says nothing was published', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      final CreateRouteDraft before = draftOf(tester);

      await tester.tap(find.text('Rotayı yayınla'));
      await tester.pump();

      expect(
        find.text(
          'Rota henüz yayınlanmadı. Yayınlama özelliği yakında eklenecek.',
        ),
        findsOneWidget,
      );
      // The draft is untouched — not mutated, not cleared.
      expect(draftOf(tester), before);
      // No navigation, no success state, no disabled flip.
      expect(find.byType(CreateRouteScreen), findsOneWidget);
      expect(find.text('Rotayı yayınla'), findsOneWidget);
      for (final String forbidden in <String>[
        'Rota oluşturuldu',
        'Yayınlandı',
        'başarıyla',
      ]) {
        expect(find.textContaining(forbidden), findsNothing, reason: forbidden);
      }
    });
  });

  group('Responsiveness', () {
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
      expect(find.text('Mon–Fri · departs 08:00'), findsOneWidget);
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
