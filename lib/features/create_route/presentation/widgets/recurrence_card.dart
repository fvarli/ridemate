// ─────────────────────────────────────────────────────────────
// RideMate — Recurrence card
//
// Source: docs/claude-designs/RideMate App.dc.html, "CREATE ROUTE" (immutable).
//
// `Her hafta içi tekrarla` with a summary line and a switch. This is the only
// switch in all fifteen approved screens, so it stays feature-local rather
// than being promoted to core — the project's rule is that a primitive earns
// `core/` by being reused, not by looking reusable.
//
// It is composed from RmCard rather than RmListRow because RmListRow always
// passes a semanticLabel, and RmCard's no-tap branch wraps that in a
// Semantics container — which would swallow the switch into one labelled node
// and make the toggle unreadable and unactionable.
//
// DEVIATION D-create-3: the comp draws only the ON state. When the toggle is
// off, the summary is hidden rather than replaced, so no copy is invented —
// only a visibility rule. The underlying fixtures are not cleared, so turning
// it back on restores exactly the same summary.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_motion.dart';
import '../../../../core/theme/tokens/rm_radius.dart';
import '../../../../core/theme/tokens/rm_shadows.dart';
import '../../../../core/theme/tokens/rm_sizing.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_card.dart';
import '../../../../l10n/app_localizations.dart';

/// The weekday-recurrence row.
class RecurrenceCard extends StatelessWidget {
  const RecurrenceCard({
    required this.repeats,
    required this.onChanged,
    super.key,
  });

  final bool repeats;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);

    final String title = l10n.createRouteRecurrenceTitle;

    // The whole row is the target: a 56x32 track is the row's only affordance,
    // and one node beats two announcing the same state. `toggled` without
    // `button`, so it announces as a switch rather than as a button — and
    // excludeSemantics, or the InkWell below would contribute a second,
    // button-flavoured node saying the same thing.
    return Semantics(
      container: true,
      toggled: repeats,
      label: title,
      onTap: () => onChanged(!repeats),
      excludeSemantics: true,
      child: RmCard(
        radius: RmRadius.xl,
        padding: const EdgeInsets.all(RmSpacing.xl),
        child: InkWell(
          onTap: () => onChanged(!repeats),
          borderRadius: RmRadius.brXl,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      style: RmTypography.body.copyWith(color: c.ink),
                      // At the maximum text scale this will not fit on one
                      // line beside the track.
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (repeats) ...<Widget>[
                      const SizedBox(height: RmSpacing.xxs),
                      Text(
                        // The days only. The departure time has its own
                        // control now, and a card repeating it would go stale
                        // the moment the two disagreed.
                        l10n.createRouteRecurrenceDetail,
                        style: RmTypography.caption.copyWith(color: c.muted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: RmSpacing.lg),
              ExcludeSemantics(child: RecurrenceSwitch(value: repeats)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The switch itself. Purely visual — the row above owns the semantics.
class RecurrenceSwitch extends StatelessWidget {
  const RecurrenceSwitch({required this.value, super.key});

  final bool value;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    // A member who has asked for reduced motion should not get a sliding knob.
    final Duration duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : RmMotion.fast;

    return SizedBox(
      width: RmSizing.switchTrackWidth,
      height: RmSizing.switchTrackHeight,
      child: AnimatedContainer(
        duration: duration,
        curve: RmMotion.ease,
        padding: const EdgeInsets.all(RmSizing.switchKnobInset),
        decoration: BoxDecoration(
          // The off track is extrapolated: the source draws only the on state.
          color: value ? c.primary : c.disabled,
          borderRadius: RmRadius.brPill,
        ),
        child: AnimatedAlign(
          duration: duration,
          curve: RmMotion.ease,
          // Directional, so the knob mirrors in RTL. A plain centerRight would
          // leave the switch reading backwards.
          alignment: value
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: Container(
            width: RmSizing.switchKnob,
            height: RmSizing.switchKnob,
            decoration: BoxDecoration(
              color: c.onPrimary,
              shape: BoxShape.circle,
              boxShadow: context.rmShadows.cardSoft,
            ),
          ),
        ),
      ),
    );
  }
}
