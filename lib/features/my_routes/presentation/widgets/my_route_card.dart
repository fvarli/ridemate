// ─────────────────────────────────────────────────────────────
// RideMate — One published journey
//
// WHAT IS NOT ON THIS CARD
//
// No cost, no available seats, no driver name, no rating, no verified badge,
// no trust score, no trip count, no vehicle, no plate, no match percentage, no
// walking time, no map. Not trimmed for space: RideMate does not have any of
// them, and one plausible number beside real departure times is what makes the
// rest of a screen look equally true.
//
// `seats_offered` is labelled as OFFERED. It is what the driver said they have
// room for, not what is left — nothing has requested a seat yet, and there is
// no seat-request model to subtract from it.
//
// `timezone` is decoded and deliberately not drawn. The card has no use for
// it, and putting it on screen would invite someone to compute with it.
//
// A RULE THAT IS OFF IS NOT A RULE
//
// Only the rules the driver selected become chips. `no_pets: false` says they
// did not choose that rule; it does not say pets are welcome, and rendering
// the inverse would put a promise on the card that nobody made. When nothing
// is selected the row is absent entirely rather than empty.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/format/rm_text_conventions.dart';
import '../../../../core/routes/departure.dart';
import '../../../../core/routes/my_route.dart';
import '../../../../core/routes/published_route.dart';
import '../../../../core/routes/ride_rule.dart';
import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/trips/trip_lifecycle.dart';
import '../../../../core/widgets/rm_button.dart';
import '../../../../core/widgets/rm_card.dart';
import '../../../../core/widgets/rm_chip.dart';
import '../../../../core/widgets/rm_status_pill.dart';
import '../../../../l10n/app_localizations.dart';

class MyRouteCard extends StatelessWidget {
  const MyRouteCard({
    required this.row,
    required this.isCancelling,
    required this.isChangingTrip,
    required this.onCancel,
    required this.onStart,
    required this.onComplete,
    required this.onAbort,
    required this.onOpenRequests,
    required this.onOpenTrip,
    super.key,
  });

  /// The journey and whether it was made — the owner's projection, which is
  /// the only one carrying a lifecycle.
  final MyRoute row;

  final bool isCancelling;

  /// Whether any lifecycle command for this journey is in flight.
  ///
  /// One flag for all three: only one of them is ever offered at a time, so
  /// a per-verb flag would be three ways to say the same thing.
  final bool isChangingTrip;

  final VoidCallback onCancel;

  /// Tells the server the journey is under way. Whether it may be is the
  /// server's answer, not this card's.
  final VoidCallback onStart;

  /// Says the journey was made.
  final VoidCallback onComplete;

  /// Says it was not. No reason is collected; none is stored.
  final VoidCallback onAbort;

  /// Opens who has asked for a seat on this journey.
  final VoidCallback onOpenRequests;

  /// Opens this journey's own lifecycle, in full.
  final VoidCallback onOpenTrip;

  PublishedRoute get route => row.route;

  /// Whether this journey can still be withdrawn.
  ///
  /// READ, NEVER COMPUTED. Both halves come from the response: the server
  /// decides what `past` means, in the route's own timezone, and it is the only
  /// party that can. A client answering this locally would eventually offer
  /// Cancel on a journey the API refuses to cancel, or hide it on one it would
  /// have accepted — and would do so silently.
  bool get _canCancel =>
      route.status == RouteStatus.published &&
      route.departureState == DepartureState.upcoming;

  /// Whether there is a journey left to begin.
  ///
  /// The whole condition. Everything that decides whether Start will be
  /// ACCEPTED — the departure instant in the route's own timezone, whether the
  /// plan recurs, whether it still stands — belongs to the backend, which
  /// answers with a reason this screen can say out loud. A client that
  /// pre-judged any of it would eventually hide a Start the API would have
  /// taken, and would do so silently.
  bool get _canStart => row.trip.state == TripState.notStarted;

  /// Whether there is a journey under way to end.
  ///
  /// The same rule read the other way, and the same reasoning: a journey the
  /// server calls `in_progress` is exactly one that can be completed or
  /// abandoned, and nothing else here has a say. Both endings are offered
  /// together because the driver — not this screen — knows which happened.
  bool get _canEnd => row.trip.state == TripState.inProgress;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmColors c = context.rmColors;

