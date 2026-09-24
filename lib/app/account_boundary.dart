// ─────────────────────────────────────────────────────────────
// RideMate — Where one member's state ends
//
// ONE OWNER
//
// This is the only place the app reacts to a session ending by discarding what
// the member left behind. Screens do not reset themselves on sign-out; a reset
// that depends on which screen happened to be open is one that eventually
// misses.
//
// EVERY WAY OF BEING SIGNED OUT, NOT ONLY THE BUTTON
//
// A member who taps Sign out, one whose refresh token expired, one whose
// session an operator revoked and one whose account was suspended all leave
// the device the same way — and any of them can be followed by somebody else
// signing in on it. So the trigger is the session becoming RmSignedOut, not
// the action that caused it.
//
// WHAT IS LISTED, AND WHAT IS NOT
//
// Only what survives the authenticated shell. Everything the shell's screens
// watch through an auto-dispose provider — the profile, My Routes, journeys,
// seat requests, reviews, discovery results, the seat-request and review
// attempts — is disposed when signing out tears the shell down, and the next
// member gets fresh instances. The providers below are app-scoped by design,
// so that a tab switch or a back gesture does not lose the member's input, and
// that is exactly what lets them outlive the member.
//
// Device choices are deliberately absent: theme, language and whether the
// intro has been seen belong to the phone, not to whoever is signed in on it.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../core/session/rm_session.dart';
import '../features/create_route/application/create_route_providers.dart';
import '../features/create_route/application/publication_providers.dart';
import '../features/discovery/application/discovery_providers.dart';
import '../features/discovery/application/discovery_search_providers.dart';
import 'providers/session_provider.dart';

/// Member-owned state that outlives the authenticated shell.
///
///   * the route a driver is composing — where they commute from and to;
///   * the publication attempt, whose id is an idempotency key that must never
///     be presented under another account;
///   * the search being composed, and the search in effect — the second is
///     what the results provider re-runs as soon as Search is mounted again.
final List<ProviderOrFamily> kAccountBoundState = <ProviderOrFamily>[
  createRouteDraftProvider,
  publicationProvider,
  searchDraftProvider,
  discoveryQueryProvider,
];

/// Discards [kAccountBoundState] whenever the session becomes signed out.
///
/// Read once by the router, which lives as long as the app does, so the
/// listener is in place before any session can end.
final Provider<void> accountBoundaryProvider = Provider<void>((Ref ref) {
  final RmSession session = ref.watch(rmSessionProvider);

  void onSessionChanged() {
    if (session.state.value is! RmSignedOut) return;

    for (final ProviderOrFamily state in kAccountBoundState) {
      ref.invalidate(state);
    }
  }

  session.state.addListener(onSessionChanged);
  ref.onDispose(() => session.state.removeListener(onSessionChanged));
});
