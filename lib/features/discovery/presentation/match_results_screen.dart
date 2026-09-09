// ─────────────────────────────────────────────────────────────
// RideMate — Match results
//
// Source: docs/claude-designs/RideMate App.dc.html, "MATCH RESULTS" (immutable).
//
// REAL RESULTS, AND THEREFORE A DIFFERENT SCREEN
//
// This listed a fixture in a declared order per sort chip. It now lists what
// GET /api/v1/routes/discover returned, which changes what the screen is
// allowed to say about itself.
//
// The sort chips are gone. They offered `En iyi eşleşme`, `En yakın` and `En
// ucuz` — a ranking, a distance and a price, none of which exists. The one
// ordering that is real is the order journeys were published in, and the header
// says exactly that rather than implying a match quality nobody computed.
//
// The result count is gone from the search CTA for the same reason: it reported
// how many results there would be before the search had run.
//
// FIVE STATES, AND NO FIXTURE IN ANY OF THEM
//
//   idle      nobody has searched yet — not the same as finding nothing
//   loading   the request is out
//   matches   what the server returned, possibly none
//   failure   an honest message and a retry
//   more      a load-more control while the server says there is more
//
// A failed search never falls back to MockRouteOffers. Invented people on the
// screen where somebody decides who to travel with is the lie this phase exists
// to remove.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/rm_error_copy.dart';
import '../../../core/api/rm_failure.dart';
import '../../../core/icons/rm_icons.dart';
import '../../../core/theme/tokens/rm_colors.dart';
import '../../../core/theme/tokens/rm_spacing.dart';
import '../../../core/theme/tokens/rm_typography.dart';
import '../../../core/widgets/rm_button.dart';
import '../../../core/widgets/rm_icon_button.dart';
import '../../../core/widgets/rm_list_row.dart';
import '../../../l10n/app_localizations.dart';
import '../application/discovery_search_providers.dart';
import 'widgets/discovered_route_card.dart';

/// The results list.
class MatchResultsScreen extends ConsumerWidget {
  const MatchResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RmColors c = context.rmColors;
    final AsyncValue<DiscoveryState> results = ref.watch(discoveryProvider);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const _Header(),
            Expanded(
              // `hasError` before `isLoading`, the same idiom every server-backed
              // surface uses: a build that threw sits in a loading state carrying
              // its error, and matching loading first would spin for ever.
              child: switch (results) {
                AsyncValue<DiscoveryState>(
                  hasError: true,
                  :final Object? error,
                ) =>
                  _Failed(failure: error, onRetry: () => _retry(ref)),
                AsyncValue<DiscoveryState>(:final DiscoveryState? value)
                    when value != null =>
                  switch (value) {
                    DiscoveryIdle() => const _Message(kind: _MessageKind.idle),
                    DiscoveryMatches(routes: []) => const _Message(
                      kind: _MessageKind.empty,
                    ),
                    final DiscoveryMatches matches => _Results(
                      matches: matches,
                    ),
                  },
                _ => const _Loading(),
              },
            ),
          ],
        ),
      ),
    );
  }

  static void _retry(WidgetRef ref) =>
      ref.read(discoveryProvider.notifier).refresh();
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        RmSpacing.screenGutter,
        RmSpacing.lg,
        RmSpacing.screenGutter,
        RmSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          RmIconButton(
            icon: RmIcons.chevronLeft,
            semanticLabel: l10n.commonBack,
            onPressed: () => _back(context),
          ),
          const SizedBox(width: RmSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  l10n.discoveryTitle,
                  style: RmTypography.label.copyWith(color: c.ink),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // The only ordering claim on the screen, and it is the true one.
                Text(
                  l10n.discoveryOrdering,
                  style: RmTypography.caption.copyWith(color: c.sub),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoutesSearchFallback.search);
    }
  }
}

/// Kept local so the header does not import the whole route registry for one
/// fallback destination.
abstract final class AppRoutesSearchFallback {
  const AppRoutesSearchFallback._();

  static const String search = 'search';
}

class _Results extends ConsumerWidget {
  const _Results({required this.matches});

  final DiscoveryMatches matches;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        RmSpacing.screenGutter,
        0,
        RmSpacing.screenGutter,
        RmSpacing.huge,
      ),
      children: <Widget>[
        for (int i = 0; i < matches.routes.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: RmSpacing.md),
          DiscoveredRouteCard(route: matches.routes[i]),
        ],
        // Page two failing does not take page one off the screen.
        if (matches.loadMoreFailure != null) ...<Widget>[
          const SizedBox(height: RmSpacing.md),
          RmInlineMessage(
            message: l10n.discoveryLoadMoreFailed,
            icon: RmIcons.alertTriangle,
            tone: RmRowTone.danger,
          ),
        ],
        // Shown only while the server says there is more. When it stops sending
        // a cursor the control disappears rather than sitting there doing
        // nothing.
        if (matches.hasMore) ...<Widget>[
          const SizedBox(height: RmSpacing.lg),
          RmButton(
            label: matches.loadMoreFailure == null
                ? l10n.discoveryLoadMore
                : l10n.commonRetry,
            variant: RmButtonVariant.outline,
            fullWidth: true,
            loading: matches.isLoadingMore,
            onPressed: () => ref.read(discoveryProvider.notifier).loadMore(),
          ),
        ],
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => _Centred(
    child: Text(
      AppLocalizations.of(context).commonLoading,
      style: RmTypography.body.copyWith(color: context.rmColors.sub),
    ),
  );
}

enum _MessageKind { idle, empty }

/// Nothing asked, or nothing found — deliberately different sentences.
///
/// An empty search result is the server's answer about two named places. Idle
/// is the app before anybody asked, and saying "no journeys" there would be
/// reporting on a question nobody put.
class _Message extends StatelessWidget {
  const _Message({required this.kind});

  final _MessageKind kind;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return _Centred(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            switch (kind) {
              _MessageKind.idle => l10n.discoveryIdle,
              _MessageKind.empty => l10n.discoveryEmpty,
            },
            style: RmTypography.body.copyWith(color: c.ink),
            textAlign: TextAlign.center,
          ),
          if (kind == _MessageKind.empty) ...<Widget>[
            const SizedBox(height: RmSpacing.xs),
            Text(
              l10n.discoveryEmptyBody,
              style: RmTypography.caption.copyWith(color: c.sub),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// The search failed. Nothing is rendered in its place.
class _Failed extends StatelessWidget {
  const _Failed({required this.failure, required this.onRetry});

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
