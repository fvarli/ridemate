// ─────────────────────────────────────────────────────────────
// RideMate — Active trip domain
//
// The values are fixtures. These tests exist to keep them that way, and to
// keep the screen out of reach of anyone who has not asked for it.
// ─────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/widgets/rm_avatar.dart';
import 'package:ridemate/features/trip/application/active_trip_providers.dart';
import 'package:ridemate/features/trip/domain/active_trip_fixtures.dart';
import 'package:ridemate/features/trip/domain/active_trip_snapshot.dart';
import 'package:ridemate/features/trip/presentation/widgets/active_trip_map.dart';

/// The code in [path], with comments removed.
///
/// The banned names are all written down in headers explaining why they are
/// banned, so a raw scan would match the prohibition itself.
String codeOf(String path) => File(path)
    .readAsLinesSync()
    .map((String line) {
      final int slash = line.indexOf('//');
      return slash == -1 ? line : line.substring(0, slash);
    })
    .join('\n');

void main() {
  group('The trip reproduces the design', () {
    test('carries every figure the design shows', () {
      const ActiveTripSnapshot t = kMockActiveTrip;
      expect(t.driverName, 'Selin K.');
      expect(t.driverRating, 4.9);
      expect(t.vehicleName, 'VW Passat');
      expect(t.plate, '34 ABC 128');
      expect(t.etaMinutes, 18);
      expect(t.remainingKm, 6.2);
      expect(t.punctuality, TripPunctuality.onTime);
      expect(t.emergencyContactCount, 2);
    });

    test('the driver carries presence, not verification', () {
      // The comp draws a plain green dot with no check. Presence and
      // verification are separate claims and separate types; this snapshot has
      // no verification field at all, so one cannot be read as the other.
      expect(kMockActiveTrip.driverPresence, RmPresence.online);
      expect(
        codeOf('lib/features/trip/domain/active_trip_snapshot.dart'),
        isNot(contains('RmVerification')),
      );
    });

    test('the design draws exactly one punctuality state', () {
      expect(TripPunctuality.values, <TripPunctuality>[TripPunctuality.onTime]);
    });
  });

  group('Nothing is live', () {
    test('the provider returns a constant, not a lifecycle', () {
      final ProviderContainer c = ProviderContainer();
      addTearDown(c.dispose);

      expect(c.read(activeTripSnapshotProvider), same(kMockActiveTrip));
      // Reading twice cannot advance anything.
      expect(c.read(activeTripSnapshotProvider), same(kMockActiveTrip));
    });

    test('progress and position are declared, not derived from each other', () {
      // The comp's muted overdraw ends at (150, 360); measured against the
      // point list below that lands at 0.396. The car sits at (161, 373),
      // which is deliberately NOT on the polyline — snapping it would be
      // deriving one fixture from the other.
      expect(kTravelledFraction, 0.4);
      expect(kVehicleAt, const Offset(161, 373));
      expect(kActiveTripMapScene.travelledFraction, kTravelledFraction);
      expect(kActiveTripMapScene.route, contains(const Offset(150, 360)));
      expect(
        kActiveTripMapScene.route,
        isNot(contains(kVehicleAt)),
        reason: 'the marker is placed by the comp, not by the route',
      );
    });

    test('no timer, stream or animation drives the trip', () {
      const List<String> files = <String>[
        'lib/features/trip/domain/active_trip_snapshot.dart',
        'lib/features/trip/domain/active_trip_fixtures.dart',
        'lib/features/trip/application/active_trip_providers.dart',
        'lib/features/trip/presentation/widgets/active_trip_map.dart',
      ];
      for (final String f in files) {
        final String source = codeOf(f);
        for (final String banned in <String>[
          'Timer',
          'Stream',
          'Future.delayed',
          'AnimationController',
          'Notifier',
        ]) {
          expect(
            source.contains(banned),
            isFalse,
            reason: '$f must not use $banned',
          );
        }
      }
    });
  });

  group('The screen stays out of release', () {
    test('its route is registered inside the debug guard', () {
      final List<String> lines = File(
        'lib/app/router/app_router.dart',
      ).readAsLinesSync();
      final int route = lines.indexWhere(
        (String l) => l.contains('AppRoutes.activeTripPath'),
      );
      expect(route, isNot(-1), reason: 'the route should exist');

      // The nearest preceding guard must be kDebugMode.
      final int guard = lines
          .sublist(0, route)
          .lastIndexWhere((String l) => l.contains('if (kDebugMode)'));
      expect(guard, isNot(-1));
      expect(
        route - guard,
        lessThan(6),
        reason: 'the active trip route must sit under the kDebugMode guard',
      );
    });

    test('no product screen navigates to it', () {
      // Nothing links to Active Trip, because reaching it honestly needs a
      // trip lifecycle that does not exist. A deep link in a debug build is
      // the only way in.
      final List<String> offenders = <String>[];
      for (final FileSystemEntity e in Directory(
        'lib/features',
      ).listSync(recursive: true)) {
        if (e is! File || !e.path.endsWith('.dart')) continue;
        if (e.path.contains('/trip/')) continue;
        if (codeOf(e.path).contains('AppRoutes.activeTrip')) {
          offenders.add(e.path);
        }
      }
      expect(offenders, isEmpty);
    });

    test('its live-location claim never leaks to a release surface', () {
      // "Canlı konumun 2 acil kişiyle paylaşılıyor" is presentation copy: no
      // location is shared, no contact is reached, no background location
      // exists. It may only appear on the debug-only screen.
      final List<String> offenders = <String>[];
      for (final FileSystemEntity e in Directory(
        'lib',
      ).listSync(recursive: true)) {
        if (e is! File || !e.path.endsWith('.dart')) continue;
        if (e.path.contains('app_localizations')) continue;
        if (e.path.startsWith('lib/features/trip/')) continue;
        if (codeOf(e.path).contains('activeTripLocationSharing')) {
          offenders.add(e.path);
        }
      }
      expect(offenders, isEmpty);
    });
  });
}
