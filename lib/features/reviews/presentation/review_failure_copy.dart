// ─────────────────────────────────────────────────────────────
// RideMate — Why a rating did not land, in the member's language
//
// One mapping, shared by the sheet and both listings, so the same refusal
// cannot be explained two different ways on two surfaces.
//
// BRANCHES ON THE MACHINE STRING, AND ON NOTHING ELSE
//
// Never on the status — all five refusals arrive as 409 — and never on the
// server's message, which `RmFailure` does not carry at all. A 404 names no
// refusal and falls to the generic seam: presenting it as "already reviewed"
// would tell a member something the server never said.
// ─────────────────────────────────────────────────────────────

import '../../../core/api/rm_error_copy.dart';
import '../../../core/api/rm_failure.dart';
import '../../../core/reviews/review.dart';
import '../../../core/reviews/review_decoder.dart';
import '../../../l10n/app_localizations.dart';

/// What to put in front of the member when a rating was refused.
String reviewFailureCopy(AppLocalizations l10n, RmFailure failure) {
  // Nobody knows whether it landed, which is the one case worth retrying —
  // and the one where the id and the rating stay frozen.
  if (failure.isTransport) return l10n.reviewIndeterminate;

  return switch (failure.reviewRefusal) {
    ReviewRefusal.reviewWindowClosed => l10n.reviewWindowClosed,
    ReviewRefusal.alreadyReviewed => l10n.reviewAlreadyReviewed,
    // Both say the same thing to a member: the relationship is not in a state
    // this rates, and the row they were looking at is stale.
    ReviewRefusal.seatRequestNotAccepted ||
    ReviewRefusal.tripNotCompleted => l10n.reviewNotEligible,
    ReviewRefusal.idAlreadyUsed => l10n.reviewIdConflict,
    // No reason, one from another domain, or one this build has never heard of
    // — including a 404, which is not a refusal.
    null => failure.copy(l10n),
  };
}
