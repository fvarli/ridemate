// ─────────────────────────────────────────────────────────────
// RideMate — Incoming requests
//
// Who has asked for a seat on one journey this driver published, and the two
// answers they can give.
//
// CAPACITY IS NOT THIS SCREEN'S TO KNOW
//
// Nothing here counts accepted rows, works out how many seats are left, or
// decides whether a journey is full. The backend serializes acceptance inside
// the route lock and owns that invariant entirely; this asks, and renders what
// it is told. A `route_full` answer is the server's, not a conclusion drawn
// here — and a refused acceptance never turns a row into an accepted one.
//
// ROUTE-SCOPED, AND DELIBERATELY NOT AN INBOX
//
// A driver holds several journeys and each has its own list. One list of
// everything would imply arrival — that something reached them — and nothing
// notifies anybody yet.
//
// NO FIXTURE, EVER. A failed read says so and offers a retry.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/api/rm_error_copy.dart';
import '../../../core/api/rm_failure.dart';
import '../../../core/icons/rm_icons.dart';
import '../../../core/seat_requests/seat_request.dart';
import '../../../core/seat_requests/seat_request_decoder.dart';
import '../../../core/theme/tokens/rm_colors.dart';
import '../../../core/theme/tokens/rm_spacing.dart';
import '../../../core/theme/tokens/rm_typography.dart';
import '../../../core/widgets/rm_button.dart';
import '../../../core/widgets/rm_icon_button.dart';
import '../../../core/widgets/rm_list_row.dart';
import '../../../l10n/app_localizations.dart';
import '../application/seat_request_providers.dart';
import '../domain/seat_request_page.dart';
import 'widgets/incoming_request_card.dart';

class RouteRequestsScreen extends ConsumerWidget {
  const RouteRequestsScreen({required this.routeId, super.key});

  final String routeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmColors c = context.rmColors;
    final AsyncValue<SeatRequestPage<IncomingSeatRequest>> page = ref.watch(
      incomingSeatRequestsProvider(routeId),
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
                    child: Text(
                      l10n.routeRequestsTitle,
                      style: RmTypography.label.copyWith(color: c.ink),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              // `hasError` before `isLoading`: a build that threw sits in a
              // loading state carrying its error, so matching AsyncLoading
              // first would spin for ever and say nothing.
              child: switch (page) {
                AsyncValue<SeatRequestPage<IncomingSeatRequest>>(
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
                              .read(
                                incomingSeatRequestsProvider(routeId).notifier,
                              )
                              .refresh(),
                        ),
                      ],
                    ),
                  ),
                AsyncValue<SeatRequestPage<IncomingSeatRequest>>(
                  isLoading: true,
                ) =>
                  _Centred(
                    child: Text(
                      l10n.commonLoading,
                      style: RmTypography.body.copyWith(color: c.sub),
                    ),
                  ),
                AsyncValue<SeatRequestPage<IncomingSeatRequest>>(
                  :final SeatRequestPage<IncomingSeatRequest>? value,
                )
                    when value != null =>
                  // Empty means the server answered and held nothing. It is
                  // never what a failure looks like.
                  value.isEmpty
                      ? _Empty(l10n: l10n)
                      : _RequestList(routeId: routeId, page: value),
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
      context.goNamed(AppRoutes.myRoutes);
    }
  }
}

class _RequestList extends ConsumerWidget {
  const _RequestList({required this.routeId, required this.page});

  final String routeId;
  final SeatRequestPage<IncomingSeatRequest> page;

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
        // In the order the server returned them. Nothing here sorts, and a
        // decision does not move a row.
        for (int i = 0; i < page.requests.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: RmSpacing.md),
          IncomingRequestCard(
            request: page.requests[i],
            // Keyed by request id: one row being decided leaves the others
            // usable.
            isDeciding: page.isBusy(page.requests[i].id),
            onAccept: () =>
                _decide(context, ref, page.requests[i], accept: true),
            onDecline: () =>
                _decide(context, ref, page.requests[i], accept: false),
          ),
        ],
        if (page.loadMoreFailure != null) ...<Widget>[
          const SizedBox(height: RmSpacing.md),
          RmInlineMessage(
            message: l10n.routeRequestsLoadMoreFailed,
            icon: RmIcons.alertTriangle,
            tone: RmRowTone.danger,
          ),
        ],
        if (page.hasMore) ...<Widget>[
          const SizedBox(height: RmSpacing.lg),
          RmButton(
            label: page.loadMoreFailure == null
                ? l10n.routeRequestsLoadMore
                : l10n.commonRetry,
            variant: RmButtonVariant.outline,
            loading: page.isLoadingMore,
            onPressed: () => ref
                .read(incomingSeatRequestsProvider(routeId).notifier)
                .loadMore(),
          ),
        ],
      ],
    );
  }

  /// Ask the server, then say what it answered.
  ///
  /// Nothing is decided locally. A failure leaves the request exactly as it
  /// was, and the message names the reason the server gave — matched on the
  /// machine string, never read out of `message`.
  Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    IncomingSeatRequest request, {
    required bool accept,
  }) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final IncomingSeatRequestsController controller = ref.read(
      incomingSeatRequestsProvider(routeId).notifier,
    );

    final RmFailure? failure = accept
        ? await controller.accept(request.id)
        : await controller.decline(request.id);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            failure == null
                ? (accept
                      ? l10n.routeRequestsAccepted
                      : l10n.routeRequestsDeclined)
                : _failureCopy(l10n, failure),
          ),
        ),
      );
  }

  /// The server's own reason, or the one thing certainly true.
  String _failureCopy(AppLocalizations l10n, RmFailure failure) =>
      switch (failure.seatRequestRefusal) {
        // Both are facts about the journey, not about this request — the row
        // stays exactly what it was.
        SeatRequestRefusal.routeFull => l10n.routeRequestsFull,
        SeatRequestRefusal.routeUnavailable =>
          l10n.routeRequestsRouteUnavailable,
        _ => l10n.routeRequestsDecisionFailed,
      };
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
            l10n.routeRequestsEmpty,
            style: RmTypography.body.copyWith(color: c.ink),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: RmSpacing.xs),
          Text(
            l10n.routeRequestsEmptyBody,
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
