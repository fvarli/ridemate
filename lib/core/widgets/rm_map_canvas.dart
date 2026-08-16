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
// The scene is described in the design's own 276x598 coordinate space and
// scaled to whatever box the widget is given — the same contract an SVG
// `viewBox` provides — so the illustration keeps its proportions on any
// screen.
//
// Colours come from the map tokens, so light and dark are a re-palette of the
// same scene rather than two different scenes.
// ─────────────────────────────────────────────────────────────

import 'dart:ui' show PathMetric;

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
  });

  final List<RmMapRoad> roads;
  final List<RmMapBuilding> buildings;

  /// The route polyline, in design coordinates. Drawn as a smooth curve.
  final List<Offset> route;

  final double routeWidth;

  /// 0..1 of the route already covered, drawn in a muted tone.
  ///
  /// Used by the live-trip treatment; 0 leaves the whole route highlighted.
  final double travelledFraction;
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

    // Scale the design artboard to fill the box, cropping rather than
    // letterboxing so the illustration always bleeds to the edges.
    final double scale = _coverScale(size);
    final double dx = (size.width - kRmMapDesignSize.width * scale) / 2;
    final double dy = (size.height - kRmMapDesignSize.height * scale) / 2;

    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..translate(dx, dy)
      ..scale(scale);

    _paintRoads(canvas);
    _paintBuildings(canvas);
    _paintRoute(canvas);

    canvas.restore();
  }

  double _coverScale(Size size) {
    final double x = size.width / kRmMapDesignSize.width;
    final double y = size.height / kRmMapDesignSize.height;
    return x > y ? x : y;
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
