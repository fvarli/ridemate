// ─────────────────────────────────────────────────────────────
// RideMate — Active trip
//
// Source: docs/claude-designs/RideMate App.dc.html, "ACTIVE TRIP" (immutable),
// with the dark variant at "ACTIVE TRIP · DARK".
//
// NOTHING ON THIS SCREEN IS LIVE, AND IT IS DEBUG-ONLY FOR THAT REASON.
//
// Reaching an active trip honestly needs a lifecycle this product does not
// have — a seat request, an acceptance, a departure. Rather than fabricate
// `acceptedTrip`, `tripStarted` or `currentRide` to unlock a screen, the route
// is registered only under kDebugMode, so it is absent from the release route
// table entirely and no product surface links to it.
//
// That also keeps two things away from real members: an SOS button with no
// emergency behaviour, and a footer that says their live location is being
// shared with two emergency contacts when nothing is shared with anyone.
//
// The three actions are honest about doing nothing. Sharing shares nothing,
// calling calls nobody, and SOS notifies nobody — each says so. Only the chat
// button does something real, because Chat exists.
//
// PUMP WARNING: the live dot, the footer dot and the SOS halo all animate
// indefinitely, so `pumpAndSettle` will time out on this screen. Use
// `pump(Duration)`, or pump with `disableAnimations: true`.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/theme/tokens/rm_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../application/active_trip_providers.dart';
import '../domain/active_trip_snapshot.dart';
import 'widgets/active_trip_map.dart';
import 'widgets/trip_sheet.dart';
import 'widgets/trip_top_bar.dart';

/// A journey in progress, as the design draws one.
class ActiveTripScreen extends ConsumerWidget {
  const ActiveTripScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ActiveTripSnapshot trip = ref.watch(activeTripSnapshotProvider);

    return Scaffold(
      backgroundColor: c.mapCanvas,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const ActiveTripMap(),
          const Align(alignment: Alignment.topCenter, child: TripTopBar()),
          Align(
            alignment: Alignment.bottomCenter,
            child: TripSheet(
              trip: trip,
              onCall: () => _notify(context, l10n.activeTripCallUnavailable),
              onMessage: () => context.pushNamed(AppRoutes.chat),
              onShare: () => _notify(context, l10n.activeTripShareUnavailable),
              onSos: () => _onSosRequested(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the Safety Center.
  ///
  /// It does NOT arm, count down, trigger, confirm, call, notify a contact,
  /// share a location or set any state — see sos_button.dart. Both screens are
  /// debug-only, so this is a review path rather than a product one, and the
  /// SOS card it lands on says plainly that nobody was notified.
  void _onSosRequested(BuildContext context) =>
      context.pushNamed(AppRoutes.safety);

  static void _notify(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
