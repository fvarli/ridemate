// ─────────────────────────────────────────────────────────────
// RideMate — Route details
//
// Source: docs/claude-designs/RideMate App.dc.html, "ROUTE DETAILS" (immutable).
//
// Gradient hero → three trust tiles overlapping it → route timeline → vehicle
// and mutual-connection tiles → a docked action bar.
//
// PHASE 3 SCOPE — the two actions are honest about what they do.
//
// `İstek gönder` does NOT send anything: there is no backend, no driver, and no
// request lifecycle. It shows a temporary message and creates no "sent" state.
// Flipping the button to "Gönderildi" would tell a member their request had
// been delivered when nothing happened, which is the wrong thing to encode in
// a trust product. When a backend exists the flow becomes
// request → server acknowledgement → pending → accepted/declined, and only
// then may the UI claim anything was sent.
//
// Every figure on this screen is carried by the offer. Nothing is computed —
// not the Trust Score, not the approval rate, not the cost share.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/format/rm_formatters.dart';
import '../../../core/format/rm_text_conventions.dart';
import '../../../core/icons/rm_icons.dart';
import '../../../core/theme/rm_theme.dart';
import '../../../core/theme/tokens/rm_colors.dart';
import '../../../core/theme/tokens/rm_radius.dart';
import '../../../core/theme/tokens/rm_sizing.dart';
import '../../../core/theme/tokens/rm_spacing.dart';
import '../../../core/theme/tokens/rm_typography.dart';
import '../../../core/widgets/rm_avatar.dart';
import '../../../core/widgets/rm_button.dart';
import '../../../core/widgets/rm_card.dart';
import '../../../core/widgets/rm_chip.dart';
import '../../../core/widgets/rm_cta_dock.dart';
import '../../../core/widgets/rm_icon.dart';
import '../../../core/widgets/rm_icon_button.dart';
import '../../../core/widgets/rm_journey_marker.dart';
import '../../../core/widgets/rm_list_row.dart';
import '../../../core/widgets/rm_selector_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/mock_discovery_fixtures.dart';
import '../domain/route_offer.dart';
import 'widgets/route_timeline.dart';

/// How far the trust tiles overlap the hero.
const double _kStatOverlap = 20;

/// A published shared journey, in full.
class RouteDetailsScreen extends ConsumerWidget {
  const RouteDetailsScreen({required this.routeId, super.key});

  final String routeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RmColors c = context.rmColors;
    final RouteOffer? offer = MockRouteOffers.byId(routeId);

    if (offer == null) return const _RouteNotFound();

    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                _Hero(offer: offer),
                Transform.translate(
                  offset: const Offset(0, -_kStatOverlap),
                  child: Column(
                    children: <Widget>[
                      _TrustTiles(offer: offer),
                      const SizedBox(height: RmSpacing.xl),
                      _TimelineCard(offer: offer),
                      const SizedBox(height: RmSpacing.md),
                      _DetailTiles(offer: offer),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _ActionDock(offer: offer),
        ],
      ),
    );
  }
}

/// The gradient identity header.
class _Hero extends StatelessWidget {
  const _Hero({required this.offer});

