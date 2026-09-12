// ─────────────────────────────────────────────────────────────
// RideMate — Reviews domain
//
// Reputation is the easiest place in this app to accidentally write a rule.
// Three of the design's figures reconstruct each other exactly, so these
// tests exist to keep every one of them a declaration.
// ─────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/widgets/rm_avatar.dart';
import 'package:ridemate/features/reviews/fixture/domain/review_entry.dart';
import 'package:ridemate/features/reviews/fixture/domain/review_fixtures.dart';
import 'package:ridemate/l10n/app_localizations.dart';
import 'package:ridemate/l10n/app_localizations_en.dart';
import 'package:ridemate/l10n/app_localizations_tr.dart';

/// The code in [path], with comments removed.
///
/// Every banned name below is written down in a header explaining why it is
/// banned, so a raw scan would match the prohibition itself.
String codeOf(String path) => File(path)
    .readAsLinesSync()
    .map((String line) {
      final int slash = line.indexOf('//');
      return slash == -1 ? line : line.substring(0, slash);
    })
    .join('\n');

/// The fixture half of the feature, which is now a directory.
///
/// The Reviews feature had two halves living in one tree. Phase 15 added a real
/// repository, a real controller, a real rating sheet and a real screen — the
/// very things these guards were written to say did not exist — so a scan of
/// `lib/features/reviews` turned a guard about invented figures into one
/// forbidding the feature from ever becoming real. It had to be relaxed twice
/// in one slice, and the second relaxation replaced it with a list of file
/// names, which is a guard that can go stale without saying so.
///
/// F3 moved the cause rather than the symptom: the fixture is an island under
/// [kFixtureRoot], and the guard is a path rule again. What it protects is
/// exactly what it always did — the FIXTURE computes nothing, claims no
/// moderation, and reaches no repository of its own, because a screen of
/// invented figures that started rendering half-real ones would be the worst of
/// both. `package:http` stays banned across the whole feature by
/// `api_boundary_test`, which enforces it everywhere outside `lib/core/api`.
const String kFixtureRoot = 'lib/features/reviews/fixture';

/// Every Dart file in the island.
Iterable<String> reviewsSources() => Directory(kFixtureRoot)
    .listSync(recursive: true)
    .whereType<File>()
    .map((File f) => f.path)
    .where((String path) => path.endsWith('.dart'));

/// Every Dart file shipped in the app.
Iterable<File> libSources() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((File f) => f.path.endsWith('.dart'));

