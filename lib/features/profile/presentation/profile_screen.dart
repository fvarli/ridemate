// ─────────────────────────────────────────────────────────────
// RideMate — Profile / Trust
//
// Source: docs/claude-designs/RideMate App.dc.html, "PROFILE · TRUST"
// (immutable).
//
// Five stacked pieces, as drawn: the gradient identity header, the Trust
// Score card riding up over it, the three stat tiles, and the two list rows.
//
// PHASE 6 SCOPE. There is no account, no session, no identity provider, no
// reputation service and no Trust Score engine. Everything on this screen is
// a figure copied out of the design, and nothing on it is computed — see
// profile_snapshot.dart.
//
// The comp draws no navigation bar, but this is a tab destination reached
// from the shell, so the bar stays (D-profile-1, following D-search-1). It
// also draws no back control, which is correct for a tab.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/theme/tokens/rm_colors.dart';
import '../../../core/theme/tokens/rm_spacing.dart';
import '../application/profile_providers.dart';
import '../domain/profile_snapshot.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_links.dart';
import 'widgets/profile_stats.dart';
import 'widgets/trust_score_card.dart';

/// Design -36px: how far the Trust Score card rides up over the header, at
/// RmScale.factor.
const double kTrustCardOverlap = 51;

/// The member's own profile.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RmColors c = context.rmColors;
    final ProfileSnapshot snapshot = ref.watch(profileSnapshotProvider);

    return Scaffold(
      backgroundColor: c.background,
      body: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          ProfileHeader(snapshot: snapshot),
          // A relative shift rather than a Stack: the identity pill wraps at
          // large text scales and the header has to be free to grow.
          Transform.translate(
            offset: const Offset(0, -kTrustCardOverlap),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: RmSpacing.screenGutter,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TrustScoreCard(snapshot: snapshot),
                  const SizedBox(height: RmSpacing.md),
                  ProfileStats(snapshot: snapshot),
                  const SizedBox(height: RmSpacing.md),
                  ProfileLinks(
                    snapshot: snapshot,
                    onOpenReviews: () => context.pushNamed(AppRoutes.reviews),
                    onOpenMyRoutes: () => context.pushNamed(AppRoutes.myRoutes),
                  ),
                ],
              ),
            ),
          ),
          // The translate above leaves its own height behind it.
          const SizedBox(height: RmSpacing.xl),
        ],
      ),
    );
  }
}