  final RouteOffer offer;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmFormatters f = RmFormatters.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The hero is always the brand gradient, so its status-bar glyphs are
      // light in either theme.
      value: SystemUiOverlayStyle.light,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: c.heroPrimary),
        padding: const EdgeInsets.fromLTRB(
          RmSpacing.screenGutter,
          0,
          RmSpacing.screenGutter,
          RmSpacing.huge,
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: RmSpacing.sm),
              RmIconButton(
                icon: RmIcons.chevronLeft,
                semanticLabel: l10n.commonBack,
                onPressed: () => context.pop(),
              ),
              const SizedBox(height: RmSpacing.xl),
              Row(
                children: <Widget>[
                  RmAvatar(
                    initials: offer.initials,
                    size: RmAvatarSize.hero,
                    identity: offer.identity,
                    verification: offer.isVerified
                        ? RmVerification.verified
                        : RmVerification.none,
                    // The badge is punched out of the gradient's deeper end,
                    // exactly as the design draws it.
                    surfaceColor: c.primaryPressed,
                  ),
                  const SizedBox(width: RmSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          offer.driverName,
                          style: RmTypography.titleMd.copyWith(
                            color: c.onPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: RmSpacing.xs),
                        RmBadge(
                          label: l10n.routeDetailsRatingSummary(
                            f.rating(offer.rating),
                            f.count(offer.tripCount),
                          ),
                          tone: RmBadgeTone.onColor,
                          icon: RmIcons.starFilled,
                        ),
                        const SizedBox(height: RmSpacing.xs),
                        Text(
                          l10n.routeDetailsMemberSince(
                            offer.memberSince,
                            offer.homeArea,
                          ),
                          style: RmTypography.caption.copyWith(
                            color: c.onPrimary.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The three figures that overlap the hero.
class _TrustTiles extends StatelessWidget {
  const _TrustTiles({required this.offer});

  final RouteOffer offer;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmFormatters f = RmFormatters.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: RmSpacing.lg),
      // The tiles match heights whatever the longest caption wraps to. Inside
      // a scroll view `stretch` alone would demand an infinite height, so the
      // row is measured first.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: RmStatTile(
                // Displayed, never computed — the Trust Score is backend-owned.
                value: f.trustScore(offer.trustScore),
                caption: l10n.routeDetailsStatTrustScore,
                valueColor: c.primaryText,
              ),
            ),
            const SizedBox(width: RmSpacing.sm),
            Expanded(
              child: RmStatTile(
                value: f.percent(offer.approvalRate),
                caption: l10n.routeDetailsStatApprovalRate,
                valueColor: c.success,
              ),
            ),
            const SizedBox(width: RmSpacing.sm),
            Expanded(
              child: RmStatTile(
                value: offer.sharedDistance,
                caption: l10n.routeDetailsStatSharedDistance,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.offer});

  final RouteOffer offer;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmFormatters f = RmFormatters.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: RmSpacing.screenGutter),
      child: RmCard(
        radius: RmRadius.xl,
        child: RouteTimeline(
          stops: <RouteTimelineStop>[
            RouteTimelineStop(
              point: RmJourneyPoint.origin,
              name: offer.originLabel,
              detail: l10n.routeDetailsPickupLabel,
              time: f.hourMinute(offer.departureHour, offer.departureMinute),
            ),
            RouteTimelineStop(
              point: RmJourneyPoint.destination,
              name: offer.destinationLabel,
              detail: l10n.routeDetailsArrivalLabel(f.count(offer.tripMinutes)),
              time: f.hourMinute(offer.arrivalHour, offer.arrivalMinute),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vehicle and mutual-connection, side by side.
class _DetailTiles extends StatelessWidget {
  const _DetailTiles({required this.offer});

  final RouteOffer offer;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmFormatters f = RmFormatters.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: RmSpacing.screenGutter),
      // Same reason as the trust tiles: measure before stretching, since a
      // scroll view offers no bounded height to stretch into.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: RmCard(
                padding: const EdgeInsets.all(RmSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    RmIcon(RmIcons.car, color: c.sub),
                    const SizedBox(height: RmSpacing.sm),
                    Text(
                      offer.vehicleName,
                      style: RmTypography.captionSm.copyWith(
                        color: c.ink,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: RmSpacing.xxs),
                    Text(
                      RmTextConventions.plate(offer.plate),
                      style: RmTypography.numericMicro.copyWith(color: c.muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: RmSpacing.md),
            Expanded(
              child: RmCard(
                variant: RmCardVariant.tinted,
                padding: const EdgeInsets.all(RmSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      l10n.routeDetailsMutualTitle,
                      style: RmTypography.labelSm.copyWith(
                        color: c.primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: RmSpacing.sm),
                    Text(
                      l10n.matchesMetaSharedRoutes(
                        f.count(offer.sharedRouteCount ?? 0),
                      ),
                      style: RmTypography.captionSm.copyWith(
                        color: c.ink,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (offer.ridePreferences != null) ...<Widget>[
                      const SizedBox(height: RmSpacing.xxs),
                      Text(
                        offer.ridePreferences!,
                        style: RmTypography.micro.copyWith(color: c.sub),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The docked cost share and the two actions.
class _ActionDock extends StatelessWidget {
  const _ActionDock({required this.offer});

  final RouteOffer offer;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmFormatters f = RmFormatters.of(context);

    return RmCtaDock(
      children: <Widget>[
        // Cost sharing, not a fare: this is display data and nothing charges
        // anyone.
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              l10n.routeDetailsFareLabel,
              style: RmTypography.micro.copyWith(color: c.muted),
            ),
            Text(
              f.money(offer.fareShare),
              style: RmTypography.numericMd.copyWith(color: c.ink),
            ),
          ],
        ),
        RmIconButton(
          icon: RmIcons.chatBubble,
          semanticLabel: l10n.routeDetailsMessageSemanticLabel,
          variant: RmIconButtonVariant.surface,
          size: RmIconButtonSize.md,
          // Chat exists now. Opening it creates no request, match, booking or
          // trip — it is a conversation surface, nothing more.
          onPressed: () => context.pushNamed(AppRoutes.chat),
        ),
        Expanded(
          child: RmButton(
            label: l10n.routeDetailsRequestSeat,
            size: RmButtonSize.lg,
            onPressed: () => _onRequestSeatRequested(context, l10n),
          ),
        ),
      ],
    );
  }

  /// Temporary Phase 3 behaviour for requesting a seat.
  ///
  /// Shows an informational message only. It deliberately does NOT create a
  /// "sent" state, mutate the offer, or start a request lifecycle — nothing
  /// was actually sent anywhere. A real implementation may only claim a
  /// request was sent once a server has acknowledged it.
  void _onRequestSeatRequested(BuildContext context, AppLocalizations l10n) =>
      _notifyUnavailable(context, l10n.routeDetailsRequestUnavailable);

  static void _notifyUnavailable(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Shown when an unknown offer id is opened.
///
/// Defensive only: ids come from our own fixture. This is not a designed
/// empty state.
class _RouteNotFound extends StatelessWidget {
  const _RouteNotFound();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: context.rmColors.background,
      appBar: AppBar(
        systemOverlayStyle: RmTheme.overlayStyleFor(
          Theme.of(context).brightness,
        ),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(RmSpacing.screenGutter),
          child: RmInlineMessage(message: l10n.routeDetailsNotFound),
        ),
      ),
    );
  }
}
