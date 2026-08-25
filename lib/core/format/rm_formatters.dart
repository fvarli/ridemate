// ─────────────────────────────────────────────────────────────
// RideMate — Locale-aware formatting
//
// Source of truth for the CONVENTIONS: docs/claude-designs/RideMate App.dc.html
// Source of truth for the SEPARATORS: the active locale, via package:intl.
//
// LOCALE IS ALWAYS EXPLICIT. Nothing here reads Intl.defaultLocale or any
// other ambient state: RideMate has an in-app language override, and ambient
// state silently desyncs from it. Construct with
// `RmFormatters.of(context)` (or `RmFormatters(localeName)`) so the formatter
// and the visible UI can never disagree.
//
// DECISION D1 — decimal separators are locale-correct. Turkish renders 4,9 and
// 6,2 km. The design mock's anglicised "4.9" / "6.2" is a slip in the mock and
// is NOT authoritative over correct locale formatting.
//
// DECISION R2 — the currency SYMBOL POSITION follows the design, not the
// locale. The design consistently shows a prefixed "₺18"; Turkish convention
// would be "18 ₺". D1 governs separators, not symbol placement, and prefixing
// is a deliberate brand presentation choice. The separator inside the number
// is still locale-correct.
//
// TIME is always 24-hour, zero-padded, in every locale. The design uses this
// form throughout (08:25, 08:57, 09:00) and it is the right convention for a
// Turkish transport product. Formatting it directly also avoids intl's
// date-symbol initialization, which would otherwise force async work before
// the first frame.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

/// Formats numbers, money, distances, durations and times for one locale.
///
/// Cheap to construct; hold one per build rather than caching globally.
@immutable
class RmFormatters {
  const RmFormatters(this.localeName, {AppLocalizations? l10n}) : _l10n = l10n;

  /// Builds a formatter bound to the locale currently rendering [context].
  factory RmFormatters.of(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return RmFormatters(l10n.localeName, l10n: l10n);
  }

  /// e.g. `tr`, `en`.
  final String localeName;

  final AppLocalizations? _l10n;

  /// The Turkish Lira sign. Prefixed without a space — see R2 above.
  static const String liraSign = '₺';

  /// Middle dot with surrounding spaces: the design's separator for compound
  /// metadata, e.g. `Doğrulanmış · 128 yolculuk · 2 ortak rota`.
  static const String separator = ' · ';

  /// Route arrow, e.g. `Kadıköy → Levent`.
  static const String routeArrow = ' → ';

  AppLocalizations get _strings {
    final AppLocalizations? l = _l10n;
    if (l == null) {
      throw StateError(
        'This RmFormatters was built without AppLocalizations, so it cannot '
        'format localized units. Use RmFormatters.of(context).',
      );
    }
    return l;
  }

  // ── Money ──────────────────────────────────────────────────

  /// A cost share, e.g. `₺18`.
  ///
  /// Whole lira only: the design never shows kuruş. Amounts are presentation
  /// data — RideMate implements no payment behaviour.
  String money(num amount) =>
      '$liraSign${NumberFormat.decimalPattern(localeName).format(amount)}';

  /// A money amount with decimals, for cases that genuinely need them.
  String moneyPrecise(num amount, {int decimalDigits = 2}) =>
      liraSign +
      NumberFormat.decimalPatternDigits(
        locale: localeName,
        decimalDigits: decimalDigits,
      ).format(amount);

  // ── Numbers ────────────────────────────────────────────────

  /// A percentage from a 0..1 ratio.
  ///
  /// Locale-correct placement: `%94` in Turkish, `94%` in English.
  String percent(double ratio) =>
      NumberFormat.percentPattern(localeName).format(ratio);

  /// A percentage from an already-whole value (94 -> `%94`).
  String percentOf100(num value) => percent(value / 100);

  /// A whole count with grouping, e.g. `12.480` in Turkish.
  String count(num value) =>
      NumberFormat.decimalPattern(localeName).format(value);

  /// A one-decimal score, e.g. `4,9` in Turkish and `4.9` in English.
  String rating(num value) => NumberFormat.decimalPatternDigits(
    locale: localeName,
    decimalDigits: 1,
  ).format(value);

  /// A trust score, always a whole number out of 100.
  String trustScore(int value) => count(value);

  // ── Distance and duration ──────────────────────────────────

  /// A distance in kilometres, e.g. `6,2 km`.
  String distanceKm(num km) => _strings.unitDistanceKm(rating(km));

  /// A duration in whole minutes, e.g. `18 dk`.
  String durationMinutes(int minutes) =>
      _strings.unitDurationMinutes(count(minutes));

  /// An approximate duration, e.g. `~5 dk`.
  String durationApprox(int minutes) =>
      _strings.unitDurationApproxMinutes(count(minutes));

  // ── Time ───────────────────────────────────────────────────

  /// A wall-clock time, always 24-hour and zero-padded: `08:25`.
  String time(DateTime dateTime) => hourMinute(dateTime.hour, dateTime.minute);

  /// An hour and minute as 24-hour, zero-padded text.
  /// A calendar day in the reader's language, e.g. `14 Eylül 2026`.
  ///
  /// Takes the parts rather than a DateTime because the value it renders IS
  /// three numbers: a day on a calendar, with no time and no zone. A DateTime
  /// is assembled here only because that is what the formatter wants, and it
  /// never leaves this method.
  String calendarDate(int year, int month, int day) =>
      DateFormat.yMMMMd(localeName).format(DateTime(year, month, day));

  String hourMinute(int hour, int minute) => '${_pad(hour)}:${_pad(minute)}';

  static String _pad(int value) => value.toString().padLeft(2, '0');

  // ── Relative dates ─────────────────────────────────────────

  /// A natural-language relative date.
  ///
  /// The design shows only relative dates (`Bugün`, `Dün`, `Yarın`,
  /// `2 gün önce`, `1 hafta önce`) and never an absolute one. [now] is
  /// injectable so tests are not clock-dependent.
  String relativeDate(DateTime date, {required DateTime now}) {
    final int days = _wholeDaysBetween(now, date);

    if (days == 0) return _strings.dateToday;
    if (days == -1) return _strings.dateYesterday;
    if (days == 1) return _strings.dateTomorrow;

    if (days < 0) {
      final int ago = -days;
      return ago >= 7
          ? _strings.dateWeeksAgo(ago ~/ 7)
          : _strings.dateDaysAgo(ago);
    }

    // Future dates beyond tomorrow have no design treatment yet; fall back to
    // the day count rather than inventing a format.
    return _strings.dateDaysAgo(days);
  }

  /// Calendar days between two instants, ignoring the time of day.
  static int _wholeDaysBetween(DateTime from, DateTime to) {
    final DateTime a = DateTime(from.year, from.month, from.day);
    final DateTime b = DateTime(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }

  @override
  bool operator ==(Object other) =>
      other is RmFormatters && other.localeName == localeName;

  @override
  int get hashCode => localeName.hashCode;
}
