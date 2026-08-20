// ─────────────────────────────────────────────────────────────
// RideMate — Safety Center
//
// Source: docs/claude-designs/RideMate App.dc.html, "SAFETY · SOS" and the
// dark variant (immutable).
//
// DEBUG BUILDS ONLY, and linked from no product surface.
//
// This is the most safety-sensitive screen in the app and the one with the
// least behind it. Its SOS card promises that pressing it sends your location
// and journey to your emergency contacts and to "our team"; a tile offers to
// call 112; a row says two trusted contacts have been added. None of that
// exists — there is no backend, no telephony, no location, no notification
// channel and no contact store — so rather than rewrite the approved safety
// copy to make it survivable in release, the route is left out of the release
// table entirely. Withholding the screen is the honest move; softening the
// claims would leave a safety surface that reads as real.
//
// Debug-only is about the ENTRY POINT, not the code. Everything here is
// production quality: localized, accessible, RTL-safe, themed, tested and
// captured in goldens. What is withheld is reachability.
//
// Before it can become reachable, all five of these must exist — see
// docs/architecture.md:
//   1. an approved SOS state machine (one of its eleven states is designed)
//   2. trusted-contact storage and a delivery channel with evidence
//   3. location-sharing semantics: precision, duration, audience, stopping
//   4. emergency-call behaviour, per jurisdiction
//   5. the permission model and every denial and failure path
//
// The comp draws no back control, so neither does this. It is pushed from
// Active Trip in debug builds, where the system gesture works; a cold deep
// link leaves nothing beneath it, exactly as for Active Trip.
//
// The halo repeats forever, so pumpAndSettle hangs here. Tests pump fixed
// frames.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/rm_icons.dart';
import '../../../core/theme/tokens/rm_colors.dart';
import '../../../core/theme/tokens/rm_spacing.dart';
import '../../../core/theme/tokens/rm_typography.dart';
import '../../../core/widgets/rm_list_row.dart';
import '../../../l10n/app_localizations.dart';
import '../application/safety_providers.dart';
import '../domain/safety_snapshot.dart';
import 'widgets/safety_links.dart';
import 'widgets/safety_quick_actions.dart';
import 'widgets/sos_card.dart';

/// Emergency help, trusted contacts and safety tools.
class SafetyScreen extends ConsumerWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final SafetySnapshot snapshot = ref.watch(safetySnapshotProvider);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            RmSpacing.screenGutter,
            RmSpacing.lg,
            RmSpacing.screenGutter,
            RmSpacing.xl,
          ),
          children: <Widget>[
            Text(
              l10n.safetyTitle,
              style: RmTypography.titleSm.copyWith(color: c.ink),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: RmSpacing.xxs),
            Text(
              l10n.safetySubtitle,
              style: RmTypography.captionSm.copyWith(color: c.muted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: RmSpacing.lg),
            SosCard(onPressed: () => _notify(context, l10n.sosUnavailable)),
            const SizedBox(height: RmSpacing.md),
            SafetyQuickActions(
              actions: <SafetyQuickAction>[
                SafetyQuickAction(
                  icon: RmIcons.phone,
                  title: l10n.safetyCallEmergencyTitle,
                  caption: l10n.safetyCallEmergencyCaption,
                  tone: SafetyActionTone.danger,
                  // Names the capability that is missing. The app cannot place
                  // a call at all — no tel:, no launcher, no platform channel.
                  onPressed: () => _notify(context, l10n.safetyCallUnavailable),
                ),
                SafetyQuickAction(
                  icon: RmIcons.shareTrip,
                  title: l10n.safetyShareTripTitle,
                  caption: l10n.safetyShareTripCaption,
                  tone: SafetyActionTone.primary,
                  onPressed: () =>
                      _notify(context, l10n.activeTripShareUnavailable),
                ),
              ],
            ),
            const SizedBox(height: RmSpacing.lg),
            SafetyLinks(
              // Three different missing capabilities, three different
              // sentences. None of these rows navigates or stores anything.
              links: <SafetyLink>[
                SafetyLink(
                  icon: RmIcons.person,
                  title: l10n.safetyTrustedContactsTitle,
                  subtitle: l10n.safetyTrustedContactsSubtitle(
                    snapshot.trustedContactCount,
                  ),
                  tone: RmRowTone.success,
                  onPressed: () =>
                      _notify(context, l10n.safetyTrustedContactsUnavailable),
                ),
                SafetyLink(
                  icon: RmIcons.shield,
                  title: l10n.safetyVerifyPartnerTitle,
                  subtitle: l10n.safetyVerifyPartnerSubtitle,
                  tone: RmRowTone.primary,
                  onPressed: () =>
                      _notify(context, l10n.safetyVerifyPartnerUnavailable),
                ),
                SafetyLink(
                  icon: RmIcons.closeX,
                  title: l10n.safetyBlockReportTitle,
                  subtitle: l10n.safetyBlockReportSubtitle,
                  tone: RmRowTone.danger,
                  onPressed: () =>
                      _notify(context, l10n.safetyBlockReportUnavailable),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static void _notify(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
