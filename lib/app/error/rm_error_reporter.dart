// ─────────────────────────────────────────────────────────────
// RideMate — Error reporting seam
//
// One function. There is no reporter interface, no observability abstraction
// and no third-party dependency, because there is exactly one implementation
// and inventing a hierarchy for it would be the ceremony architecture.md
// forbids. When a crash reporter is chosen, it attaches inside [reportError]
// and nothing else in the app changes.
//
// WHAT THIS DOES AND DOES NOT DO
//
// It OBSERVES. It does not suppress, swallow or recover. An error that would
// have reached the console still reaches it, and an error that would have
// crashed the app still crashes it. Marking errors handled while nothing
// records them would hide defects, which is the opposite of the point.
//
// NO DOUBLE REPORTING. Two hooks are installed and they are disjoint:
//
//   FlutterError.onError                  framework errors — build, layout,
//                                         paint, gesture callbacks
//   PlatformDispatcher.instance.onError   uncaught asynchronous errors that
//                                         reach the platform
//
// `runZonedGuarded` is deliberately NOT used. It would catch the same
// uncaught async errors that PlatformDispatcher.onError receives, so every
// one of them would be reported twice.
// ─────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/foundation.dart';

/// Installs the application-wide error hooks.
///
/// Call once, as early in `main()` as possible — before anything that can
/// fail, so a bootstrap failure is observed rather than lost.
void installRmErrorHandlers() {
  FlutterError.onError = (FlutterErrorDetails details) {
    reportError(details.exception, details.stack, context: details.context);
    // Keep the framework's own behaviour: the red screen in debug, the console
    // dump everywhere. Nothing about developer visibility changes.
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    reportError(error, stack);
    // FALSE means "not handled". The error continues to the default handler
    // exactly as it would have without this hook. Returning true would
    // silence a crash that nothing is recording.
    return false;
  };
}

/// Records [error] for later diagnosis.
///
/// The single place a crash reporter will attach. Until then this writes to
/// the developer log, which is where an unattended error already goes — the
/// value today is that every path funnels through one function, so attaching
/// a reporter is a one-file change rather than an audit.
///
/// Never throws: a failure inside error reporting must not become a second
/// error, and must never replace the original one.
void reportError(
  Object error,
  StackTrace? stack, {
  DiagnosticsNode? context,
  String? hint,
}) {
  try {
    final StringBuffer message = StringBuffer('[RideMate] $error');
    if (hint != null) message.write(' — $hint');
    if (context != null) message.write(' (${context.toDescription()})');
    debugPrint(message.toString());
    if (stack != null) debugPrintStack(stackTrace: stack);
  } on Object {
    // Deliberately empty: nothing useful remains to do, and rethrowing here
    // would lose the error we were asked to record.
  }
}

/// Runs [body], reporting anything it throws without letting it escape.
///
/// For work whose failure must not stop startup — reading a stored preference,
/// for instance. The caller supplies what happens instead via [orElse], so the
/// degraded behaviour is a decision at the call site rather than a silent
/// default here.
Future<T> reportingFailures<T>(
  Future<T> Function() body, {
  required T Function() orElse,
  String? hint,
}) async {
  try {
    return await body();
  } on Object catch (error, stack) {
    reportError(error, stack, hint: hint);
    return orElse();
  }
}
