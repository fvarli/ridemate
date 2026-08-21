// ─────────────────────────────────────────────────────────────
// RideMate — Release-reachable copy and controls
//
// Two properties that are easy to break by accident and invisible when broken:
//
//   1. every string a member can read is localized, in a product whose source
//      language is Turkish;
//   2. no control a member can press does nothing without saying so.
//
// The second is the rule the rest of the codebase already follows — eleven
// localized "this did not happen" messages exist — and the Home shortcuts were
// the one place it had been missed.
// ─────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/app/providers/app_preferences_provider.dart';
import 'package:ridemate/app/ride_mate_app.dart';
import 'package:ridemate/features/home/presentation/home_screen.dart';
import 'package:ridemate/features/onboarding/application/onboarding_controller.dart';
import 'package:ridemate/l10n/app_localizations.dart';
import 'package:ridemate/l10n/app_localizations_en.dart';
import 'package:ridemate/l10n/app_localizations_tr.dart';

import '../support/fakes.dart';

void main() {
  group('Home shortcuts say what is missing', () {
    testWidgets('every shortcut reports that saved addresses do not exist', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            onboardingRepositoryProvider.overrideWithValue(
              InMemoryOnboardingRepository(seen: true),
            ),
          ],
          child: const RideMateApp(),
        ),
      );
      await tester.pumpAndSettle();
      ProviderScope.containerOf(
        tester.element(find.byType(RideMateApp)),
      ).read(localeProvider.notifier).set(const Locale('tr'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);

      for (final String label in <String>['Ev', 'İş · Levent', 'Üniversite']) {
        // The shortcut row scrolls horizontally and builds lazily, so the last
        // chip is not in the tree until it is dragged into view.
        if (find.text(label).evaluate().isEmpty) {
          await tester.drag(find.text('Ev'), const Offset(-240, 0));
          await tester.pumpAndSettle();
        }

        await tester.tap(find.text(label));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(
          find.text('Kayıtlı adres özelliği henüz eklenmedi.'),
          findsOneWidget,
          reason: '$label must not silently do nothing',
        );
        // It says so and stops there: no navigation, no search started.
        expect(find.byType(HomeScreen), findsOneWidget);
      }
    });

    test('no product screen leaves a control silently inert', () {
      // The debug gallery is excluded on purpose: its chips are component
      // specimens, and a specimen that navigated somewhere would be the bug.
      final List<String> offenders = <String>[];
      for (final FileSystemEntity entity in Directory(
        'lib',
      ).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.contains('/gallery/')) continue;

        final List<String> lines = entity.readAsLinesSync();
        for (int i = 0; i < lines.length; i++) {
          final String line = lines[i];
          if (line.trimLeft().startsWith('//')) continue;
          if (line.contains('onTap: () {}') ||
              line.contains('onPressed: () {}')) {
            offenders.add('${entity.path}:${i + 1}');
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'a control that looks live and does nothing is dishonest',
      );
    });
  });

  group('Release-reachable copy is localized', () {
    test('the router and shell hold no user-visible English literals', () {
      // Both files fed hardcoded English into the Messages tab of a
      // Turkish-first product.
      for (final String path in <String>[
        'lib/app/router/app_router.dart',
        'lib/app/app_shell.dart',
      ]) {
        final List<String> lines = File(path).readAsLinesSync();
        for (int i = 0; i < lines.length; i++) {
          final String line = lines[i];
          if (line.trimLeft().startsWith('//')) continue;
          // Anything handed to a widget as display text must come from l10n.
          for (final String literal in <String>[
            "title: '",
            "phase: '",
            "label: '",
            "Text('",
          ]) {
            expect(
              line.contains(literal),
              isFalse,
              reason: '$path:${i + 1} — $literal is a hardcoded string',
            );
          }
        }
      }
    });

    test('the new keys exist in both locales', () {
      final AppLocalizations tr = AppLocalizationsTr();
      final AppLocalizations en = AppLocalizationsEn();

      for (final String Function(AppLocalizations) key
          in <String Function(AppLocalizations)>[
            (AppLocalizations l) => l.messagesPlaceholderBody,
            (AppLocalizations l) => l.homeShortcutUnavailable,
            (AppLocalizations l) => l.errorTitle,
            (AppLocalizations l) => l.errorBody,
            (AppLocalizations l) => l.errorReturnHome,
          ]) {
        expect(key(tr), isNotEmpty);
        expect(key(en), isNotEmpty);
        expect(
          key(tr),
          isNot(key(en)),
          reason: 'an untranslated string usually means a copy-paste',
        );
      }
    });
  });

  group('Localization parity', () {
    /// Message keys, ignoring the `@`-prefixed metadata blocks.
    Set<String> keysOf(String path) {
      final String source = File(path).readAsStringSync();
      return RegExp(
        r'^  "([^@"][^"]*)":',
        multiLine: true,
      ).allMatches(source).map((RegExpMatch m) => m.group(1)!).toSet();
    }

    test('every Turkish key has an English counterpart, and vice versa', () {
      final Set<String> tr = keysOf('lib/l10n/app_tr.arb');
      final Set<String> en = keysOf('lib/l10n/app_en.arb');

      expect(tr.difference(en), isEmpty, reason: 'missing from English');
      expect(en.difference(tr), isEmpty, reason: 'missing from Turkish');
      expect(tr, isNotEmpty);
    });

    test('Turkish remains the source language', () {
      // gen-l10n resolves descriptions and placeholder metadata against the
      // template, so this is what keeps Turkish authoritative.
      expect(
        File('l10n.yaml').readAsStringSync(),
        contains('template-arb-file: app_tr.arb'),
      );
    });
  });

  group('Brand casing', () {
    test('every user-visible surface says RideMate', () {
      // Three surfaces showed three different spellings: RideMate in the task
      // switcher, `ridemate` under the Android launcher icon and `Ridemate` on
      // the iOS home screen.
      expect(
        File('lib/app/ride_mate_app.dart').readAsStringSync(),
        contains("appTitle = 'RideMate'"),
      );
      expect(
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
        contains('android:label="RideMate"'),
      );
      expect(
        File('ios/Runner/Info.plist').readAsStringSync(),
        contains('<key>CFBundleDisplayName</key>\n\t<string>RideMate</string>'),
      );
    });

    test('technical identifiers stay lowercase and unchanged', () {
      // Renaming any of these is either impossible after publish or a
      // gratuitous churn of the project. They are not brand surfaces.
      expect(
        File('pubspec.yaml').readAsStringSync(),
        contains('name: ridemate'),
      );
      expect(
        File('android/app/build.gradle.kts').readAsStringSync(),
        contains('applicationId = "com.lunexa.ridemate"'),
      );
      expect(
        File('ios/Runner/Info.plist').readAsStringSync(),
        contains('<key>CFBundleName</key>\n\t<string>ridemate</string>'),
      );
      expect(
        File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync(),
        contains('PRODUCT_BUNDLE_IDENTIFIER = com.lunexa.ridemate;'),
      );
    });
  });
}
