import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import 'app/data/app_preferences_repository.dart';
import 'app/error/rm_error_reporter.dart';
import 'app/providers/api_client_provider.dart';
import 'app/providers/app_preferences_provider.dart';
import 'app/providers/credential_store_provider.dart';
import 'app/providers/session_provider.dart';
import 'app/ride_mate_app.dart';
import 'core/api/rm_api_client.dart';
import 'core/config/rm_api_config.dart';
import 'core/session/auth_api.dart';
import 'core/session/credential_store.dart';
import 'core/session/rm_session.dart';

Future<void> main() async {
  // Binding first, then the error hooks, then anything that can fail. An
  // error during startup is exactly the one worth seeing, so nothing runs
  // before the handlers that would observe it.
  WidgetsFlutterBinding.ensureInitialized();
  installRmErrorHandlers();

  // Immediately after the handlers, and before anything else can happen.
  //
  // A build with no backend URL is a build that cannot work, and the honest
  // moment to say so is now. Starting normally would hide it until the first
  // sign-in attempt, where it would surface as a network error — describing
  // the symptom and not the cause, on someone else's machine, hours later.
  //
  // It throws rather than rendering anything. This is a mistake in the build
  // command, not a state a member can be in, and a configuration screen would
  // be UI for a situation no released app can reach.
  RmApiConfig.verify();

  // Resolved here, before the first frame, so every later read is
  // synchronous. That is what removes the hydration race: nothing arrives
  // afterwards to overwrite a choice the member has already made.
  //
  // This is why main() is async, reversing the Phase 1 decision to keep it
  // synchronous. That decision was taken when there was nothing to load; it
  // became the cause of preferences resetting on every restart. Failure
  // degrades to a session-only store rather than blocking startup.
  final AppPreferencesRepository preferences =
      await loadAppPreferencesRepository();

  // Opening the store also purges anything left behind by a previous
  // installation — on iOS the Keychain outlives app deletion, so a reinstall
  // would otherwise inherit the last install's session. The purge happens
  // inside loadCredentialStore, before the store is handed to anyone, so no
  // read can observe a stale credential.
  //
  // Nothing acts on the stored credential yet. Deciding what "signed in"
  // means is a later commit; this one only settles where the secret lives.
  final CredentialStore credentials = await loadCredentialStore();

  // The composition seam: transport, client, endpoints, session. Assembled
  // once, here, so nothing downstream has to know how any of it is built.
  //
  // Restoration starts here and is deliberately NOT awaited.
  //
  // It exchanges the stored refresh token over the network, and blocking the
  // first frame on that would stall launch for as long as a bad connection
  // takes — on a device that may have no session to restore at all. The
  // session begins unresolved instead, which the router holds on the startup
  // surface until this settles, so nothing signed-out flashes on the way.
  //
  // It never throws: every outcome ends signed in or signed out.
  // One client for the whole app: the session authenticates through it, and
  // every feature repository sends through the session.
  final RmApiClient api = RmApiClient.fromConfig();

  final RmSession session = RmSession(api: AuthApi(api), store: credentials);

  unawaited(session.restore());

  runApp(
    ProviderScope(
      overrides: <Override>[
        appPreferencesRepositoryProvider.overrideWithValue(preferences),
        credentialStoreProvider.overrideWithValue(credentials),
        rmSessionProvider.overrideWithValue(session),
        rmApiClientProvider.overrideWithValue(api),
      ],
      child: const RideMateApp(),
    ),
  );
}
