// ─────────────────────────────────────────────────────────────
// RideMate — Create route fixtures
//
// PRESENTATION FIXTURES. NOT BUSINESS RULES.
//
// What is left here reproduces the approved Create Route screen so the driver
// flow can be seen and reviewed on a device. None of it is policy, and none of
// it is computed from anything else.
//
// WHAT LEFT, AND WHY
//
// The suggested per-person cost share is gone. This screen is becoming a real
// publication form, and a fixture amount sitting beside fields the server will
// own would read as though it belonged to the published journey. It does not:
// no driver chose it and no approved policy produced it. Cost sharing stays
// visible on the screens that remain wholly fixture-backed, where nothing on
// them claims to be server truth.
//
// The fixed 08:00 departure is gone for the same reason turned around. It
// existed because the screen had no way to ask, and it was honest only while
// nothing was published. Now the driver picks a time, so a default would be a
// choice attributed to somebody who never made it.
// ─────────────────────────────────────────────────────────────

import 'create_route_draft.dart';
import 'departure.dart';

/// The lowest seat count the screen allows.
///
/// The screen is about sharing a seat, so zero or negative free seats is
/// meaningless. This is the screen's own semantic invariant, NOT a vehicle
/// capacity or a product policy.
///
/// There is deliberately NO ceiling constant: any maximum would invent a
/// capacity rule the design does not state. When a vehicle model exists, the
/// real limit arrives as domain data rather than as a number chosen here.
const int kSeatsFloor = 1;

/// The state Create Route opens in.
///
/// The endpoints and the departure are deliberately empty. Everything else is
/// the design's own starting state; where a journey runs and when it leaves
/// are the driver's to say, and seeding either would put words in their mouth
/// before they had opened the screen.
const CreateRouteDraft kInitialCreateRouteDraft = CreateRouteDraft(
  // Unselected. The catalogue is the server's, so nothing can be chosen
  // before it arrives — and a fixture sitting here would be a choice the
  // driver never made and the server would not recognise.
  origin: null,
  destination: null,
  // The design draws the toggle on.
  recurrence: Recurrence.weekdays,
  departureDate: null,
  departureTime: null,
  seats: 3,
  // The design selects exactly one rule.
  rules: <RideRuleId>{RideRuleId.noSmoking},
);