void main() {
  final AppLocalizations l10n = AppLocalizationsTr();

  test('the fixture island is still there to guard', () {
    // A directory scan over a directory that no longer exists asserts nothing
    // at all, quietly. F4 retires the island; until then it is here.
    expect(Directory(kFixtureRoot).existsSync(), isTrue);
    expect(reviewsSources(), isNotEmpty);
  });

  /// CARRIES WEIGHT. This is what makes "production cannot reach the fixture"
  /// a structural fact rather than a claim.
  ///
  /// The design's Reviews screen shows a 4.9 average over 73 reviews, a
  /// histogram and four tag counts, none of which anything computes. Beside a
  /// member's real name that is not a placeholder, it is the app telling
  /// somebody a figure about themselves. Phase 15 gave `/reviews` a real
  /// screen; nothing shipped may reach the old one, by route or by import.
  test('nothing outside the island imports it', () {
    final List<String> offenders = <String>[];

    for (final File file in libSources()) {
      if (file.path.startsWith(kFixtureRoot)) continue;

      final List<String> lines = file.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        if (!lines[i].startsWith('import ')) continue;
        // Both spellings: a package: import and a relative one that climbs
        // back into the island.
        if (lines[i].contains('features/reviews/fixture/') ||
            lines[i].contains('/fixture/domain/') ||
            lines[i].contains('/fixture/presentation/')) {
          offenders.add('${file.path}:${i + 1}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'the fixture is reachable from shipped code',
    );
  });

  group('The fixture reproduces the design', () {
    test('carries every figure the design shows', () {
      final ReviewsSnapshot s = mockReviews(l10n);
      expect(s.averageRating, 4.9);
      expect(s.reviewCount, 73);
      expect(s.entries.length, 2);
      expect(s.tags.map((ReviewTag t) => t.count), <int>[41, 38, 33, 24]);
      expect(s.entries.first.authorName, 'Mert A.');
      expect(s.entries.first.rating, 5.0);
      expect(s.entries.first.authorIdentity, RmIdentity.green);
      expect(s.entries.last.rating, 4.8);
      expect(s.entries.last.authorIdentity, RmIdentity.purple);
    });

    test('the histogram has four bars and the last one is empty', () {
      // The comp draws no 1-star row, and its 2-star bar is a bare track.
      // Dropping either would claim nobody has ever rated below three.
      expect(kMockRatingDistribution.map((RatingBucket b) => b.stars), <int>[
        5,
        4,
        3,
        2,
      ]);
      expect(kMockRatingDistribution.last.share, 0);
    });

    test('the prose follows the locale rather than being baked in', () {
      final ReviewsSnapshot tr = mockReviews(AppLocalizationsTr());
      final ReviewsSnapshot en = mockReviews(AppLocalizationsEn());
      expect(tr.entries.first.body, isNot(en.entries.first.body));
      expect(tr.tags.first.label, isNot(en.tags.first.label));
      // The figures do not move with the language.
      expect(tr.averageRating, en.averageRating);
      expect(tr.reviewCount, en.reviewCount);
    });

    test('snapshots compare by value', () {
      expect(mockReviews(l10n), mockReviews(l10n));
      expect(mockReviews(l10n).hashCode, mockReviews(l10n).hashCode);
    });
  });

  group('Nothing is computed', () {
    test('the histogram reconstructs the headline, and is still not its '
        'source', () {
      // 0.92*5 + 0.06*4 + 0.02*3 = 4.90, exactly the headline. That agreement
      // is the design's, and it is the single most tempting thing in this
      // feature to turn into a function. There is no reviews service, so
      // there is nothing to be right about.
      final double weighted = kMockRatingDistribution.fold<double>(
        0,
        (double sum, RatingBucket b) => sum + b.share * b.stars,
      );
      expect(weighted, closeTo(4.9, 0.0001));

      for (final String path in reviewsSources()) {
        final String source = codeOf(path);
        for (final String banned in <String>[
          'calculateRating',
          'calculateReputation',
          'aggregateRatings',
          'ratingFromDistribution',
          'averageOf',
          'weightedAverage',
        ]) {
          expect(source.contains(banned), isFalse, reason: '$path: $banned');
        }
      }
    });

    test('the two visible cards average to the headline, and are still not '
        'its source', () {
      // (5.0 + 4.8) / 2 = 4.9 as well. Two cards out of a claimed 73 cannot
      // average to anything, which is exactly why this must stay a fixture.
      final ReviewsSnapshot s = mockReviews(l10n);
      final double mean =
          s.entries.fold<double>(0, (double a, ReviewEntry e) => a + e.rating) /
          s.entries.length;
      expect(mean, closeTo(s.averageRating, 0.0001));
      expect(s.entries.length, lessThan(s.reviewCount));
    });

    test('the tag counts exceed the review total on purpose', () {
      // 41 + 38 + 33 + 24 = 136 across 73 reviews: a review carries several
      // tags. Nobody should "fix" these to sum to the total.
      final ReviewsSnapshot s = mockReviews(l10n);
      final int total = s.tags.fold<int>(
        0,
        (int a, ReviewTag t) => a + t.count,
      );
      expect(total, 136);
      expect(total, greaterThan(s.reviewCount));
    });

    /// The fixture screen still reaches nothing and moderates nothing.
    ///
    /// `ReviewRepository` stays banned HERE: a real one exists under `data/`
    /// now, and the fixture presentation reading it is exactly how a screen of
    /// invented figures starts rendering half-real ones.
    test('no service, repository or moderation machinery is introduced', () {
      for (final String path in reviewsSources()) {
        final String source = codeOf(path);
        for (final String banned in <String>[
          'ModerationService',
          'ReportService',
          'ReviewRepository',
          'ReviewService',
          'Notifier',
          'http',
          'reportSubmitted',
          'isModerated',
          'isFlagged',
        ]) {
          expect(source.contains(banned), isFalse, reason: '$path: $banned');
        }
      }
    });
  });

  group('Nothing claims more than the design draws', () {
    test('a review author carries no verification or presence claim', () {
      // The comp draws a bare avatar on both cards. Whether the author is a
      // verified member is a claim this screen has no source for.
      final String source = codeOf('$kFixtureRoot/domain/review_entry.dart');
      expect(source, isNot(contains('RmVerification')));
      expect(source, isNot(contains('RmPresence')));
    });

    test('the context field is free text, not a route', () {
      // One card says `Kadıköy → Levent` and the other says `Düzenli rota`,
      // which is not a route at all.
      final ReviewsSnapshot s = mockReviews(l10n);
      expect(s.entries.first.context, contains('→'));
      expect(s.entries.last.context, l10n.reviewsContextRegularRoute);
      final String source = codeOf('$kFixtureRoot/domain/review_entry.dart');
      expect(source, isNot(contains('origin')));
      expect(source, isNot(contains('destination')));
    });
  });
}
