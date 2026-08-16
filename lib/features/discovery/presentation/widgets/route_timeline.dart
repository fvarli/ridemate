// ─────────────────────────────────────────────────────────────
// RideMate — Route timeline
//
// Source: docs/claude-designs/RideMate App.dc.html, "ROUTE DETAILS" (immutable).
//
// A two-column stepper: a rail of markers joined by a stretching connector,
// beside a column of stops. The design shows two stops, but the connector is
// flexible, so intermediate stops are structurally possible.
//
// The markers reuse RmJourneyMarker, so the two ends read the same here as on
// Search and on the Home map.
//
// Times are displayed, not computed — there is no route engine.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_sizing.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_journey_marker.dart';

/// One stop on the journey.
@immutable
class RouteTimelineStop {
  const RouteTimelineStop({
    required this.point,
    required this.name,
    required this.detail,
    required this.time,
  });

  final RmJourneyPoint point;
  final String name;

  /// e.g. `Alış noktası` or `Varış · 32 dk`.
  final String detail;

  /// Already formatted, e.g. `08:25`.
  final String time;
}

/// The origin → destination stepper.
class RouteTimeline extends StatelessWidget {
  const RouteTimeline({required this.stops, super.key});

  final List<RouteTimelineStop> stops;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // The rail. Decorative: each stop announces its own end.
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: RmSpacing.xs),
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < stops.length; i++) ...<Widget>[
                    RmJourneyMarker(stops[i].point),
                    if (i < stops.length - 1)
                      Expanded(
                        child: Container(
                          width: RmSizing.borderWidthEmphasis,
                          margin: const EdgeInsets.symmetric(
                            vertical: RmSpacing.xs,
                          ),
                          color: c.border,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: RmSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                for (final RouteTimelineStop stop in stops)
                  _StopRow(stop: stop),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({required this.stop});

  final RouteTimelineStop stop;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return Semantics(
      container: true,
      label: '${stop.name}. ${stop.detail}. ${stop.time}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: RmSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    stop.name,
                    style: RmTypography.body.copyWith(color: c.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: RmSpacing.xxs),
                  Text(
                    stop.detail,
                    style: RmTypography.caption.copyWith(color: c.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: RmSpacing.md),
            Text(
              stop.time,
              style: RmTypography.numericXs.copyWith(color: c.ink),
            ),
          ],
        ),
      ),
    );
  }
}
