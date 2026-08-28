// ─────────────────────────────────────────────────────────────
// RideMate — My Routes
//
// The journeys a member has published, as the server holds them.
//
// The immutable design has no such screen. Publishing became real in F4 and a
// driver had no way to see or withdraw what they had published, which is worse
// than a screen the comp does not draw — so this is an approved truthfulness
// extension, composed entirely from existing primitives. Nothing new is
// invented visually; RouteTimeline in Discovery resembles what a route card
// needs and is deliberately NOT imported, because resembling something is not
// a reason to depend on another feature.
//
// NO FIXTURE, EVER. When the request fails this screen says so and offers a
// retry. It never falls back to MockRouteOffers or any other fixture: a route
// nobody published, rendered on the screen that exists to show what you
// published, would be the exact lie Phase 10 was built to remove.
//
// DEVIATION D-myroutes-1: loading, empty, failure, retry and pagination states
// have no counterpart in the design source, which draws none of them anywhere.
// See docs/design-system.md §8.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/api/rm_error_copy.dart';
import '../../../core/api/rm_failure.dart';
import '../../../core/format/rm_text_conventions.dart';
import '../../../core/icons/rm_icons.dart';
import '../../../core/routes/published_route.dart';
import '../../../core/theme/tokens/rm_colors.dart';
import '../../../core/theme/tokens/rm_spacing.dart';
import '../../../core/theme/tokens/rm_typography.dart';
import '../../../core/widgets/rm_button.dart';
import '../../../core/widgets/rm_icon_button.dart';
import '../../../core/widgets/rm_list_row.dart';
import '../../../l10n/app_localizations.dart';
import '../application/my_routes_providers.dart';
import '../domain/my_routes_page.dart';
import 'widgets/cancel_route_sheet.dart';
import 'widgets/my_route_card.dart';

class MyRoutesScreen extends ConsumerWidget {
  const MyRoutesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmColors c = context.rmColors;
    final AsyncValue<MyRoutesPage> page = ref.watch(myRoutesProvider);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                RmSpacing.screenGutter,
                RmSpacing.md,
                RmSpacing.screenGutter,
                0,
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
                    child: Text(
                      l10n.myRoutesTitle,
                      style: RmTypography.label.copyWith(color: c.ink),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              // `hasError` is tested BEFORE `isLoading`, and the order is not
              // cosmetic: Riverpod retries a failed provider on its own, so a
              // build that threw sits in a loading state carrying its error.
              // Matching AsyncLoading first would show a spinner for ever and
              // never tell the member anything went wrong. Same idiom as the
              // Create Route catalogue.
              child: switch (page) {
                // The whole list failed. Nothing is rendered in its place —
                // there is nothing honest to render — so the failure is stated
                // and can be tried again.
                AsyncValue<MyRoutesPage>(
                  hasError: true,
                  :final Object? error,
                ) =>
                  _Centred(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        RmInlineMessage(
                          message: error is RmFailure
                              ? error.copy(l10n)
                              : l10n.errorUnexpected,
                          icon: RmIcons.alertTriangle,
                          tone: RmRowTone.danger,
                        ),
                        const SizedBox(height: RmSpacing.md),
                        RmButton(
                          label: l10n.commonRetry,
                          size: RmButtonSize.sm,
                          variant: RmButtonVariant.outline,
                          onPressed: () =>
                              ref.read(myRoutesProvider.notifier).refresh(),
                        ),
                      ],
                    ),
                  ),
                AsyncValue<MyRoutesPage>(isLoading: true) => _Centred(
                  child: Text(
                    l10n.commonLoading,
                    style: RmTypography.body.copyWith(color: c.sub),
                  ),
                ),
                AsyncValue<MyRoutesPage>(:final MyRoutesPage? value)
                    when value != null =>
                  value.isEmpty ? _Empty(l10n: l10n) : _RouteList(page: value),
                _ => const SizedBox.shrink(),
              },
            ),
          ],
        ),
      ),
    );
  }

  static void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoutes.home);
    }
  }
}

class _RouteList extends ConsumerWidget {
  const _RouteList({required this.page});

  final MyRoutesPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        RmSpacing.screenGutter,
        RmSpacing.lg,
        RmSpacing.screenGutter,
        RmSpacing.xl,
      ),
      children: <Widget>[
        // Rendered in the order the server returned them. Nothing here sorts.
        for (int i = 0; i < page.routes.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: RmSpacing.md),
          MyRouteCard(
            route: page.routes[i],
            isCancelling: page.isCancelling(page.routes[i].id),
            onCancel: () => _cancel(context, ref, page.routes[i]),
          ),
        ],
        // Page two failing does not take page one off the screen.
        if (page.loadMoreFailure != null) ...<Widget>[
          const SizedBox(height: RmSpacing.md),
          RmInlineMessage(
            message: l10n.myRoutesLoadMoreFailed,
            icon: RmIcons.alertTriangle,
            tone: RmRowTone.danger,
          ),
        ],
        // Shown only while the server says there is more. When it stops
        // sending a cursor the control disappears rather than sitting there
        // doing nothing.
        if (page.hasMore) ...<Widget>[
          const SizedBox(height: RmSpacing.lg),
          RmButton(
            label: page.loadMoreFailure == null
                ? l10n.myRoutesLoadMore
                : l10n.commonRetry,
            variant: RmButtonVariant.outline,
            fullWidth: true,
            loading: page.isLoadingMore,
            onPressed: () => ref.read(myRoutesProvider.notifier).loadMore(),
          ),
        ],
      ],
    );
  }

  /// Confirm, then ask the server, then show what it said.
  ///
  /// Nothing is marked cancelled before the answer arrives, and a failure
  /// leaves the route exactly as it was — including a 404, which is not
  /// evidence that this member's route has gone.
  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    PublishedRoute route,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    final bool confirmed = await confirmRouteCancellation(
      context,
      journey: RmTextConventions.route(
        route.origin.label,
        route.destination.label,
      ),
    );

    if (!confirmed) return;

    final RmFailure? failure = await ref
        .read(myRoutesProvider.notifier)
        .cancel(route.id);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            failure == null ? l10n.myRoutesCancelled : failure.copy(l10n),
          ),
        ),
      );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return _Centred(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            l10n.myRoutesEmptyTitle,
            style: RmTypography.body.copyWith(color: c.ink),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: RmSpacing.xs),
          Text(
            // No sample route, no placeholder card. An empty list is a fact.
            l10n.myRoutesEmptyBody,
            style: RmTypography.caption.copyWith(color: c.sub),
            textAlign: TextAlign.center,
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
