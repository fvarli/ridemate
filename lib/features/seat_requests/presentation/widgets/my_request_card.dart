// ─────────────────────────────────────────────────────────────
// RideMate — One of the member's own askings
//
// The request's status, the journey's, and whether the journey was made are
// rendered as three separate lines, because they are three separate facts.
// `Kabul edildi` above `Bu yolculuk iptal edildi` is not a bug: the driver
// agreed to share a seat and then withdrew the journey, and both of those
// happened. `Beklemede` above `Yolculuk: Başladı` is not one either — a driver
// may set off while somebody's asking is still unanswered, and the server says
// so. Merging any of them into one label would have to invent a state —
// `cancelled_by_route`, `expired`, `missed` — that no response carries and no
// decision produced.
//
// NOTHING HERE IS A PASSENGER ACTION ON THE JOURNEY
//
// The lifecycle is read and nothing else. A passenger cannot start, complete or
// abandon a journey, and the line saying `Başladı` does not say the member is
// aboard, was picked up, is moving, or is anywhere at all.
//
// WITHDRAW APPEARS ONLY WHILE THERE IS SOMETHING TO WITHDRAW
//
// A pending asking, and nothing else. An accepted one cannot be taken back in
// Phase 13 — the driver planned around that seat and nothing tells them it went
// away — and declined and withdrawn are already ends.
//
// The driver is a name and the server's own initials. Nothing about a rating,
// verification, trip count, trust score, cost or remaining seats appears here,
// because none of them exists.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/format/rm_text_conventions.dart';
import '../../../../core/routes/departure.dart';
import '../../../../core/routes/published_route.dart';
import '../../../../core/seat_requests/seat_request.dart';
import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/trips/trip_state_copy.dart';
import '../../../../core/widgets/rm_avatar.dart';
import '../../../../core/widgets/rm_button.dart';
import '../../../../core/widgets/rm_card.dart';
import '../../../../l10n/app_localizations.dart';

class MyRequestCard extends StatelessWidget {
  const MyRequestCard({
    required this.request,
    required this.isWithdrawing,
    required this.onWithdraw,
    super.key,
  });

  final MySeatRequest request;
  final bool isWithdrawing;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmColors c = context.rmColors;
    final SeatRequestRoute route = request.route;

    final String journey = RmTextConventions.route(
      route.origin.label,
      route.destination.label,
    );

    // What the journey now says about itself, when there is something to say.
    // Absent while it is simply still running: a line saying nothing has gone
    // wrong is noise on a card that is mostly about something else.
    final String? journeyNote = switch (route) {
      SeatRequestRoute(status: RouteStatus.cancelled) =>
        l10n.myRequestsRouteCancelled,
      SeatRequestRoute(departureState: DepartureState.past) =>
        l10n.myRequestsRouteDeparted,
      _ => null,
    };

    return RmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              RmAvatar(
                // The server's letters, as they arrived.
                initials: route.driver.initials,
                // Nothing verifies anybody.
                verification: RmVerification.none,
                identity: RmIdentity.purple,
              ),
              const SizedBox(width: RmSpacing.sm),
              Expanded(
                child: Text(
                  route.driver.displayName,
                  style: RmTypography.body.copyWith(color: c.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: RmSpacing.sm),
          Text(journey, style: RmTypography.body.copyWith(color: c.ink)),
          const SizedBox(height: RmSpacing.xs),
          Text(
            _departure(l10n),
            style: RmTypography.caption.copyWith(color: c.sub),
          ),
          const SizedBox(height: RmSpacing.sm),
          // The asking's own state — history, and the first of the three.
          Text(
            _statusLabel(l10n),
            style: RmTypography.body.copyWith(color: c.ink),
          ),
          // The journey's, separately, and only when it has changed.
          if (journeyNote != null) ...<Widget>[
            const SizedBox(height: RmSpacing.xs),
            Text(
              journeyNote,
              style: RmTypography.caption.copyWith(color: c.sub),
            ),
          ],
          // And whether it was made — the third truth, always said. Unlike the
          // note above it is never absent: `Başlamadı` is a fact about the
          // journey rather than the lack of one, and a passenger reading their
          // own history needs to know which journeys happened.
          const SizedBox(height: RmSpacing.xs),
          Text(
            tripStateLine(l10n, route.trip.state),
            style: RmTypography.caption.copyWith(color: c.sub),
          ),
          if (request.status == SeatRequestStatus.pending) ...<Widget>[
            const SizedBox(height: RmSpacing.sm),
            RmButton(
              label: l10n.myRequestsWithdraw,
              size: RmButtonSize.sm,
              variant: RmButtonVariant.outline,
              loading: isWithdrawing,
              // Null disables it. A second tap while one is in flight is the
              // same intention arriving twice.
              onPressed: isWithdrawing ? null : onWithdraw,
            ),
          ],
        ],
      ),
    );
  }

  /// The departure as the driver published it.
  ///
  /// The wall clock exactly as sent — no zone conversion, and no formatting
  /// that would imply an instant this client cannot compute. Same shape My
  /// Routes and Discovery use, because it is the same fact.
  String _departure(AppLocalizations l10n) {
    final DepartureDate? date = request.route.departureDate;

    return switch (request.route.recurrence) {
      Recurrence.weekdays =>
        '${l10n.myRoutesRecurrenceWeekdays} · ${request.route.departureTime.hhMm}',
      Recurrence.once when date != null =>
        '${date.iso} · ${request.route.departureTime.hhMm}',
      Recurrence.once => request.route.departureTime.hhMm,
    };
  }

  String _statusLabel(AppLocalizations l10n) => switch (request.status) {
    SeatRequestStatus.pending => l10n.seatRequestPending,
    SeatRequestStatus.accepted => l10n.seatRequestAccepted,
    SeatRequestStatus.declined => l10n.seatRequestDeclined,
    SeatRequestStatus.withdrawn => l10n.seatRequestWithdrawn,
  };
}
