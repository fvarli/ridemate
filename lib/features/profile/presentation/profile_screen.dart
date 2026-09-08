// ─────────────────────────────────────────────────────────────
// RideMate — Profile
//
// Source: docs/claude-designs/RideMate App.dc.html, "PROFILE · TRUST"
// (immutable).
//
// WHAT THIS SCREEN USED TO BE, AND WHY MOST OF IT IS GONE
//
// The comp draws a Trust Score ring, a four-factor breakdown, a percentile
// tier, three stat tiles — trips, rating, savings — and a verification-badge
// count. Every one of those was a figure copied out of the design, and while
// the whole screen was imaginary that was honest enough: a fixture next to a
// fixture claims nothing.
//
// Phase 11 put a real account's real name at the top. A Trust Score of 92
// underneath it is no longer a placeholder — it is the app telling a member
// something about themselves that nothing computed, beside something that is
// true, which is exactly what makes it believable. There is no reputation
// store, no ratings, no trip history and no verification system, so the
// figures are not moved, softened or labelled; they are removed.
//
// D-profile-2: the screen is now identity and navigation. What returns is
// whatever a later phase can actually source — reviews with Phase 15, trips
// with Phase 14 — and it returns with a backend behind it.
//
// THE THREE STATES, AND WHY NONE OF THEM INVENTS A NAME
//
//   ready       the server's profile
//   error       an honest failure with a retry — NEVER the old fixture
//   missing     normally intercepted by the router; if it is ever reached
//               here, it says so and offers setup rather than a name
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/api/rm_error_copy.dart';
import '../../../core/api/rm_failure.dart';
import '../../../core/icons/rm_icons.dart';
import '../../../core/profile/profile.dart';
import '../../../core/theme/tokens/rm_colors.dart';
import '../../../core/theme/tokens/rm_spacing.dart';
import '../../../core/theme/tokens/rm_typography.dart';
import '../../../core/widgets/rm_button.dart';
import '../../../core/widgets/rm_list_row.dart';
import '../../../l10n/app_localizations.dart';
import '../application/my_profile_providers.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_links.dart';

/// The member's own profile.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RmColors c = context.rmColors;
    final AsyncValue<ProfileState> state = ref.watch(myProfileProvider);

    return Scaffold(
      backgroundColor: c.background,
      // `hasError` is tested BEFORE `isLoading`, the same idiom the other two
      // server-backed surfaces use: a build that threw sits in a loading state
      // carrying its error, and matching loading first would spin for ever
      // while never telling the member anything went wrong.
      body: switch (state) {
        AsyncValue<ProfileState>(hasError: true, :final Object? error) =>
          _Unavailable(failure: error, onRetry: () => _retry(ref)),
        AsyncValue<ProfileState>(:final ProfileState? value)
            when value != null =>
          switch (value) {
            ProfileReady(:final Profile profile) => _Loaded(profile: profile),
            ProfileMissing() => const _NoProfileYet(),
          },
        _ => const _Loading(),
      },
    );
  }

  static void _retry(WidgetRef ref) =>
      ref.read(myProfileProvider.notifier).refresh();
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.zero,
    children: <Widget>[
      ProfileHeader(profile: profile),
      // No negative-margin overlap any more. The comp's -36px existed so the
      // trust card could ride up over the header; with the card gone it would
      // only pull the rows under a gradient they have no reason to touch — and
      // an overlap that serves nothing is an overlap that eventually swallows
      // a tap.
      const SizedBox(height: RmSpacing.lg),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: RmSpacing.screenGutter),
        child: ProfileLinks(
          onEditProfile: () => context.pushNamed(AppRoutes.profileEdit),
          onOpenReviews: () => context.pushNamed(AppRoutes.reviews),
          onOpenMyRoutes: () => context.pushNamed(AppRoutes.myRoutes),
        ),
      ),
      const SizedBox(height: RmSpacing.xl),
    ],
  );
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return _Centred(
      child: Text(
        AppLocalizations.of(context).commonLoading,
        style: RmTypography.body.copyWith(color: c.sub),
      ),
    );
  }
}

/// The read failed. Nothing is rendered in its place.
///
/// In particular not the previous fixture: a screen that fell back to a name
/// nobody chose would be inventing an identity at the exact moment it could
/// not confirm one.
class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.failure, required this.onRetry});

  final Object? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return _Centred(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          RmInlineMessage(
            message: failure is RmFailure
                ? (failure! as RmFailure).copy(l10n)
                : l10n.errorUnexpected,
            icon: RmIcons.alertTriangle,
            tone: RmRowTone.danger,
          ),
          const SizedBox(height: RmSpacing.md),
          RmButton(
            label: l10n.commonRetry,
            size: RmButtonSize.sm,
            variant: RmButtonVariant.outline,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

/// The server says there is no profile.
///
/// The router normally intercepts this before anyone gets here, so reaching it
/// means something unusual happened. It still must not invent a name — it says
/// what is true and offers the one action that fixes it.
class _NoProfileYet extends StatelessWidget {
  const _NoProfileYet();

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return _Centred(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            l10n.profileNoProfileYet,
            style: RmTypography.body.copyWith(color: c.ink),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: RmSpacing.md),
          RmButton(
            label: l10n.profileSetupSubmit,
            size: RmButtonSize.sm,
            variant: RmButtonVariant.outline,
            onPressed: () => context.goNamed(AppRoutes.profileSetup),
          ),
        ],
      ),
    );
  }
}

class _Centred extends StatelessWidget {
  const _Centred({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(RmSpacing.screenGutter),
      child: child,
    ),
  );
}
