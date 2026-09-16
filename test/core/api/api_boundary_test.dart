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

    /// INVERTED IN PHASE 12, AND THE INVERSION IS THE POINT.
    ///
    /// This asserted that Search still chose from `mock_places`, deliberately:
    /// Phase 10 gave it no real query to run, so a fixture picker was the
    /// honest arrangement and the guard recorded that the split was intentional
    /// rather than half-migrated.
    ///
    /// Phase 12 gave it a real query. An endpoint chosen from the fixture would
    /// now be an id the discovery endpoint has never heard of, so the same
    /// concern — a picker whose places the backend does not recognise — points
    /// the other way. The guard follows it.
    test('search chooses from the server catalogue, never the fixture', () {
      final String screen = code(
        File('lib/features/discovery/presentation/search_screen.dart'),
      );

      expect(
        screen,
        isNot(contains('mock_places')),
        reason: 'a fixture place is an id discovery would refuse',
      );
      expect(screen, contains('place_catalogue_providers'));
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
    ///
    /// Two decoders now do it — a discovered journey and the one a seat
    /// request is about — and the list stays exact so a third is a decision.
    /// The second assertion is the part that carries the invariant: whatever
    /// is on this list must be a decoder in `core/`, so a feature cannot join
    /// it by being added to the list, and business logic cannot build a
    /// departure state by calling itself a decoder somewhere else.
    test('a departure state is only ever constructed by a core decoder', () {
      final List<String> builders = <String>[
        for (final File file in dartFilesIn('lib'))
          if (code(file).contains('DepartureState.values')) file.path,
      ];

      expect(builders..sort(), <String>[
        'lib/core/routes/route_decoder.dart',
        'lib/core/seat_requests/seat_request_decoder.dart',
      ]);

      for (final String path in builders) {
        expect(path, startsWith('lib/core/'));
        expect(path, endsWith('_decoder.dart'));
      }
    });
  });

  group('Initials belong to the server', () {
    /// CARRIES WEIGHT. The client renders initials; it never derives them.
    ///
    /// `RmTextConventions.initials` exists and is correct, which is exactly
    /// what makes this worth guarding: reaching for it here would create a
    /// second implementation of a deterministic rule, and Turkish casing is
    /// precisely where the two would drift. The server sends the letters and
    /// this feature prints them.
    /// Discovery renders another member's initials, which is the surface where
    /// deriving them would be least visible and most wrong.
    test('nothing under features/discovery computes initials', () {
      final List<String> offenders = <String>[
        for (final File file in dartFilesIn('lib/features/discovery'))
          if (code(file).contains('RmTextConventions.initials') ||
              code(file).contains('upperTr'))
            file.path,
      ];

      expect(
        offenders,
        isEmpty,
        reason: 'initials are read from the response, never recomputed',
      );
    });

    test('nothing under features/profile computes initials', () {
      final List<String> offenders = <String>[
        for (final File file in dartFilesIn('lib/features/profile'))
          if (code(file).contains('RmTextConventions.initials') ||
              code(file).contains('toUpperCase') ||
              code(file).contains('upperTr'))
            file.path,
      ];

      expect(
        offenders,
        isEmpty,
        reason: 'initials are read from the response, never recomputed',
      );
    });

    /// And the profile model holds them as a field rather than a getter, so
    /// there is no place for a derivation to hide.
    test(
      'the shared profile model stores initials rather than deriving them',
      () {
        final String source = code(File('lib/core/profile/profile.dart'));

        expect(source, contains('final String initials;'));
        expect(source, isNot(contains('RmTextConventions')));
      },
    );
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

  group('Which days a journey may be asked about is the server\'s answer', () {
    /// CARRIES WEIGHT. No IANA capability has been added to answer it here.
    ///
    /// This was the blocker F2 opened with: deciding which service dates a
    /// recurring plan offers means knowing what today is in the ROUTE's
    /// timezone, and this app has no way to evaluate one. The resolution was to
    /// publish the days from the backend, not to ship a timezone database — a
    /// second implementation of the rule, current only as often as the app
    /// ships, would disagree with the server twice a year and be believed.
    test('no timezone database has appeared', () {
      final String pubspec = File('pubspec.yaml').readAsStringSync();
      final String lock = File('pubspec.lock').readAsStringSync();

      for (final String absent in <String>[
        'timezone',
        'tzdata',
        'flutter_native_timezone',
        'flutter_timezone',
      ]) {
        expect(pubspec, isNot(contains(absent)), reason: absent);
        // The lock too: a transitive arrival is an arrival, and it would put
        // `tz.getLocation` one import away from any widget.
        expect(lock, isNot(contains('$absent:')), reason: '$absent (lock)');
      }
    });

    /// CARRIES WEIGHT. Discovery renders the days; it never works one out.
    ///
    /// The defect this prevents is a card that consults the device clock, or a
    /// fixed offset, to decide whether today is still open. It would be right
    /// in İstanbul — which has not observed daylight saving since 2016 — and
    /// wrong wherever the product went next, silently.
    test('discovery computes no date and consults no clock', () {
      for (final File file in dartFilesIn('lib/features/discovery')) {
        for (final String forbidden in <String>[
          'DateTime.now',
          'toUtc',
          'toLocal',
          'isBefore',
          'isAfter',
          'difference(',
          'add(const Duration',
          'addDays',
          'weekday ==',
          'DateTime.monday',
          'DateTime.saturday',
          'DateTime.sunday',
        ]) {
          expect(code(file), isNot(contains(forbidden)), reason: file.path);
        }
      }
    });

    /// The horizon is the backend's number and is not restated anywhere here.
    ///
    /// A `14` in this client would be a copy of a rule that lives in
    /// `SeatRequestHorizon`, and the copy would not move when the original did.
    test('the request horizon is not reimplemented', () {
      for (final File file in <File>[
        ...dartFilesIn('lib/features/discovery'),
        ...dartFilesIn('lib/features/seat_requests'),
        ...dartFilesIn('lib/core/routes'),
      ]) {
        for (final String forbidden in <String>[
          'Duration(days: 14)',
          'Duration(days: 15)',
          'Europe/Istanbul',
          'UTC+3',
          'Duration(hours: 3)',
        ]) {
          expect(code(file), isNot(contains(forbidden)), reason: file.path);
        }
      }
    });

    /// CARRIES WEIGHT. An asking is always for a named day.
    ///
    /// The whole of Phase 16b is that a journey is `(route, service_date)`. A
    /// request action keyed by the route alone would make two days of one plan
    /// share an attempt and the id it carries — which the backend answers with
    /// `id_already_used`, or worse, replays as the wrong journey.
    test('the request action is keyed by journey and not by route', () {
      final String controller = code(
        File(
          'lib/features/seat_requests/application/'
          'seat_request_action_providers.dart',
        ),
      );

      expect(
        controller,
        contains(
          'typedef JourneyKey = ({String routeId, DepartureDate serviceDate});',
        ),
      );

      // And every caller names a day rather than passing a bare route id.
      for (final File file in dartFilesIn('lib/features/discovery')) {
        expect(
          code(file),
          isNot(contains('.request(route.id)')),
          reason: file.path,
        );
      }
    });

    /// CARRIES WEIGHT. Nothing derives how many seats are left.
    ///
    /// `seats_offered` is what the driver offered, never what remains, and no
    /// endpoint publishes a remainder. A day greyed out because this client
    /// counted acceptances would be the app inventing `route_full`.
    ///
    /// Scoped to the surfaces built on the real projection. `domain/` still
    /// holds the pre-Phase-12 fixture model, which has a `seatsAvailable` of
    /// its own — invented, never served, and already fenced off by the guard
    /// above that keeps Search and the card away from those fixtures.
    test('discovery derives no remaining capacity', () {
      for (final File file in <File>[
        ...dartFilesIn('lib/features/discovery/presentation'),
        ...dartFilesIn('lib/features/discovery/data'),
        ...dartFilesIn('lib/features/discovery/application'),
        ...dartFilesIn('lib/core/routes'),
      ]) {
        for (final String forbidden in <String>[
          'seatsRemaining',
          'seatsAvailable',
          'seatsLeft',
          'seatsOffered -',
          'accepted.length',
        ]) {
          expect(code(file), isNot(contains(forbidden)), reason: file.path);
        }
      }
    });
  });

  group("A driver's journeys are dated, and the dates are the server's", () {
    /// CARRIES WEIGHT. Every dated lifecycle command names a day.
    ///
    /// The route-only aliases address a one-off route's single journey and
    /// answer `recurring_route_unsupported` for a plan. A recurring surface
    /// that reached for one would be asking the server to guess which morning
    /// it meant, and the server would refuse — or, worse, a future alias would
    /// pick one.
    test('the journeys feature never calls a route-only trip command', () {
      for (final File file in dartFilesIn('lib/features/journeys')) {
        for (final String forbidden in <String>[
          'myRoutesProvider',
          'MyRoutesController',
          'MyRoutesRepository',
        ]) {
          expect(code(file), isNot(contains(forbidden)), reason: file.path);
        }
      }

      // And the dated repository builds every path from one spelling, which
      // always carries the day.
      final String repo = code(
        File('lib/features/journeys/data/journeys_repository.dart'),
      );
      expect(
        repo,
        contains(r"'/api/v1/routes/$routeId/journeys/${serviceDate.iso}'"),
      );
    });

    /// CARRIES WEIGHT. Which journeys exist is the feed's answer.
    ///
    /// Not the device's date. A client that worked out "is this today" would be
    /// reading a calendar in the wrong timezone, and would hide a journey the
    /// driver is in the middle of.
    test('nothing in journeys consults a clock or generates a date', () {
      for (final File file in dartFilesIn('lib/features/journeys')) {
        for (final String forbidden in <String>[
          'DateTime.now',
          'toUtc',
          'toLocal',
          'isBefore',
          'isAfter',
          'difference(',
          'addDays',
          'DateTime.monday',
          'weekday ==',
          'Europe/Istanbul',
        ]) {
          expect(code(file), isNot(contains(forbidden)), reason: file.path);
        }
      }
    });

    /// CARRIES WEIGHT. `MyRoute.trip == null` is not `not_started`.
    ///
    /// Null means the question does not apply to a plan. Turned into a state it
    /// would put Start on a card the server refuses, and the driver would learn
    /// that by pressing it.
    test('a plan absent lifecycle is never turned into a state', () {
      for (final File file in <File>[
        ...dartFilesIn('lib/features/my_routes'),
        ...dartFilesIn('lib/features/journeys'),
        ...dartFilesIn('lib/core/routes'),
      ]) {
        for (final String forbidden in <String>[
          '?? TripState.notStarted',
          '?? const TripLifecycle',
          'trip ?? TripLifecycle',
        ]) {
          expect(code(file), isNot(contains(forbidden)), reason: file.path);
        }
      }
    });

    /// CARRIES WEIGHT. A journey under way is not hidden by its own date, nor
    /// by what became of its plan.
    ///
    /// `/me/journeys` keeps both reachable on purpose. A client that filtered
    /// either would strand a driver mid-journey with a trip they cannot close.
    test('nothing filters a journey by its date or its plan status', () {
      for (final File file in dartFilesIn('lib/features/journeys')) {
        for (final String forbidden in <String>[
          'RouteStatus.cancelled',
          'serviceDate.isBefore',
          'journeys.where',
          'journeys.removeWhere',
        ]) {
          expect(code(file), isNot(contains(forbidden)), reason: file.path);
        }
      }
    });

    /// CARRIES WEIGHT. Lifecycle state is keyed by journey, not by route.
    ///
    /// Keyed by route, starting Monday would disable Tuesday's control and then
    /// write Monday's answer onto it.
    test('the journey controller is a family over route AND day', () {
      final String providers = code(
        File('lib/features/journeys/application/journeys_providers.dart'),
      );

      expect(providers, contains('JourneyRef'));
      expect(providers, contains('AsyncNotifierProvider.family'));
      // The identity itself carries both halves.
      expect(
        code(File('lib/core/journeys/journey.dart')),
        contains(
          'typedef JourneyRef = ({String routeId, DepartureDate serviceDate});',
        ),
      );
    });

    /// Nobody else is on a journey, because nobody else is in the projection.
    test('a journey shows no passenger, vehicle, cost or trust', () {
      for (final File file in <File>[
        ...dartFilesIn('lib/features/journeys'),
        File('lib/core/journeys/journey.dart'),
        File('lib/core/journeys/journey_decoder.dart'),
      ]) {
        for (final String forbidden in <String>[
          'passenger',
          'riders',
          'seatsOffered',
          'seatsRemaining',
          'vehicle',
          'plate',
          'cost',
          'rating',
          'isVerified',
          'latitude',
          'longitude',
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
