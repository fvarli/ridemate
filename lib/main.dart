import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import 'app/data/app_preferences_repository.dart';
import 'app/error/rm_error_reporter.dart';
import 'app/providers/app_preferences_provider.dart';
import 'app/ride_mate_app.dart';

Future<void> main() async {
  // Binding first, then the error hooks, then anything that can fail. An
  // error during startup is exactly the one worth seeing, so nothing runs
  // before the handlers that would observe it.
  WidgetsFlutterBinding.ensureInitialized();
  installRmErrorHandlers();

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

  runApp(
    ProviderScope(
      overrides: <Override>[
        appPreferencesRepositoryProvider.overrideWithValue(preferences),
      ],
      child: const RideMateApp(),
    ),
  );
}
