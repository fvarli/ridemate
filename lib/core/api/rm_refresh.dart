// ─────────────────────────────────────────────────────────────
// RideMate — Re-reading what another member can change
//
// WHY THIS EXISTS
//
// A seat request's answer is somebody else's decision, and a journey can be
// started, ended or withdrawn from another device. Every screen showing one
// read it once, and kept showing that read for as long as it stayed open —
// which for Home, a tab that never closes, meant until the process ended.
//
// This is the whole freshness model, and it is deliberately small: the member
// pulls a list down, or brings the app back to the foreground, and the server
// is asked again. No polling, no timer, no push and no realtime channel exist,
// so nothing here claims a screen is live.
//
// WHAT A SCREEN SHOWS WHILE IT ASKS AGAIN
//
// The rows it already had. They were the server's answer a moment ago and are
// no less true for being re-read; replacing them with "loading" would take a
// list away from the member in order to fetch the same list.
//
// WHAT IT SHOWS WHEN ASKING AGAIN FAILS
//
// The same rows, and a sentence saying they could not be refreshed. Never the
// rows alone — that would present an old answer as a new one — and never a
// full-screen failure either, which would erase an answer the member could
// read a second ago to report that a second answer did not arrive. Paging
// already follows this rule; a refresh is the same case.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

extension RmHeldValue<T> on AsyncValue<T> {
  /// The previous answer, while it is being re-read or after the re-read
  /// failed; otherwise null.
  ///
  /// Only a REFRESH holds a value. A reload — the provider rebuilding because
  /// something it watches changed, such as the session — is a different
  /// question, and its old answer is not shown while the new one arrives.
  T? get held =>
      hasValue && (isRefreshing || (hasError && !isLoading)) ? value : null;

  /// Whether [held] is an answer the last re-read failed to replace.
  bool get refreshFailed => hasValue && hasError && !isLoading;
}

/// Re-reads each of [reads] and completes once every one has settled.
///
/// Completes normally whether they succeeded or not: each provider's own state
/// already records its failure, and a screen reads it from there. Awaiting is
/// the point — a pull-to-refresh indicator that stopped as soon as the request
/// was SENT would claim a refresh that had not happened yet.
Future<void> rmReread(
  WidgetRef ref,
  Iterable<Refreshable<Future<Object?>>> reads,
) async {
  await Future.wait(<Future<void>>[
    for (final Refreshable<Future<Object?>> read in reads)
      ref.refresh(read).then<void>((_) {}, onError: (Object _) {}),
  ]);
}
