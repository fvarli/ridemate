// ─────────────────────────────────────────────────────────────
// RideMate — Onboarding controller
//
// Owns the single question "has the intro presentation been completed?".
// It says nothing about accounts, sessions or identity verification — see the
// header of onboarding_repository.dart.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/onboarding_repository.dart';

/// The repository backing [onboardingControllerProvider].
///
/// Overridden in tests with an in-memory fake; production ships no fake.
final Provider<OnboardingRepository> onboardingRepositoryProvider =
    Provider<OnboardingRepository>(
      (Ref ref) => SharedPreferencesOnboardingRepository(),
    );

/// Whether the intro presentation has been completed.
///
/// `AsyncValue.loading` means "not resolved yet" — the router treats that as
/// "decide nothing", so neither Onboarding nor Home can flash before the
/// stored value is known.
final AsyncNotifierProvider<OnboardingController, bool>
onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, bool>(OnboardingController.new);

class OnboardingController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() =>
      ref.read(onboardingRepositoryProvider).hasSeenOnboarding();

  /// Records that the intro was completed and publishes the new state.
  ///
  /// This is NOT account creation and NOT sign-in.
  Future<void> markSeen() async {
    await ref.read(onboardingRepositoryProvider).markOnboardingSeen();
    state = const AsyncValue<bool>.data(true);
  }
}
