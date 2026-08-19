// ─────────────────────────────────────────────────────────────
// RideMate — Map canvas
//
// Source of truth: docs/claude-designs/RideMate App.dc.html (immutable).
//
// THIS IS ARTWORK, NOT A MAP.
//
// It reproduces the illustrated map the design draws as inline SVG: a base
// fill, road strokes, building blocks and a route polyline. It is NOT a map
// abstraction, NOT a provider contract, and NOT a step toward one. There is no
// tile source, no projection, no location and no vendor. The real maps and
// location architecture is a later, separate decision, and nothing here should
// be mistaken for its interface.
//
// The scene is described in its own artboard coordinate space (276x598 for a
// full screen, 220x84 for the chat location card) and scaled to whatever box
// the widget is given — the same contract an SVG `viewBox` provides — so the
// illustration keeps its proportions on any screen.
//
// [RmMapProjection] exposes that mapping so overlays can sit on top of the
// artwork. It is a DRAWING transform and nothing more: artboard pixels in,
// widget pixels out. It must never grow latitude/longitude semantics, a
// camera, zoom, bearing, tiles or a vendor. If you find yourself wanting
// `latLngToScreen` here, you want the real maps architecture, which is a
// separate decision and does not start in this file.
//
// Colours come from the map tokens, so light and dark are a re-palette of the
// same scene rather than two different scenes.
// ─────────────────────────────────────────────────────────────

import 'dart:ui' show PathMetric;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';

import '../theme/tokens/rm_colors.dart';

/// The design's artboard, and therefore this widget's coordinate space.
const Size kRmMapDesignSize = Size(276, 598);

/// A straight road segment, in design coordinates.
@immutable
class RmMapRoad {
  const RmMapRoad({
    required this.start,
    required this.end,
    required this.width,
    this.arterial = false,
  });

  final Offset start;
  final Offset end;
  final double width;

  /// Arterial roads are drawn a shade lighter than the grid.
  final bool arterial;
}

/// A city block, in design coordinates.
@immutable
class RmMapBuilding {
  const RmMapBuilding({required this.rect, this.radius = 4});

  final Rect rect;
  final double radius;
}

/// Everything the canvas draws.
@immutable
class RmMapScene {
  const RmMapScene({
    required this.roads,
    required this.buildings,
    required this.route,
    this.routeWidth = 6,
    this.travelledFraction = 0,
    this.designSize = kRmMapDesignSize,
  });

  final List<RmMapRoad> roads;
  final List<RmMapBuilding> buildings;

  /// The route polyline, in design coordinates. Drawn as a smooth curve.
  final List<Offset> route;

  final double routeWidth;

  /// 0..1 of the route already covered, drawn in a muted tone.
  ///
  /// A DISPLAYED figure, never a computed one. Nothing in this codebase
  /// derives it from a position, an ETA or elapsed time, and it is never
  /// animated — a progress bar creeping over a fixture would be a route-
  /// progress calculation with extra steps.
  final double travelledFraction;

  /// The artboard this scene's coordinates belong to.
  ///
  /// Full-screen maps use the default 276x598; the chat location card draws a
  /// 220x84 artboard, and cover-scaling that to the phone artboard would crop
  /// it into a meaningless fragment.
  final Size designSize;

  @override
  bool operator ==(Object other) =>
      other is RmMapScene &&
      listEquals(other.roads, roads) &&
      listEquals(other.buildings, buildings) &&
      listEquals(other.route, route) &&
      other.routeWidth == routeWidth &&
      other.travelledFraction == travelledFraction &&
      other.designSize == designSize;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(roads),
    Object.hashAll(buildings),
    Object.hashAll(route),
    routeWidth,
    travelledFraction,
    designSize,
  );
}

/// Maps a scene's artboard coordinates onto the box the canvas was given.
///
/// The canvas cover-fits — it crops rather than letterboxes, so the artwork
/// always bleeds to the edges — and any widget layered over the map has to
/// apply exactly the same transform or the overlays drift off the artwork.
/// This is that transform, in one place.
///
/// STRICTLY A DRAWING TRANSFORM. No geography, no camera, no vendor. See the
/// file header.
@immutable
class RmMapProjection {
  const RmMapProjection._(this.scale, this._dx, this._dy);

  /// The cover-fit projection of [designSize] onto [box].
  factory RmMapProjection.cover({required Size box, required Size designSize}) {
    final double x = box.width / designSize.width;
    final double y = box.height / designSize.height;
    final double scale = x > y ? x : y;
    return RmMapProjection._(
      scale,
      (box.width - designSize.width * scale) / 2,
      (box.height - designSize.height * scale) / 2,
    );
  }

  /// The projection for [scene] inside [box].
  factory RmMapProjection.of(RmMapScene scene, Size box) =>
      RmMapProjection.cover(box: box, designSize: scene.designSize);

  final double scale;
  final double _dx;
  final double _dy;

  /// Where [design] lands inside the box.
  Offset place(Offset design) =>
      Offset(_dx + design.dx * scale, _dy + design.dy * scale);

