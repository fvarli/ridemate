// ─────────────────────────────────────────────────────────────
// RideMate — One asking, as the driver sees it
//
// A name, the server's own initials, when it was asked, and where it stands.
// The journey is not repeated: the driver opened this list from that journey
// and owns it.
//
// Nothing about a rating, verification, trip count, trust score, phone number
// or any identifier appears here — the endpoint sends none of them, and this is
// the screen where a plausible figure about a stranger would do the most harm.
//
// ONLY A PENDING REQUEST CAN BE ANSWERED
//
// Accepted, declined and withdrawn are ends. There is no Withdraw here either:
// taking an asking back is the passenger's to do, not the driver's.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/reviews/review.dart';
import '../../../../core/seat_requests/seat_request.dart';
import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_avatar.dart';
import '../../../../core/widgets/rm_button.dart';
import '../../../../core/widgets/rm_card.dart';
import '../../../../l10n/app_localizations.dart';

class IncomingRequestCard extends StatelessWidget {
  const IncomingRequestCard({
    required this.request,
    required this.isDeciding,
    required this.onAccept,
    required this.onDecline,
    required this.onRate,
    required this.journeyWasMade,
    super.key,
  });

  final IncomingSeatRequest request;

  /// Whether a decision on THIS request is in flight.
  final bool isDeciding;

  final VoidCallback onAccept;
  final VoidCallback onDecline;

  /// Opens the rating control for this relationship.
  final VoidCallback onRate;

  /// Whether the server says this journey was completed.
  ///
  /// Passed in rather than read off the row: the driver's incoming projection
  /// carries no route and no trip, so the screen fetches it from the owner's
  /// own list. **Absent is false** — a projection that has not loaded is not
  /// evidence that a journey was made.
  final bool journeyWasMade;

  /// Whether there is a journey here to rate. See [MyRequestCard] for why the
  /// route's status and the review window are both absent from this rule.
  bool get _canRate =>
      request.status == SeatRequestStatus.accepted &&
      journeyWasMade &&
      request.myReview == null;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmColors c = context.rmColors;
    final String passenger = request.passenger.displayName;

    return RmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              RmAvatar(
                // The server's letters, as they arrived.
                initials: request.passenger.initials,
                // Nothing verifies anybody.
                verification: RmVerification.none,
                identity: RmIdentity.purple,
              ),
              const SizedBox(width: RmSpacing.sm),
              Expanded(
                child: Text(
                  passenger,
                  style: RmTypography.body.copyWith(color: c.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: RmSpacing.sm),
          Text(
            _statusLabel(l10n),
            style: RmTypography.body.copyWith(color: c.ink),
          ),
          // What this driver said, and never what the passenger did.
          if (request.myReview case final MyReview mine) ...<Widget>[
            const SizedBox(height: RmSpacing.xs),
            Text(
              l10n.reviewSubmitted(mine.rating),
              style: RmTypography.caption.copyWith(color: c.sub),
            ),
          ],
          if (_canRate) ...<Widget>[
            const SizedBox(height: RmSpacing.sm),
            RmButton(
              label: l10n.reviewSubmit,
              semanticLabel: l10n.reviewSubmitSemanticLabel(passenger),
              size: RmButtonSize.sm,
              variant: RmButtonVariant.outline,
              fullWidth: false,
              onPressed: onRate,
            ),
          ],
          if (request.status == SeatRequestStatus.pending) ...<Widget>[
            const SizedBox(height: RmSpacing.sm),
            // Wrap, not Row: two labelled actions do not fit beside each other
            // at the narrow width in every locale, and they stack rather than
            // being truncated — a clipped action label is worse than a taller
            // card. `fullWidth: false` is load-bearing here: without it each
            // button claims the whole line.
            Wrap(
              spacing: RmSpacing.sm,
              runSpacing: RmSpacing.sm,
              children: <Widget>[
                RmButton(
                  label: l10n.routeRequestsAccept,
                  // Names the passenger, so the action is unambiguous when
                  // several cards each offer one.
                  semanticLabel: l10n.routeRequestsAcceptSemanticLabel(
                    passenger,
                  ),
                  size: RmButtonSize.sm,
                  fullWidth: false,
                  loading: isDeciding,
                  // Null disables it. A second tap while one is in flight is
                  // the same intention arriving twice.
                  onPressed: isDeciding ? null : onAccept,
                ),
                RmButton(
                  label: l10n.routeRequestsDecline,
                  semanticLabel: l10n.routeRequestsDeclineSemanticLabel(
                    passenger,
                  ),
                  size: RmButtonSize.sm,
                  variant: RmButtonVariant.outline,
                  fullWidth: false,
                  onPressed: isDeciding ? null : onDecline,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n) => switch (request.status) {
    SeatRequestStatus.pending => l10n.seatRequestPending,
    SeatRequestStatus.accepted => l10n.seatRequestAccepted,
    SeatRequestStatus.declined => l10n.seatRequestDeclined,
    SeatRequestStatus.withdrawn => l10n.seatRequestWithdrawn,
  };
}
