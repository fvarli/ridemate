// ─────────────────────────────────────────────────────────────
// RideMate — A member's public identity
//
// Neutral, not feature-local. The Profile screen reads it today and Phase 12's
// discovery surfaces will read it for OTHER members, so it lives beside
// `core/places` and `core/routes` rather than inside `features/profile` —
// the same promotion `PublishedRoute` earned in F5 once a second consumer
// existed.
//
// INITIALS ARE THE SERVER'S
//
// `initials` is a field, not a getter. The server derives it from the display
// name and returns it, and this class stores what it was given. That looks
// redundant — `RmTextConventions.initials` is right there — and it is exactly
// what must not happen: two implementations of a deterministic rule eventually
// disagree about a member's name, and Turkish casing is precisely where they
// would. A guard in api_boundary_test asserts nothing under features/profile
// computes them.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

/// What a member is called, and the initials the server drew from it.
///
/// Two fields, which is the whole of what the contract publishes. There is no
/// id: the API exposes none, and a client that invented one would be storing a
/// handle nothing can be looked up by.
@immutable
final class Profile {
  const Profile({required this.displayName, required this.initials});

  /// As the member typed it, minus surrounding whitespace — the server
  /// normalises before storing, so this is what was actually kept.
  final String displayName;

  /// Rendered, never recomputed. See the file header.
  final String initials;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Profile &&
          other.displayName == displayName &&
          other.initials == initials;

  @override
  int get hashCode => Object.hash(displayName, initials);

  @override
  String toString() => 'Profile($displayName, $initials)';
}