    final String journey = RmTextConventions.route(
      route.origin.label,
      route.destination.label,
    );
    final String departure = _departure(l10n);
    final String seats = l10n.myRoutesSeatsOffered(route.seatsOffered);
    final String status = _status(l10n);
    final String trip = _trip(l10n);

    return RmCard(
      // The ordinary "this row opens its detail" gesture, so the lifecycle in
      // full does not need a fifth control on an already crowded card.
      //
      // Deliberately NO `semanticLabel` here: RmCard excludes its subtree's
      // semantics whenever one is given, which would swallow every action
      // button on this card. The journey's own description stays on the inner
      // container below, where it does not.
      onTap: onOpenTrip,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // The description reads as ONE thing, so a screen reader announces a
          // journey rather than four unrelated fragments. Only this part is
          // collapsed: wrapping the whole card would swallow the Cancel
          // button's own semantics and leave it unreachable.
          Semantics(
            container: true,
            // The lifecycle is inside the excluded subtree, so it has to be
            // named here or a screen reader would be told less than the screen
            // shows.
            label: l10n.myRoutesCardSemanticLabel(
              journey,
              departure,
              seats,
              status,
              trip,
            ),
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          journey,
                          style: RmTypography.body.copyWith(color: c.ink),
                        ),
                      ),
                      const SizedBox(width: RmSpacing.sm),
                      RmStatusPill(
                        label: status,
                        tone: _tone,
                        dotColor: _dotColor(c),
                      ),
                    ],
                  ),
                  const SizedBox(height: RmSpacing.xs),
                  Text(
                    departure,
                    style: RmTypography.caption.copyWith(color: c.sub),
                  ),
                  const SizedBox(height: RmSpacing.xs),
                  Text(
                    seats,
                    style: RmTypography.caption.copyWith(color: c.sub),
                  ),
                  const SizedBox(height: RmSpacing.xs),
                  // Subordinate to the journey, and deliberately not a second
                  // pill: the pill above answers whether the plan still
                  // stands, and this answers whether it was made. They are
                  // different questions and a route can say anything about one
                  // while saying anything about the other.
                  Text(
                    trip,
                    style: RmTypography.caption.copyWith(color: c.sub),
                  ),
                  // Absent, not empty, when the driver selected nothing.
                  if (route.rules.isNotEmpty) ...<Widget>[
                    const SizedBox(height: RmSpacing.sm),
                    Wrap(
                      spacing: RmSpacing.xs,
                      runSpacing: RmSpacing.xs,
                      children: <Widget>[
                        for (final RideRuleId id in RideRuleId.values)
                          if (route.rules.contains(id))
                            RmChip(label: _ruleLabel(l10n, id), compact: true),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: RmSpacing.md),
          // Wrap, not Row: two labelled actions do not fit beside each other at
          // the narrow width in every locale — found by the RTL/narrow test,
          // overflowing by 11px. They stack rather than being truncated,
          // because a clipped action label is worse than a taller card.
          Wrap(
            alignment: WrapAlignment.end,
            spacing: RmSpacing.sm,
            runSpacing: RmSpacing.sm,
            children: <Widget>[
              // Offered on every journey, including one that was cancelled or
              // has departed: people asked, and the driver still has to be able
              // to see and answer them. Whether a request can still be decided
              // is the request's own business, and the server's.
              RmButton(
                label: l10n.routeRequestsOpen,
                semanticLabel: l10n.routeRequestsOpenSemanticLabel(journey),
                size: RmButtonSize.sm,
                variant: RmButtonVariant.outline,
                onPressed: onOpenRequests,
              ),
              // Offered on exactly the server's own answer, and on nothing
              // else. Not the departure clock — the device's or the server's:
              // `departureState` would hide Start precisely when the backend
              // allows it, since a journey may only begin once its departure
              // has been reached. Not the route's status either: a withdrawn
              // journey answers `route_unavailable`, which is the server
              // saying so rather than this card guessing it.
              if (_canStart)
                RmButton(
                  label: l10n.myRoutesStartTrip,
                  semanticLabel: l10n.myRoutesStartTripSemanticLabel(journey),
                  size: RmButtonSize.sm,
                  loading: isChangingTrip,
                  onPressed: onStart,
                ),
              if (_canEnd) ...<Widget>[
                RmButton(
                  label: l10n.myRoutesCompleteTrip,
                  semanticLabel: l10n.myRoutesCompleteTripSemanticLabel(
                    journey,
                  ),
                  size: RmButtonSize.sm,
                  loading: isChangingTrip,
                  onPressed: onComplete,
                ),
                RmButton(
                  label: l10n.myRoutesAbortTrip,
                  semanticLabel: l10n.myRoutesAbortTripSemanticLabel(journey),
                  size: RmButtonSize.sm,
                  variant: RmButtonVariant.outline,
                  loading: isChangingTrip,
                  onPressed: onAbort,
                ),
              ],
              if (_canCancel)
                RmButton(
                  label: l10n.myRoutesCancel,
                  // Names the journey, so the action is unambiguous when
                  // several cards each offer one.
                  semanticLabel: l10n.myRoutesCancelSemanticLabel(journey),
                  size: RmButtonSize.sm,
                  variant: RmButtonVariant.outline,
                  loading: isCancelling,
                  onPressed: onCancel,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// A withdrawn journey reads as closed; one that still stands reads as live.
  ///
  /// Past is deliberately NOT given the heavy treatment: a weekday commute is
  /// never past, and a one-off that has departed still stands — nobody
  /// withdrew it. Only cancellation is a decision, and only it looks like one.
  RmStatusPillTone get _tone => switch (route.status) {
    RouteStatus.cancelled => RmStatusPillTone.ink,
    RouteStatus.published => RmStatusPillTone.info,
  };

  /// The dot is green ONLY when the journey is still ahead.
  ///
  /// It defaults to success green, which beside "İptal edildi" would put a
  /// positive signal on a route the member withdrew — the pill would contradict
  /// its own label.
  Color _dotColor(RmColors c) =>
      route.status == RouteStatus.published &&
          route.departureState == DepartureState.upcoming
      ? c.success
      : c.muted;

  /// What the pill says.
  ///
  /// Cancelled wins over past: a withdrawn journey is withdrawn regardless of
  /// when it was going to leave, and saying "past" would describe the clock
  /// rather than the decision the member made.
  String _status(AppLocalizations l10n) => switch (route.status) {
    RouteStatus.cancelled => l10n.myRoutesStatusCancelled,
    RouteStatus.published => switch (route.departureState) {
      DepartureState.past => l10n.myRoutesStatusPast,
      DepartureState.upcoming => l10n.myRoutesStatusPublished,
    },
  };

  /// Whether the journey was made, in the member's own language.
  ///
  /// `Başladı` means the driver said so and the server recorded it. It does
  /// NOT say the car is moving, that anybody boarded, that the driver is at
  /// the origin, or that any location is known — none of which this product
  /// knows. `Yarıda bırakıldı` is separate from `İptal edildi`: one is a
  /// journey abandoned, the other a plan withdrawn.
  String _trip(AppLocalizations l10n) => switch (row.trip.state) {
    TripState.notStarted => l10n.myRoutesTripStateNotStarted,
    TripState.inProgress => l10n.myRoutesTripStateInProgress,
    TripState.completed => l10n.myRoutesTripStateCompleted,
    TripState.aborted => l10n.myRoutesTripStateAborted,
  };

  /// When it leaves, in the terms the driver chose.
  ///
  /// A weekday commute names the pattern; a one-off names its date. Both print
  /// the wall clock exactly as published — no zone conversion, no formatting
  /// that would imply an instant this client is not entitled to compute.
  String _departure(AppLocalizations l10n) {
    final DepartureDate? date = route.departureDate;

    return switch (route.recurrence) {
      Recurrence.weekdays =>
        '${l10n.myRoutesRecurrenceWeekdays} · ${route.departureTime.hhMm}',
      Recurrence.once when date != null =>
        '${date.iso} · ${route.departureTime.hhMm}',
      Recurrence.once => route.departureTime.hhMm,
    };
  }

  String _ruleLabel(AppLocalizations l10n, RideRuleId id) => switch (id) {
    RideRuleId.noSmoking => l10n.createRouteRuleNoSmoking,
    RideRuleId.musicOk => l10n.createRouteRuleMusicOk,
    RideRuleId.noPets => l10n.createRouteRuleNoPets,
    RideRuleId.quiet => l10n.createRouteRuleQuiet,
  };
}
