// ─────────────────────────────────────────────────────────────
// RideMate — A discovered journey
//
// Built from DiscoveredRoute, which is built from the wire. Everything on this
// card is a fact the backend owns.
//
// WHAT THE DESIGN'S MATCH CARD SHOWED THAT THIS DOES NOT
//
// A rating, a verified badge, a trip count, a shared-route count, a trust
// score, an approval rate, a compatibility percentage, walking minutes, a
// distance and a cost. Eleven claims about a stranger, none of which any
// endpoint knows. They were transcribed from the comp and were harmless while
// the whole card was invented; beside a real member's real name they are the
// app vouching for somebody it knows nothing about, on the one screen whose
// entire purpose is deciding whether to travel with them.
//
// So the card was rebuilt rather than thinned. Narrowing MatchCard would have
// left every one of those fields in the type, waiting for a widget to read one
// again.
//
// IT STILL GOES NOWHERE, AND THAT IS STILL DELIBERATE
//
// Route Details is fixture-backed: opening it from a real result would show a
// real member's name above an invented vehicle, an invented plate and an
// invented cost. A truthful card that goes nowhere is better than a tap into
// fabricated details, so the card body is inert.
//
// ONE ACTION, AND ONLY WHEN IT IS TRUE
//
// Phase 13 gave it a seat request. The action appears only for a one-off
// journey that has not departed and that this member has not already asked
// about — three facts the card owns, checked here rather than assumed from the
// endpoint's own filtering.
//
// A weekday plan gets no action at all: it has no single departure to hold a
// seat on, and a disabled control would imply the feature exists and is being
// withheld from this member.
//
// Once an asking exists the action is gone for good. A member may create one
// seat request per journey for that journey's lifetime, so `declined` and
// `withdrawn` are ends — offering to ask again would be a control the server
// would refuse.
//
// INITIALS ARE THE SERVER'S
//
// Rendered as received. A guard asserts nothing under features/discovery
// computes them.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/rm_text_conventions.dart';
import '../../../../core/routes/departure.dart';
import '../../../../core/routes/discovered_route.dart';
import '../../../../core/routes/published_route.dart';
import '../../../../core/routes/ride_rule.dart';
import '../../../../core/seat_requests/seat_request.dart';
import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_avatar.dart';
import '../../../../core/widgets/rm_button.dart';
import '../../../../core/widgets/rm_card.dart';
import '../../../../core/widgets/rm_chip.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../seat_requests/application/seat_request_action_providers.dart';

/// One journey somebody else published.
class DiscoveredRouteCard extends StatelessWidget {
  const DiscoveredRouteCard({required this.route, super.key});

  final DiscoveredRoute route;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmColors c = context.rmColors;

    final String journey = RmTextConventions.route(
      route.origin.label,
      route.destination.label,
    );
    final String departure = _departure(l10n);
    final String seats = l10n.discoverySeatsOffered(route.seatsOffered);

    final Widget? action = _action(context, l10n, c);

