// ─────────────────────────────────────────────────────────────
// RideMate — Match card
//
// Source: docs/claude-designs/RideMate App.dc.html, "MATCH RESULTS" (immutable).
//
// The design draws three ranked density tiers:
//
//   highlighted  emphasised border + glow, gradient compatibility meter,
//                filled CTA
//   standard     hairline border, muted grey meter, outlined CTA
//   condensed    single row, no meter, no CTA, no verified badge, smaller
//                avatar and price
//
// The tier is a PRESENTATION rank the fixture assigns by position. Nothing
// here computes a rank, a compatibility figure or a cost share — every number
// is read straight off the offer.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/format/rm_formatters.dart';
import '../../../../core/format/rm_text_conventions.dart';
import '../../../../core/icons/rm_icons.dart';
import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_radius.dart';
import '../../../../core/theme/tokens/rm_sizing.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_avatar.dart';
import '../../../../core/widgets/rm_button.dart';
import '../../../../core/widgets/rm_card.dart';
import '../../../../core/widgets/rm_chip.dart';
import '../../../../core/widgets/rm_meters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/route_offer.dart';

/// How prominently a match is presented.
enum MatchCardTier {
  /// The design's "best match" treatment.
  highlighted,

  /// The default card.
  standard,

  /// The single-row card.
  condensed,
}

/// One route offer in the results list.
class MatchCard extends StatelessWidget {
  const MatchCard({
    required this.offer,
    required this.tier,
    required this.onInspect,
    super.key,
  });

  final RouteOffer offer;
  final MatchCardTier tier;
  final VoidCallback onInspect;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmFormatters f = RmFormatters.of(context);

    final String rating = f.rating(offer.rating);
    final String fare = f.money(offer.fareShare);
    final String compatibility = f.percent(offer.compatibility);
    final String departure = f.hourMinute(
      offer.departureHour,
      offer.departureMinute,
    );

    final String semanticLabel = l10n.matchesCardSemanticLabel(
      offer.driverName,
      rating,
      compatibility,
      departure,
      fare,
    );

    return switch (tier) {
      MatchCardTier.condensed => _CondensedCard(
        offer: offer,
        rating: rating,
        fare: fare,
        compatibility: compatibility,
        departure: departure,
        semanticLabel: semanticLabel,
        onTap: onInspect,
      ),
      MatchCardTier.highlighted || MatchCardTier.standard => _FullCard(
        offer: offer,
        tier: tier,
        rating: rating,
        fare: fare,
        compatibility: compatibility,
        departure: departure,
        semanticLabel: semanticLabel,
        onInspect: onInspect,
      ),
    };
  }
}

class _FullCard extends StatelessWidget {
  const _FullCard({
    required this.offer,
    required this.tier,
    required this.rating,
    required this.fare,
    required this.compatibility,
    required this.departure,
    required this.semanticLabel,
    required this.onInspect,
  });

  final RouteOffer offer;
  final MatchCardTier tier;
  final String rating;
  final String fare;
  final String compatibility;
  final String departure;
  final String semanticLabel;
  final VoidCallback onInspect;

