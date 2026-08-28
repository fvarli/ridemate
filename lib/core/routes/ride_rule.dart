// ─────────────────────────────────────────────────────────────
// RideMate — What a driver said about the journey
//
// Shared vocabulary, not one feature's. Create Route collects these and sends
// them; My Routes reads them back. Both directions go through the one wire
// mapping below, because two mappings are two chances to disagree about what
// `music_ok` means, and the disagreement would be silent in one direction.
// ─────────────────────────────────────────────────────────────

/// The ride rules the design offers, in the order it draws them.
///
/// These are a driver's PUBLISHED RULES. Search's [SearchFilterId] carries
/// some of the same words (`Sigara yok`) as a passenger's PREFERENCE, which is
/// the opposite side of the same conversation. The two stay separate types in
/// separate features on purpose; reconciling them is a backend concern.
enum RideRuleId {
  /// `Sigara yok`
  noSmoking,

  /// `Müzik OK`
  musicOk,

  /// `Evcil hayvan yok`
  noPets,

  /// `Sessiz`
  quiet,
}

/// A policy-sensitive preference.
///
/// The client renders it and stores it in the draft; it enforces no
/// eligibility from it. Connecting a "no pets" rule to real matching or
/// eligibility may raise accessibility and non-discrimination considerations,
/// and requires legal, accessibility and product review before any backend
/// enforcement.
///
/// This records a review requirement. It states no legal conclusion — how any
/// particular law applies to this use case is not the client layer's call.
const RideRuleId kRuleNeedingPolicyReview = RideRuleId.noPets;

/// The one place a rule's wire name is decided.
///
/// Exhaustive on purpose: adding a [RideRuleId] stops this compiling rather
/// than silently sending `false` for a preference the driver expressed, or
/// dropping one on the way back. Serializing by enum name would have been
/// shorter and would have broken the day somebody renamed a case.
String rideRuleWireKey(RideRuleId id) => switch (id) {
  RideRuleId.noSmoking => 'no_smoking',
  RideRuleId.musicOk => 'music_ok',
  RideRuleId.noPets => 'no_pets',
  RideRuleId.quiet => 'quiet',
};

/// Every rule, always — the contract requires all four booleans.
Map<String, bool> rideRulesToJson(Set<RideRuleId> rules) => <String, bool>{
  for (final RideRuleId id in RideRuleId.values)
    rideRuleWireKey(id): rules.contains(id),
};

/// The rules a response says are set.
///
/// WHAT AN ABSENT RULE DOES NOT MEAN. `false` says the driver did not select
/// that rule. It does not say the opposite is true: `no_pets: false` is not
/// permission to bring a dog, and rendering it as one would put a promise on
/// screen that nobody made. Callers get the set that IS selected, and there is
/// deliberately no accessor for "the rules that are off".
Set<RideRuleId> rideRulesFromFlags(bool Function(String) isSet) => <RideRuleId>{
  for (final RideRuleId id in RideRuleId.values)
    if (isSet(rideRuleWireKey(id))) id,
};
