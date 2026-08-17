// ─────────────────────────────────────────────────────────────
// RideMate — Place picker
//
// The sheet is core now, so it carries its own coverage rather than only being
// exercised through Search.
//
// The boundary test at the bottom is the one that matters most: it is what
// stops `create_route` quietly re-acquiring a dependency on `discovery` after
// the shared vocabulary was moved out of it.
// ─────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/places/mock_places.dart';
import 'package:ridemate/core/places/place.dart';
import 'package:ridemate/core/widgets/rm_journey_marker.dart';
import 'package:ridemate/core/widgets/rm_list_row.dart';
import 'package:ridemate/core/widgets/rm_place_picker_sheet.dart';

import '../../support/pump.dart';

void main() {
  group('showPlacePicker', () {
    /// The place the last completed pick resolved to.
    late Place? chosen;

    /// Pumps a screen whose only job is to open the sheet.
    Future<void> open(
      WidgetTester tester, {
      Place selected = MockPlaces.kadikoy,
      Brightness brightness = Brightness.light,
      TextDirection textDirection = TextDirection.ltr,
    }) async {
      chosen = null;

      await tester.pumpRmScreen(
        Scaffold(
          body: Builder(
            builder: (BuildContext context) => Center(
              child: TextButton(
                onPressed: () async {
                  chosen = await showPlacePicker(
                    context,
                    title: 'Nereden yola çıkıyorsun?',
                    places: MockPlaces.all,
                    selected: selected,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
        brightness: brightness,
        textDirection: textDirection,
        surfaceSize: const Size(393, 852),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    /// The sheet row showing [place].
    RmListRow rowFor(WidgetTester tester, Place place) =>
        tester.widget<RmListRow>(
          find.ancestor(
            of: find.text(place.label),
            matching: find.byType(RmListRow),
          ),
        );

    testBothThemes('lists every fixture place under a titled header', (
      WidgetTester tester,
      Brightness brightness,
    ) async {
      await open(tester, brightness: brightness);

      expect(tester.takeException(), isNull);
      expect(find.text('Nereden yola çıkıyorsun?'), findsOneWidget);
      for (final Place place in MockPlaces.all) {
        expect(find.text(place.label), findsOneWidget, reason: place.label);
      }
      // A deterministic list, not a search result: no text entry anywhere.
      expect(find.byType(EditableText), findsNothing);
    });

    testWidgets('resolves to the tapped place', (WidgetTester tester) async {
      await open(tester);

      await tester.tap(find.text('Maslak, 42 Maslak'));
      await tester.pumpAndSettle();

      expect(chosen, MockPlaces.maslak);
      expect(find.text('Nereden yola çıkıyorsun?'), findsNothing);
    });

    testWidgets('resolves to null when dismissed', (WidgetTester tester) async {
      await open(tester);

      // Tap the barrier above the sheet.
      await tester.tapAt(const Offset(196, 40));
      await tester.pumpAndSettle();

      expect(chosen, isNull);
      expect(find.text('Nereden yola çıkıyorsun?'), findsNothing);
    });

    testWidgets('marks only the current selection', (
      WidgetTester tester,
    ) async {
      await open(tester, selected: MockPlaces.levent);

      expect(rowFor(tester, MockPlaces.levent).tone, RmRowTone.primary);
      expect(rowFor(tester, MockPlaces.kadikoy).tone, RmRowTone.neutral);
      // Exactly one row carries the marker.
      expect(find.byType(RmJourneyMarker), findsOneWidget);
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text(MockPlaces.levent.label),
            matching: find.byType(RmListRow),
          ),
          matching: find.byType(RmJourneyMarker),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders in RTL and at the narrow width without overflow', (
      WidgetTester tester,
    ) async {
      await open(tester, textDirection: TextDirection.rtl);
      expect(tester.takeException(), isNull);
    });
  });

  group('Feature boundaries', () {
    test('create_route never imports discovery', () {
      // The shared place vocabulary moved to core precisely so the driver side
      // does not depend on the passenger side. This asserts it stays that way.
      final Directory dir = Directory('lib/features/create_route');
      if (!dir.existsSync()) return;

      final List<String> offenders = <String>[];
      for (final FileSystemEntity entity in dir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.readAsStringSync().contains('features/discovery')) {
          offenders.add(entity.path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'create_route must reach shared code through core/, not through '
            'the discovery feature',
      );
    });
  });
}
