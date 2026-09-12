// ─────────────────────────────────────────────────────────────
// RideMate — Rating a journey
//
// A modal sheet, because that is the one modal convention this app has —
// `showPlacePicker` and `confirmRouteCancellation` — and a dialog here would be
// a second pattern for the same job.
//
// WHILE AN ATTEMPT IS UNRESOLVED, THE RATING IS NOT EDITABLE
//
// A submission whose answer is unknown may already have landed. Retrying it
// under the same id with a different rating would be answered
// `id_already_used`, which is a conflict this app would have invented. So the
// stars lock to what was sent, Retry resends exactly that, and changing it
// means abandoning the attempt on purpose — at which point the next submission
// is a new one, and may correctly be told the first had landed after all.
//
// WHAT THE SHEET DOES NOT SAY
//
// Whether the other member has rated anybody, whether anything has been
// released, or that this journey was verified. The server knows the first two
// and deliberately does not tell a client before it releases both; the third it
// does not know at all.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/rm_failure.dart';
import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_button.dart';
import '../../../../core/widgets/rm_rating_input.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/review_action_providers.dart';
import '../review_failure_copy.dart';

/// Rates the relationship [requestId] names.
///
/// Resolves to the failure when the server refused, and null when it accepted
/// or when the member closed the sheet without sending. The caller re-reads its
/// own listing either way, because the server's `my_review` is the truth.
Future<RmFailure?> rateTrip(
  BuildContext context, {
  required String requestId,
}) => showModalBottomSheet<RmFailure?>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (BuildContext context) => _RateTripSheet(requestId: requestId),
);

class _RateTripSheet extends ConsumerStatefulWidget {
  const _RateTripSheet({required this.requestId});

  final String requestId;

  @override
  ConsumerState<_RateTripSheet> createState() => _RateTripSheetState();
}

class _RateTripSheetState extends ConsumerState<_RateTripSheet> {
  int? _rating;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmColors c = context.rmColors;

    final Map<String, ReviewAttempt> attempts = ref.watch(reviewActionProvider);
    final ReviewAttempt? attempt = attempts[widget.requestId];
    final bool sending = attempt is ReviewSending;

    // The rating an unresolved attempt is locked to. While one exists the
    // member's current selection is irrelevant: what was sent is what goes
    // again.
    final int? locked = ref
        .read(reviewActionProvider.notifier)
        .lockedRating(widget.requestId);
    final int? shown = locked ?? _rating;
    final bool canSend = shown != null && !sending;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          RmSpacing.screenGutter,
          RmSpacing.xl,
          RmSpacing.screenGutter,
          RmSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.reviewSheetTitle,
              style: RmTypography.titleSm.copyWith(color: c.ink),
            ),
            const SizedBox(height: RmSpacing.xs),
            Text(
              l10n.reviewSheetBody,
              style: RmTypography.caption.copyWith(color: c.sub),
            ),
            const SizedBox(height: RmSpacing.lg),
            RmRatingInput(
              value: shown,
              label: l10n.reviewStarSemanticLabel,
              // Locked while an attempt is unresolved, and while one is in
              // flight.
              onChanged: locked != null || sending
                  ? null
                  : (int value) => setState(() => _rating = value),
            ),
            if (attempt is ReviewFailed) ...<Widget>[
              const SizedBox(height: RmSpacing.md),
              Text(
                reviewFailureCopy(l10n, attempt.failure),
                style: RmTypography.caption.copyWith(color: c.danger),
              ),
            ],
            const SizedBox(height: RmSpacing.lg),
            RmButton(
              label: locked == null ? l10n.reviewSend : l10n.reviewRetry,
              fullWidth: true,
              loading: sending,
              onPressed: canSend ? () => _send(shown) : null,
            ),
            const SizedBox(height: RmSpacing.sm),
            RmButton(
              // Dismissing does NOT abandon an unresolved attempt: closing a
              // sheet is not a decision about a submission whose fate is
              // unknown. Giving up on one is its own, named act.
              label: locked == null ? l10n.reviewDismiss : l10n.reviewAbandon,
              variant: RmButtonVariant.outline,
              fullWidth: true,
              onPressed: sending
                  ? null
                  : () {
                      if (locked != null) {
                        ref
                            .read(reviewActionProvider.notifier)
                            .abandon(widget.requestId);
                      }
                      Navigator.of(context).pop();
                    },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send(int rating) async {
    final NavigatorState navigator = Navigator.of(context);

    final RmFailure? failure = await ref
        .read(reviewActionProvider.notifier)
        .submit(widget.requestId, rating);

    if (!mounted) return;

    // A transport failure keeps the sheet open, because the same submission can
    // be sent again from here. Anything else is the server's settled answer and
    // belongs to the listing, which re-reads.
    if (failure != null && failure.isTransport) return;

    navigator.pop(failure);
  }
}
