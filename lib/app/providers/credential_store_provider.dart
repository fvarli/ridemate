// ─────────────────────────────────────────────────────────────
// RideMate — where the stored credential is reached from
//
// One provider, holding the store and not the credential.
//
// Session STATE — signed in, signed out, refreshing — is not here and does not
// exist yet. This commit establishes only where the refresh credential lives;
// deciding what the app does about it is a later commit, and putting a
// half-formed version of that decision here would be the thing later work has
// to unpick.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session/credential_store.dart';

/// Where the refresh credential is read and written.
///
/// Overridden in `main()` with the platform-backed store, after the
/// reinstall purge has run. The default is an in-memory store for the same
/// reason preferences has one: anything that forgets to override it gets a
/// working, empty, process-lifetime store rather than silently reaching the
/// platform keystore — which is what a widget test would otherwise do.
final Provider<CredentialStore> credentialStoreProvider =
    Provider<CredentialStore>((Ref ref) => InMemoryCredentialStore());
