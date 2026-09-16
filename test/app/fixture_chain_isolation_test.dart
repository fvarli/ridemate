// ─────────────────────────────────────────────────────────────
// RideMate — The fixture chain does not exist in a release build
//
// WHAT THIS DEFENDS
//
// Route Details and Chat are design references whose every figure is invented:
// a trust score, an approval rate, a rating, a vehicle, a number plate and a
// conversation, none of which any endpoint knows. Until Phase 17 R1 both were
// in the release route table, reachable from Home.
//
// UNLINKING IS NOT ISOLATING, AND THAT IS THE POINT OF THIS FILE
//
// `/routes/:routeId` is a path. Deleting Home's callback would leave a deep
// link that still opened the fabricated dossier — the same screen, reached a
// different way, with nothing in the app to say it had been withdrawn. So the
// assertion here is about the ROUTE TABLE, not about who calls it.
//
// The Messages tab is deliberately NOT in scope. Saying a capability is
// missing is truthful; showing a fake one is not, and only the second is what
// R1 removes.
// ─────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/app/router/app_routes.dart';

void main() {
  List<String> routerLines() =>
      File('lib/app/router/app_router.dart').readAsLinesSync();

  String code(String path) => File(path)
      .readAsLinesSync()
      .where((String line) => !line.trimLeft().startsWith('//'))
      .join('\n');

  /// Every route registered behind `if (kDebugMode)`.
  ///
  /// Generalised over the guard rather than pinned to one route, in the idiom
  /// safety_domain_test established: a route added in a way that slips out
  /// from under the guard simply stops appearing here.
  Set<String> debugGuardedRoutes() {
    final List<String> lines = routerLines();
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

  group('Neither fixture screen is in the release route table', () {
    /// CARRIES WEIGHT. The route, not the caller.
    ///
    /// A release build has no `/routes/:routeId` to resolve, so a deep link,
    /// a pasted URL and a restored navigation stack all fail to reach it —
    /// which removing Home's `pushNamed` alone would not have achieved.
    test('route details is registered only under kDebugMode', () {
      expect(debugGuardedRoutes(), contains('routeDetails'));
    });

    test('chat is registered only under kDebugMode', () {
      expect(debugGuardedRoutes(), contains('chat'));
    });

    /// And they sit beside the screens already withheld for the same reason,
    /// rather than under a second mechanism invented for this slice.
    test('they join the routes already withheld, under one guard', () {
      expect(
        debugGuardedRoutes(),
        containsAll(<String>[
          'verification',
          'gallery',
          'activeTrip',
          'safety',
          'routeDetails',
          'chat',
        ]),
      );
    });

    /// CARRIES WEIGHT. Nothing was redirected in their place.
    ///
    /// A fabricated deep link must fail, not quietly land on a real screen: a
    /// member who followed a link to somebody's "profile" and arrived at their
    /// own Search would be told nothing about what happened.
    test('no redirect rewrites either path to a real screen', () {
      final String router = code('lib/app/router/app_router.dart');

      for (final String path in <String>[
        AppRoutes.routeDetailsPath,
        AppRoutes.chatPath,
      ]) {
        expect(
          RegExp("redirect.*${RegExp.escape(path)}").hasMatch(router),
          isFalse,
          reason: path,
        );
      }
    });
  });

  group('No release surface navigates into them', () {
    /// Where a design reference may still link to another design reference.
    ///
    /// Route Details and Active Trip are themselves debug-only, so a link
    /// between them reaches nothing a release build can open. Every OTHER
    /// production file is held to the rule.
    const Set<String> referenceSurfaces = <String>{
      'lib/features/discovery/presentation/route_details_screen.dart',
      'lib/features/trip/presentation/active_trip_screen.dart',
      'lib/features/safety/presentation/safety_screen.dart',
      'lib/app/router/app_router.dart',
      'lib/app/router/app_routes.dart',
    };

    Iterable<File> productionFiles() sync* {
      for (final FileSystemEntity entity in Directory(
        'lib',
      ).listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) yield entity;
      }
    }

    /// CARRIES WEIGHT. The guard understands the boundary rather than banning
    /// the symbols everywhere, so the design references keep compiling and a
    /// new edge from a real screen still fails.
    test('only debug-reference surfaces name these routes', () {
      final List<String> offenders = <String>[
        for (final File file in productionFiles())
          if (!referenceSurfaces.contains(file.path) &&
              (code(file.path).contains('AppRoutes.routeDetails') ||
                  code(file.path).contains('AppRoutes.chat')))
            file.path,
      ];

      expect(
        offenders,
        isEmpty,
        reason:
            'a release-reachable surface began navigating into a fixture screen',
      );
    });

    /// Home in particular, which was the one production edge into the chain.
    test('home no longer opens route details', () {
      final String home = code(
        'lib/features/home/presentation/home_screen.dart',
      );

      expect(home.contains('AppRoutes.routeDetails'), isFalse);
      expect(home.contains('AppRoutes.chat'), isFalse);
      // Home navigates plenty since R2 — to Search, to a dated Journey, to My
      // Routes and My Requests. What it must never name is a fixture screen,
      // so the rule is about WHICH routes rather than about navigating at all.
      expect(home.contains('AppRoutes.search'), isTrue);
    });

    /// The real passenger and driver surfaces never did, and still do not.
    test('the real surfaces carry no dependency on either screen', () {
      for (final String dir in <String>[
        'lib/features/seat_requests',
        'lib/features/my_routes',
        'lib/features/journeys',
        'lib/features/discovery/presentation/match_results_screen.dart',
        'lib/features/discovery/presentation/widgets',
      ]) {
        final FileSystemEntity entity = FileSystemEntity.isDirectorySync(dir)
            ? Directory(dir)
            : File(dir);

        final Iterable<File> files = entity is Directory
            ? entity
                  .listSync(recursive: true)
                  .whereType<File>()
                  .where((File f) => f.path.endsWith('.dart'))
            : <File>[entity as File];

        for (final File file in files) {
          final String source = code(file.path);
          expect(
            source.contains('AppRoutes.routeDetails') ||
                source.contains('AppRoutes.chat'),
            isFalse,
            reason: file.path,
          );
        }
      }
    });
  });

  group('Nothing was deleted, and nothing was invented', () {
    /// R1 closes a boundary. R3 decides what to clean up, once Real Home
    /// exists — so the screens, their fixtures, their copy and their baselines
    /// all stay exactly where they are.
    test('both screens and their fixtures still exist', () {
      for (final String path in <String>[
        'lib/features/discovery/presentation/route_details_screen.dart',
        'lib/features/discovery/domain/mock_discovery_fixtures.dart',
        'lib/features/chat/presentation/chat_screen.dart',
        'lib/features/chat/domain/chat_fixtures.dart',
      ]) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    });

    /// CARRIES WEIGHT. No chat capability appeared in place of the screen.
    ///
    /// The honest answer to "there is no chat" is the Messages placeholder,
    /// not a local-only conversation that would be the same fabrication with
    /// a different author.
    test('no chat repository, client or store was introduced', () {
      for (final File file in Directory(
        'lib/features/chat',
      ).listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;

        for (final String banned in <String>[
          'ChatRepository',
          'MessageRepository',
          'RmApiClient',
          'WebSocket',
          'SharedPreferences',
          'Notifier',
        ]) {
          expect(code(file.path).contains(banned), isFalse, reason: file.path);
        }
      }
    });
  });
}