  bool get _highlighted => tier == MatchCardTier.highlighted;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return RmCard(
      variant: _highlighted ? RmCardVariant.selected : RmCardVariant.outlined,
      radius: RmRadius.xxl,
      padding: const EdgeInsets.all(RmSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // The informational half reads as one node; the CTA below stays a
          // separate, actionable one.
          Semantics(
            container: true,
            label: semanticLabel,
            excludeSemantics: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _IdentityRow(
                  offer: offer,
                  rating: rating,
                  fare: fare,
                  surfaceColor: c.surface,
                ),
                const SizedBox(height: RmSpacing.lg),
                _CompatibilityPanel(
                  highlighted: _highlighted,
                  compatibility: offer.compatibility,
                  formatted: compatibility,
                ),
              ],
            ),
          ),
          const SizedBox(height: RmSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  RmTextConventions.joinMeta(<String>[
                    l10n.matchesMetaDeparture(departure),
                    l10n.matchesMetaSeats(offer.seatsAvailable),
                    l10n.matchesMetaWalk('${offer.walkMinutes}'),
                  ]),
                  style: RmTypography.caption.copyWith(color: c.sub),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: RmSpacing.md),
              // Outside the card's own label so it stays separately actionable.
              RmButton(
                label: l10n.matchesInspect,
                size: RmButtonSize.sm,
                fullWidth: false,
                variant: _highlighted
                    ? RmButtonVariant.primary
                    : RmButtonVariant.outline,
                onPressed: onInspect,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Avatar, name, rating, meta line and the cost share.
class _IdentityRow extends StatelessWidget {
  const _IdentityRow({
    required this.offer,
    required this.rating,
    required this.fare,
    required this.surfaceColor,
  });

  final RouteOffer offer;
  final String rating;
  final String fare;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmFormatters f = RmFormatters.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        RmAvatar(
          initials: offer.initials,
          size: RmAvatarSize.xl,
          identity: offer.identity,
          verification: offer.isVerified
              ? RmVerification.verified
              : RmVerification.none,
          surfaceColor: surfaceColor,
        ),
        const SizedBox(width: RmSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  // Expanded, not Flexible: the name absorbs the shrinkage so
                  // the rating keeps its natural size.
                  Expanded(
                    child: Text(
                      offer.driverName,
                      style: RmTypography.body.copyWith(color: c.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: RmSpacing.sm),
                  RmBadge(
                    label: rating,
                    icon: RmIcons.starFilled,
                    numeric: true,
                  ),
                ],
              ),
              const SizedBox(height: RmSpacing.xs),
              Text(
                RmTextConventions.joinMeta(<String?>[
                  if (offer.isVerified) l10n.matchesMetaVerified,
                  l10n.matchesMetaTrips(f.count(offer.tripCount)),
                  if (offer.sharedRouteCount != null)
                    l10n.matchesMetaSharedRoutes(
                      f.count(offer.sharedRouteCount!),
                    ),
                ]),
                style: RmTypography.captionSm.copyWith(color: c.muted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: RmSpacing.md),
        Text(fare, style: RmTypography.numericMd.copyWith(color: c.ink)),
      ],
    );
  }
}

/// The route-compatibility well.
///
/// The figure is displayed, never computed — see route_offer.dart.
class _CompatibilityPanel extends StatelessWidget {
  const _CompatibilityPanel({
    required this.highlighted,
    required this.compatibility,
    required this.formatted,
  });

  final bool highlighted;
  final double compatibility;
  final String formatted;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RmSpacing.lg,
        vertical: RmSpacing.md,
      ),
      decoration: BoxDecoration(
        color: highlighted ? c.primarySoft : c.surfaceMuted,
        borderRadius: RmRadius.brMd,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n.matchesCompatibilityLabel,
                  style: RmTypography.labelSm.copyWith(
                    color: highlighted ? c.primaryText : c.sub,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: RmSpacing.sm),
              Text(
                formatted,
                style: RmTypography.numericSm.copyWith(
                  color: highlighted ? c.primaryText : c.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: RmSpacing.sm),
          RmLinearMeter(
            progress: compatibility,
            trackColor: highlighted ? c.meterTrackInfo : c.meterTrackNeutral,
            gradient: highlighted ? c.meterPrimary : null,
            color: highlighted ? null : c.muted,
          ),
        ],
      ),
    );
  }
}

/// The single-row card: no meter, no CTA, no badge.
class _CondensedCard extends StatelessWidget {
  const _CondensedCard({
    required this.offer,
    required this.rating,
    required this.fare,
    required this.compatibility,
    required this.departure,
    required this.semanticLabel,
    required this.onTap,
  });

  final RouteOffer offer;
  final String rating;
  final String fare;
  final String compatibility;
  final String departure;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return RmCard(
      radius: RmRadius.xxl,
      padding: const EdgeInsets.all(RmSpacing.xl),
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: Row(
        children: <Widget>[
          RmAvatar(
            initials: offer.initials,
            size: RmAvatarSize.lg,
            identity: offer.identity,
            // The design shows no badge on this tier.
            surfaceColor: c.surface,
          ),
          const SizedBox(width: RmSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        offer.driverName,
                        style: RmTypography.body.copyWith(color: c.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: RmSpacing.sm),
                    RmBadge(
                      label: rating,
                      icon: RmIcons.starFilled,
                      numeric: true,
                    ),
                  ],
                ),
                const SizedBox(height: RmSpacing.xs),
                Text(
                  RmTextConventions.joinMeta(<String>[
                    l10n.matchesMetaCompatibilityShort(compatibility),
                    departure,
                    l10n.matchesMetaSeats(offer.seatsAvailable),
                  ]),
                  style: RmTypography.captionSm.copyWith(color: c.muted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: RmSpacing.md),
          Text(fare, style: RmTypography.numericSm.copyWith(color: c.ink)),
        ],
      ),
    );
  }
}
