// ─────────────────────────────────────────────────────────────
// RideMate — Confirming a cancellation
//
// Withdrawing a journey affects anyone who was counting on it, so it is asked
// for rather than assumed. A modal sheet because that is the one modal
// convention this app has — `showPlacePicker` — and inventing a dialog here
// would be a second pattern for the same job.
//
// Resolves to `true` only when the member deliberately confirms. Dismissing by
// gesture, by the back control or by tapping away resolves to null, which the
// caller reads as "not confirmed" — the safe direction for a destructive act.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_button.dart';
import '../../../../l10n/app_localizations.dart';

/// Asks whether [journey] should be withdrawn.
///
/// Resolves to true only on an explicit confirmation.
Future<bool> confirmRouteCancellation(
  BuildContext context, {
  required String journey,
}) async {
  final bool? confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => _CancelRouteSheet(journey: journey),
  );

  return confirmed ?? false;
}

class _CancelRouteSheet extends StatelessWidget {
  const _CancelRouteSheet({required this.journey});

  final String journey;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmColors c = context.rmColors;

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
            Semantics(
              header: true,
              child: Text(
                l10n.myRoutesCancelConfirmTitle,
                style: RmTypography.titleSm.copyWith(color: c.ink),
              ),
            ),
            const SizedBox(height: RmSpacing.sm),
            Text(
              // Names the journey, so nobody withdraws the wrong one, and says
              // the record survives — cancelling is not deleting.
              l10n.myRoutesCancelConfirmBody(journey),
              style: RmTypography.body.copyWith(color: c.sub),
            ),
            const SizedBox(height: RmSpacing.xl),
            RmButton(
              label: l10n.myRoutesCancelConfirm,
              variant: RmButtonVariant.danger,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: RmSpacing.sm),
            RmButton(
              label: l10n.myRoutesCancelDismiss,
              variant: RmButtonVariant.ghost,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
