// ─────────────────────────────────────────────────────────────
// RideMate — Active trip top bar
//
// Source: docs/claude-designs/RideMate App.dc.html, "ACTIVE TRIP" (immutable).
//
// The live pill and the clock tile, floating over the map.
//
// DEVIATION D-trip-2: the clock tile has no defined behaviour anywhere in the
// approved design — no destination, no label, no state. It is rendered exactly
// as drawn but is NOT interactive, because giving it an action would mean
// inventing a purpose (history? timeline? schedule?) that nobody has decided.
// It is styled as a button, though, so a non-interactive render is not
// self-evidently right; the ambiguity is recorded in design-system.md §8 for
// design input rather than quietly resolved here.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/icons/rm_icons.dart';
import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_radius.dart';
import '../../../../core/theme/tokens/rm_shadows.dart';
import '../../../../core/theme/tokens/rm_sizing.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/widgets/rm_icon.dart';
import '../../../../core/widgets/rm_status_pill.dart';
import '../../../../l10n/app_localizations.dart';

/// The live badge and the clock tile.
class TripTopBar extends StatelessWidget {
  const TripTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          RmSpacing.screenGutter,
          RmSpacing.lg,
          RmSpacing.screenGutter,
          0,
        ),
        child: Row(
          children: <Widget>[
            // The pulsing dot is a visual "this is live" cue only. Nothing is
            // live; see active_trip_snapshot.dart.
            Flexible(
              child: RmStatusPill(
                label: l10n.activeTripLiveBadge,
                tone: RmStatusPillTone.ink,
                pulsing: true,
              ),
            ),
            const SizedBox(width: RmSpacing.md),
            const _ClockTile(),
          ],
        ),
      ),
    );
  }
}

/// Rendered as drawn, deliberately inert. See D-trip-2 in the file header.
class _ClockTile extends StatelessWidget {
  const _ClockTile();

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return ExcludeSemantics(
      child: Container(
        width: RmSizing.iconButtonSm,
        height: RmSizing.iconButtonSm,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: RmRadius.brMd,
          border: Border.all(color: c.border, width: RmSizing.borderWidth),
          boxShadow: context.rmShadows.cardSoft,
        ),
        child: RmIcon(RmIcons.clock, size: RmIconSize.md, color: c.ink),
      ),
    );
  }
}
