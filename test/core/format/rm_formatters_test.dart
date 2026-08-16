import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/format/rm_formatters.dart';
import 'package:ridemate/l10n/app_localizations.dart';

/// Builds a formatter for [locale] with real generated localizations, so unit
/// strings are exercised rather than stubbed.
Future<RmFormatters> _formatters(String locale) async {
  final AppLocalizations l10n = await AppLocalizations.delegate.load(
    Locale(locale),
  );
  return RmFormatters(locale, l10n: l10n);
}

void main() {
  late RmFormatters tr;
  late RmFormatters en;

  setUp(() async {
    tr = await _formatters('tr');
    en = await _formatters('en');
  });

  group('Decision D1 — decimals are locale-correct', () {
    test('ratings use the locale separator, not the design mock', () {
      // The design mock writes "4.9"; Turkish must render "4,9".
      expect(tr.rating(4.9), '4,9');
      expect(en.rating(4.9), '4.9');
    });

    test('distances use the locale separator', () {
      expect(tr.distanceKm(6.2), '6,2 km');
      expect(en.distanceKm(6.2), '6.2 km');
    });

    test('grouping matches the locale', () {
      // The design shows "12.480" — which is exactly Turkish grouping.
      expect(tr.count(12480), '12.480');
      expect(en.count(12480), '12,480');
    });
  });

  group('Percentages', () {
    test('Turkish puts the sign before the number, English after', () {
      expect(tr.percentOf100(94), '%94');
      expect(en.percentOf100(94), '94%');
    });

    test('accepts a 0..1 ratio', () {
      expect(tr.percent(0.94), '%94');
      expect(tr.percent(0.81), '%81');
      expect(tr.percent(1), '%100');
    });
  });

  group('Decision R2 — money', () {
    test('the lira sign is prefixed in both locales, per the design', () {
      expect(tr.money(18), '₺18');
      expect(en.money(18), '₺18');
    });

    test('whole lira only — the design never shows kuruş', () {
      expect(tr.money(18), isNot(contains(',')));
      expect(tr.money(2100), '₺2.100');
    });

    test('the separator inside the number is still locale-correct', () {
      expect(tr.moneyPrecise(18.5, decimalDigits: 2), '₺18,50');
      expect(en.moneyPrecise(18.5, decimalDigits: 2), '₺18.50');
    });
  });

  group('Duration', () {
    test('uses localized unit words', () {
      expect(tr.durationMinutes(18), '18 dk');
      expect(en.durationMinutes(18), '18 min');
      expect(tr.durationApprox(5), '~5 dk');
      expect(en.durationApprox(5), '~5 min');
    });
  });

  group('Time — always 24-hour, zero-padded', () {
    test('matches the design in every locale', () {
      final DateTime t = DateTime(2026, 8, 16, 8, 25);
      expect(tr.time(t), '08:25');
      expect(en.time(t), '08:25');
    });

    test('pads both components', () {
      expect(tr.time(DateTime(2026, 1, 1, 9)), '09:00');
      expect(tr.time(DateTime(2026, 1, 1, 8, 57)), '08:57');
      expect(tr.time(DateTime(2026, 1, 1, 23, 5)), '23:05');
      expect(tr.time(DateTime(2026, 1, 1)), '00:00');
    });
  });

  group('Relative dates', () {
    final DateTime now = DateTime(2026, 8, 16, 12);

    test('today, yesterday and tomorrow', () {
      expect(tr.relativeDate(DateTime(2026, 8, 16, 23), now: now), 'Bugün');
      expect(tr.relativeDate(DateTime(2026, 8, 15), now: now), 'Dün');
      expect(tr.relativeDate(DateTime(2026, 8, 17), now: now), 'Yarın');
      expect(en.relativeDate(DateTime(2026, 8, 15), now: now), 'Yesterday');
    });

    test('ignores the time of day when counting calendar days', () {
      // 23:59 yesterday is still "yesterday", even though it is <24h ago.
      expect(tr.relativeDate(DateTime(2026, 8, 15, 23, 59), now: now), 'Dün');
    });

    test('days and weeks ago use ICU plurals', () {
      expect(tr.relativeDate(DateTime(2026, 8, 14), now: now), '2 gün önce');
      expect(en.relativeDate(DateTime(2026, 8, 14), now: now), '2 days ago');
      expect(tr.relativeDate(DateTime(2026, 8, 9), now: now), '1 hafta önce');
      expect(en.relativeDate(DateTime(2026, 8, 9), now: now), '1 week ago');
      expect(tr.relativeDate(DateTime(2026, 8, 2), now: now), '2 hafta önce');
    });
  });

  group('Locale is never ambient', () {
    test('two formatters disagree without touching global state', () {
      // Constructed in this order deliberately: if either read a global
      // default, the second construction would change the first's output.
      expect(tr.rating(4.9), '4,9');
      expect(en.rating(4.9), '4.9');
      expect(tr.rating(4.9), '4,9');
    });

    test('formatters compare by locale', () {
      expect(const RmFormatters('tr'), const RmFormatters('tr'));
      expect(const RmFormatters('tr'), isNot(const RmFormatters('en')));
    });

    test('a formatter without localizations fails loudly, not silently', () {
      expect(() => const RmFormatters('tr').distanceKm(6.2), throwsStateError);
      // Pure-number formatting still works without them.
      expect(const RmFormatters('tr').rating(6.2), '6,2');
    });
  });
}
