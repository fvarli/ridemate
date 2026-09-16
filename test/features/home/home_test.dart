// ─────────────────────────────────────────────────────────────
// RideMate — Home holds up
//
// REWRITTEN IN PHASE 17 R2, BECAUSE ITS SUBJECT CHANGED
//
// This file used to assert the fixture Home: that the map drew the same pins in
// dark as in light, that the destination pin was present, that the shortcut
// chips kept their icons, and that the match card read as one node with "its
// key facts" — a rating, a compatibility figure and a fare share. Every one of
// those was a claim the product could not make, and R2 removed the screen that
// made them.
//
// What survived is what was never about the fixture: that Home renders without
// overflowing, in both directions, at the largest supported text scale, on a
// small phone, and that its controls are reachable and labelled. Those cases
// are kept and repointed at the real screen.
//
// WHAT THIS FILE IS NOT
//
// Not the truth suite. Whether Home shows the member's own name, the server's
// journeys in the server's order and the server's request statuses — and
// nothing invented — is real_home_test.dart. This one is about layout and
// reach.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/a11y/rm_a11y.dart';
import 'package:ridemate/core/journeys/journey.dart';
import 'package:ridemate/core/trips/trip_lifecycle.dart';
import 'package:ridemate/features/home/presentation/home_screen.dart';
import 'package:ridemate/features/journeys/application/journeys_providers.dart';
import 'package:ridemate/features/profile/application/my_profile_providers.dart';
import 'package:ridemate/l10n/app_localizations.dart';

import '../../support/fakes.dart';
import '../../support/pump.dart';

void main() {
  /// Home with something in every section, which is the state most likely to
  /// overflow: three journeys, a greeting and the full set of links.
  List<Override> populated() => <Override>[
    profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
    journeysRepositoryProvider.overrideWithValue(
      FakeJourneys(
        journeys: <Journey>[
          fakeJourney(
            serviceDate: '2026-09-16',
            originLabel: 'Kadıköy, Vapur İskelesi',
            destinationLabel: 'Levent, Metro İstasyonu',
          ),
          fakeJourney(
            serviceDate: '2026-09-17',
            trip: TripState.inProgress,
            startedAt: '2026-09-17T05:05:00Z',
          ),
        ],
      ),
    ),
  ];

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    TextDirection textDirection = TextDirection.ltr,
    Locale locale = kDefaultTestLocale,
    Size surfaceSize = const Size(393, 852),
  }) async {
    await tester.pumpRmScreen(
      const HomeScreen(),
      brightness: brightness,
      textDirection: textDirection,
      locale: locale,
      surfaceSize: surfaceSize,
      overrides: populated(),
    );
    await tester.pumpAndSettle();
  }

  group('Home lays out', () {
    testWidgets('in light and dark without overflow', (
      WidgetTester tester,
    ) async {
      for (final Brightness brightness in Brightness.values) {
        await pump(tester, brightness: brightness);
        expect(tester.takeException(), isNull, reason: brightness.name);
      }
    });

    testWidgets('under RTL without overflow', (WidgetTester tester) async {
      await pump(tester, textDirection: TextDirection.rtl);
      expect(tester.takeException(), isNull);
    });

    /// The two small sizes the project's accessibility baseline names.
    for (final Size size in const <Size>[Size(360, 640), Size(360, 800)]) {
      testWidgets('on a ${size.width.toInt()}×${size.height.toInt()} screen', (
        WidgetTester tester,
      ) async {
        await pump(tester, surfaceSize: size);
        expect(tester.takeException(), isNull);

        // The primary action is the one control that must never be pushed off
        // a small screen — Home exists to open Search.
        expect(
          find.text(
            AppLocalizations.of(
              tester.element(find.byType(HomeScreen)),
            ).homeFindRide,
          ),
          findsOneWidget,
        );
      });
    }

    testWidgets('at the maximum supported text scale', (
      WidgetTester tester,
    ) async {
      await tester.pumpRmScreen(
        // The scale has to be applied inside the app, where a MediaQuery to
        // copy already exists. Pumping without it asserted nothing.
        Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(RmA11y.maxTextScale),
            ),
            child: const HomeScreen(),
          ),
        ),
        surfaceSize: const Size(393, 852),
        overrides: populated(),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('Home is reachable', () {
    testWidgets('the primary action is a labelled button', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester);

      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(HomeScreen)),
      );

      expect(
        tester.getSemantics(find.text(l10n.homeFindRide)).label,
        l10n.homeFindRideSemanticLabel,
      );

      handle.dispose();
    });

    /// CARRIES WEIGHT. A journey row announces which journey it is.
    ///
    /// Its day is half its identity, so a screen reader must not have to infer
    /// the morning from the row's position in a list.
    testWidgets('a journey row reads as one node naming its day', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester);

      final Iterable<String> labels = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .map((Semantics s) => s.properties.label ?? '')
          .where((String l) => l.contains('Kadıköy'));

      expect(labels, isNotEmpty);
      expect(labels.first, contains('Eylül'));

      handle.dispose();
    });

    /// Nothing on Home claims a state through colour alone: the trip state and
    /// the request status are both rendered as words.
    testWidgets('lifecycle is carried by text', (WidgetTester tester) async {
      await pump(tester);

      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(HomeScreen)),
      );

      expect(find.text(l10n.tripStateNotStarted), findsOneWidget);
      expect(find.text(l10n.tripStateInProgress), findsOneWidget);
    });
  });
}
