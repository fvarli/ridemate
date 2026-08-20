// ─────────────────────────────────────────────────────────────
// RideMate — Safety domain
//
// This is the screen where a shortcut would do real harm, so most of what
// follows asserts the absence of things: no state machine, no stored block,
// no telephony, no permissions, and no way into it from a release build.
// ─────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/features/safety/domain/safety_fixtures.dart';
import 'package:ridemate/features/safety/domain/safety_snapshot.dart';

/// The code in [path], with comments removed.
///
/// Every banned name below is written down in a header explaining why it is
/// banned, so a raw scan would match the prohibition itself.
String codeOf(String path) => File(path)
    .readAsLinesSync()
    .map((String line) {
      final int slash = line.indexOf('//');
      return slash == -1 ? line : line.substring(0, slash);
    })
    .join('\n');

/// Every Dart file under the Safety feature.
Iterable<String> safetySources() => Directory('lib/features/safety')
    .listSync(recursive: true)
    .whereType<File>()
    .map((File f) => f.path)
    .where((String p) => p.endsWith('.dart'));

void main() {
  group('The fixture reproduces the design', () {
    test('carries the one figure the design shows', () {
      expect(kMockSafetySnapshot.trustedContactCount, 2);
      expect(kMockSafetySnapshot, const SafetySnapshot(trustedContactCount: 2));
    });
  });

  group('There is no SOS state machine', () {
    test('no state enum exists, because ten of its states are undesigned', () {
      // The design draws idle and nothing else. A one-member enum is the seed
      // of a machine; the specification lives in docs/architecture.md and is
      // not implemented against until it is approved.
      for (final String path in safetySources()) {
        final String source = codeOf(path);
        expect(source, isNot(contains('enum SosState')));
        for (final String banned in <String>[
          'sosTriggered',
          'emergencyActive',
          'isArmed',
          'countdown',
          'Countdown',
          'cancelAlert',
          'triggerSos',
          'EmergencyService',
          'DispatchService',
        ]) {
          expect(source.contains(banned), isFalse, reason: '$path: $banned');
        }
      }
    });

    test('nothing can remember a block or a report', () {
      // The most dangerous state this app could hold: a member believing they
      // are protected from someone when nothing happened.
      for (final String path in safetySources()) {
        final String source = codeOf(path);
        for (final String banned in <String>[
          'blockedUsers',
          'reportSubmitted',
          'isBlocked',
          'BlockService',
          'ReportService',
          'ModerationService',
        ]) {
          expect(source.contains(banned), isFalse, reason: '$path: $banned');
        }
      }
      // The snapshot holds exactly one field, and it is a display count.
      final String snapshot = codeOf(
        'lib/features/safety/domain/safety_snapshot.dart',
      );
      expect(
        RegExp(r'^  final ', multiLine: true).allMatches(snapshot).length,
        1,
      );
    });

    test('no telephony, permission or contacts integration is introduced', () {
      for (final String path in safetySources()) {
        final String source = codeOf(path);
        for (final String banned in <String>[
          'tel:',
          'url_launcher',
          'launchUrl',
          'MethodChannel',
          'Permission',
          'ContactsService',
          'QrService',
          'Geolocator',
          'location',
          'http',
        ]) {
          expect(source.contains(banned), isFalse, reason: '$path: $banned');
        }
      }
    });

    test('no repository, service or notifier is invented', () {
      for (final String path in safetySources()) {
        final String source = codeOf(path);
        for (final String banned in <String>[
          'SafetyRepository',
          'SafetyService',
          'Notifier',
        ]) {
          expect(source.contains(banned), isFalse, reason: '$path: $banned');
        }
      }
    });
  });

  group('The screen stays out of release', () {
    /// The routes registered behind `if (kDebugMode)`.
    ///
    /// Generalised over every guarded route rather than pinned to one, so a
    /// third one cannot be added in a way that weakens the check.
    Set<String> debugGuardedRoutes() {
      final List<String> lines = File(
        'lib/app/router/app_router.dart',
      ).readAsLinesSync();
      final Set<String> guarded = <String>{};
      for (int i = 0; i < lines.length; i++) {
        if (!lines[i].contains('if (kDebugMode)')) continue;
        for (int j = i + 1; j < i + 8 && j < lines.length; j++) {
          final RegExpMatch? match = RegExp(
            r'AppRoutes\.(\w+)Path',
          ).firstMatch(lines[j]);
          if (match != null) {
            guarded.add(match.group(1)!);
            break;
          }
        }
      }
      return guarded;
    }

    test('its route is registered inside the debug guard', () {
      expect(debugGuardedRoutes(), contains('safety'));
      // The other two withheld surfaces are still withheld.
      expect(
        debugGuardedRoutes(),
        containsAll(<String>['gallery', 'activeTrip']),
      );
    });

    test('no release-reachable screen navigates to it', () {
      // Only Active Trip may open it, and Active Trip is itself debug-only.
      final List<String> offenders = <String>[];
      for (final FileSystemEntity entity in Directory(
        'lib/features',
      ).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.contains('/safety/')) continue;
        if (entity.path.contains('/trip/')) continue;
        if (codeOf(entity.path).contains('AppRoutes.safety')) {
          offenders.add(entity.path);
        }
      }
      expect(offenders, isEmpty);
    });

    test('its claims appear on no release-reachable surface', () {
      // The SOS promise, the contact count and the 112 label are all untrue
      // or unbacked. They may exist only in the ARB and in the withheld
      // screen that renders them.
      const List<String> claims = <String>[
        'safetySosPromise',
        'safetyTrustedContactsSubtitle',
        'safetyCallEmergencyTitle',
      ];
      final List<String> offenders = <String>[];
      for (final FileSystemEntity entity in Directory(
        'lib/features',
      ).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.contains('/safety/')) continue;
        final String source = codeOf(entity.path);
        for (final String claim in claims) {
          if (source.contains(claim)) offenders.add('${entity.path}: $claim');
        }
      }
      expect(offenders, isEmpty);
    });
  });
}
