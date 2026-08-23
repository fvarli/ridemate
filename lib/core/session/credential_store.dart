// ─────────────────────────────────────────────────────────────
// RideMate — credential storage
//
// Deliberately separate from AppPreferencesRepository and from the onboarding
// flag. Those hold choices a member made; this holds something that grants
// access to their account, and the two belong in different places with
// different guarantees. Folding them together would end with SharedPreferences
// as a general-purpose session store, which is exactly where secrets end up
// in plaintext.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/error/rm_error_reporter.dart';
import 'rm_credentials.dart';

/// Secure-storage keys. Namespaced so they can never collide with a
/// preference, the onboarding flag, or a future profile key.
abstract final class RmCredentialKeys {
  static const String refreshToken = 'ridemate.credential.refreshToken';
  static const String sessionId = 'ridemate.credential.sessionId';

  /// Everything this application ever writes to secure storage.
  static const List<String> all = <String>[refreshToken, sessionId];
}

/// The SharedPreferences marker that survives a restart and not an uninstall.
abstract final class RmInstallKeys {
  /// Set once, on the first launch after installation.
  ///
  /// Holds a bare `true`. It is a marker, not a record: nothing about the
  /// member, the session or the credential is in it or ever should be.
  static const String marker = 'ridemate.install.marker';
}

/// Reads and writes the credential that outlives the process.
abstract interface class CredentialStore {
  /// The stored credential, or null when there is none or it is unusable.
  Future<RmCredentials?> read();

  /// Returns whether the credential is now durable — that is, whether it will
  /// still be there after the process restarts.
  ///
  /// `false` means the write failed and was reported. Callers that have just
  /// rotated a credential MUST treat that as fatal to the session: continuing
  /// with an in-memory token that cannot survive a restart would leave the
  /// member signed in until they close the app and silently signed out
  /// afterwards, having spent a refresh generation the server already
  /// invalidated.
  Future<bool> write(RmCredentials credentials);

  /// Removes both halves. Safe to call when nothing is stored.
  Future<void> clear();
}

/// The production implementation, backed by the platform keystore.
///
/// `FlutterSecureStorage` is constructed outside and never escapes: the
/// interface deals in [RmCredentials] and nothing else, so replacing the
/// plugin is a change to this one file. A test enforces that boundary.
class SecureCredentialStore implements CredentialStore {
  const SecureCredentialStore(this._storage);

  final FlutterSecureStorage _storage;

  /// A half-present pair is corrupt state, and it is cleared rather than
  /// repaired.
  ///
  /// There is no honest way to reconstruct the missing half: inventing a
  /// session id for a refresh token, or the reverse, would be manufacturing
  /// credential state. Signing the member out costs them one passcode; the
  /// alternative is an app reasoning about a session that may not exist.
  @override
  Future<RmCredentials?> read() => reportingFailures<RmCredentials?>(
    () async {
      final String? refreshToken = await _storage.read(
        key: RmCredentialKeys.refreshToken,
      );
      final String? sessionId = await _storage.read(
        key: RmCredentialKeys.sessionId,
      );

      if (refreshToken == null ||
          refreshToken.isEmpty ||
          sessionId == null ||
          sessionId.isEmpty) {
        // Only bother writing if something was actually there.
        if (refreshToken != null || sessionId != null) {
          await clear();
        }

        return null;
      }

      return RmCredentials(refreshToken: refreshToken, sessionId: sessionId);
    },
    orElse: () => null,
    hint: 'reading the stored credential',
  );

  @override
  Future<bool> write(RmCredentials credentials) => reportingFailures<bool>(
    () async {
      await _storage.write(
        key: RmCredentialKeys.refreshToken,
        value: credentials.refreshToken,
      );
      await _storage.write(
        key: RmCredentialKeys.sessionId,
        value: credentials.sessionId,
      );

      return true;
    },
    orElse: () => false,
    hint: 'storing the credential',
  );

  /// Best effort, and never allowed to throw.
  ///
  /// Every caller is already on a path that ends signed out, and a failure to
  /// delete must not turn that into a crash. The one thing it must not do is
  /// leave the app believing a credential is gone when it is not, which is why
  /// nothing downstream treats a successful clear as proof.
  @override
  Future<void> clear() => reportingFailures<void>(
    () async {
      await _storage.delete(key: RmCredentialKeys.refreshToken);
      await _storage.delete(key: RmCredentialKeys.sessionId);
    },
    orElse: () {},
    hint: 'clearing the credential',
  );
}

