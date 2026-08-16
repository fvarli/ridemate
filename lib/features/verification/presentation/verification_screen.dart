// ─────────────────────────────────────────────────────────────
// RideMate — Verification
//
// Source: docs/claude-designs/RideMate App.dc.html, "VERIFICATION" (immutable).
//
// The only one of the Phase 2 screens laid out in normal flow: header, trust
// hero card, step list. No tab bar, so it sits above the shell.
//
// PHASE 2 SCOPE. There is no identity provider, no document capture, no OTP
// and no selfie flow — none of those screens exist in the design. Tapping a
// step advances a scripted demo so the approved visual states can be
// reviewed; nothing is uploaded or checked.
//
// The design gives this screen no completion CTA and no forward navigation.
// None is invented: when every required step is verified, only the visual
// state changes, and back returns Home.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/format/rm_formatters.dart';
import '../../../core/icons/rm_icons.dart';
import '../../../core/theme/tokens/rm_colors.dart';
import '../../../core/theme/tokens/rm_radius.dart';
import '../../../core/theme/tokens/rm_shadows.dart';
import '../../../core/theme/tokens/rm_sizing.dart';
import '../../../core/theme/tokens/rm_spacing.dart';
import '../../../core/theme/tokens/rm_typography.dart';
import '../../../core/widgets/rm_icon_button.dart';
import '../../../core/widgets/rm_meters.dart';
import '../../../l10n/app_localizations.dart';
import '../application/verification_controller.dart';
import '../domain/verification_state.dart';
import 'widgets/verification_step_row.dart';

/// Mock presentation detail shown beside the verified phone step.
const String _kMockMaskedPhone = '+90 5•• ••• 42';

/// Mock presentation detail: how long the demo says a check takes.
const String _kMockProcessingMinutes = '2';

/// The identity-verification screen.
class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final VerificationState state = ref.watch(verificationControllerProvider);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: RmSpacing.huge),
          children: <Widget>[
            _Header(title: l10n.verificationTitle),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                RmSpacing.screenGutter,
                RmSpacing.xl,
                RmSpacing.screenGutter,
                0,
              ),
              child: _TrustHeroCard(state: state, l10n: l10n),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                RmSpacing.screenGutter,
                RmSpacing.xl,
                RmSpacing.screenGutter,
                0,
              ),
              child: _StepList(state: state),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        RmSpacing.screenGutter,
        RmSpacing.lg,
        RmSpacing.screenGutter,
        0,
      ),
      child: Row(
        children: <Widget>[
          RmIconButton(
            icon: RmIcons.chevronLeft,
            semanticLabel: l10n.commonBack,
            // The design gives this screen no forward path, so back returns to
            // Home rather than to the intro the user has already completed.
            onPressed: () => context.goNamed(AppRoutes.home),
          ),
          const SizedBox(width: RmSpacing.lg),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: RmTypography.titleMd.copyWith(
                  color: context.rmColors.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The blue hero card: progress ring plus the badge-progress copy.
class _TrustHeroCard extends StatelessWidget {
  const _TrustHeroCard({required this.state, required this.l10n});

  final VerificationState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final RmFormatters formatters = RmFormatters.of(context);

    return Container(
      padding: const EdgeInsets.all(RmSpacing.xxl),
      decoration: BoxDecoration(
        gradient: c.heroPrimary,
        borderRadius: RmRadius.brXxxl,
        boxShadow: context.rmShadows.primary,
      ),
      child: Row(
        children: <Widget>[
          RmTrustRing(
            progress: state.displayTrustScore / 100,
            size: RmSizing.trustRingSize,
            // While the score is still building the design draws the arc in
            // white on the brand gradient rather than the completed green.
            color: c.onPrimary,
            trackColor: c.onPrimary.withValues(alpha: 0.22),
            semanticLabel: l10n.verificationHeroTitle,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  formatters.trustScore(state.displayTrustScore),
                  style: RmTypography.numericLg.copyWith(color: c.onPrimary),
                ),
                Text(
                  l10n.verificationScoreCaption,
                  style: RmTypography.micro.copyWith(
                    color: c.onPrimary.withValues(alpha: 0.75),
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: RmSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  l10n.verificationHeroTitle,
                  style: RmTypography.bodyLg.copyWith(color: c.onPrimary),
                ),
                const SizedBox(height: RmSpacing.xs),
                _HeroSubtitle(state: state, l10n: l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSubtitle extends StatelessWidget {
  const _HeroSubtitle({required this.state, required this.l10n});

  final VerificationState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final TextStyle base = RmTypography.caption.copyWith(
      color: c.onPrimary.withValues(alpha: 0.78),
      height: 1.35,
    );

    // Completion changes only the copy — the design defines no success screen
    // and no onward navigation, so none is invented.
    if (state.allRequiredStepsVerified) {
      return Text(l10n.verificationHeroComplete, style: base);
    }

    return Text.rich(
      TextSpan(
        style: base,
        children: <InlineSpan>[
          TextSpan(
            text: l10n.verificationHeroSubtitleBefore(
              RmFormatters.of(context).count(state.remainingRequiredSteps),
            ),
          ),
          TextSpan(
            text: l10n.verificationHeroSubtitleEmphasis,
            style: TextStyle(color: c.onPrimary, fontWeight: FontWeight.w700),
          ),
          TextSpan(text: l10n.verificationHeroSubtitleAfter),
        ],
      ),
    );
  }
}

class _StepList extends ConsumerWidget {
  const _StepList({required this.state});

  final VerificationState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Column(
      children: <Widget>[
        for (final VerificationStep step in state.steps)
          Padding(
            padding: const EdgeInsets.only(bottom: RmSpacing.md),
            child: VerificationStepRow(
              title: _title(step.id, l10n),
              titleQualifier: step.id == VerificationStepId.licence
                  ? l10n.verificationStepLicenceQualifier
                  : null,
              status: step.status,
              statusLabel: _statusLabel(step, l10n),
              actionLabel: step.status == VerificationStepStatus.inProgress
                  ? l10n.verificationUpload
                  : null,
              onAction: step.status == VerificationStepStatus.inProgress
                  ? () => ref
                        .read(verificationControllerProvider.notifier)
                        .advance()
                  : null,
            ),
          ),
      ],
    );
  }

  static String _title(VerificationStepId id, AppLocalizations l10n) =>
      switch (id) {
        VerificationStepId.phone => l10n.verificationStepPhone,
        VerificationStepId.email => l10n.verificationStepEmail,
        VerificationStepId.identity => l10n.verificationStepIdentity,
        VerificationStepId.selfie => l10n.verificationStepSelfie,
        VerificationStepId.licence => l10n.verificationStepLicence,
      };

  static String _statusLabel(VerificationStep step, AppLocalizations l10n) =>
      switch (step.status) {
        // Only the phone step carries a detail in the design.
        VerificationStepStatus.verified =>
          step.id == VerificationStepId.phone
              ? l10n.verificationStatusVerifiedWithDetail(_kMockMaskedPhone)
              : l10n.verificationStatusVerified,
        VerificationStepStatus.inProgress => l10n.verificationStatusInProgress(
          _kMockProcessingMinutes,
        ),
        VerificationStepStatus.pending => l10n.verificationStatusPending,
        VerificationStepStatus.optional => l10n.verificationStatusOptional,
      };
}
