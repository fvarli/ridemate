// ─────────────────────────────────────────────────────────────
// RideMate — The driver's dated journeys, above their plans
//
// WHY IT SITS ON MY ROUTES
//
// A driver who opens My Routes is asking one of two questions: what have I
// published, and what am I driving. The plans answer the first and have always
// been here; this answers the second, which until Phase 16b had no answer at
// all for a weekday plan — its card offered no lifecycle, because a plan has no
// single journey to start.
//
// SEPARATE, AND VISIBLY SO
//
// Not folded into the route cards. A plan and one of its days are different
// things, and merging them is exactly how `MyRoute.trip == null` gets read as
// `not_started`. The section is its own heading, its own list, and its own
// feed.
//
// THE FEED IS BOUNDED AND THE SERVER SAYS SO
//
// Today's journey of each published route that runs today, plus anything of
// this driver's still under way — whatever its date, and whatever became of its
// plan. Nothing here recreates those rules: no weekday arithmetic, no device
// date, no filtering of a journey because its day looks past. A journey that
// arrives is a journey the driver can act on.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/api/rm_error_copy.dart';
import '../../../../core/api/rm_failure.dart';
import '../../../../core/icons/rm_icons.dart';
import '../../../../core/journeys/journey.dart';
import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_button.dart';
import '../../../../core/widgets/rm_list_row.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/journeys_providers.dart';
import '../../domain/my_journeys_page.dart';
import 'journey_card.dart';

class JourneysSection extends ConsumerWidget {
  const JourneysSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmColors c = context.rmColors;
    final AsyncValue<MyJourneysPage> feed = ref.watch(myJourneysProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            l10n.journeysSectionTitle,
            style: RmTypography.titleSm.copyWith(color: c.ink),
          ),
        ),
        const SizedBox(height: RmSpacing.xxs),
        Text(
          l10n.journeysSectionBody,
          style: RmTypography.caption.copyWith(color: c.sub),
        ),
        const SizedBox(height: RmSpacing.md),
        // `hasError` before `isLoading`: a build that threw sits in a loading
        // state carrying its error, so matching loading first would spin for
        // ever.
        switch (feed) {
          AsyncValue<MyJourneysPage>(hasError: true, :final Object? error) =>
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                RmInlineMessage(
                  message: error is RmFailure
                      ? error.copy(l10n)
                      : l10n.journeysFailed,
                  icon: RmIcons.alertTriangle,
                  tone: RmRowTone.danger,
                ),
                const SizedBox(height: RmSpacing.sm),
                RmButton(
                  label: l10n.commonRetry,
                  size: RmButtonSize.sm,
                  variant: RmButtonVariant.outline,
                  onPressed: () =>
                      ref.read(myJourneysProvider.notifier).refresh(),
                ),
              ],
            ),
          AsyncValue<MyJourneysPage>(isLoading: true) => Text(
            l10n.commonLoading,
            style: RmTypography.body.copyWith(color: c.sub),
          ),
          AsyncValue<MyJourneysPage>(:final MyJourneysPage? value)
              when value != null =>
            _List(page: value),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }
}

class _List extends ConsumerWidget {
  const _List({required this.page});

  final MyJourneysPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmColors c = context.rmColors;

    // Nothing running today. Said plainly, and without a reason: the feed does
    // not say whether the plans are cancelled, past or simply not due, and a
    // sentence that picked one would be inventing it.
    if (page.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.journeysEmpty,
            style: RmTypography.body.copyWith(color: c.ink),
          ),
          const SizedBox(height: RmSpacing.xxs),
          Text(
            l10n.journeysEmptyBody,
            style: RmTypography.caption.copyWith(color: c.sub),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // In the order the server returned them: `(service_date, route_id)`
        // descending. Nothing here sorts, and that order is deterministic
        // rather than a global chronology — routes carry their own timezones.
        for (int i = 0; i < page.journeys.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: RmSpacing.sm),
          JourneyCard(
            journey: page.journeys[i],
            onOpen: () => _open(context, page.journeys[i]),
          ),
        ],
        if (page.loadMoreFailure != null) ...<Widget>[
          const SizedBox(height: RmSpacing.sm),
          RmInlineMessage(
            message: l10n.myRoutesLoadMoreFailed,
            icon: RmIcons.alertTriangle,
            tone: RmRowTone.danger,
          ),
        ],
        if (page.hasMore) ...<Widget>[
          const SizedBox(height: RmSpacing.md),
          RmButton(
            label: page.loadMoreFailure == null
                ? l10n.myRoutesLoadMore
                : l10n.commonRetry,
            size: RmButtonSize.sm,
            variant: RmButtonVariant.outline,
            fullWidth: true,
            loading: page.isLoadingMore,
            onPressed: () => ref.read(myJourneysProvider.notifier).loadMore(),
          ),
        ],
      ],
    );
  }

  /// Opens exactly this journey.
  ///
  /// Both halves of the identity travel: the route AND the day. The route-only
  /// Trip Status would address a plan's single journey, which a plan does not
  /// have — and for a one-off route it would be a second way to reach the same
  /// lifecycle through a different feed.
  static void _open(BuildContext context, Journey journey) => context.pushNamed(
    AppRoutes.journeyStatus,
    pathParameters: <String, String>{
      'routeId': journey.routeId,
      'serviceDate': journey.serviceDate.iso,
    },
  );
}
