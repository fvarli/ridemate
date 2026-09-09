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
// IT IS NOT TAPPABLE, AND THAT IS DELIBERATE
//
// Route Details is still fixture-backed: opening it from a real result would
// show a real member's name above an invented vehicle, an invented plate and an
// invented cost. A truthful card that goes nowhere is better than a tap into
// fabricated details. There is no seat-request action either — asking for a
// seat is Phase 13, and a button that did nothing would be worse than none.
//
// INITIALS ARE THE SERVER'S
//
// Rendered as received. A guard asserts nothing under features/discovery
// computes them.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/format/rm_text_conventions.dart';
import '../../../../core/routes/departure.dart';
import '../../../../core/routes/discovered_route.dart';
import '../../../../core/routes/ride_rule.dart';
import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_avatar.dart';
import '../../../../core/widgets/rm_card.dart';
import '../../../../core/widgets/rm_chip.dart';
import '../../../../l10n/app_localizations.dart';

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

    return RmCard(
      // One announcement, so a screen reader reads a journey rather than six
      // unrelated fragments. Nothing here is actionable, so there is no control
      // whose own semantics this could swallow.
      child: Semantics(
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
              Text(journey, style: RmTypography.body.copyWith(color: c.ink)),
              const SizedBox(height: RmSpacing.xs),
              Text(
                departure,
                style: RmTypography.caption.copyWith(color: c.sub),
              ),
              const SizedBox(height: RmSpacing.xs),
              Text(seats, style: RmTypography.caption.copyWith(color: c.sub)),
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
    );
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
