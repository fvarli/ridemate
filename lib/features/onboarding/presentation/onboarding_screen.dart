// ─────────────────────────────────────────────────────────────
// RideMate — Onboarding
//
// Source: docs/claude-designs/RideMate App.dc.html, "ONBOARDING" (immutable).
//
// The design provides ONE onboarding screen with a three-dot indicator. Only
// the first page exists, so the indicator renders with the first dot active
// and the screen does not paginate. Two more pages would need approved copy;
// none is invented here.
//
// LAYOUT: this is a Stack, not a Column. The white sheet is bottom-anchored
// and deliberately overlaps — and clips — the lower part of the trust
// constellation behind it. Building it as a Column would lose that.
//
// SEMANTICS OF THE TWO ACTIONS — deliberately not interchangeable:
//
//   onCreateAccountRequested  continues the new-user flow. It is NOT account
//                             creation and NOT authentication; the app has no
//                             account concept. It records only that the intro
//                             presentation was completed.
//   onSignInRequested         means "sign in to an existing account". Sign-in
//                             does not exist yet, so this shows a temporary
//                             message. It must never mark the intro complete
//                             and must never navigate.
// ─────────────────────────────────────────────────────────────

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/format/rm_formatters.dart';
import '../../../core/icons/rm_icons.dart';
import '../../../core/theme/tokens/rm_colors.dart';
import '../../../core/theme/tokens/rm_radius.dart';
import '../../../core/theme/tokens/rm_sizing.dart';
import '../../../core/theme/tokens/rm_spacing.dart';
import '../../../core/theme/tokens/rm_typography.dart';
import '../../../core/widgets/rm_avatar.dart';
import '../../../core/widgets/rm_button.dart';
import '../../../core/widgets/rm_icon.dart';
import '../../../l10n/app_localizations.dart';
import '../application/onboarding_controller.dart';

/// Presentation fixture: the community-proof count shown in the design.
///
/// Mock display data — not a real member count and not a backend value.
const int _kMockVerifiedMemberCount = 12480;

/// The intro screen.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      // The whole screen is the brand gradient, so the status-bar glyphs must
      // be light regardless of the app's theme.
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: c.onboardingCanvas),
          child: Stack(
            children: <Widget>[
              // Hero sits in the upper area; the sheet overlaps its lower part.
              const Align(
                alignment: Alignment.topCenter,
                child: SafeArea(bottom: false, child: _TrustConstellation()),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _IntroSheet(
                  l10n: l10n,
                  onCreateAccountRequested: () =>
                      _continueNewUserFlow(context, ref),
                  onSignInRequested: () =>
                      _showSignInUnavailable(context, l10n),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Records that the intro was completed and continues to verification.
  ///
  /// Explicitly NOT account creation or sign-in — see the file header.
  Future<void> _continueNewUserFlow(BuildContext context, WidgetRef ref) async {
    await ref.read(onboardingControllerProvider.notifier).markSeen();
    if (!context.mounted) return;
    context.goNamed(AppRoutes.verification);
  }

  /// Temporary Phase 2 behaviour for "I'm already a member".
  ///
  /// Shows an informational message only. It does NOT mark the intro complete
  /// and does NOT navigate, because signing in is a different thing from
  /// having seen the intro. A real auth route replaces this handler without
  /// changing the component's semantics.
  void _showSignInUnavailable(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.onboardingSignInUnavailable)));
  }
}

/// The bottom sheet: headline, subtitle, social proof, actions, page dots.
class _IntroSheet extends StatelessWidget {
  const _IntroSheet({
    required this.l10n,
    required this.onCreateAccountRequested,
    required this.onSignInRequested,
  });

