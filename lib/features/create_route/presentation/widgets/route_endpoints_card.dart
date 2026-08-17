// ─────────────────────────────────────────────────────────────
// RideMate — Create route endpoints
//
// Source: docs/claude-designs/RideMate App.dc.html, "CREATE ROUTE" (immutable).
//
// The compact sibling of Search's from/to card: same origin ring and
// destination teardrop vocabulary, but no eyebrow labels, no swap control, no
// shadow and a tighter radius. Those differences are why this is its own
// widget rather than four flags on a card that lives in another feature.
//
// DEVIATION D-create-2: the comp draws no tap affordance and no eyebrows, but
// the rows open the place picker anyway, and their semantic labels supply the
// origin/destination role. A publish screen where the driver cannot set their
// own endpoints would be worse than a logged deviation, and without the labels
// a screen reader would announce only "Ataşehir, Palladium" with nothing to
// say which end of the journey it is.
//
// NOT A TEXT INPUT. No geocoding, no autocomplete — see rm_place_picker_sheet.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/places/place.dart';
import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_radius.dart';
import '../../../../core/theme/tokens/rm_sizing.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_journey_marker.dart';
import '../../../../l10n/app_localizations.dart';

/// The journey endpoints a driver is publishing.
class RouteEndpointsCard extends StatelessWidget {
  const RouteEndpointsCard({
    required this.origin,
    required this.destination,
    required this.onEditOrigin,
    required this.onEditDestination,
    super.key,
  });

  final Place origin;
  final Place destination;
  final VoidCallback onEditOrigin;
  final VoidCallback onEditDestination;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: RmRadius.brXl,
        border: Border.all(color: c.border, width: RmSizing.borderWidth),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _EndpointRow(
            point: RmJourneyPoint.origin,
            value: origin.label,
            semanticLabel: l10n.createRouteOriginSemanticLabel(origin.label),
            onTap: onEditOrigin,
          ),
          Divider(height: 1, thickness: 1, color: c.divider),
          _EndpointRow(
            point: RmJourneyPoint.destination,
            value: destination.label,
            semanticLabel: l10n.createRouteDestinationSemanticLabel(
              destination.label,
            ),
            onTap: onEditDestination,
          ),
        ],
      ),
    );
  }
}

class _EndpointRow extends StatelessWidget {
  const _EndpointRow({
    required this.point,
    required this.value,
    required this.semanticLabel,
    required this.onTap,
  });

  final RmJourneyPoint point;
  final String value;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: RmSpacing.xl,
            vertical: RmSpacing.lg,
          ),
          child: Row(
            children: <Widget>[
              RmJourneyMarker(point),
              const SizedBox(width: RmSpacing.lg),
              Expanded(
                child: Text(
                  value,
                  style: RmTypography.bodyLg.copyWith(color: c.ink),
                  // Two lines for the same reason as Search's card: a full
                  // İstanbul address does not fit on one at the scaled type
                  // size, and truncating hides which stop it is.
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
