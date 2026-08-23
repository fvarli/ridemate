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

  group('No dependency crept in with it', () {
    test('the transport is package:http and not an alternative', () {
      final String pubspec = File('pubspec.yaml').readAsStringSync();

      expect(pubspec, contains('http: ^1.6.0'));
      for (final String rejected in <String>['dio', 'chopper', 'retrofit']) {
        expect(pubspec, isNot(contains(rejected)), reason: rejected);
      }
    });

    /// Credential storage belongs to a later commit and would be easy to add
    /// here "while we are in the pubspec".
    test('storage packages are still absent', () {
      final String pubspec = File('pubspec.yaml').readAsStringSync();

      for (final String absent in <String>[
        'flutter_secure_storage',
        'hive',
        'sqflite',
      ]) {
        expect(pubspec, isNot(contains(absent)), reason: absent);
      }
    });
  });
}
