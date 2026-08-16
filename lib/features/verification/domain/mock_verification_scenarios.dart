// ─────────────────────────────────────────────────────────────
// RideMate — Verification demo scenarios
//
// PRESENTATION FIXTURES. NOT A SCORING POLICY. NOT A BUSINESS RULE.
//
// These scenarios exist so the approved verification states can be seen and
// reviewed on a device. Each one carries the Trust Score it should DISPLAY.
// The scores are chosen purely so the demo reads sensibly; they are not
// derived from the steps, and no function in this codebase derives a score
// from anything.
//
// The real Trust Score is backend-owned and safety-sensitive. Do not document
// these numbers as a RideMate Trust Score formula, do not extract weights from
// them, and do not let a future reader mistake them for one.
//
// Scenario 0 reproduces the approved design exactly: phone and email
// verified, identity in progress, selfie pending, licence optional, score 60.
// ─────────────────────────────────────────────────────────────

import 'verification_state.dart';

/// One step of the scripted demo.
///
/// A scenario is a snapshot to render, not a computation.
typedef MockVerificationScenario = VerificationState;

/// The scripted demo, in order. Advancing moves to the next entry.
abstract final class MockVerificationScenarios {
  const MockVerificationScenarios._();

  /// Exactly what the design source shows.
  static const MockVerificationScenario initial = VerificationState(
    displayTrustScore: 60,
    steps: <VerificationStep>[
      VerificationStep(
        id: VerificationStepId.phone,
        status: VerificationStepStatus.verified,
      ),
      VerificationStep(
        id: VerificationStepId.email,
        status: VerificationStepStatus.verified,
      ),
      VerificationStep(
        id: VerificationStepId.identity,
        status: VerificationStepStatus.inProgress,
      ),
      VerificationStep(
        id: VerificationStepId.selfie,
        status: VerificationStepStatus.pending,
      ),
      VerificationStep(
        id: VerificationStepId.licence,
        status: VerificationStepStatus.optional,
      ),
    ],
  );

  /// Identity done, selfie now under way.
  static const MockVerificationScenario identityComplete = VerificationState(
    // Display value only — chosen for the demo, not calculated.
    displayTrustScore: 82,
    steps: <VerificationStep>[
      VerificationStep(
        id: VerificationStepId.phone,
        status: VerificationStepStatus.verified,
      ),
      VerificationStep(
        id: VerificationStepId.email,
        status: VerificationStepStatus.verified,
      ),
      VerificationStep(
        id: VerificationStepId.identity,
        status: VerificationStepStatus.verified,
      ),
      VerificationStep(
        id: VerificationStepId.selfie,
        status: VerificationStepStatus.inProgress,
      ),
      VerificationStep(
        id: VerificationStepId.licence,
        status: VerificationStepStatus.optional,
      ),
    ],
  );

  /// Every required step complete; the licence stays optional.
  static const MockVerificationScenario allRequiredComplete = VerificationState(
    // Display value only — chosen for the demo, not calculated.
    displayTrustScore: 100,
    steps: <VerificationStep>[
      VerificationStep(
        id: VerificationStepId.phone,
        status: VerificationStepStatus.verified,
      ),
      VerificationStep(
        id: VerificationStepId.email,
        status: VerificationStepStatus.verified,
      ),
      VerificationStep(
        id: VerificationStepId.identity,
        status: VerificationStepStatus.verified,
      ),
      VerificationStep(
        id: VerificationStepId.selfie,
        status: VerificationStepStatus.verified,
      ),
      VerificationStep(
        id: VerificationStepId.licence,
        status: VerificationStepStatus.optional,
      ),
    ],
  );

  /// The demo script, in order.
  static const List<MockVerificationScenario> script =
      <MockVerificationScenario>[
        initial,
        identityComplete,
        allRequiredComplete,
      ];
}
