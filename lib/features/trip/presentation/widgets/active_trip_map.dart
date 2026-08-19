// ─────────────────────────────────────────────────────────────
// RideMate — Active trip map
//
// Source: docs/claude-designs/RideMate App.dc.html, "ACTIVE TRIP" (immutable).
//
// ARTWORK, NOT A MAP. The scene below is the design's own SVG transcribed into
// its coordinate space: four roads, two blocks and a route. There is no tile
// source, no projection, no location, no permission and no vendor.
//
// Two values are DECLARED and never derived from each other:
//
//   * travelledFraction — measured once against the point list below (the
//     canvas smooths through midpoints, so the arc-length position of the
//     comp's colour break depends on which points are used). The design's
//     muted overdraw ends at (150, 360); on this list that lands at 0.396, so
//     0.4 ships. Changing the points means re-measuring it.
//   * the car's position — taken straight from the comp, which places it at
//     design (161, 373). That is NOT exactly on the polyline, and the offset is
//     intentional: do not "correct" it by snapping the marker to the route,
//     which would be deriving one fixture from the other.
//
// Nothing animates. The car does not move and the fraction does not advance.
//
// Dark keeps the buildings and the destination pin the dark comp omits, per the
// parity rule recorded as D-home-1: dark re-palettes the scene, it never shows
// the member less.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/icons/rm_icons.dart';
import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_radius.dart';
import '../../../../core/theme/tokens/rm_shadows.dart';
import '../../../../core/theme/tokens/rm_sizing.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/widgets/rm_icon.dart';
import '../../../../core/widgets/rm_journey_marker.dart';
import '../../../../core/widgets/rm_map_canvas.dart';

/// The road grid, blocks and route the design draws, in design coordinates.
const RmMapScene kActiveTripMapScene = RmMapScene(
  roads: <RmMapRoad>[
    // Over-extended so the grid bleeds off every edge, as the source does.
    RmMapRoad(start: Offset(-10, 160), end: Offset(286, 160), width: 11),
    RmMapRoad(start: Offset(-10, 360), end: Offset(286, 360), width: 11),
    RmMapRoad(start: Offset(90, -10), end: Offset(90, 608), width: 11),
    RmMapRoad(start: Offset(200, -10), end: Offset(200, 608), width: 11),
  ],
  buildings: <RmMapBuilding>[
    RmMapBuilding(rect: Rect.fromLTWH(110, 180, 70, 60), radius: 5),
    RmMapBuilding(rect: Rect.fromLTWH(40, 380, 55, 50), radius: 5),
  ],
  // Sampled from the source's `M60 500 Q110 420 150 360 T230 120`.
  route: <Offset>[
    Offset(60, 500),
    Offset(108, 425),
    Offset(150, 360),
    Offset(190, 270),
    Offset(230, 120),
  ],
  routeWidth: 7,
  travelledFraction: kTravelledFraction,
);

/// How much of the route the design draws in the muted, already-covered tone.
///
/// MEASURED, NOT COMPUTED — see the file header. It is a picture of progress,
/// not a measure of it.
const double kTravelledFraction = 0.4;

/// Where the comp puts the vehicle, in design coordinates.
const Offset kVehicleAt = Offset(161, 373);

/// Where the comp puts the destination teardrop, in design coordinates.
const Offset kDestinationAt = Offset(225, 115);

/// The full-bleed trip map with its two markers.
class ActiveTripMap extends StatelessWidget {
  const ActiveTripMap({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // The same projection the canvas paints with, so the markers land on
        // the artwork rather than drifting off it.
        final RmMapProjection projection = RmMapProjection.of(
          kActiveTripMapScene,
          constraints.biggest,
        );

        return Stack(
          children: <Widget>[
            // The dashed flow overlay is light-only; see D-home-2.
            RmMapCanvas(
              scene: kActiveTripMapScene,
              showRouteFlow: Theme.of(context).brightness == Brightness.light,
            ),
            _Centred(
              at: projection.place(kVehicleAt),
              child: const _VehicleMarker(),
            ),
            _Centred(
              at: projection.place(kDestinationAt),
              child: const RmJourneyMarker(
                RmJourneyPoint.destination,
                size: RmSpacing.xl,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Centres [child] on a point rather than positioning its top-left corner.
class _Centred extends StatelessWidget {
  const _Centred({required this.at, required this.child});

  final Offset at;
  final Widget child;

  @override
  Widget build(BuildContext context) => Positioned(
    left: at.dx,
    top: at.dy,
    child: FractionalTranslation(
      translation: const Offset(-0.5, -0.5),
      child: child,
    ),
  );
}

/// The car on the route. Decorative — the sheet below carries the meaning.
class _VehicleMarker extends StatelessWidget {
  const _VehicleMarker();

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return ExcludeSemantics(
      child: Container(
        width: RmSizing.ctaSm,
        height: RmSizing.ctaSm,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.primary,
          borderRadius: RmRadius.brMd,
          // The ring punches the marker out of the map behind it.
          border: Border.all(
            color: c.background,
            width: RmSizing.badgeRingWidth,
          ),
          boxShadow: context.rmShadows.primary,
        ),
        child: RmIcon(
          RmIcons.carMarker,
          size: RmIconSize.sm,
          color: c.onPrimary,
        ),
      ),
    );
  }
}
