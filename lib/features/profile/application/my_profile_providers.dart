// ─────────────────────────────────────────────────────────────
// RideMate — The signed-in member's own profile
//
// THREE OUTCOMES, AND ONLY TWO OF THEM ARE DATA
//
//   ProfileReady    the server returned a profile
//   ProfileMissing   the server said 404 — no name chosen yet
//   AsyncError       anything else: offline, 5xx, unreadable body
//
// "Missing" is a fact the server stated, so it is DATA. "Unavailable" is the
// app not knowing, so it is an ERROR. Collapsing them would be the defect this
// feature exists to avoid: routing a member to a setup screen because the
// network was down asks somebody who already has a name to invent a second one.
//
// Keeping failures on the error channel is also what keeps `retry` load-bearing
// — a build that returns data has nothing to retry, and the policy below would
// quietly become decoration.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/api_client_provider.dart';
import '../../../app/providers/session_provider.dart';
import '../../../core/api/rm_retry.dart';
import '../../../core/profile/profile.dart';
import '../data/profile_repository.dart';

final Provider<ProfileRepository> profileRepositoryProvider =
    Provider<ProfileRepository>(
      (Ref ref) => ApiProfileRepository(
        client: ref.watch(rmApiClientProvider),
        session: ref.watch(rmSessionProvider),
      ),
    );

/// What the server currently says about this member's identity.
@immutable
sealed class ProfileState {
  const ProfileState();
}

/// The member has a profile, and this is it.
final class ProfileReady extends ProfileState {
  const ProfileReady(this.profile);

  final Profile profile;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileReady && other.profile == profile;

  @override
  int get hashCode => profile.hashCode;
}

/// The member has not chosen a name yet — stated by the server, not inferred.
///
/// Reached only from a 404. A failed request never produces this, which is why
/// it is safe for routing to act on.
final class ProfileMissing extends ProfileState {
  const ProfileMissing();

  @override
  bool operator ==(Object other) => other is ProfileMissing;

  @override
  int get hashCode => (ProfileMissing).hashCode;
}

/// The member's own profile, loaded when something first asks.
///
/// AUTO-DISPOSE, for the reason Phase 10 learned twice on hardware: a provider
/// that outlives its listeners serves a page the server has not confirmed since
/// it was read. Here that would mean a name the member has just changed
/// elsewhere, or — worse — a `ProfileMissing` held after they completed setup.
///
/// `retry` is stated rather than left to the default. Riverpod would otherwise
/// re-run a failed build ten times on a backoff, which on this provider means
/// eleven reads of a profile while the member is shown nothing. See
/// [noAutomaticRetry].
final AsyncNotifierProvider<MyProfileController, ProfileState>
myProfileProvider = AsyncNotifierProvider<MyProfileController, ProfileState>(
  MyProfileController.new,
  isAutoDispose: true,
  retry: noAutomaticRetry,
);

class MyProfileController extends AsyncNotifier<ProfileState> {
  @override
  Future<ProfileState> build() async {
    try {
      return ProfileReady(await ref.watch(profileRepositoryProvider).read());
    } on ProfileNotFound {
      // The only failure that becomes data. Everything else escapes and lands
      // on the error channel, exactly as it should.
      return const ProfileMissing();
    }
  }

  /// Asks the server again.
  ///
  /// `invalidateSelf` rather than assigning state by hand: re-running build
  /// produces the loading state, the request and the answer as one step, and
  /// assigning after a FAILED build re-initialises the notifier — which sends
  /// two requests for one tap, the defect F3 found.
  void refresh() => ref.invalidateSelf();

  /// Sets the display name, then adopts what the server stored.
  ///
  /// Never optimistic, and never a local trim: the name that appears is the one
  /// the server kept, so the screen cannot show something the backend would
  /// disagree with. Returns the failure when there was one and leaves the
  /// current state untouched, so a member whose save failed still sees whatever
  /// was true before they tried.
  Future<RmSaveOutcome> save(String displayName) async {
    try {
      final Profile saved = await ref
          .read(profileRepositoryProvider)
          .save(displayName);

      state = AsyncData<ProfileState>(ProfileReady(saved));

      return const RmSaveOutcome.succeeded();
    } on Object catch (error) {
      return RmSaveOutcome.failed(error);
    }
  }
}

/// Whether a save landed, and what stopped it if not.
///
/// A returned value rather than a thrown one: the caller is a widget that has
/// to say something either way, and making the failure part of the result stops
/// it being forgotten in a `try` nobody wrote.
@immutable
final class RmSaveOutcome {
  const RmSaveOutcome.succeeded() : failure = null;
  const RmSaveOutcome.failed(Object this.failure);

  /// `null` when the save succeeded.
  final Object? failure;

  bool get succeeded => failure == null;
}
