// ─────────────────────────────────────────────────────────────
// RideMate — Profile domain
//
// The Trust Score is the loudest claim in the product and the one with the
// least behind it. These tests exist to keep every number on this screen a
// figure copied from the design, and to keep the four breakdown rows from
// ever becoming a formula for the score above them.
// ─────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/widgets/rm_avatar.dart';
import 'package:ridemate/features/profile/domain/profile_fixtures.dart';
import 'package:ridemate/features/profile/domain/profile_snapshot.dart';
import 'package:ridemate/features/verification/domain/verification_state.dart';

/// The code in [path], with comments removed.
///
/// The banned names are all written down in headers explaining why they are
/// banned, so a raw scan would match the prohibition itself.
String codeOf(String path) => File(path)
    .readAsLinesSync()
    .map((String line) {
      final int slash = line.indexOf('//');
      return slash == -1 ? line : line.substring(0, slash);
    })
    .join('\n');

/// Every Dart file under the Profile feature.
Iterable<String> profileSources() => Directory('lib/features/profile')
    .listSync(recursive: true)
    .whereType<File>()
    .map((File f) => f.path)
    .where((String p) => p.endsWith('.dart'));

void main() {
  group('The fixture reproduces the design', () {
    test('carries every figure the design shows', () {
      const ProfileSnapshot p = kMockProfileSnapshot;
      expect(p.name, 'Elif Çelik');
      expect(p.initials, 'EÇ');
      expect(p.identity, RmIdentity.purple);
      expect(p.trustScore, 92);
      expect(p.tierPercentile, 8);
      expect(p.tripCount, 73);
      expect(p.rating, 4.9);
      expect(p.savingsLabel, '₺2.1k');
      expect(p.verifiedBadgeCount, 4);
      expect(p.verifiedBadgeTotal, 5);
      expect(p.factors.map((TrustFactor f) => f.value), <int>[100, 90, 94, 82]);
    });

    test('the member carries verification, not presence', () {
      // The comp draws the green check badge. Presence and verification are
      // separate claims and separate types; this snapshot has no presence
      // field at all, so one cannot be read as the other.
      expect(kMockProfileSnapshot.verification, RmVerification.verified);
      expect(
        codeOf('lib/features/profile/domain/profile_snapshot.dart'),
        isNot(contains('RmPresence')),
      );
    });

    test('snapshots compare by value', () {
      expect(kMockProfileSnapshot, kMockProfileSnapshot);
      expect(
        kMockProfileSnapshot.factors.first,
        const TrustFactor(
          id: TrustFactorId.identity,
          value: 100,
          meter: 1,
          tone: TrustFactorTone.complete,
        ),
      );
    });
  });

  group('The Trust Score is displayed, never computed', () {
    test('the breakdown does not add up to the score, and must not', () {
      // (100 + 90 + 94 + 82) / 4 = 91.5, against a displayed 92. A near miss
      // invites exactly the wrong fix. Both are declarations; neither is a
      // decomposition of the other, and there is no service that could make
      // them agree.
      final double mean =
          kMockProfileSnapshot.factors.fold<int>(
            0,
            (int sum, TrustFactor f) => sum + f.value,
          ) /
          kMockProfileSnapshot.factors.length;
      expect(mean, 91.5);
      expect(mean, isNot(kMockProfileSnapshot.trustScore.toDouble()));
    });

    test('a factor tone is declared, never thresholded', () {
      // 82 is amber and 90 is blue, which would put a cut-off somewhere in
      // 83..89. There is no such threshold because no policy defines one, so
      // nothing may derive a tone from a value.
      final Map<int, TrustFactorTone> byValue = <int, TrustFactorTone>{
        for (final TrustFactor f in kMockProfileSnapshot.factors)
          f.value: f.tone,
      };
      expect(byValue[100], TrustFactorTone.complete);
      expect(byValue[94], TrustFactorTone.standard);
      expect(byValue[90], TrustFactorTone.standard);
      expect(byValue[82], TrustFactorTone.attention);

      for (final String path in profileSources()) {
        final String source = codeOf(path);
        for (final String banned in <String>[
          'toneFor',
          'threshold',
          'Threshold',
          'if (value',
          'value >=',
          'value <=',
        ]) {
          expect(source.contains(banned), isFalse, reason: '$path: $banned');
        }
      }
    });

    test('the ring colour does not follow from the score either', () {
      // 100 green, 94 and 90 blue, 82 amber reads as "green means complete",
      // which the green ring at 92 immediately contradicts. Declared tone is
      // what keeps both from becoming a rule.
      expect(kMockProfileSnapshot.trustScore, lessThan(100));
      expect(
        kMockProfileSnapshot.factors
            .where((TrustFactor f) => f.tone == TrustFactorTone.complete)
            .single
            .value,
        100,
      );
    });

    test('no trust, reputation or scoring machinery is introduced', () {
      for (final String path in profileSources()) {
        final String source = codeOf(path);
        for (final String banned in <String>[
          'calculateTrustScore',
          'calculateReputation',
          'deriveVerificationTier',
          'trustWeights',
          'pointsPerTrip',
          'TrustEngine',
          'TrustService',
          'ProfileRepository',
          'Notifier',
          'http',
        ]) {
          expect(source.contains(banned), isFalse, reason: '$path: $banned');
        }
      }
    });

    test('the next-step line takes no parameter', () {
      // `100'e ulaşmak için 1 yolculuk daha` asserts eight points per trip.
      // It ships as one opaque string precisely so it cannot be turned into
      // a rate, and no test would catch that — only this one.
      final String arb = File('lib/l10n/app_tr.arb').readAsStringSync();
      final int key = arb.indexOf('"@profileTrustNextStep"');
      expect(key, isNot(-1));
      final String block = arb.substring(key, arb.indexOf('},', key));
      expect(block, isNot(contains('placeholders')));
    });
  });

  group('The verification count stays tied to verification', () {
    test('the badge total is the number of steps the flow declares', () {
      // The comp's `4 / 5` counts the same five steps /verification models.
      // A test rather than a shared fixture: the two features stay apart, but
      // they cannot drift.
      expect(
        kMockProfileSnapshot.verifiedBadgeTotal,
        VerificationStepId.values.length,
      );
      expect(
        kMockProfileSnapshot.verifiedBadgeCount,
        lessThan(kMockProfileSnapshot.verifiedBadgeTotal),
      );
    });

    test('Profile does not import the verification feature', () {
      for (final String path in profileSources()) {
        expect(
          File(path).readAsStringSync(),
          isNot(contains('features/verification')),
          reason: '$path reaches across features',
        );
      }
    });
  });
}