/// A real store that happens to live in memory.
///
/// Durable for the life of the process, and honest about it: `write` returns
/// true because the value genuinely is retrievable afterwards. Used by tests
/// and as the provider default, where process lifetime is the whole scope.
///
/// It is NOT the degraded production fallback — see [UnavailableCredentialStore].
/// It was, and that was a defect: `true` from this class told the session a
/// credential was durable when the platform store had failed to open, so the
/// member signed in and was silently signed out at the next launch, having
/// already spent a refresh generation the server had invalidated.
class InMemoryCredentialStore implements CredentialStore {
  RmCredentials? _credentials;

  @override
  Future<RmCredentials?> read() async => _credentials;

  @override
  Future<bool> write(RmCredentials credentials) async {
    _credentials = credentials;

    return true;
  }

  @override
  Future<void> clear() async => _credentials = null;
}

/// What stands in when the platform keystore cannot be opened at all.
///
/// FAILS CLOSED, DELIBERATELY.
///
/// `write` returns false, so a session can never be established on a device
/// where the credential could not outlive the process. The alternative —
/// keeping it in memory and reporting success — is worse than it sounds:
/// signing in spends a refresh generation server-side, so the member would be
/// signed in until they closed the app and then unable to recover, with
/// nothing on screen having suggested anything was wrong.
///
/// Refusing means such a device cannot hold a session at all. That is a real
/// cost, and it is the honest one: the app still runs, still shows everything
/// that does not require an account, and says so at the point of signing in
/// rather than an hour later.
class UnavailableCredentialStore implements CredentialStore {
  const UnavailableCredentialStore();

  /// Nothing was ever stored, because nothing could be.
  @override
  Future<RmCredentials?> read() async => null;

  @override
  Future<bool> write(RmCredentials credentials) async => false;

  /// A no-op that succeeds: callers clear on paths that end signed out, and
  /// there is nothing here to remove.
  @override
  Future<void> clear() async {}
}

/// Clears secure storage if this is the first launch after an installation.
///
/// WHY THIS EXISTS
///
/// On iOS the Keychain SURVIVES app deletion. Reinstalling therefore hands the
/// new install the previous one's refresh token — on a shared or resold
/// device, somebody else's session, resumed silently. Android generally
/// discards the backing store with the app, but Auto Backup can restore it, so
/// the defence is wanted on both rather than being an iOS special case.
///
/// SharedPreferences is the right home for the marker precisely because it
/// does NOT survive an uninstall. Its absence beside a populated keystore is
/// the signal that the two came from different installations.
///
/// Ordering matters: this runs during [loadCredentialStore], before the store
/// is handed to anyone, so no read can observe a stale credential. That is
/// stronger than asking callers to purge first and hoping they remember.
Future<void> purgeIfReinstalled(
  SharedPreferences preferences,
  CredentialStore store,
) async {
  if (preferences.getBool(RmInstallKeys.marker) ?? false) {
    return;
  }

  await store.clear();
  await preferences.setBool(RmInstallKeys.marker, true);
}

/// Opens the credential store, purging anything left by a previous install.
///
/// Never throws. A platform store that cannot be opened is reported and
/// degrades to an in-memory one, so a keystore problem signs the member out
/// instead of stopping the app.
Future<CredentialStore> loadCredentialStore() {
  return reportingFailures<CredentialStore>(
    () async {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();

      const SecureCredentialStore store = SecureCredentialStore(
        FlutterSecureStorage(
          // Jetpack Security rather than the legacy KeyStore-wrapped
          // preferences file. Set explicitly because the default has changed
          // between major versions of the plugin before.
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        ),
      );

      await purgeIfReinstalled(preferences, store);

      return store;
    },
    // NOT an in-memory store. See UnavailableCredentialStore: reporting a
    // durable write from a store that is standing in for a broken keystore is
    // what makes a session look established and vanish at restart.
    orElse: UnavailableCredentialStore.new,
    hint: 'opening the credential store',
  );
}
