// ─────────────────────────────────────────────────────────────
// RideMate — Reviews about me
//
// What other members said about journeys this one shared, as the backend
// released them.
//
// PRIVATE FEEDBACK, NOT A REPUTATION PAGE
//
// There is no average, no total, no distribution, no trust score, no tier and
// no badge — not because they are hidden here, but because RideMate computes
// none of them anywhere. This screen is the member reading their own feedback,
// and nothing on it is shown to anybody else.
//
// EMPTY IS NOT "NOBODY REVIEWED YOU"
//
// A review becomes visible when the other side has written one too or the
// fourteen days have run out, and which of those happened is deliberately
// withheld. So an empty page means exactly one thing: **the server released
// nothing**. Unreleased reviews may well exist, and this client is not
// permitted to know — which is why the empty copy claims nothing about who did
// or did not write. Getting that sentence wrong would leak the very fact the
// release rule protects.
//
// NO FIXTURE, EVER. A failed read says so and offers a retry.
//
// The design source draws a Reviews screen full of invented figures — a 4.9
// average over 73 reviews, a histogram and four tag counts. None of it is
// sourced by anything, so none of it is here. Same approved extension as My
// Routes (D-myroutes-1), composed from existing primitives.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
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
import '../application/received_reviews_providers.dart';
import '../domain/received_reviews_page.dart';
import 'widgets/received_review_card.dart';

class ReceivedReviewsScreen extends ConsumerWidget {
  const ReceivedReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmColors c = context.rmColors;
    final AsyncValue<ReceivedReviewsPage> page = ref.watch(
      receivedReviewsProvider,
    );

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          l10n.receivedReviewsTitle,
                          style: RmTypography.label.copyWith(color: c.ink),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // The order the server returned them in, said plainly.
                        // Nothing here sorts, so nothing here may imply a
                        // ranking.
                        Text(
                          l10n.receivedReviewsSubtitle,
                          style: RmTypography.caption.copyWith(color: c.sub),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              // `hasError` before `isLoading`, and the order is not cosmetic: a
              // build that threw sits in a loading state carrying its error, so
              // matching AsyncLoading first would show a spinner for ever and
              // never say anything went wrong. Same idiom as My Requests.
              child: switch (page) {
                AsyncValue<ReceivedReviewsPage>(
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
                          onPressed: () => ref
                              .read(receivedReviewsProvider.notifier)
                              .refresh(),
                        ),
                      ],
                    ),
                  ),
                AsyncValue<ReceivedReviewsPage>(isLoading: true) => _Centred(
                  child: Text(
                    l10n.commonLoading,
                    style: RmTypography.body.copyWith(color: c.sub),
                  ),
                ),
                AsyncValue<ReceivedReviewsPage>(
                  :final ReceivedReviewsPage? value,
                )
                    when value != null =>
                  // Empty means the server released nothing. It is never what
                  // a failure looks like, and never a claim about who wrote.
                  value.isEmpty ? _Empty(l10n: l10n) : _ReviewList(page: value),
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

class _ReviewList extends ConsumerWidget {
  const _ReviewList({required this.page});

  final ReceivedReviewsPage page;

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
        // In the order the server returned them. Nothing here sorts, counts or
        // groups — and nothing renders the length of this list as a figure.
        for (int i = 0; i < page.reviews.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: RmSpacing.md),
          ReceivedReviewCard(review: page.reviews[i]),
        ],
        // Page two failing does not take page one off the screen.
        if (page.loadMoreFailure != null) ...<Widget>[
          const SizedBox(height: RmSpacing.md),
          RmInlineMessage(
            message: l10n.receivedReviewsLoadMoreFailed,
            icon: RmIcons.alertTriangle,
            tone: RmRowTone.danger,
          ),
        ],
        // Shown only while the server offers a position. When it stops sending
        // a cursor the control disappears rather than sitting there doing
        // nothing.
        if (page.hasMore) ...<Widget>[
          const SizedBox(height: RmSpacing.lg),
          RmButton(
            label: page.loadMoreFailure == null
                ? l10n.receivedReviewsLoadMore
                : l10n.commonRetry,
            variant: RmButtonVariant.outline,
            loading: page.isLoadingMore,
            onPressed: () =>
                ref.read(receivedReviewsProvider.notifier).loadMore(),
          ),
        ],
      ],
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
          // Says what is true — there is nothing to show — and stops there.
          // NOT "nobody has reviewed you": reviews this member may not see can
          // exist, and saying otherwise would report their absence as a fact.
          Text(
            l10n.receivedReviewsEmpty,
            style: RmTypography.body.copyWith(color: c.ink),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: RmSpacing.xs),
          Text(
            l10n.receivedReviewsEmptyBody,
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
