import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `package:http` stays inside lib/core/api.
///
/// The point of a transport boundary is that it is one. Once a feature imports
/// the HTTP package directly it also owns retry, decoding and error handling
/// for itself, and the client stops being the place those decisions live —
/// which is discovered years later, during the migration that was supposed to
/// be confined to one directory.
///
/// Three feature directories already ban the string `http` outright
/// (profile, reviews, safety). This is the general rule those were an early
/// instance of.
void main() {
  Iterable<File> dartFilesIn(String path) => Directory(path)
      .listSync(recursive: true)
      .whereType<File>()
      .where((File f) => f.path.endsWith('.dart'))
      .where((File f) => !f.path.contains('app_localizations'));

  /// Source with `//` comments removed.
  ///
  /// The files below discuss package:http by name in their own headers, and a
  /// scanner reading raw text reports the explanation rather than a defect.
  String code(File file) => file
      .readAsLinesSync()
      .map((String line) {
        final int comment = line.indexOf('//');

        return comment == -1 ? line : line.substring(0, comment);
      })
      .join('\n');

  group('The transport boundary', () {
    test('package:http is imported only inside lib/core/api', () {
      final List<String> offenders = <String>[];

      for (final File file in dartFilesIn('lib')) {
        if (file.path.startsWith('lib/core/api/')) {
          continue;
        }
        if (code(file).contains('package:http')) {
          offenders.add(file.path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'feature code must depend on RmApiClient, not on the transport',
      );
    });

    test('the client is the only file that imports it', () {
      final List<String> importers = <String>[
        for (final File file in dartFilesIn('lib/core/api'))
          if (code(file).contains('package:http')) file.path,
      ];

      expect(importers, <String>['lib/core/api/rm_api_client.dart']);
    });

    /// http.Response, http.Client and friends must not appear in the types a
    /// caller touches, or the boundary exists only by convention.
    test('no package:http type crosses the public surface', () {
      for (final String file in <String>[
        'lib/core/api/rm_failure.dart',
        'lib/core/api/rm_response.dart',
        'lib/core/api/rm_error_code.dart',
      ]) {
        expect(code(File(file)), isNot(contains('http.')), reason: file);
      }
    });
  });

  group('The client knows nothing about credentials', () {
    /// Commit 9 is the transport. Storage, refresh coordination and session
    /// state arrive in later commits and must not leak backwards into a layer
    /// whose job is to send bytes.
    test('it holds no token, storage or refresh logic', () {
      final String source = code(File('lib/core/api/rm_api_client.dart'));

      for (final String banned in <String>[
        'refresh',
        'accessToken',
        'refreshToken',
        'secure_storage',
        'SecureStorage',
        'credential',
        'Session',
      ]) {
        expect(source, isNot(contains(banned)), reason: banned);
      }
    });

    /// Authorization is attached by the caller, never assembled here.
    test('it never builds an Authorization header itself', () {
      expect(
        code(File('lib/core/api/rm_api_client.dart')),
        isNot(contains('Bearer')),
      );
    });

    /// Nothing in this layer writes to a log, so there is nothing to redact:
    /// bodies carry passcodes and tokens, and the cheapest way to keep them
    /// out of a log file is to have no logging at all.
    test('it logs nothing', () {
      final String source = code(File('lib/core/api/rm_api_client.dart'));

      for (final String banned in <String>[
        'print(',
        'debugPrint',
        'developer.log',
        'Logger',
      ]) {
        expect(source, isNot(contains(banned)), reason: banned);
      }
    });
  });

  group('Where places come from', () {
    /// CARRIES WEIGHT. Create Route may not fall back to fixtures.
    ///
    /// The whole point of F3 is that its endpoints are the server's. A single
    /// import of the mock catalogue would make a fallback one line away, and
    /// the failure it produces — a journey published against an id the server
    /// has never seen — surfaces far from wherever that line was written.
    test('create_route never reaches for the fixture catalogue', () {
      final List<String> offenders = <String>[];

      for (final File file in dartFilesIn('lib/features/create_route')) {
        if (code(file).contains('mock_places')) {
          offenders.add(file.path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'Create Route reads the server catalogue. A fixture here would be '
            'a list the backend does not recognise.',
      );
    });

    /// And Search still does, deliberately.
    ///
    /// Search stays wholly fixture-backed in Phase 10 — it has no real query
    /// to run — so its picker keeps the mock list. This asserts the split is
    /// intentional rather than something half-migrated.
    test('search still chooses from fixtures', () {
      final File screen = File(
        'lib/features/discovery/presentation/search_screen.dart',
      );

      expect(code(screen), contains('mock_places'));
    });

    test('the feature reaches the network only through core/api', () {
      for (final File file in dartFilesIn('lib/features/create_route')) {
        expect(code(file), isNot(contains('package:http')), reason: file.path);
      }
    });
  });

  group('Where a route id comes from', () {
    /// CARRIES WEIGHT. One generator, one seam, one place to override.
    ///
    /// The id IS the create-idempotency mechanism: a retry after a timeout
    /// must carry the id the first attempt carried, or the same journey is
    /// published twice. A second `Uuid()` anywhere would be a second source of
    /// ids that no test could hold still, and the duplicate it eventually
    /// produced would look like a server defect.
    test('package:uuid is used only inside lib/core/id', () {
      final List<String> offenders = <String>[];

      for (final File file in dartFilesIn('lib')) {
        if (file.path.startsWith('lib/core/id/')) continue;
        if (code(file).contains('package:uuid')) offenders.add(file.path);
      }

      expect(
        offenders,
        isEmpty,
        reason: 'mint ids through RmUuidGenerator, not through the package',
      );
    });

    test('the wrapper is the only file that imports it', () {
      final List<String> importers = <String>[
        for (final File file in dartFilesIn('lib/core/id'))
          if (code(file).contains('package:uuid')) file.path,
      ];

      expect(importers, <String>['lib/core/id/rm_uuid.dart']);
    });

    /// CARRIES WEIGHT. Whether a departure has passed is read, never computed.
    ///
    /// The rule lives in the pilot's timezone, which is the server's
    /// configuration. A client that answered the question locally would
    /// eventually disagree with the service about whether a route may still be
    /// cancelled — and it would disagree silently.
    /// RENDERING a decoded state is fine and necessary; My Routes has to know
    /// which pill to draw. What must never happen is a file naming a
    /// DepartureState case AND reaching for a clock, because that is the shape
    /// of deriving one. The two together are the defect, not either alone.
    test('nothing decides departure state from a clock', () {
      const List<String> clock = <String>[
        'DateTime.now',
        'toUtc',
        'toLocal',
        'isBefore',
        'isAfter',
        'difference(',
      ];

      final List<String> offenders = <String>[
        for (final File file in dartFilesIn('lib'))
          if ((code(file).contains('DepartureState.upcoming') ||
                  code(file).contains('DepartureState.past')) &&
              clock.any(code(file).contains))
            file.path,
      ];

      expect(offenders, isEmpty, reason: 'the server decides this');
    });

    /// And the enum is only ever built by name, from a response.
    test('a departure state is only ever constructed by the decoder', () {
      final List<String> builders = <String>[
        for (final File file in dartFilesIn('lib'))
          if (code(file).contains('DepartureState.values')) file.path,
      ];

      expect(builders, <String>['lib/core/routes/route_decoder.dart']);
    });
  });

  group('My Routes depends inward, never sideways', () {
    /// CARRIES WEIGHT. Two features, one shared model, no arrow between them.
    ///
    /// My Routes and Create Route are equal consumers of the same server
    /// projection. If one imported the other, the shared type would belong to
    /// whichever got written first, and every later change to it would be made
    /// on behalf of a feature that is not asking.
    test('my_routes never imports create_route', () {
      final List<String> offenders = <String>[
        for (final File file in dartFilesIn('lib/features/my_routes'))
          if (code(file).contains('features/create_route')) file.path,
      ];

      expect(
        offenders,
        isEmpty,
        reason: 'the shared route model lives in lib/core/routes',
      );
    });

    /// RouteTimeline lives in Discovery and looks like what a route card
    /// needs. Resembling something is not a reason to depend on it.
    test('my_routes never imports discovery', () {
      final List<String> offenders = <String>[
        for (final File file in dartFilesIn('lib/features/my_routes'))
          if (code(file).contains('features/discovery')) file.path,
      ];

      expect(offenders, isEmpty, reason: 'compose core primitives instead');
    });

    test('and create_route does not import my_routes either', () {
      final List<String> offenders = <String>[
        for (final File file in dartFilesIn('lib/features/create_route'))
          if (code(file).contains('features/my_routes')) file.path,
      ];

      expect(offenders, isEmpty);
    });

    test('the feature reaches the network only through core/api', () {
      for (final File file in dartFilesIn('lib/features/my_routes')) {
        expect(code(file), isNot(contains('package:http')), reason: file.path);
      }
    });

    /// CARRIES WEIGHT. No fixture may reach this screen.
    ///
    /// A route nobody published, on the screen that exists to show what you
    /// published, would be the exact lie Phase 10 was built to remove — and it
    /// would appear precisely when the network failed, which is when nobody is
    /// looking closely.
    test('my_routes reaches for no fixture at all', () {
      for (final File file in dartFilesIn('lib/features/my_routes')) {
        for (final String fixture in <String>[
          'mock_places',
          'mock_discovery_fixtures',
          'review_fixtures',
          'create_route_fixtures',
          'MockPlaces',
          'MockRouteOffers',
        ]) {
          expect(code(file), isNot(contains(fixture)), reason: file.path);
        }
      }
    });

    /// CARRIES WEIGHT. Whether a journey has departed is the server's answer.
    ///
    /// The rule lives in the route's own timezone, which is the server's
    /// configuration. A client that worked it out locally would eventually
    /// offer Cancel on a journey the API refuses to cancel — or hide it on one
    /// the API would have accepted — and would do it silently.
    test('my_routes never works out past or upcoming for itself', () {
      for (final File file in dartFilesIn('lib/features/my_routes')) {
        // Reading `route.departureState` is the point; computing one is the
        // defect. So what is banned here is the clock, not the enum.
        for (final String forbidden in <String>[
          'DateTime.now',
          'toUtc',
          'toLocal',
          'isBefore',
          'isAfter',
          'difference(',
        ]) {
          expect(code(file), isNot(contains(forbidden)), reason: file.path);
        }
      }
    });
  });

  group('No dependency crept in with it', () {
    test('the transport is package:http and not an alternative', () {
      final String pubspec = File('pubspec.yaml').readAsStringSync();

      expect(pubspec, contains('http: ^1.6.0'));
      expect(pubspec, contains('uuid: ^4.6.0'));
      for (final String rejected in <String>['dio', 'chopper', 'retrofit']) {
        expect(pubspec, isNot(contains(rejected)), reason: rejected);
      }
    });

    /// flutter_secure_storage arrived deliberately, in the commit that needed
    /// it, and this assertion failing was how that arrival got noticed. What
    /// must stay absent is a general-purpose local database: those invite
    /// "just put the token in there for now", and none of them encrypt by
    /// default. The credential boundary test enforces where the secure store
    /// itself may be used.
    test('no general-purpose local database has appeared', () {
      final String pubspec = File('pubspec.yaml').readAsStringSync();

      for (final String absent in <String>[
        'hive',
        'sqflite',
        'isar',
        'objectbox',
        'get_storage',
      ]) {
        expect(pubspec, isNot(contains(absent)), reason: absent);
      }
    });
  });
}
