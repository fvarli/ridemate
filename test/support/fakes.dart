// ─────────────────────────────────────────────────────────────
// RideMate — Test doubles
//
// These live in `test/` on purpose. Production ships no fake implementations;
// `architecture.md` forbids building them "so the architecture looks
// complete".
// ─────────────────────────────────────────────────────────────

import 'package:ridemate/features/onboarding/data/onboarding_repository.dart';

/// In-memory [OnboardingRepository].
///
/// Records how many times the intro was marked complete, so a test can prove
/// an action did NOT touch persistence.
class InMemoryOnboardingRepository implements OnboardingRepository {
  InMemoryOnboardingRepository({bool seen = false}) : _seen = seen;

  bool _seen;

  /// How many times [markOnboardingSeen] was called.
  int markCallCount = 0;

  bool get seen => _seen;

  @override
  Future<bool> hasSeenOnboarding() async => _seen;

  @override
  Future<void> markOnboardingSeen() async {
    markCallCount++;
    _seen = true;
  }
}