  @override
  bool operator ==(Object other) =>
      other is RmMapProjection &&
      other.scale == scale &&
      other._dx == _dx &&
      other._dy == _dy;

  @override
  int get hashCode => Object.hash(scale, _dx, _dy);
}

/// Paints an [RmMapScene] using the palette's map tokens.
class RmMapCanvas extends StatelessWidget {
  const RmMapCanvas({
    required this.scene,
    super.key,
    this.showRouteFlow = true,
    this.semanticLabel,
  });

  final RmMapScene scene;

  /// The dashed overlay the design draws along the route.
  ///
  /// Light only: the source deliberately omits it in dark, where a white dash
  /// over a near-black map reads as noise. This is a visual treatment, not
  /// information, so dropping it removes nothing the user needs.
  final bool showRouteFlow;

  /// Optional description. The illustration is decorative by default.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    final Widget canvas = CustomPaint(
      painter: _MapPainter(
        scene: scene,
        canvasColor: c.mapCanvas,
        roadColor: c.mapRoad,
        arterialColor: Color.lerp(c.mapRoad, c.mapCanvas, 0.35)!,
        buildingColor: c.mapBuilding,
        routeColor: c.primary,
        travelledColor: Color.lerp(c.primary, c.mapCanvas, 0.55)!,
        flowColor: c.onPrimary,
        showRouteFlow: showRouteFlow,
      ),
      size: Size.infinite,
    );

    return semanticLabel == null
        ? ExcludeSemantics(child: canvas)
        : Semantics(
            label: semanticLabel,
            image: true,
            excludeSemantics: true,
            child: canvas,
          );
  }
}

class _MapPainter extends CustomPainter {
  const _MapPainter({
    required this.scene,
    required this.canvasColor,
    required this.roadColor,
    required this.arterialColor,
    required this.buildingColor,
    required this.routeColor,
    required this.travelledColor,
    required this.flowColor,
    required this.showRouteFlow,
  });

  final RmMapScene scene;
  final Color canvasColor;
  final Color roadColor;
  final Color arterialColor;
  final Color buildingColor;
  final Color routeColor;
  final Color travelledColor;
  final Color flowColor;
  final bool showRouteFlow;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = canvasColor);

    // Scale the artboard to fill the box, cropping rather than letterboxing so
    // the illustration always bleeds to the edges. Overlays use the same
    // projection, which is why it is public.
    final RmMapProjection projection = RmMapProjection.of(scene, size);
    final Offset origin = projection.place(Offset.zero);

    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..translate(origin.dx, origin.dy)
      ..scale(projection.scale);

    _paintRoads(canvas);
    _paintBuildings(canvas);
    _paintRoute(canvas);

    canvas.restore();
  }

  void _paintRoads(Canvas canvas) {
    for (final RmMapRoad road in scene.roads) {
      canvas.drawLine(
        road.start,
        road.end,
        Paint()
          ..color = road.arterial ? arterialColor : roadColor
          ..strokeWidth = road.width
          ..strokeCap = StrokeCap.butt,
      );
    }
  }

  void _paintBuildings(Canvas canvas) {
    final Paint paint = Paint()..color = buildingColor;
    for (final RmMapBuilding building in scene.buildings) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          building.rect,
          Radius.circular(building.radius),
        ),
        paint,
      );
    }
  }

  void _paintRoute(Canvas canvas) {
    if (scene.route.length < 2) return;

    final Path path = _smoothPath(scene.route);
    final Paint casing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = scene.routeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = routeColor;

    if (scene.travelledFraction <= 0) {
      canvas.drawPath(path, casing);
    } else {
      // Split the route so the covered part reads as already behind you.
      for (final PathMetric metric in path.computeMetrics()) {
        final double cut = metric.length * scene.travelledFraction.clamp(0, 1);
        canvas
          ..drawPath(metric.extractPath(0, cut), casing..color = travelledColor)
          ..drawPath(
            metric.extractPath(cut, metric.length),
            casing..color = routeColor,
          );
      }
    }

    if (!showRouteFlow) return;

    // The dashed overlay: short marks with long gaps, giving the route a
    // direction-of-travel texture.
    final Paint flow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = scene.routeWidth / 3
      ..strokeCap = StrokeCap.round
      ..color = flowColor;

    for (final PathMetric metric in path.computeMetrics()) {
      const double dash = 2;
      const double gap = 8;
      double distance = 0;
      while (distance < metric.length) {
        final double end = (distance + dash).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), flow);
        distance = end + gap;
      }
    }
  }

  /// A quadratic-smoothed path through [points], matching the source's
  /// `Q`/`T` curve rather than drawing hard corners.
  static Path _smoothPath(List<Offset> points) {
    final Path path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length - 1; i++) {
      final Offset current = points[i];
      final Offset next = points[i + 1];
      final Offset mid = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      path.quadraticBezierTo(current.dx, current.dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.scene != scene ||
      old.canvasColor != canvasColor ||
      old.routeColor != routeColor ||
      old.showRouteFlow != showRouteFlow;
}
