// ─────────────────────────────────────────────────────────────
// RideMate — When the journey leaves
//
// AN ADDITION TO THE APPROVED DESIGN, MADE FOR TRUTHFULNESS.
//
// The comp has no date or time control at all. That was liveable while the
// screen published nothing: it showed `Pzt–Cum · 08:00 kalkış` and nobody was
// misled, because nothing left the device. It stops being liveable the moment
// the screen publishes for real, because then a fixed 08:00 becomes a departure
// attributed to a driver who never chose it.
//
// So the smallest honest addition: two selector tiles, in the component Search
// already uses for exactly this shape of field. No new visual language, no new
// dependency, and no calendar widget of our own — the platform pickers speak
// Turkish because the app already ships the localization delegates.
//
// The date tile appears only for a one-off journey. A weekday commute has no
// single day to name, and offering one would invite a driver to state something
// the product cannot publish.
//
// WHAT THIS CONTROL DOES NOT DO
//
// It does not know about timezones, and it does not decide whether a departure
// has passed. Both are read in the pilot's zone, which is the server's
// configuration; a client re-deriving them would eventually disagree with the
// service about whether a journey may still be cancelled.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/format/rm_formatters.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/widgets/rm_selector_tile.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/departure.dart';

class DepartureCard extends StatelessWidget {
  const DepartureCard({
    required this.recurrence,
    required this.date,
    required this.time,
    required this.onPickDate,
    required this.onPickTime,
    super.key,
  });

  final Recurrence recurrence;
  final DepartureDate? date;
  final DepartureTime? time;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmFormatters f = RmFormatters.of(context);

    final DepartureDate? date = this.date;
    final DepartureTime? time = this.time;

    final Widget timeTile = RmSelectorTile(
      label: l10n.createRouteDepartureTimeLabel,
      // The empty state says what to do rather than showing a placeholder
      // time, which would be indistinguishable from a chosen one.
      value: time == null
          ? l10n.createRouteDepartureTimeEmpty
          : f.hourMinute(time.hour, time.minute),
      onTap: onPickTime,
    );

    if (!recurrence.needsDate) {
      return timeTile;
    }

    final String dateValue = date == null
        ? l10n.createRouteDepartureDateEmpty
        : f.calendarDate(date.year, date.month, date.day);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: RmSelectorTile(
            label: l10n.createRouteDepartureDateLabel,
            value: dateValue,
            onTap: onPickDate,
          ),
        ),
        const SizedBox(width: RmSpacing.md),
        Expanded(child: timeTile),
      ],
    );
  }
}
