// ─────────────────────────────────────────────────────────────
// RideMate — Verification controller
//
// Walks the scripted demo scenarios so the approved visual states can be
// reviewed on a device. It computes nothing: each scenario already carries the
// Trust Score to display.
//
// State is in-memory and is NEVER persisted — showing a fake verification
// level that survived a restart would be misleading in a trust product.
// Verification is also entirely separate from onboarding and authentication.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/mock_verification_scenarios.dart';
import '../domain/verification_state.dart';

/// The verification screen's state.
final NotifierProvider<VerificationController, VerificationState>
verificationControllerProvider =
    NotifierProvider<VerificationController, VerificationState>(
      VerificationController.new,
    );

class VerificationController extends Notifier<VerificationState> {
  int _scenarioIndex = 0;

  @override
  VerificationState build() {
    _scenarioIndex = 0;
    return MockVerificationScenarios.script.first;
  }

  /// Whether the demo can advance any further.
  bool get canAdvance =>
      _scenarioIndex < MockVerificationScenarios.script.length - 1;

  /// Advances to the next scripted scenario.
  ///
  /// This is a demo transition, not a verification submission: nothing is
  /// uploaded, checked or scored. The last scenario is terminal.
  void advance() {
    if (!canAdvance) return;
    _scenarioIndex++;
    state = MockVerificationScenarios.script[_scenarioIndex];
  }
}
