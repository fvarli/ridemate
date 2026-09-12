// ─────────────────────────────────────────────────────────────
// RideMate — Profile screen
//
// WHAT THIS FILE USED TO TEST, AND WHY IT NO LONGER DOES
//
// It measured the trust card: a ring, a tier badge, two lines of prose and
// four columns, surviving 360dp at the maximum text scale. That card is gone,
// and with it the assertions about a Trust Score of 92, a rating of 4,9, 73
// trips, ₺2.1k of savings and 4 / 5 verification badges. None of those numbers
// had a source. They were harmless beside other fixtures and stopped being
// harmless the moment a real account's real name appeared above them.
//
// What is tested now is smaller and load-bearing: the screen renders the
// server's identity, invents none when it cannot, and never falls back to the
// name it used to show.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/api/rm_error_code.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/profile/profile.dart';
import 'package:ridemate/features/profile/application/my_profile_providers.dart';
import 'package:ridemate/features/profile/presentation/profile_screen.dart';
import 'package:ridemate/features/profile/presentation/widgets/profile_links.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/pump.dart';

const Size kNarrowPhone = Size(360, 780);
const Size kWidePhone = Size(393, 852);

/// The name the fixture used to show. It must never appear again — a screen
/// that fell back to it would be inventing an identity at the exact moment it
/// could not confirm one.
const String kRetiredFixtureName = 'Elif Çelik';

void main() {
  setUpAll(loadRideMateFonts);

  Future<void> pumpProfile(
    WidgetTester tester, {
    required FakeProfileRepository profiles,
    Brightness brightness = Brightness.light,
    Size surfaceSize = kWidePhone,
    TextScaler textScaler = TextScaler.noScaling,
    TextDirection textDirection = TextDirection.ltr,
  }) async {
    await tester.pumpRmScreen(
      const ProfileScreen(),
      brightness: brightness,
      surfaceSize: surfaceSize,
      textScaler: textScaler,
      textDirection: textDirection,
      overrides: <Override>[
        profileRepositoryProvider.overrideWithValue(profiles),
      ],
    );
    await tester.pumpAndSettle();
  }

  testBothThemes('renders the server identity and the navigation rows', (
    WidgetTester tester,
    Brightness brightness,
  ) async {
    await pumpProfile(
      tester,
      brightness: brightness,
      profiles: FakeProfileRepository(
        profile: const Profile(displayName: 'İrem Yılmaz', initials: 'İY'),
      ),
    );

    expect(find.text('İrem Yılmaz'), findsOneWidget);
    // The server's letters, rendered as they arrived.
    expect(find.text('İY'), findsOneWidget);
    expect(find.text('Adını düzenle'), findsOneWidget);
    expect(find.text('Rotalarım'), findsOneWidget);
    expect(find.text('Hakkımdaki değerlendirmeler'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  /// CARRIES WEIGHT. Everything the screen may no longer claim.
  ///
  /// Listed as literals rather than by widget type, because the failure worth
  /// catching is a number reappearing somewhere new — in a header, a row, a
  /// badge — not a particular widget coming back.
  testWidgets('no unsupported claim survives anywhere on the screen', (
    WidgetTester tester,
  ) async {
    await pumpProfile(tester, profiles: FakeProfileRepository());

    for (final String gone in <String>[
      // Trust Score, its tier and its next step.
      'Güven Puanı', '92', '/ 100', 'Üst %8 · Güvenilir',
      "100'e ulaşmak için 1 yolculuk daha",
      // The four factors.
      'Kimlik', 'Topluluk', 'Güvenilirlik', 'Aktiflik',
      // The stat tiles.
      'Yolculuk', 'Puan', 'Tasarruf', '73', '4,9', '₺2.1k',
      // Verification: the row, its count, and the membership claim.
      'Doğrulama rozetleri', '4 / 5', "Doğrulanmış üye · 2024'ten beri",
    ]) {
      expect(find.text(gone), findsNothing, reason: gone);
    }
  });

  group('When the profile cannot be read', () {
    /// CARRIES WEIGHT. An honest failure, and no invented identity.
    testWidgets('an unreachable backend says so and offers a retry', (
      WidgetTester tester,
    ) async {
      await pumpProfile(tester, profiles: FakeProfileRepository.offline());

      expect(
        find.text('Bağlantı kurulamadı. İnternet bağlantını kontrol et.'),
        findsOneWidget,
      );
      expect(find.text('Yeniden dene'), findsOneWidget);
      expect(find.byType(ProfileLinks), findsNothing);
    });

    /// CARRIES WEIGHT. The fixture is not a fallback.
    testWidgets('no failure brings the old fixture name back', (
      WidgetTester tester,
    ) async {
      for (final RmFailure failure in <RmFailure>[
        const RmFailure.transport(),
        const RmFailure.fromBackend(
          status: 500,
          code: RmErrorCode.internalError,
        ),
        const RmFailure.fromBackend(status: 200, code: RmErrorCode.unexpected),
      ]) {
        await pumpProfile(
          tester,
          profiles: FakeProfileRepository(readError: failure),
        );

        expect(find.text(kRetiredFixtureName), findsNothing);
      }
    });

    testWidgets('pressing Retry asks exactly once more', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository profiles = FakeProfileRepository.offline();
      await pumpProfile(tester, profiles: profiles);

      expect(profiles.readCount, 1);

      profiles.readError = null;
      await tester.tap(find.text('Yeniden dene'));
      await tester.pumpAndSettle();

      expect(profiles.readCount, 2, reason: 'one deliberate action, one read');
      expect(find.text('Ayşe Demir'), findsOneWidget);
    });
  });

  /// Normally intercepted by the router. If it is ever reached here it must
  /// still invent nothing.
  testWidgets('a missing profile names nobody', (WidgetTester tester) async {
    await pumpProfile(tester, profiles: FakeProfileRepository.missing());

    expect(find.text('Henüz bir adın yok.'), findsOneWidget);
    expect(find.text(kRetiredFixtureName), findsNothing);
    expect(find.byType(ProfileLinks), findsNothing);
  });

  group('Layout', () {
    /// The screen is far lighter than the trust card made it, but a long name
    /// at the largest scale the app allows is still the case that overflows.
    testWidgets('a long name survives 360dp at the maximum text scale', (
      WidgetTester tester,
    ) async {
      await pumpProfile(
        tester,
        surfaceSize: kNarrowPhone,
        textScaler: const TextScaler.linear(1.3),
        profiles: FakeProfileRepository(
          profile: const Profile(
            displayName: 'Ayşegül Hümeyra Kadıoğlu Yılmaztürk',
            initials: 'AY',
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('lays out under RTL without overflow', (
      WidgetTester tester,
    ) async {
      await pumpProfile(
        tester,
        textDirection: TextDirection.rtl,
        profiles: FakeProfileRepository(),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
