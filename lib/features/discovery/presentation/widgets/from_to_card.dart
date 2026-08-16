// ─────────────────────────────────────────────────────────────
// RideMate — From/to card
//
// Source: docs/claude-designs/RideMate App.dc.html, "SEARCH ROUTES" (immutable).
//
// Two endpoint rows separated by a hairline, with the swap control absolutely
// centred on the card's trailing edge so it straddles the divider.
//
// NOT A TEXT INPUT. The design contains no <input>, no caret, no placeholder
// treatment and no autocomplete surface anywhere. Both rows render filled
// values and open a picker when tapped. There is no geocoding: when real
// location search arrives, only the source of the picker's list changes.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/icons/rm_icons.dart';
import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_radius.dart';
import '../../../../core/theme/tokens/rm_shadows.dart';
import '../../../../core/theme/tokens/rm_sizing.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_icon_button.dart';
import '../../../../core/widgets/rm_journey_marker.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/place.dart';

/// The journey endpoints, with a swap control.
class FromToCard extends StatelessWidget {
  const FromToCard({
    required this.origin,
    required this.destination,
    required this.onEditOrigin,
    required this.onEditDestination,
    required this.onSwap,
    super.key,
  });

  final Place origin;
  final Place destination;
  final VoidCallback onEditOrigin;
  final VoidCallback onEditDestination;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: RmRadius.brXxl,
        border: Border.all(color: c.border, width: RmSizing.borderWidth),
        boxShadow: context.rmShadows.cardSoft,
      ),
      child: Stack(
        children: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _EndpointRow(
                point: RmJourneyPoint.origin,
                label: l10n.searchFieldOriginLabel,
                value: origin.label,
                onTap: onEditOrigin,
              ),
              Divider(height: 1, thickness: 1, color: c.divider),
              _EndpointRow(
                point: RmJourneyPoint.destination,
                label: l10n.searchFieldDestinationLabel,
                value: destination.label,
                onTap: onEditDestination,
              ),
            ],
          ),
          // Straddles the divider on the trailing edge, exactly as drawn.
          PositionedDirectional(
            end: RmSpacing.lg,
            top: 0,
            bottom: 0,
            child: Center(
              child: RmIconButton(
                icon: RmIcons.swapVertical,
                semanticLabel: l10n.searchSwapSemanticLabel,
                variant: RmIconButtonVariant.tinted,
                onPressed: onSwap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EndpointRow extends StatelessWidget {
  const _EndpointRow({
    required this.point,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final RmJourneyPoint point;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      label: '$label: $value',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: RmSpacing.xl,
            vertical: RmSpacing.xl,
          ),
          child: Row(
            children: <Widget>[
              RmJourneyMarker(point),
              const SizedBox(width: RmSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      label,
                      style: RmTypography.overline.copyWith(color: c.faint),
                    ),
                    const SizedBox(height: RmSpacing.xxs),
                    Text(
                      value,
                      style: RmTypography.bodyLg.copyWith(color: c.ink),
                      // Two lines, not one. At the scaled type size a full
                      // Istanbul address does not fit beside the swap control
                      // on a 393dp screen, and truncating "İskele Meydanı" to
                      // "İskele Mey…" hides which of two nearby stops this is.
                      // The comp's own text runs under its swap tile, so a
                      // single line was never actually achievable.
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Room for the swap control that overlaps this row: its own
              // footprint, and no more.
              const SizedBox(width: RmSizing.iconButtonSm),
            ],
          ),
        ),
      ),
    );
  }
}