  final AppLocalizations l10n;
  final VoidCallback onCreateAccountRequested;
  final VoidCallback onSignInRequested;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.sheet,
        // Only the top corners round; the bottom is flush with the device edge.
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(RmRadius.xxxl),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        RmSpacing.xxxl,
        RmSpacing.huge,
        RmSpacing.xxxl,
        RmSpacing.xxxl,
      ),
      child: SafeArea(
        top: false,
        // The sheet is bottom-anchored in a Stack, so it takes its natural
        // height and nothing clips it in portrait. On a short landscape
        // surface that natural height exceeds the screen, so it scrolls
        // instead of overflowing. Sizing to the content means portrait
        // rendering is byte-identical; only the too-short case changes.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _Headline(l10n: l10n),
              const SizedBox(height: RmSpacing.md),
              Text(
                l10n.onboardingSubtitle,
                style: RmTypography.caption.copyWith(
                  color: c.sub,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: RmSpacing.xxl),
              _SocialProof(l10n: l10n),
              const SizedBox(height: RmSpacing.xxl),
              RmButton(
                label: l10n.onboardingCreateAccount,
                onPressed: onCreateAccountRequested,
              ),
              const SizedBox(height: RmSpacing.sm),
              RmButton(
                label: l10n.onboardingSignIn,
                variant: RmButtonVariant.ghost,
                size: RmButtonSize.md,
                onPressed: onSignInRequested,
              ),
              const SizedBox(height: RmSpacing.xl),
              const _PageDots(count: 3, activeIndex: 0),
            ],
          ),
        ),
      ),
    );
  }
}

