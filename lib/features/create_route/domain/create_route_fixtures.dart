// ─────────────────────────────────────────────────────────────
// RideMate — Create route fixtures
//
// PRESENTATION FIXTURES. NOT BUSINESS RULES.
//
// Everything here reproduces the approved Create Route screen so the driver
// flow can be seen and reviewed on a device. None of it is policy, and none of
// it is computed from anything else.
// ─────────────────────────────────────────────────────────────

import '../../../core/places/mock_places.dart';
import 'create_route_draft.dart';

/// The per-person cost share the design displays.
///
/// PRESENTATION FIXTURE — REQUIRES LEGAL AND PRODUCT REVIEW BEFORE IT BECOMES
/// EDITABLE.
///
/// The design shows this amount read-only, captioned `Önerilen · maliyet
/// paylaşımı`, and it stays that way. Making driver-set cost sharing editable
/// may materially affect how RideMate is characterized for regulatory
/// purposes, so it needs legal and product review before implementation rather
/// than a decision taken in the client layer.
///
/// The value is NOT derived from distance, duration, seats, recurrence, route,
/// vehicle or anything else. There is deliberately no `calculateFare`,
/// `calculatePrice`, `recommendedPrice` or pricing engine in this codebase,
/// and no total is displayed anywhere — `seats × costShare` would be both a
/// formula the client may not author and a driver-earnings claim this product
/// does not make.
const int kSuggestedCostSharePerPerson = 18;

/// The departure the recurrence summary shows: `Pzt–Cum · 08:00 kalkış`.
///
/// Fixtures, not a schedule engine. The approved screen has no date or time
/// control at all, so this is the only departure information it can express.
/// That gap is recorded in docs/design-system.md §8.
const int kRecurrenceDepartureHour = 8;
const int kRecurrenceDepartureMinute = 0;

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

/// The journey the design shows already filled in.
const CreateRouteDraft kInitialCreateRouteDraft = CreateRouteDraft(
  origin: MockPlaces.atasehir,
  destination: MockPlaces.maslak,
  // The design draws the toggle on.
  repeatsOnWeekdays: true,
  seats: 3,
  // The design selects exactly one rule.
  rules: <RideRuleId>{RideRuleId.noSmoking},
);
