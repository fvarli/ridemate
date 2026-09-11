// ─────────────────────────────────────────────────────────────
// RideMate — Why the server would not move a journey's lifecycle
//
// One mapping, shared by the card and the Trip Status screen, so the same
// refusal cannot be explained two different ways on two surfaces.
//
// BRANCHES ON THE MACHINE STRING, AND ON NOTHING ELSE
//
// Never on the status: all six refusals arrive as 409, so it distinguishes
// nothing. Never on the server's `message`, which is developer-facing English
// the contract forbids clients to display — and which RmFailure does not carry
// at all, so there is nothing here to reach for by accident.
//
// EXHAUSTIVE ON PURPOSE
//
// No `_` arm. A seventh reason added to TripRefusal makes this stop compiling
// and forces someone to decide what it says, rather than quietly joining a
// generic pile. Forward compatibility is handled a layer down: a reason this
// build has never heard of arrives as null from `tripRefusal` and lands on the
// generic seam below.
// ─────────────────────────────────────────────────────────────

import '../../../core/api/rm_error_copy.dart';
import '../../../core/api/rm_failure.dart';
import '../../../core/trips/trip_decoder.dart';
import '../../../core/trips/trip_lifecycle.dart';
import '../../../l10n/app_localizations.dart';

/// What to put in front of the driver when a lifecycle command is refused.
String tripRefusalCopy(AppLocalizations l10n, RmFailure failure) =>
    switch (failure.tripRefusal) {
      // Reachable from Start.
      TripRefusal.departureNotReached => l10n.myRoutesStartDepartureNotReached,
      TripRefusal.recurringRouteUnsupported =>
        l10n.myRoutesStartRecurringUnsupported,
      TripRefusal.routeUnavailable => l10n.myRoutesStartRouteUnavailable,
      // Reachable from Complete and Abort.
      TripRefusal.tripNotStarted => l10n.myRoutesTripNotStarted,
      // Reachable from all three: the journey already ended, so the row that
      // offered the command was stale. The ending itself is re-read from the
      // server rather than built from the reason — see MyRoutesController.
      TripRefusal.alreadyCompleted => l10n.myRoutesTripAlreadyCompleted,
      TripRefusal.alreadyAborted => l10n.myRoutesTripAlreadyAborted,
      // No reason, or one this build does not know.
      null => failure.copy(l10n),
    };
