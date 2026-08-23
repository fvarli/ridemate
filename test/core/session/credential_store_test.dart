import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/session/credential_store.dart';
import 'package:ridemate/core/session/rm_credentials.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Credential persistence, the reinstall purge, and what happens when the
/// platform store misbehaves.
///
/// The success paths drive the REAL SecureCredentialStore through the
/// plugin's own in-memory test platform, and the failure paths drive it
/// through a storage that throws — so both are the production class rather
/// than a stand-in that happens to agree with it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const RmCredentials credentials = RmCredentials(
    refreshToken: 'rmr_00000000-0000-7000-8000-000000000000.EXAMPLE',
    sessionId: '00000000-0000-7000-8000-000000000001',
  );

  SecureCredentialStore storeWith(Map<String, String> initial) {
    FlutterSecureStorage.setMockInitialValues(initial);

    return const SecureCredentialStore(FlutterSecureStorage());
  }

  group('Reading and writing', () {
    test('an empty store yields no credential', () async {
      expect(await storeWith(<String, String>{}).read(), isNull);
    });

    test('a credential survives a round trip', () async {
      final SecureCredentialStore store = storeWith(<String, String>{});

      await store.write(credentials);

      expect(await store.read(), credentials);
    });

    test('clear removes both halves', () async {
      final SecureCredentialStore store = storeWith(<String, String>{});
      await store.write(credentials);

      await store.clear();

      expect(await store.read(), isNull);
    });

    test('clearing an empty store is harmless', () async {
      final SecureCredentialStore store = storeWith(<String, String>{});

      await store.clear();

      expect(await store.read(), isNull);
    });

    test('only the two documented keys are ever written', () async {
      final SecureCredentialStore store = storeWith(<String, String>{});
      await store.write(credentials);

      final Map<String, String> all = await const FlutterSecureStorage()
          .readAll();

      expect(all.keys.toSet(), RmCredentialKeys.all.toSet());
    });
  });

  group('A half-present pair is corrupt, not repairable', () {
    /// Reconstructing the missing half would mean inventing credential state:
    /// a refresh token whose session is unknown cannot be reasoned about, and
    /// a session id without a token grants nothing. Signing the member out
    /// costs one passcode.
    test('a refresh token without a session id yields nothing', () async {
      final SecureCredentialStore store = storeWith(<String, String>{
        RmCredentialKeys.refreshToken: credentials.refreshToken,
      });

      expect(await store.read(), isNull);
    });

    test('a session id without a refresh token yields nothing', () async {
      final SecureCredentialStore store = storeWith(<String, String>{
        RmCredentialKeys.sessionId: credentials.sessionId,
      });

      expect(await store.read(), isNull);
    });

    test('reading a half-present pair clears the survivor', () async {
      final SecureCredentialStore store = storeWith(<String, String>{
        RmCredentialKeys.refreshToken: credentials.refreshToken,
      });

      await store.read();

      expect(await const FlutterSecureStorage().readAll(), isEmpty);
    });

    test('an empty string counts as absent', () async {
      final SecureCredentialStore store = storeWith(<String, String>{
        RmCredentialKeys.refreshToken: '',
        RmCredentialKeys.sessionId: credentials.sessionId,
      });

      expect(await store.read(), isNull);
    });
  });

  group('The reinstall purge', () {
    /// On iOS the Keychain survives app deletion, so a reinstall would
    /// otherwise inherit the previous install's session — on a shared or
    /// resold device, somebody else's. SharedPreferences does not survive an
    /// uninstall, which is exactly what makes its absence the signal.
    test('a first launch purges stale storage and marks the install', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final InMemoryCredentialStore store = InMemoryCredentialStore();
      await store.write(credentials);

      await purgeIfReinstalled(preferences, store);

      expect(await store.read(), isNull, reason: 'inherited credential');
      expect(preferences.getBool(RmInstallKeys.marker), isTrue);
    });

    test('a later launch leaves a valid credential alone', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        RmInstallKeys.marker: true,
      });
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final InMemoryCredentialStore store = InMemoryCredentialStore();
      await store.write(credentials);

      await purgeIfReinstalled(preferences, store);

      expect(await store.read(), credentials);
    });

    /// The reinstall itself: preferences are gone, the keystore is not.
    test('a reinstall purges credentials the keystore kept', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final SecureCredentialStore store = storeWith(<String, String>{
        RmCredentialKeys.refreshToken: credentials.refreshToken,
        RmCredentialKeys.sessionId: credentials.sessionId,
      });

      await purgeIfReinstalled(preferences, store);

      expect(await store.read(), isNull);
      expect(await const FlutterSecureStorage().readAll(), isEmpty);
    });

    test('purging twice is harmless', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final InMemoryCredentialStore store = InMemoryCredentialStore();

      await purgeIfReinstalled(preferences, store);
      await store.write(credentials);
      await purgeIfReinstalled(preferences, store);

      expect(
        await store.read(),
        credentials,
        reason: 'the marker was already set, so nothing should be purged',
      );
    });

    /// The marker is a marker. Nothing about the member, the session or the
    /// credential belongs in it.
    test('the marker holds no credential material', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();

      await purgeIfReinstalled(preferences, InMemoryCredentialStore());

      expect(preferences.get(RmInstallKeys.marker), isA<bool>());
      expect(preferences.getKeys(), <String>{RmInstallKeys.marker});
    });
  });

  group('Platform failures degrade to signed out', () {
    late List<String> reported;
    late DebugPrintCallback original;

    setUp(() {
      reported = <String>[];
      original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) =>
          reported.add(message ?? '');
    });

    tearDown(() => debugPrint = original);

    SecureCredentialStore throwingStore() =>
        const SecureCredentialStore(_ThrowingSecureStorage());

    test('a failed read yields no credential and is reported', () async {
      expect(await throwingStore().read(), isNull);
      expect(reported.join('\n'), contains('reading the stored credential'));
    });

    test('a failed write does not throw and is reported', () async {
      await throwingStore().write(credentials);

      expect(reported.join('\n'), contains('storing the credential'));
    });

    test('a failed clear does not throw and is reported', () async {
      await throwingStore().clear();

      expect(reported.join('\n'), contains('clearing the credential'));
    });

    /// Reporting writes to the developer log. A credential reaching it — by
    /// way of an interpolated object, say — is the kind of leak nobody writes
    /// on purpose, which is why RmCredentials redacts itself.
    test('nothing reported contains the credential', () async {
      final SecureCredentialStore store = throwingStore();
      await store.write(credentials);
      await store.read();
      await store.clear();

      final String log = reported.join('\n');
      expect(log, isNot(contains(credentials.refreshToken)));
      expect(log, isNot(contains('EXAMPLE')));
    });

    test('the credential redacts itself when printed', () {
      expect(credentials.toString(), isNot(contains('EXAMPLE')));
      expect(credentials.toString(), contains(credentials.sessionId));
    });
  });

  group('The in-memory store', () {
    test('round-trips and clears', () async {
      final InMemoryCredentialStore store = InMemoryCredentialStore();

      expect(await store.read(), isNull);
      await store.write(credentials);
      expect(await store.read(), credentials);
      await store.clear();
      expect(await store.read(), isNull);
    });
  });
}

/// A platform store that fails at everything, for the degradation paths.
class _ThrowingSecureStorage extends FlutterSecureStorage {
  const _ThrowingSecureStorage();

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => throw StateError('keystore unavailable');

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => throw StateError('keystore unavailable');

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => throw StateError('keystore unavailable');
}
