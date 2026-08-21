import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/error/rm_error_reporter.dart';
import 'app/ride_mate_app.dart';

void main() {
  // Binding first, then the error hooks, then anything that can fail. An
  // error during startup is exactly the one worth seeing, so nothing runs
  // before the handlers that would observe it.
  WidgetsFlutterBinding.ensureInitialized();
  installRmErrorHandlers();

  runApp(const ProviderScope(child: RideMateApp()));
}
