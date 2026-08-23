import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/app/data/app_preferences_repository.dart';
import 'package:ridemate/core/session/credential_store.dart';
import 'package:ridemate/core/session/rm_credentials.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where secrets may live, and where they may not.
///
/// Two rules, both easy to erode by accident: the platform plugin stays behind
/// the CredentialStore interface, and nothing secret is ever written to
/// SharedPreferences — which is an unencrypted XML file on Android and a
/// plist on iOS, readable on a rooted or jailbroken device.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Iterable<File> dartFilesIn(String path) => Directory(path)
      .listSync(recursive: true)
      .whereType<File>()
      .where((File f) => f.path.endsWith('.dart'))
      .where((File f) => !f.path.contains('app_localizations'));

  /// Source with `//` comments removed: these files discuss the plugin and the
  /// access token by name in their own headers, and a scanner reading raw text
  /// reports the explanation rather than a defect.
  String code(File file) => file
      .readAsLinesSync()
      .map((String line) {
        final int comment = line.indexOf('//');

        return comment == -1 ? line : line.substring(0, comment);
      })
      .join('\n');

  const String implementation = 'lib/core/session/credential_store.dart';

  group('The plugin stays behind the interface', () {
    test('flutter_secure_storage is imported by exactly one file', () {
      final List<String> importers = <String>[
        for (final File file in dartFilesIn('lib'))
          if (code(file).contains('package:flutter_secure_storage'))
            file.path.replaceFirst('./', ''),
      ];

      expect(importers, <String>[implementation]);
    });

    test('no plugin type crosses into the credential model or provider', () {
      for (final String file in <String>[
        'lib/core/session/rm_credentials.dart',
        'lib/app/providers/credential_store_provider.dart',
      ]) {
        expect(
          code(File(file)),
          isNot(contains('FlutterSecureStorage')),
          reason: file,
        );
      }
    });
  });

  group('Nothing secret reaches SharedPreferences', () {
    /// The strongest form of this: perform a real write, then inspect the
    /// whole preference store.
    test('a stored credential leaves no trace in preferences', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      FlutterSecureStorage.setMockInitialValues(<String, String>{});

      const RmCredentials credentials = RmCredentials(
        refreshToken: 'rmr_CANARY-REFRESH',
        sessionId: 'CANARY-SESSION',
      );
      await const SecureCredentialStore(
        FlutterSecureStorage(),
      ).write(credentials);

      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final String dumped = preferences
          .getKeys()
          .map((String key) => '$key=${preferences.get(key)}')
          .join('\n');

      expect(dumped, isNot(contains('CANARY-REFRESH')));
      expect(dumped, isNot(contains('CANARY-SESSION')));
    });

    test('credential keys are not preference keys', () {
      for (final String key in RmCredentialKeys.all) {
        expect(AppPreferenceKeys.all, isNot(contains(key)));
      }
      expect(RmCredentialKeys.all, isNot(contains(RmInstallKeys.marker)));
    });

    /// Namespaces are what keep the three stores from growing into each other.
    test('each store owns a distinct key prefix', () {
      for (final String key in RmCredentialKeys.all) {
        expect(key, startsWith('ridemate.credential.'));
      }
      expect(RmInstallKeys.marker, startsWith('ridemate.install.'));
      for (final String key in AppPreferenceKeys.all) {
        expect(key, startsWith('ridemate.prefs.'));
      }
    });

    test(
      'the credential keys appear nowhere outside the session directory',
      () {
        final List<String> offenders = <String>[];

        for (final File file in dartFilesIn('lib')) {
          if (file.path.startsWith('lib/core/session/')) {
            continue;
          }
          for (final String key in RmCredentialKeys.all) {
            if (code(file).contains(key)) {
              offenders.add('${file.path}: $key');
            }
          }
        }

        expect(offenders, isEmpty);
      },
    );
  });

  group('What is deliberately never persisted', () {
    /// The access token is memory-only, and RmCredentials has nowhere to put
    /// one — so the rule is a property of the type rather than a convention.
    /// Passcodes are single-use and live five minutes; persisting one would be
    /// storing a credential that exists only to be spent immediately.
    test('no key or field names an access token or a passcode', () {
      final String keys = code(File(implementation));
      final String model = code(File('lib/core/session/rm_credentials.dart'));

      for (final String banned in <String>[
        'accessToken',
        'access_token',
        'otp',
        'Otp',
        'passcode',
        'Passcode',
      ]) {
        expect(keys, isNot(contains(banned)), reason: 'store: $banned');
        expect(model, isNot(contains(banned)), reason: 'model: $banned');
      }
    });

    test('secure storage holds only the two documented keys', () {
      expect(RmCredentialKeys.all, <String>[
        'ridemate.credential.refreshToken',
        'ridemate.credential.sessionId',
      ]);
    });
  });

  group('The existing stores are untouched', () {
    test('preference keys are unchanged', () {
      expect(AppPreferenceKeys.all, <String>[
        'ridemate.prefs.themeMode',
        'ridemate.prefs.locale',
      ]);
    });

    test('the onboarding flag is unchanged and still separate', () {
      final String source = File(
        'lib/features/onboarding/data/onboarding_repository.dart',
      ).readAsStringSync();

      expect(source, contains("'ridemate.onboarding.hasSeenOnboarding'"));
      expect(source, isNot(contains('credential')));
      expect(source, isNot(contains('flutter_secure_storage')));
    });

    /// Credential storage is not a settings store and must not become one.
    test('the preferences repository knows nothing about credentials', () {
      final String source = code(
        File('lib/app/data/app_preferences_repository.dart'),
      );

      expect(source, isNot(contains('flutter_secure_storage')));
      expect(source, isNot(contains('RmCredential')));
    });
  });
}
