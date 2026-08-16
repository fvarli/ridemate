import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/theme/rm_theme.dart';
import 'package:ridemate/core/theme/tokens/rm_colors.dart';
import 'package:ridemate/core/theme/tokens/rm_shadows.dart';
import 'package:ridemate/core/theme/tokens/rm_typography.dart';

import '../../support/pump.dart';

void main() {
  group('RmTheme', () {
    test('attaches both RideMate extensions to each theme', () {
      for (final ThemeData theme in <ThemeData>[RmTheme.light, RmTheme.dark]) {
        expect(theme.extension<RmColors>(), isNotNull);
        expect(theme.extension<RmShadows>(), isNotNull);
      }
    });

    test('extensions match the theme brightness', () {
      expect(RmTheme.light.extension<RmColors>(), RmColors.light);
      expect(RmTheme.dark.extension<RmColors>(), RmColors.dark);
      expect(RmTheme.light.extension<RmShadows>(), RmShadows.light);
      expect(RmTheme.dark.extension<RmShadows>(), RmShadows.dark);
    });

    test('ColorScheme is driven by the design tokens, not a seed', () {
      final ColorScheme s = RmTheme.light.colorScheme;
      expect(s.primary, RmColors.light.primary);
      expect(s.error, RmColors.light.danger);
      expect(s.surface, RmColors.light.surface);
      expect(s.brightness, Brightness.light);
    });

    test('scaffold background comes from the palette', () {
      expect(RmTheme.light.scaffoldBackgroundColor, RmColors.light.background);
      expect(RmTheme.dark.scaffoldBackgroundColor, RmColors.dark.background);
    });

    test('text theme uses the bundled families', () {
      expect(RmTheme.light.textTheme.bodyMedium!.fontFamily, 'Manrope');
      expect(
        RmTheme.light.textTheme.displayLarge!.fontFamily,
        RmTypography.monoFontFamily,
        reason: 'displayLarge maps to the numeric role',
      );
    });

    test('Material tap targets are padded to the a11y floor', () {
      expect(RmTheme.light.materialTapTargetSize, MaterialTapTargetSize.padded);
    });

    test('of() resolves by brightness', () {
      expect(RmTheme.of(Brightness.light).brightness, Brightness.light);
      expect(RmTheme.of(Brightness.dark).brightness, Brightness.dark);
    });
  });

  group('RmTheme in a widget tree', () {
    testBothThemes('exposes the palette through context', (
      WidgetTester tester,
      Brightness brightness,
    ) async {
      late RmColors seen;
      await tester.pumpRm(
        Builder(
          builder: (BuildContext context) {
            seen = context.rmColors;
            return const SizedBox.shrink();
          },
        ),
        brightness: brightness,
      );

      expect(seen.brightness, brightness);
      expect(
        seen,
        brightness == Brightness.light ? RmColors.light : RmColors.dark,
      );
    });

    testWidgets('two brightnesses can coexist in one frame', (
      WidgetTester tester,
    ) async {
      // This is the scenario that rules out a global mutable palette: the
      // Home screen floats a light sheet over a dark map surface.
      late RmColors outer;
      late RmColors inner;

      await tester.pumpWidget(
        MaterialApp(
          theme: RmTheme.dark,
          home: Builder(
            builder: (BuildContext context) {
              outer = context.rmColors;
              return Theme(
                data: RmTheme.light,
                child: Builder(
                  builder: (BuildContext context) {
                    inner = context.rmColors;
                    return const SizedBox.shrink();
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(outer.brightness, Brightness.dark);
      expect(inner.brightness, Brightness.light);
      expect(outer.surface, isNot(inner.surface));
    });
  });
}
