// ─────────────────────────────────────────────────────────────
// RideMate — What a lifecycle state is called
//
// ONE OWNER, THREE SURFACES
//
// The driver's card, the driver's trip status screen and the passenger's own
// requests all publish the same backend fact. Each having its own copy is how
// `in_progress` starts meaning something slightly different depending on which
// screen a member is looking at — and the difference would be invisible until
// somebody compared two screenshots.
//
// Takes AppLocalizations rather than a BuildContext, in the idiom of
// `core/api/rm_error_copy.dart`: a controller or a test can map a state
// without a widget tree.
//
// COPY, NOT BEHAVIOUR
//
// Nothing here says what a member may DO about a state. Whether a control is
// offered is each surface's own decision, taken from the lifecycle and from
// what the server answers when it tries — the passenger feature depends on
// this file and on nothing else the driver feature owns.
//
// `Başladı` MEANS ONE THING
//
// The driver pressed Start and the server accepted it. Not that the car is
// moving, that the driver is at the origin, that anybody boarded or was picked
// up, or that any location is known. There are no coordinates in this product.
// ─────────────────────────────────────────────────────────────

import '../../l10n/app_localizations.dart';
import 'trip_lifecycle.dart';

/// The state on its own, for a surface that has already named the subject.
String tripStateLabel(AppLocalizations l10n, TripState state) =>
    switch (state) {
      TripState.notStarted => l10n.tripStateNotStarted,
      TripState.inProgress => l10n.tripStateInProgress,
      TripState.completed => l10n.tripStateCompleted,
      TripState.aborted => l10n.tripStateAborted,
    };

/// The state with its subject, for a card that is saying several things at
/// once and must not leave a reader guessing which one this is.
String tripStateLine(AppLocalizations l10n, TripState state) =>
    l10n.tripStateLine(tripStateLabel(l10n, state));
