// ─────────────────────────────────────────────────────────────
// RideMate — Home map illustration
//
// Source: docs/claude-designs/RideMate App.dc.html, "HOME · MAP" (immutable).
//
// The scene below is transcribed from the design's inline SVG, in its own
// 276x598 coordinate space. [RmMapCanvas] scales it to the device.
//
// LIGHT/DARK PARITY — a deliberate deviation from the dark comp.
//
// The dark comp omits the arterial road, one building, the destination pin and
// the second driver pin. Those omissions are treated as presentation
// simplification in the comp, NOT as product behaviour: dropping a pin would
// mean the same screen shows the user LESS information at night, which is not
// something a trust-and-safety product should do. Dark re-palettes the scene;
// it never reduces it.
//
// The one light-only element is the dashed route overlay, which is texture
// rather than information — a white dash over a near-black map reads as noise,
// and the source's choice there is clearly deliberate.
//
// The map is decorative artwork. It carries no location, no live data and no
// interaction.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_radius.dart';
import '../../../../core/theme/tokens/rm_shadows.dart';
import '../../../../core/theme/tokens/rm_sizing.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_avatar.dart';
import '../../../../core/widgets/rm_map_canvas.dart';

/// The illustrated street layout, transcribed from the design source.
const RmMapScene kHomeMapScene = RmMapScene(
  roads: <RmMapRoad>[
    // Horizontal grid — deliberately over-extended so it bleeds off-screen.
    RmMapRoad(start: Offset(-10, 120), end: Offset(286, 120), width: 10),
    RmMapRoad(start: Offset(-10, 300), end: Offset(286, 300), width: 10),
    RmMapRoad(start: Offset(-10, 470), end: Offset(286, 470), width: 10),
    // Vertical grid.
    RmMapRoad(start: Offset(60, -10), end: Offset(60, 608), width: 10),
    RmMapRoad(start: Offset(160, -10), end: Offset(160, 608), width: 10),
    RmMapRoad(start: Offset(230, -10), end: Offset(230, 608), width: 10),
    // The diagonal arterial. Kept in dark for parity.
    RmMapRoad(
      start: Offset(-10, 210),
      end: Offset(286, 380),
      width: 14,
      arterial: true,
    ),
  ],
  buildings: <RmMapBuilding>[
    RmMapBuilding(rect: Rect.fromLTWH(80, 135, 60, 50)),
    RmMapBuilding(rect: Rect.fromLTWH(175, 320, 44, 40)),
    // Kept in dark for parity.
    RmMapBuilding(rect: Rect.fromLTWH(30, 330, 50, 46)),
  ],
  route: <Offset>[
    Offset(70, 470),
    Offset(120, 380),
    Offset(138, 320),
    Offset(174, 235),
    Offset(210, 150),
  ],
);

/// The map layer: illustration plus its overlay markers.
class HomeMap extends StatelessWidget {
  const HomeMap({required this.destinationLabel, super.key});

  /// Mock presentation label on the destination pin.
  final String destinationLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // The same projection the canvas paints with, so overlays land on the
        // artwork rather than drifting off it.
        final RmMapProjection projection = RmMapProjection.of(
          kHomeMapScene,
          constraints.biggest,
        );
        final Offset Function(Offset) place = projection.place;

        return Stack(
          children: <Widget>[
            // The dashed flow overlay is light-only; see the file header.
            RmMapCanvas(
              scene: kHomeMapScene,
              showRouteFlow: Theme.of(context).brightness == Brightness.light,
            ),
            _Positioned(
              at: place(const Offset(66, 465)),
              child: const _OriginDot(),
            ),
            _Positioned(
              at: place(const Offset(210, 150)),
              child: _DestinationPin(label: destinationLabel),
            ),
            _Positioned(
              at: place(const Offset(137, 317)),
              child: const _DriverPin(
                initials: 'SK',
                identity: RmIdentity.amber,
                size: RmAvatarSize.md,
              ),
            ),
            _Positioned(
              at: place(const Offset(215, 395)),
              child: const _DriverPin(
                initials: 'MA',
                identity: RmIdentity.green,
                size: RmAvatarSize.sm,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Centres [child] on a point rather than positioning its top-left corner.
class _Positioned extends StatelessWidget {
  const _Positioned({required this.at, required this.child});

  final Offset at;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: at.dx,
      top: at.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: child,
      ),
    );
  }
}

/// The blue-ringed dot marking where the journey starts.
class _OriginDot extends StatelessWidget {
  const _OriginDot();

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return ExcludeSemantics(
      child: Container(
        width: RmSpacing.xxxl,
        height: RmSpacing.xxxl,
        decoration: BoxDecoration(
          color: c.background,
          shape: BoxShape.circle,
          border: Border.all(color: c.primary, width: 7),
          boxShadow: context.rmShadows.cardSoft,
        ),
      ),
    );
  }
}

/// The ink teardrop and its label.
class _DestinationPin extends StatelessWidget {
  const _DestinationPin({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return ExcludeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: RmSpacing.md,
              vertical: RmSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: c.ink,
              borderRadius: RmRadius.brXs,
            ),
            child: Text(
              label,
              style: RmTypography.micro.copyWith(
                color: c.onInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // A teardrop: a square with three rounded corners, rotated 45°.
          Transform.rotate(
            angle: 0.7853981634,
            child: Container(
              width: RmSpacing.xl,
              height: RmSpacing.xl,
              decoration: BoxDecoration(
                color: c.ink,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(RmSpacing.xl),
                  topRight: Radius.circular(RmSpacing.xl),
                  bottomLeft: Radius.circular(RmSpacing.xl),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A nearby member's avatar, ringed against the map.
class _DriverPin extends StatelessWidget {
  const _DriverPin({
    required this.initials,
    required this.identity,
    required this.size,
  });

  final String initials;
  final RmIdentity identity;
  final double size;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return ExcludeSemantics(
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // The ring is the map background, punching the pin out of it.
          border: Border.all(
            color: c.background,
            width: RmSizing.badgeRingWidth,
          ),
          boxShadow: context.rmShadows.cardSoft,
        ),
        child: RmAvatar(
          initials: initials,
          size: size,
          shape: RmAvatarShape.circle,
          identity: identity,
        ),
      ),
    );
  }
}
