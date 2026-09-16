// ─────────────────────────────────────────────────────────────
// RideMate — One of the driver's dated journeys
//
// A JOURNEY, NOT A PLAN
//
// My Routes shows plans: recurrence, seats, rules, and whether the plan still
// stands. This shows one day of one — where it goes, which day, what time, and
// whether it was made. The two look similar and answer different questions, and
// a card that carried both would let a driver edit a plan from a page about one
// of its mornings.
//
// WHAT IS NOT ON IT
//
// No passenger count, no accepted riders, no seats remaining, no vehicle, no
// cost, no rating, no verification and no location. Not one of those is on the
// journey projection, and none is a column anywhere: a number here would be
// answered from somewhere else and read as a fact about this morning.
//
// THE DAY IS RENDERED, NEVER COMPUTED
//
// The service date arrives decided, in the route's own timezone, and is only
// ever formatted for reading. Nothing here consults a clock — not to decide
// whether the day is today, not to sort, not to grey a row out. Which journeys
// exist is the feed's answer, and it is the server's.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/format/rm_formatters.dart';
import '../../../../core/format/rm_text_conventions.dart';
import '../../../../core/journeys/journey.dart';
import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/trips/trip_state_copy.dart';
import '../../../../core/widgets/rm_card.dart';
import '../../../../l10n/app_localizations.dart';

class JourneyCard extends StatelessWidget {
  const JourneyCard({required this.journey, required this.onOpen, super.key});

  final Journey journey;

  /// Opens this journey — this one, named by its own day.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmColors c = context.rmColors;
    final RmFormatters f = RmFormatters.of(context);

    final String route = RmTextConventions.route(
      journey.origin.label,
      journey.destination.label,
    );
    final String day = f.weekdayDate(
      journey.serviceDate.year,
      journey.serviceDate.month,
      journey.serviceDate.day,
    );
    // The wall clock exactly as published. No zone conversion: a departure is
    // read in the route's own zone, which this client does not evaluate.
    final String departure = journey.departureTime.hhMm;
    final String state = tripStateLabel(l10n, journey.trip.state);

    return RmCard(
      child: Semantics(
        button: true,
        // One announcement for the whole journey, and it names the DAY. A
        // screen reader must not have to infer which morning a row is about
        // from its position in a list.
        label: l10n.journeyCardSemanticLabel(route, day, departure, state),
        onTapHint: l10n.journeyOpenSemanticLabel(route, day),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(RmSpacing.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: RmSpacing.xs),
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(route, style: RmTypography.body.copyWith(color: c.ink)),
                  const SizedBox(height: RmSpacing.xs),
                  Text(
                    '$day${RmFormatters.separator}$departure',
                    style: RmTypography.caption.copyWith(color: c.sub),
                  ),
                  const SizedBox(height: RmSpacing.xs),
                  // The lifecycle as text. Never colour or an icon alone — a
                  // started journey and an abandoned one must not differ only
                  // by a shade.
                  Text(
                    state,
                    style: RmTypography.caption.copyWith(color: c.ink),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
