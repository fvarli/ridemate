// ─────────────────────────────────────────────────────────────
// RideMate — Verification state
//
// THE TRUST SCORE IS NEVER CALCULATED HERE.
//
// There is deliberately no scoring function, no weights and no policy in this
// codebase. The design shows two verified steps and a score of 60 — which is
// not 2/5, proving the score is not derived from step counts. Turning a design
// mock into a formula would invent a business rule.
//
// The real Trust Score is a backend-owned, safety-sensitive domain concept
// that will draw on identity verification, account age, trip history,
// cancellations, ratings, reports, fraud signals and device/account risk.
// Nothing in the client may pre-empt it.
//
// So [VerificationState] simply CARRIES the score it should display. Where
// that number comes from today is a presentation fixture — see
// mock_verification_scenarios.dart.
//
// Verification is also strictly separate from onboarding and from
// authentication. It is in-memory only and is never persisted.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

/// The verification steps the design defines, in the order it lists them.
enum VerificationStepId { phone, email, identity, selfie, licence }

/// The four states the design draws for a step.
enum VerificationStepStatus {
  /// Complete. Green filled indicator with a check.
  verified,

  /// Under way. Blue emphasised card with the ring indicator and an action.
  inProgress,

  /// Not started, but required. Dimmed with a hollow indicator.
  pending,

  /// Not started and not required — the driving licence.
  ///
  /// The design renders this identically to [pending]; only the status text
  /// differs. The distinction is kept in the type system and the accessibility
  /// tree regardless, so a future visual treatment is a one-line change.
  optional,
}

/// One step in the verification list.
@immutable
final class VerificationStep {
  const VerificationStep({required this.id, required this.status});

  final VerificationStepId id;
  final VerificationStepStatus status;

  /// Whether this step is needed for the verified badge.
  bool get isRequired => status != VerificationStepStatus.optional;

  VerificationStep copyWith({VerificationStepStatus? status}) =>
      VerificationStep(id: id, status: status ?? this.status);

  @override
  bool operator ==(Object other) =>
      other is VerificationStep && other.id == id && other.status == status;

  @override
  int get hashCode => Object.hash(id, status);
}

/// What the verification screen renders.
@immutable
final class VerificationState {
  const VerificationState({
    required this.steps,
    required this.displayTrustScore,
  });

  final List<VerificationStep> steps;

  /// The Trust Score to DISPLAY, supplied by whatever produced this state.
  ///
  /// Not computed here and not computable from [steps]. See the file header.
  final int displayTrustScore;

  /// Whether every required step is complete.
  ///
  /// This is a description of the step list, not a scoring rule.
  bool get allRequiredStepsVerified => steps
      .where((VerificationStep s) => s.isRequired)
      .every(
        (VerificationStep s) => s.status == VerificationStepStatus.verified,
      );

  /// How many required steps are still outstanding — the design's
  /// "2 adım daha tamamla" line.
  int get remainingRequiredSteps => steps
      .where(
        (VerificationStep s) =>
            s.isRequired && s.status != VerificationStepStatus.verified,
      )
      .length;

  @override
  bool operator ==(Object other) =>
      other is VerificationState &&
      other.displayTrustScore == displayTrustScore &&
      listEquals(other.steps, steps);

  @override
  int get hashCode => Object.hash(displayTrustScore, Object.hashAll(steps));
}
