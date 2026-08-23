import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Cleartext HTTP is permitted in debug builds and nowhere else.
///
/// Local development needs plain HTTP to reach a Laravel server on the
/// developer's machine. The risk is that the easiest way to arrange that —
/// `android:usesCleartextTraffic="true"` in the main manifest — also arranges
/// it for every release build, permanently, and nothing about the app would
/// look different afterwards.
///
/// These assertions are cheap and the failure they prevent is not: an app
/// shipping passcodes and bearer tokens over unencrypted connections, with no
/// symptom until somebody looks at the traffic.
void main() {
  String read(String path) => File(path).readAsStringSync();

  /// Markup with XML comments removed.
  ///
  /// These files explain what they deliberately do NOT contain — a
  /// <base-config> granting cleartext to everything, a LAN range — and a
  /// scanner reading raw text finds those phrases in the explanation and
  /// reports the documentation as a defect. The same trap the backend's
  /// vocabulary guard avoids by inspecting identifiers rather than prose.
  String markup(String path) =>
      read(path).replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');

  const String main = 'android/app/src/main/AndroidManifest.xml';
  const String debug = 'android/app/src/debug/AndroidManifest.xml';
  const String profile = 'android/app/src/profile/AndroidManifest.xml';
  const String config =
      'android/app/src/debug/res/xml/network_security_config.xml';

  group('The debug build permits local cleartext', () {
    test('the debug manifest references the network security config', () {
      expect(markup(debug), contains('android:networkSecurityConfig'));
      expect(markup(debug), contains('@xml/network_security_config'));
    });

    test('the config lives under src/debug, so no other variant sees it', () {
      expect(File(config).existsSync(), isTrue);
      expect(
        File(
          'android/app/src/main/res/xml/network_security_config.xml',
        ).existsSync(),
        isFalse,
        reason: 'a config under src/main would apply to release builds',
      );
    });

    test('it permits exactly the three local hosts', () {
      final String source = markup(config);

      for (final String host in <String>[
        '10.0.2.2',
        '127.0.0.1',
        'localhost',
      ]) {
        expect(
          source,
          contains('<domain includeSubdomains="false">$host</domain>'),
        );
      }

      expect(
        '<domain '.allMatches(source).length,
        3,
        reason: 'exactly three hosts, and adding a fourth is a decision',
      );
    });

    /// The one-line version of this file grants cleartext to every host,
    /// including whatever a mistyped base URL points at.
    test('it does not grant cleartext to everything', () {
      expect(markup(config), isNot(contains('<base-config')));
    });

    /// A LAN address changes with the network and would mean trusting a range
    /// belonging to whatever network the laptop is on. `adb reverse` needs no
    /// such permission.
    test('it permits no LAN range', () {
      final String source = markup(config);
      for (final String prefix in <String>['192.168.', '10.0.0.', '172.16.']) {
        expect(source, isNot(contains(prefix)), reason: prefix);
      }
    });
  });

  group('Release inherits none of it', () {
    for (final (String label, String path) in <(String, String)>[
      ('main', main),
      ('profile', profile),
    ]) {
      test('the $label manifest permits no cleartext', () {
        final String source = markup(path);
        expect(
          source,
          isNot(contains('usesCleartextTraffic')),
          reason: 'this would apply to release builds too',
        );
        expect(
          source,
          isNot(contains('networkSecurityConfig')),
          reason: 'a release build must keep the platform default',
        );
      });
    }

    /// The permission itself is fine and necessary — HTTPS needs it too. What
    /// must not accompany it is an exception to the transport rules.
    test('the main manifest still declares INTERNET', () {
      expect(markup(main), contains('android.permission.INTERNET'));
    });
  });
}
