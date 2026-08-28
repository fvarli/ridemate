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
import '../../../../core/routes/published_route.dart';
import '../../../../core/routes/ride_rule.dart';
import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_button.dart';
import '../../../../core/widgets/rm_card.dart';
import '../../../../core/widgets/rm_chip.dart';
import '../../../../core/widgets/rm_status_pill.dart';
import '../../../../l10n/app_localizations.dart';

class MyRouteCard extends StatelessWidget {
  const MyRouteCard({
    required this.route,
    required this.isCancelling,
    required this.onCancel,
    super.key,
  });

  final PublishedRoute route;
  final bool isCancelling;
  final VoidCallback onCancel;

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

    return RmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // The description reads as ONE thing, so a screen reader announces a
          // journey rather than four unrelated fragments. Only this part is
          // collapsed: wrapping the whole card would swallow the Cancel
          // button's own semantics and leave it unreachable.
          Semantics(
            container: true,
            label: l10n.myRoutesCardSemanticLabel(
              journey,
              departure,
              seats,
              status,
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
          if (_canCancel) ...<Widget>[
            const SizedBox(height: RmSpacing.md),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: RmButton(
                label: l10n.myRoutesCancel,
                // Names the journey, so the action is unambiguous when several
                // cards each offer one.
                semanticLabel: l10n.myRoutesCancelSemanticLabel(journey),
                size: RmButtonSize.sm,
                variant: RmButtonVariant.outline,
                loading: isCancelling,
                onPressed: onCancel,
              ),
            ),
          ],
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