    return RmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // One announcement for the journey, so a screen reader reads it as a
          // journey rather than six unrelated fragments. The action sits
          // OUTSIDE this, because a control that a container swallows is a
          // control a screen reader cannot describe or reach.
          Semantics(
            container: true,
            label: l10n.discoveryCardSemanticLabel(
              route.driver.displayName,
              journey,
              departure,
              seats,
            ),
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      RmAvatar(
                        // The server's letters, as they arrived.
                        initials: route.driver.initials,
                        // No verification badge: nothing verifies anybody.
                        verification: RmVerification.none,
                        identity: RmIdentity.purple,
                      ),
                      const SizedBox(width: RmSpacing.sm),
                      Expanded(
                        child: Text(
                          route.driver.displayName,
                          style: RmTypography.body.copyWith(color: c.ink),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: RmSpacing.sm),
                  Text(
                    journey,
                    style: RmTypography.body.copyWith(color: c.ink),
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
                  // Absent, not empty, when the driver selected nothing. A rule set
                  // to false says only that they did not choose it.
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
          if (action != null) ...<Widget>[
            const SizedBox(height: RmSpacing.sm),
            action,
          ],
        ],
      ),
    );
  }

  /// The one thing this card can do, or what became of it.
  ///
  /// Outside the `ExcludeSemantics` above, so the action keeps its own
  /// semantics while the journey is announced as one piece.
  Widget? _action(BuildContext context, AppLocalizations l10n, RmColors c) {
    // The asking for the day this card would ask about — a one-off route's own
    // date. A plan has one per day it runs and this card has no way to choose
    // between them yet, which is why the recurring gate below still stands.
    //
    // FOR F2. Once a passenger can pick a service date, the card reads the
    // asking for the date they picked and the gate goes.
    final MySeatRequestSummary? asked = route.seatRequestOn(
      route.departureDate,
    );

    // An asking exists. The card says what the server says about it, and
    // offers nothing: this journey cannot be asked about again.
    if (asked != null) {
      return _Status(
        label: switch (asked.status) {
          SeatRequestStatus.pending => l10n.seatRequestPending,
          SeatRequestStatus.accepted => l10n.seatRequestAccepted,
          SeatRequestStatus.declined => l10n.seatRequestDeclined,
          SeatRequestStatus.withdrawn => l10n.seatRequestWithdrawn,
        },
      );
    }

    // No single departure to hold a seat on. Stated once, quietly, rather
    // than as a disabled control.
    if (route.recurrence != Recurrence.once) {
      return _Status(label: l10n.seatRequestRecurringUnsupported, muted: true);
    }

    // The server excludes departed journeys, but a page can be read and then
    // sat on. The card owns this fact, so it checks it.
    if (route.departureState != DepartureState.upcoming) return null;

    // An asking is for a journey, so the control cannot exist without the day
    // it is about. A one-off route always carries one — the decoder refuses a
    // route that does not — so this narrows a type rather than handling a case,
    // and the answer to the impossible state is no control at all rather than
    // one that cannot name what it is asking for.
    final DepartureDate? serviceDate = route.departureDate;

    if (serviceDate == null) return null;

    return _RequestButton(routeId: route.id, serviceDate: serviceDate);
  }

  /// The departure as the driver chose it.
  ///
  /// A recurring commute has a time and no date, and saying so is the whole
  /// difference between "every weekday at 08:00" and a date nobody picked.
  String _departure(AppLocalizations l10n) {
    final DepartureDate? date = route.departureDate;

    // The wall clock exactly as published — no zone conversion, and no
    // formatting that would imply an instant this client may not compute. Same
    // shape My Routes uses, because it is the same fact.
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

/// The action, and the failure it may leave behind.
///
/// A `ConsumerWidget` of its own rather than state on the card: only this
/// journey's attempt should rebuild when it changes, and the card itself has
/// nothing to watch.
class _RequestButton extends ConsumerWidget {
  const _RequestButton({required this.routeId, required this.serviceDate});

  final String routeId;

  /// The day this asking is for. Part of the intent's identity, so two dates
  /// of one plan never share an attempt or the id it is carrying.
  final DepartureDate serviceDate;

  JourneyKey get _journey => (routeId: routeId, serviceDate: serviceDate);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmColors c = context.rmColors;
    final SeatRequestAttempt? attempt = ref.watch(
      seatRequestActionProvider.select(
        (Map<JourneyKey, SeatRequestAttempt> all) => all[_journey],
      ),
    );

    final bool sending = attempt is SeatRequestSending;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        RmButton(
          label: sending ? l10n.seatRequestSending : l10n.seatRequestAsk,
          // The in-card size the design uses for a card action, and the
          // lower-ranked variant: a solid brand fill would make asking for a
          // seat look like the screen's single main action, and there are as
          // many of these as there are results.
          size: RmButtonSize.sm,
          variant: RmButtonVariant.outline,
          // Null disables it. A tap while one is in flight would be the same
          // asking sent twice — the server would recognise it, but the member
          // would have watched two spinners to find that out.
          onPressed: sending
              ? null
              : () => ref
                    .read(seatRequestActionProvider.notifier)
                    .request(_journey),
          loading: sending,
        ),
        if (attempt is SeatRequestFailed) ...<Widget>[
          const SizedBox(height: RmSpacing.xs),
          Text(
            _failureLabel(l10n, attempt),
            style: RmTypography.caption.copyWith(color: c.danger),
          ),
        ],
      ],
    );
  }

  /// What went wrong, from the reason the server named.
  ///
  /// Matched on the machine string, never on `message` — which is
  /// developer-facing English no client displays — and never on the status,
  /// which several of these share. Anything this build does not recognise
  /// falls back to saying only that the request was not sent, which is the one
  /// thing that is certainly true.
  String _failureLabel(AppLocalizations l10n, SeatRequestFailed attempt) =>
      switch (attempt.refusal) {
        SeatRequestRefusal.ownRoute => l10n.seatRequestOwnRoute,
        SeatRequestRefusal.routeFull => l10n.seatRequestRouteFull,
        SeatRequestRefusal.routeUnavailable => l10n.seatRequestUnavailable,
        _ => l10n.seatRequestFailed,
      };
}

/// What became of an asking, or why one cannot be made.
///
/// Text, not a control: there is nothing here to do.
class _Status extends StatelessWidget {
  const _Status({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return Text(
      label,
      style: RmTypography.caption.copyWith(color: muted ? c.sub : c.ink),
    );
  }
}
