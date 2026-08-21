// ─────────────────────────────────────────────────────────────
// RideMate — Android release configuration
//
// These assertions are about a file Dart never imports, which is exactly why
// they are worth having: nothing else in the toolchain notices when a Gradle
// edit reintroduces the debug key into a release path, and the consequence is
// an artifact that cannot be told apart from a legitimate one.
//
// A signed-release build cannot be exercised here — that needs a private
// upload key. What can be exercised is that the configuration has no way to
// reach the debug key, and that the secrets are ignored before they exist.
// ─────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The Gradle build file, with `//` comments removed.
///
/// The prohibition is written down in that file's header, so a raw scan would
/// match the explanation rather than a defect. Same helper shape as the
/// feature ban tests.
String _gradleCode() => File('android/app/build.gradle.kts')
    .readAsLinesSync()
    .map((String line) {
      final int slash = line.indexOf('//');
      return slash == -1 ? line : line.substring(0, slash);
    })
    .join('\n');

void main() {
  group('Release signing fails closed', () {
    test('no release path can select the debug signing config', () {
      final String gradle = _gradleCode();

      // The exact Flutter template line this repository shipped with.
      expect(
        gradle.contains('signingConfigs.getByName("debug")'),
        isFalse,
        reason: 'a release build must never fall back to the shared debug key',
      );
      // And nothing weaker, either.
      expect(gradle.contains('"debug"'), isFalse);
      expect(gradle.contains("'debug'"), isFalse);
    });

    test('a release build without a key stops instead of producing one', () {
      final String gradle = _gradleCode();

      expect(gradle, contains('throw GradleException'));
      expect(
        gradle,
        contains('key.properties'),
        reason: 'the failure must name the file the developer has to create',
      );
      // The guard must be scoped to release tasks, or every debug build and
      // every `pub get` would fail with it.
      expect(gradle, contains('gradle.startParameter.taskNames'));
    });

    test('an unsigned artifact requires an explicit opt-in', () {
      final String gradle = _gradleCode();

      // Producing one must be a named, deliberate act — never the quiet
      // outcome of a missing file.
      expect(gradle, contains('ridemate.allowUnsignedRelease'));
    });

    test('the release signing config is only created when a key exists', () {
      final String gradle = _gradleCode();
      expect(gradle, contains('hasReleaseSigning'));
      expect(gradle, contains('signingConfigs.getByName("release")'));
    });
  });

  group('Signing material is ignored before it exists', () {
    test('the root ignore file covers every private key form', () {
      final String ignore = File('.gitignore').readAsStringSync();

      for (final String pattern in <String>[
        'key.properties',
        '*.jks',
        '*.keystore',
        '*.p12',
        '*.p8',
        '*.mobileprovision',
      ]) {
        expect(
          ignore,
          contains(pattern),
          reason: '$pattern must be ignored at the repository root too',
        );
      }
    });

    test('public certificate extensions are deliberately not ignored', () {
      // Blanket-ignoring these would hide legitimate files rather than
      // secrets, and would make a real omission invisible.
      final List<String> patterns = File('.gitignore')
          .readAsLinesSync()
          .map((String l) => l.trim())
          .where((String l) => l.isNotEmpty && !l.startsWith('#'))
          .toList();

      for (final String extension in <String>['*.pem', '*.crt', '*.cer']) {
        expect(patterns, isNot(contains(extension)));
      }
    });

    test('no signing material is committed', () {
      final List<String> offenders = <String>[];
      for (final FileSystemEntity entity in Directory(
        '.',
      ).listSync(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        final String path = entity.path;
        if (path.startsWith('./build/') || path.startsWith('./.git/')) continue;
        if (RegExp(
          r'(key\.properties|\.jks|\.keystore|\.p12|\.p8|\.mobileprovision)$',
        ).hasMatch(path)) {
          offenders.add(path);
        }
      }
      expect(offenders, isEmpty);
    });
  });

  group('Android permissions', () {
    test('the main manifest declares INTERNET and nothing else', () {
      final String manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();

      final List<String> declared = RegExp(
        r'<uses-permission android:name="([^"]+)"',
      ).allMatches(manifest).map((RegExpMatch m) => m.group(1)!).toList();

      expect(declared, <String>['android.permission.INTERNET']);
    });

    test('no product permission is declared ahead of its behaviour', () {
      final String manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();

      // Each of these belongs to a capability that does not exist yet, and
      // declaring one early is how a store listing starts claiming it.
      for (final String permission in <String>[
        'ACCESS_FINE_LOCATION',
        'ACCESS_COARSE_LOCATION',
        'ACCESS_BACKGROUND_LOCATION',
        'CAMERA',
        'READ_CONTACTS',
        'POST_NOTIFICATIONS',
        'CALL_PHONE',
      ]) {
        expect(manifest, isNot(contains(permission)), reason: permission);
      }
    });
  });
}
