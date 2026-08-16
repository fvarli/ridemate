import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/theme/tokens/rm_colors.dart';
import 'package:ridemate/core/theme/tokens/rm_motion.dart';
import 'package:ridemate/core/theme/tokens/rm_radius.dart';
import 'package:ridemate/core/theme/tokens/rm_shadows.dart';
import 'package:ridemate/core/theme/tokens/rm_sizing.dart';
import 'package:ridemate/core/theme/tokens/rm_spacing.dart';
import 'package:ridemate/core/theme/tokens/rm_typography.dart';

/// These tests pin the token layer to the immutable design source at
/// `docs/claude-designs/RideMate App.dc.html`. They are the guard against
/// silent design drift: if a value here changes, it must be a deliberate,
/// reviewed decision recorded in docs/design-system.md.
void main() {
  group('RmScale', () {
    test('derives the design-board factor from the artboard geometry', () {
      // The artboard viewport is 276x598, exactly the iPhone 14 Pro aspect
      // ratio (393x852) at 0.702 scale.
      expect(RmScale.designWidth, 276);
      expect(RmScale.deviceWidth, 393);
      expect(RmScale.factor, closeTo(1.4239, 0.0001));
    });

    test('scales raw design pixels', () {
      // The screen gutter: design 18px.
      expect(RmScale.of(18), closeTo(25.6, 0.1));
      // Body metadata text: design 11px -> ~16.
      expect(RmScale.of(11), closeTo(15.7, 0.1));
    });
  });

  group('RmColors — light palette matches the design source', () {
    const RmColors c = RmColors.light;

    test('brand and semantic colours', () {
      expect(c.primary.toARGB32(), 0xFF2E5BFF, reason: 'Primary');
      expect(c.primaryPressed.toARGB32(), 0xFF1E3FBF);
      expect(c.success.toARGB32(), 0xFF18A957, reason: 'Verified');
      expect(c.danger.toARGB32(), 0xFFE5484D, reason: 'Safety');
      expect(c.warning.toARGB32(), 0xFFF5A524, reason: 'Rating');
    });

    test('surfaces and text', () {
      expect(c.background.toARGB32(), 0xFFF6F8FB);
      expect(c.surface.toARGB32(), 0xFFFFFFFF);
      expect(c.border.toARGB32(), 0xFFE7E9EF);
      expect(c.ink.toARGB32(), 0xFF0F1729);
      expect(c.sub.toARGB32(), 0xFF5B6478);
      expect(c.muted.toARGB32(), 0xFF8A93A6);
    });

    test('brightness is light', () => expect(c.brightness, Brightness.light));
  });

  group('RmColors — dark palette matches the design source', () {
    const RmColors c = RmColors.dark;

    test('brand lightens, safety red does NOT', () {
      expect(c.primary.toARGB32(), 0xFF4D74FF);
      expect(c.primaryText.toARGB32(), 0xFF7FA0FF);
      expect(c.success.toARGB32(), 0xFF3FD07E);
      // The source deliberately keeps the safety red constant across themes.
      expect(
        c.danger.toARGB32(),
        RmColors.light.danger.toARGB32(),
        reason: 'Safety red must not change between themes',
      );
      expect(
        c.warning.toARGB32(),
        RmColors.light.warning.toARGB32(),
        reason: 'Rating amber must not change between themes',
      );
    });

    test('surfaces', () {
      expect(c.background.toARGB32(), 0xFF0B0E14);
      expect(c.surface.toARGB32(), 0xFF151A23);
      expect(c.surfaceRaised.toARGB32(), 0xFF181E29);
      expect(c.sheet.toARGB32(), 0xFF11151D);
      expect(c.navBar.toARGB32(), 0xFF0E1219);
      expect(c.border.toARGB32(), 0xFF232A38);
      expect(c.ink.toARGB32(), 0xFFF2F4F8);
    });
  });

  group('RmColors interpolation', () {
    test('lerp moves every field, so theme transitions stay in step', () {
      final RmColors mid = RmColors.light.lerp(RmColors.dark, 0.5);
      expect(mid.background, isNot(RmColors.light.background));
      expect(mid.background, isNot(RmColors.dark.background));
      expect(
        mid.background.toARGB32(),
        Color.lerp(
          RmColors.light.background,
          RmColors.dark.background,
          0.5,
        )!.toARGB32(),
      );
    });

    test('lerp endpoints resolve to the exact palettes', () {
      expect(
        RmColors.light.lerp(RmColors.dark, 0).background.toARGB32(),
        RmColors.light.background.toARGB32(),
      );
      expect(
        RmColors.light.lerp(RmColors.dark, 1).background.toARGB32(),
        RmColors.dark.background.toARGB32(),
      );
    });

    test('copyWith resolves to the palette for a brightness', () {
      expect(
        RmColors.light.copyWith(brightness: Brightness.dark),
        RmColors.dark,
      );
      expect(
        RmColors.dark.copyWith(brightness: Brightness.light),
        RmColors.light,
      );
      expect(RmColors.light.copyWith(), same(RmColors.light));
    });
  });

  group('RmShadows', () {
    test('dark mode replaces neutral shadows with borders', () {
      // The source's three dark screens drop shadows entirely and use a 1px
      // border instead. Only the floating sheet keeps one.
      expect(RmShadows.dark.cardSoft, isEmpty);
      expect(RmShadows.dark.cardRaised, isEmpty);
      expect(RmShadows.dark.cardFloat, isEmpty);
      expect(RmShadows.dark.overlay, isEmpty);
      expect(RmShadows.dark.sheetUp, isEmpty);
      expect(RmShadows.dark.sheetFloat, isNotEmpty);
    });

    test('coloured glows survive into dark mode', () {
      expect(RmShadows.dark.primary, isNotEmpty);
      expect(RmShadows.dark.fab, isNotEmpty);
      expect(RmShadows.dark.danger, isNotEmpty);
    });

    test('light neutral shadows are present', () {
      expect(RmShadows.light.cardSoft, isNotEmpty);
      expect(RmShadows.light.sheetUp.single.offset.dy, isNegative);
    });
  });

  group('RmSpacing', () {
    test('is a 4pt grid', () {
      expect(RmSpacing.base, 4);
      for (final double step in <double>[
        RmSpacing.xs,
        RmSpacing.sm,
        RmSpacing.md,
        RmSpacing.lg,
        RmSpacing.xl,
        RmSpacing.xxl,
        RmSpacing.xxxl,
        RmSpacing.huge,
      ]) {
        expect(step % RmSpacing.base, 0, reason: '$step is off the 4pt grid');
      }
    });

    test('screen gutter derives from the design 18px inset', () {
      expect(RmSpacing.screenGutter, 24);
      expect(RmSpacing.screenGutter, closeTo(RmScale.of(18), 2));
    });
  });

  group('RmRadius', () {
    test('scale ascends and pill is fully rounded', () {
      expect(<double>[
        RmRadius.xs,
        RmRadius.sm,
        RmRadius.md,
        RmRadius.lg,
        RmRadius.xl,
        RmRadius.xxl,
        RmRadius.xxxl,
        RmRadius.sheet,
      ], orderedEquals(<double>[8, 12, 16, 20, 24, 28, 32, 36]));
      expect(RmRadius.pill, 999);
    });

    test('sheetTop rounds only the top corners', () {
      expect(RmRadius.sheetTop.topLeft.x, RmRadius.sheet);
      expect(RmRadius.sheetTop.bottomLeft, Radius.zero);
    });
  });

  group('RmSizing — clamps are deliberate deviations', () {
    test('interactive heights meet the 48dp touch floor', () {
      for (final double h in <double>[
        RmSizing.ctaXl,
        RmSizing.ctaLg,
        RmSizing.ctaMd,
        RmSizing.iconButtonSm,
        RmSizing.iconButtonMd,
        RmSizing.fab,
      ]) {
        expect(h, greaterThanOrEqualTo(48), reason: '$h is below 48dp');
      }
    });

    test('CTA heights are clamped well below the raw scaled values', () {
      // Design 52px would scale to ~74, which is unusable on device.
      expect(RmScale.of(52), greaterThan(70));
      expect(RmSizing.ctaXl, 56);
      expect(RmSizing.navBarHeight, 64);
    });

    test('the 34px icon button scales almost exactly onto the 48dp floor', () {
      expect(RmScale.of(34), closeTo(48.4, 0.1));
      expect(RmSizing.iconButtonSm, 48);
    });

    test('meter radius always equals its height', () {
      expect(RmSizing.meterHeight, RmRadius.xs);
    });
  });

  group('RmAvatarMetrics — ratios measured from the source', () {
    test('radius is 0.32 of the box across every design instance', () {
      // Every avatar/radius pair measured from the design source.
      const List<(double size, double radius)> designPairs = <(double, double)>[
        (38, 12),
        (40, 13),
        (44, 14),
        (48, 15),
        (58, 18),
        (60, 19),
      ];
      for (final (double size, double radius) in designPairs) {
        expect(
          RmAvatarMetrics.radiusFor(size),
          closeTo(radius, 1),
          reason: 'avatar $size should round to ~$radius',
        );
      }
    });

    test('derived geometry for a 72dp avatar', () {
      expect(RmAvatarMetrics.radiusFor(RmAvatarSize.xxl), closeTo(23, 0.5));
      expect(
        RmAvatarMetrics.initialsSizeFor(RmAvatarSize.xxl),
        closeTo(26, 0.5),
      );
      expect(
        RmAvatarMetrics.badgeSizeFor(RmAvatarSize.xxl),
        closeTo(27.4, 0.5),
      );
    });
  });

  group('RmTypography', () {
    test('splits prose and data across two families', () {
      expect(RmTypography.body.fontFamily, 'Manrope');
      expect(RmTypography.titleLg.fontFamily, 'Manrope');
      // Every numeric role must be mono — this is the rule the whole design
      // hangs on.
      for (final MapEntry<String, TextStyle> e in RmTypography.all.entries) {
        if (e.key.startsWith('numeric')) {
          expect(
            e.value.fontFamily,
            'IBM Plex Mono',
            reason: '${e.key} renders data and must be mono',
          );
        } else {
          expect(e.value.fontFamily, 'Manrope', reason: e.key);
        }
      }
    });

    test('no role carries a colour', () {
      for (final MapEntry<String, TextStyle> e in RmTypography.all.entries) {
        expect(e.value.color, isNull, reason: '${e.key} must stay colourless');
      }
    });

    test('every role declares an explicit size and weight', () {
      for (final MapEntry<String, TextStyle> e in RmTypography.all.entries) {
        expect(e.value.fontSize, isNotNull, reason: e.key);
        expect(e.value.fontWeight, isNotNull, reason: e.key);
      }
    });

    test('sizes derive from the design source', () {
      // Design 13px body -> ~18.5; 22px title -> ~31.3; 9.5px micro -> ~13.5.
      expect(RmTypography.body.fontSize, 18);
      expect(RmTypography.titleLg.fontSize, 32);
      expect(RmTypography.micro.fontSize, 14);
    });

    test('textTheme applies the requested ink colour', () {
      final TextTheme t = RmTypography.textTheme(const Color(0xFF0F1729));
      expect(t.bodyMedium!.color!.toARGB32(), 0xFF0F1729);
      expect(t.bodyMedium!.fontFamily, 'Manrope');
    });
  });

  group('RmMotion', () {
    test('matches the only two animations in the design source', () {
      // @keyframes rm-pulse ... 1.4s infinite
      expect(RmMotion.pulse, const Duration(milliseconds: 1400));
      expect(RmMotion.pulseMinOpacity, 0.35);
      expect(RmMotion.pulseMinScale, 0.82);
      // @keyframes rm-ring ... 1.8s infinite
      expect(RmMotion.ring, const Duration(milliseconds: 1800));
      expect(RmMotion.ringStartOpacity, 0.45);
      expect(RmMotion.ringMaxSpread, closeTo(RmScale.of(14), 0.01));
    });
  });
}