/// The headline, whose middle word carries the brand colour.
class _Headline extends StatelessWidget {
  const _Headline({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final TextStyle base = RmTypography.titleXl.copyWith(color: c.ink);

    return Semantics(
      header: true,
      child: Text.rich(
        TextSpan(
          style: base,
          children: <InlineSpan>[
            TextSpan(text: l10n.onboardingHeadlineBefore),
            TextSpan(
              text: l10n.onboardingHeadlineEmphasis,
              style: TextStyle(color: c.primaryText),
            ),
            TextSpan(text: l10n.onboardingHeadlineAfter),
          ],
        ),
      ),
    );
  }
}

/// Stacked member avatars plus the community count.
class _SocialProof extends StatelessWidget {
  const _SocialProof({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final RmFormatters formatters = RmFormatters.of(context);
    final String count = formatters.count(_kMockVerifiedMemberCount);

    return Container(
      padding: const EdgeInsets.all(RmSpacing.lg),
      decoration: BoxDecoration(
        color: c.primarySoft,
        borderRadius: RmRadius.brMd,
        border: Border.all(color: c.primarySoftBorder),
      ),
      child: Row(
        children: <Widget>[
          const _StackedAvatars(),
          const SizedBox(width: RmSpacing.md),
          Expanded(
            // The count is data, so it renders in the mono family per the
            // design system's prose/data split.
            child: Text.rich(
              TextSpan(
                style: RmTypography.caption.copyWith(color: c.ink),
                children: <InlineSpan>[
                  TextSpan(
                    text: count,
                    style: RmTypography.numericMicro.copyWith(
                      color: c.primaryText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: l10n
                        .onboardingSocialProof(count)
                        .replaceFirst(count, ''),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Three overlapping identity avatars.
class _StackedAvatars extends StatelessWidget {
  const _StackedAvatars();

  static const double _size = RmAvatarSize.xs;
  static const double _overlap = 12;

  @override
  Widget build(BuildContext context) {
    const List<RmIdentity> identities = <RmIdentity>[
      RmIdentity.amber,
      RmIdentity.green,
      RmIdentity.purple,
    ];

    return ExcludeSemantics(
      child: SizedBox(
        width: _size + (identities.length - 1) * (_size - _overlap),
        height: _size,
        child: Stack(
          children: <Widget>[
            for (int i = 0; i < identities.length; i++)
              PositionedDirectional(
                start: i * (_size - _overlap),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.rmColors.sheet,
                      width: RmSizing.borderWidthEmphasis,
                    ),
                  ),
                  child: RmAvatar(
                    initials: '',
                    size: _size,
                    shape: RmAvatarShape.circle,
                    identity: identities[i],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The page indicator. The active dot is a pill, not a circle.
///
/// Decorative: there is a single page, so it carries no semantics.
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (int i = 0; i < count; i++)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: RmSpacing.sm),
              child: Container(
                width: i == activeIndex ? RmSpacing.xxxl : RmSpacing.sm,
                height: RmSpacing.sm,
                decoration: BoxDecoration(
                  color: i == activeIndex ? c.primary : c.disabled,
                  borderRadius: RmRadius.brXs,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The hero: two dashed rings, a frosted logo tile and three member avatars.
///
/// Entirely decorative — it conveys nothing a screen reader needs.
class _TrustConstellation extends StatelessWidget {
  const _TrustConstellation();

  /// Design 276x228, scaled to the device width by [RmScale].
  static const double _height = 324;
  static const double _outerRing = 300;
  static const double _innerRing = 214;
  static const double _logoTile = 120;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return ExcludeSemantics(
      child: SizedBox(
        height: _height,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            _DashedRing(
              diameter: _outerRing,
              color: c.onPrimary,
              opacity: 0.12,
            ),
            _DashedRing(
              diameter: _innerRing,
              color: c.onPrimary,
              opacity: 0.22,
            ),
            Container(
              width: _logoTile,
              height: _logoTile,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.onPrimary.withValues(alpha: 0.16),
                borderRadius: RmRadius.brXxxl,
                border: Border.all(color: c.onPrimary.withValues(alpha: 0.25)),
              ),
              child: RmIcon(
                RmIcons.brandLogo,
                size: _logoTile * 0.48,
                color: c.onPrimary,
              ),
            ),
            const _ConstellationAvatar(
              alignment: AlignmentDirectional(-0.62, -0.52),
              initials: 'SK',
              identity: RmIdentity.amber,
              size: RmAvatarSize.xl,
            ),
            const _ConstellationAvatar(
              alignment: AlignmentDirectional(0.66, -0.28),
              initials: 'EY',
              identity: RmIdentity.purple,
              size: RmAvatarSize.lg,
            ),
            const _ConstellationAvatar(
              alignment: AlignmentDirectional(0.58, 0.62),
              initials: 'MA',
              identity: RmIdentity.green,
              size: RmAvatarSize.xl,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConstellationAvatar extends StatelessWidget {
  const _ConstellationAvatar({
    required this.alignment,
    required this.initials,
    required this.identity,
    required this.size,
  });

  final AlignmentDirectional alignment;
  final String initials;
  final RmIdentity identity;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // The ring is the brand blue, which reads as a cut-out against the
          // gradient behind it.
          border: Border.all(
            color: context.rmColors.primary,
            width: RmSizing.badgeRingWidth,
          ),
        ),
        child: RmAvatar(
          initials: initials,
          size: size,
          shape: RmAvatarShape.circle,
          identity: identity,
        ),
      ),
    );
  }
}

/// A dashed circle outline.
class _DashedRing extends StatelessWidget {
  const _DashedRing({
    required this.diameter,
    required this.color,
    required this.opacity,
  });

  final double diameter;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: diameter,
      height: diameter,
      child: CustomPaint(
        painter: _DashedRingPainter(color: color.withValues(alpha: opacity)),
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  const _DashedRingPainter({required this.color});

  final Color color;

  static const double _dash = 6;
  static const double _gap = 6;
  static const double _stroke = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = (size.shortestSide - _stroke) / 2;
    final Offset centre = size.center(Offset.zero);
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..color = color;

    final double circumference = 2 * math.pi * radius;
    final int segments = (circumference / (_dash + _gap)).floor().clamp(1, 400);
    final double sweep = 2 * math.pi / segments;
    // Keep the on/off ratio the design uses rather than a fixed pixel dash, so
    // the rhythm stays even all the way round.
    final double onSweep = sweep * (_dash / (_dash + _gap));
    final Rect rect = Rect.fromCircle(center: centre, radius: radius);

    for (int i = 0; i < segments; i++) {
      canvas.drawArc(rect, i * sweep, onSweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) => old.color != color;
}
