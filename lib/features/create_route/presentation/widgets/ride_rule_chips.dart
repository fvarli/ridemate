// ─────────────────────────────────────────────────────────────
// RideMate — Ride rules
//
// Source: docs/claude-designs/RideMate App.dc.html, "CREATE ROUTE" (immutable).
//
// The rules a driver publishes with the journey. Same chip treatment as
// Search's trust filters — the source gives both `padding:8px 13px` and
// `font:700 12px` — with one difference: the selected chip here carries NO
// leading check.
//
// Toggling changes only the chip and the draft. Nothing here filters, matches
// or enforces eligibility, and `Evcil hayvan yok` in particular is flagged in
// create_route_draft.dart as needing review before it ever does.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/widgets/rm_chip.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/create_route_draft.dart';

/// The ride-rule chip cloud.
class RideRuleChips extends StatelessWidget {
  const RideRuleChips({
    required this.selected,
    required this.onToggle,
    super.key,
  });

  final Set<RideRuleId> selected;
  final ValueChanged<RideRuleId> onToggle;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    String labelFor(RideRuleId id) => switch (id) {
      RideRuleId.noSmoking => l10n.createRouteRuleNoSmoking,
      RideRuleId.musicOk => l10n.createRouteRuleMusicOk,
      RideRuleId.noPets => l10n.createRouteRuleNoPets,
      RideRuleId.quiet => l10n.createRouteRuleQuiet,
    };

    return Wrap(
      spacing: RmSpacing.sm,
      runSpacing: RmSpacing.sm,
      children: <Widget>[
        for (final RideRuleId id in RideRuleId.values)
          RmChip(
            label: labelFor(id),
            selected: selected.contains(id),
            compact: true,
            onTap: () => onToggle(id),
          ),
      ],
    );
  }
}
