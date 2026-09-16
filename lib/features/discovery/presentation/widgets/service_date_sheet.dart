// ─────────────────────────────────────────────────────────────
// RideMate — Choosing which day to ask about
//
// A plan is not a journey. A weekday commute runs again tomorrow, so asking for
// a seat on one means naming a day — and until F2 the card had no way to, which
// is why a recurring result offered nothing at all.
//
// NOT A CALENDAR, AND THE HORIZON IS WHY
//
// The server offers at most fifteen calendar dates, of which around eleven are
// weekdays. A date picker for eleven options would be a month grid with most of
// it unselectable, and every greyed-out square would invite the member to work
// out a rule nobody wrote down. A short list of the days that are actually open
// says the same thing without the puzzle.
//
// THE DAYS ARE THE SERVER'S, IN THE SERVER'S ORDER
//
// Nothing here generates, filters or sorts a date. The list arrives decided —
// see DiscoveredRoute.requestableServiceDates for why it must — and this sheet
// renders it. There is no clock in this file.
//
// IT SAYS NOTHING ABOUT SEATS
//
// An option is a day this member may ask about. It is not a day with room, a
// day likely to be accepted, or a day the app recommends: none of those are
// things any endpoint knows, and a subtitle implying one would be the app
// vouching for an answer the driver has not given yet.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/format/rm_formatters.dart';
import '../../../../core/routes/departure.dart';
import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../l10n/app_localizations.dart';

/// Asks which of [days] the member wants a seat on.
///
/// Resolves to the chosen day, or null when the sheet is dismissed — by
/// gesture, by the back control, or by tapping away. Null means no day was
/// chosen and therefore nothing is asked for: dismissing must never be read as
/// picking the first option, which is the whole reason this returns a value
/// rather than calling back.
Future<DepartureDate?> chooseServiceDate(
  BuildContext context, {
  required List<DepartureDate> days,
}) => showModalBottomSheet<DepartureDate>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (BuildContext context) => _ServiceDateSheet(days: days),
);

class _ServiceDateSheet extends StatelessWidget {
  const _ServiceDateSheet({required this.days});

  final List<DepartureDate> days;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmColors c = context.rmColors;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          RmSpacing.screenGutter,
          RmSpacing.xl,
          RmSpacing.screenGutter,
          RmSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                l10n.seatRequestChooseDayTitle,
                style: RmTypography.titleSm.copyWith(color: c.ink),
              ),
            ),
            const SizedBox(height: RmSpacing.sm),
            Text(
              l10n.seatRequestChooseDayBody,
              style: RmTypography.body.copyWith(color: c.sub),
            ),
            const SizedBox(height: RmSpacing.md),
            // Scrollable rather than fixed: eleven options plus large text
            // settings is taller than a short phone, and a list that cannot
            // reach its last day would hide the end of the horizon.
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: days.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: RmSpacing.xs),
                itemBuilder: (BuildContext context, int index) =>
                    _DayOption(day: days[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One day, as something to choose.
class _DayOption extends StatelessWidget {
  const _DayOption({required this.day});

  final DepartureDate day;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    // The reader's language and the reader's calendar conventions. No zone is
    // involved: a calendar day does not have one, and converting it would be
    // this client second-guessing which day the server meant.
    final String label = RmFormatters.of(
      context,
    ).weekdayDate(day.year, day.month, day.day);

    return Semantics(
      button: true,
      // The date is the whole content of the control, so the announced label
      // is the same text a sighted member reads. Nothing about this option is
      // carried by position or colour alone.
      label: label,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(day),
        borderRadius: BorderRadius.circular(RmSpacing.sm),
        child: Padding(
          // A full-width row with vertical padding, so the target is the
          // comfortable size a list row should be rather than the height of
          // one line of text.
          padding: const EdgeInsets.symmetric(
            vertical: RmSpacing.sm,
            horizontal: RmSpacing.xs,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: ExcludeSemantics(
                  child: Text(
                    label,
                    style: RmTypography.body.copyWith(color: c.ink),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
