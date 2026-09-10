// ─────────────────────────────────────────────────────────────
// RideMate — My Requests
//
// What this member has asked for, and what came of it.
//
// HISTORY, NOT A FEED
//
// Nothing here is filtered by what discovery would show today. A request on a
// journey that was later cancelled stays, and so does one on a journey that has
// departed — this is the only surface that says what became of an asking, and
// dropping rows because the journey moved on would erase the member's own
// record. Every status appears for the same reason: a declined request is an
// answer, not an absence.
//
// TWO TRUTHS, SIDE BY SIDE
//
// The request's status is what the member asked and what they were told. The
// journey's status and departure state are how the journey now stands. A card
// showing `accepted` above `this journey was cancelled` is not a contradiction
// to reconcile — it is both facts, and collapsing them into one would claim a
// decision nobody made.
//
// NO FIXTURE, EVER. A failed read says so and offers a retry.
//
// The design source draws no such screen. Same approved extension as My
// Routes (D-myroutes-1), composed from existing primitives.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/api/rm_error_copy.dart';
import '../../../core/api/rm_failure.dart';
import '../../../core/icons/rm_icons.dart';
import '../../../core/seat_requests/seat_request.dart';
import '../../../core/theme/tokens/rm_colors.dart';
import '../../../core/theme/tokens/rm_spacing.dart';
import '../../../core/theme/tokens/rm_typography.dart';
import '../../../core/widgets/rm_button.dart';
import '../../../core/widgets/rm_icon_button.dart';
import '../../../core/widgets/rm_list_row.dart';
import '../../../l10n/app_localizations.dart';
import '../application/seat_request_providers.dart';
import '../domain/seat_request_page.dart';
import 'widgets/my_request_card.dart';

class MyRequestsScreen extends ConsumerWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmColors c = context.rmColors;
    final AsyncValue<SeatRequestPage<MySeatRequest>> page = ref.watch(
      mySeatRequestsProvider,
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
                          l10n.myRequestsTitle,
                          style: RmTypography.label.copyWith(color: c.ink),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // The order the server returned them in, said plainly.
                        // Nothing here sorts, so nothing here may imply a
                        // ranking.
                        Text(
                          l10n.myRequestsSubtitle,
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
              // never say anything went wrong. Same idiom as My Routes.
              child: switch (page) {
                AsyncValue<SeatRequestPage<MySeatRequest>>(
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
                              .read(mySeatRequestsProvider.notifier)
                              .refresh(),
                        ),
                      ],
                    ),
                  ),
                AsyncValue<SeatRequestPage<MySeatRequest>>(isLoading: true) =>
                  _Centred(
                    child: Text(
                      l10n.commonLoading,
                      style: RmTypography.body.copyWith(color: c.sub),
                    ),
                  ),
                AsyncValue<SeatRequestPage<MySeatRequest>>(
                  :final SeatRequestPage<MySeatRequest>? value,
                )
                    when value != null =>
                  // Empty means the server answered and held nothing. It is
                  // never what a failure looks like.
                  value.isEmpty
                      ? _Empty(l10n: l10n)
                      : _RequestList(page: value),
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

class _RequestList extends ConsumerWidget {
  const _RequestList({required this.page});

  final SeatRequestPage<MySeatRequest> page;

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
        // In the order the server returned them. Nothing here sorts.
        for (int i = 0; i < page.requests.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: RmSpacing.md),
          MyRequestCard(
            request: page.requests[i],
            isWithdrawing: page.isWithdrawing(page.requests[i].id),
            onWithdraw: () => _withdraw(context, ref, page.requests[i]),
          ),
        ],
        // Page two failing does not take page one off the screen.
        if (page.loadMoreFailure != null) ...<Widget>[
          const SizedBox(height: RmSpacing.md),
          RmInlineMessage(
            message: l10n.myRequestsLoadMoreFailed,
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
                ? l10n.myRequestsLoadMore
                : l10n.commonRetry,
            variant: RmButtonVariant.outline,
            loading: page.isLoadingMore,
            onPressed: () =>
                ref.read(mySeatRequestsProvider.notifier).loadMore(),
          ),
        ],
      ],
    );
  }

  /// Ask the server, then show what it said.
  ///
  /// Nothing is marked withdrawn before the answer arrives, and a failure
  /// leaves the request exactly as it was.
  Future<void> _withdraw(
    BuildContext context,
    WidgetRef ref,
    MySeatRequest request,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    final RmFailure? failure = await ref
        .read(mySeatRequestsProvider.notifier)
        .withdraw(request.id);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            failure == null
                ? l10n.myRequestsWithdrawn
                : l10n.myRequestsWithdrawFailed,
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
            l10n.myRequestsEmpty,
            style: RmTypography.body.copyWith(color: c.ink),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: RmSpacing.xs),
          Text(
            l10n.myRequestsEmptyBody,
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
