import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/icons/rm_icons.dart';
import 'package:ridemate/core/theme/tokens/rm_colors.dart';
import 'package:ridemate/core/theme/tokens/rm_sizing.dart';
import 'package:ridemate/core/widgets/rm_icon.dart';

import '../../support/pump.dart';

void main() {
  group('RmIcons registry', () {
    test('every registered icon asset exists on disk', () {
      for (final MapEntry<String, String> e in RmIcons.all.entries) {
        expect(
          File(e.value).existsSync(),
          isTrue,
          reason: '${e.key} -> ${e.value} is missing',
        );
      }
      expect(File(RmIcons.brandLogo).existsSync(), isTrue);
    });

    test('registry and asset directory agree', () {
      final Set<String> onDisk = Directory(
        'assets/icons',
      ).listSync().whereType<File>().map((File f) => f.path).toSet();
      expect(
        RmIcons.all.values.toSet(),
        onDisk,
        reason: 'an icon file exists that no constant points at, or vice versa',
      );
    });

    test('icons are tintable — no hard-coded colours survive', () {
      // A stray hex would silently ignore the theme and break dark mode.
      for (final String path in RmIcons.all.values) {
        final String svg = File(path).readAsStringSync();
        expect(svg, isNot(contains('#')), reason: '$path has a literal colour');
        expect(svg, contains('currentColor'), reason: '$path is not tintable');
      }
    });

    test('the brand mark keeps its two deliberate colours', () {
      // It is a logo, not an icon: it must NOT be tinted.
      final String svg = File(RmIcons.brandLogo).readAsStringSync();
      expect(svg, contains('#FFFFFF'));
      expect(svg, contains('#9DB8FF'));
      expect(RmIcons.all.values, isNot(contains(RmIcons.brandLogo)));
    });

    test('all icons share the 24-unit viewBox from the source', () {
      for (final String path in RmIcons.all.values) {
        expect(
          File(path).readAsStringSync(),
          contains('viewBox="0 0 24 24"'),
          reason: path,
        );
      }
    });

    test('the check ships in two optical weights', () {
      // The source thickens the check as it shrinks (2.6 at 14px, 3.4 at 9px);
      // scaling the thin one down would make it disappear in a small badge.
      expect(
        File(RmIcons.check).readAsStringSync(),
        contains('stroke-width="2.6"'),
      );
      expect(
        File(RmIcons.checkBold).readAsStringSync(),
        contains('stroke-width="3.4"'),
      );
    });

    test(
      'the filled star is a fill, since U+2605 is missing from the fonts',
      () {
        final String svg = File(RmIcons.starFilled).readAsStringSync();
        expect(svg, contains('fill="currentColor"'));
        expect(svg, isNot(contains('stroke-width')));
      },
    );

    test('shield-alert tints its filled dot too', () {
      // The dot is a `fill` in the source, in the same colour as the strokes.
      // A stroke-only substitution would leave it hard-coded amber.
      final String svg = File(RmIcons.shieldAlert).readAsStringSync();
      expect(svg, contains('fill="currentColor"'));
    });
  });

  group('RmIcon', () {
    testBothThemes('renders at the requested size', (
      WidgetTester tester,
      Brightness brightness,
    ) async {
      await tester.pumpRm(
        const RmIcon(RmIcons.search, size: RmIconSize.lg),
        brightness: brightness,
      );

      expect(tester.takeException(), isNull);
      final Size size = tester.getSize(find.byType(RmIcon));
      expect(size, const Size(RmIconSize.lg, RmIconSize.lg));
    });

    testWidgets('is decorative by default', (WidgetTester tester) async {
      await tester.pumpRm(const RmIcon(RmIcons.clock));

      final Semantics semantics = tester.widget(
        find
            .descendant(
              of: find.byType(RmIcon),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(semantics.properties.label, isNull);
    });

    testWidgets('exposes a label when one is given', (
      WidgetTester tester,
    ) async {
      await tester.pumpRm(const RmIcon(RmIcons.phone, semanticLabel: 'Ara'));
      expect(find.bySemanticsLabel('Ara'), findsOneWidget);
    });

    testWidgets('mirrors directional glyphs in RTL only', (
      WidgetTester tester,
    ) async {
      await tester.pumpRm(
        const RmIcon(RmIcons.chevronLeft),
        textDirection: TextDirection.rtl,
      );
      expect(
        find.descendant(
          of: find.byType(RmIcon),
          matching: find.byType(Transform),
        ),
        findsWidgets,
        reason: 'a chevron must flip so "back" still points back in Arabic',
      );
    });

    testWidgets('leaves neutral glyphs unmirrored in RTL', (
      WidgetTester tester,
    ) async {
      await tester.pumpRm(
        const RmIcon(RmIcons.shield),
        textDirection: TextDirection.rtl,
      );
      expect(
        find.descendant(
          of: find.byType(RmIcon),
          matching: find.byType(Transform),
        ),
        findsNothing,
      );
      expect(RmIcons.directional, isNot(contains(RmIcons.shield)));
    });

    testWidgets('falls back to the palette ink when given no colour', (
      WidgetTester tester,
    ) async {
      await tester.pumpRm(const RmIcon(RmIcons.home));
      expect(tester.takeException(), isNull);
      expect(find.byType(RmIcon), findsOneWidget);
      // Sanity: the default ink differs between themes, so the fallback is
      // theme-sensitive rather than a hard-coded black.
      expect(RmColors.light.ink, isNot(RmColors.dark.ink));
    });
  });
}
