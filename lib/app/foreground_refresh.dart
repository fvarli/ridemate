// ─────────────────────────────────────────────────────────────
// RideMate — Asking again when the member comes back
//
// ONE OWNER
//
// This is the only place the app reacts to returning to the foreground. Five
// screens each listening for themselves would be five places to disagree about
// what "coming back" means, and five requests racing whenever it happens.
//
// WHAT COMES BACK IS WHAT WAS AWAY
//
// Only a return from the BACKGROUND counts. The app turns inactive for a
// notification shade, an incoming call, a permission prompt or a system sheet
// without the member ever leaving it, and re-reading every list on each of
// those would be traffic nobody asked for.
//
// ONLY WHAT IS ON SCREEN IS ASKED AGAIN
//
// Every provider named below disposes itself when no screen watches it.
// Invalidating one that is not alive does nothing, so a return re-reads the
// lists the member can actually see, and nothing else. There is no timer and
// no polling: without a return, or a pull, nothing is asked again.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../features/journeys/application/journeys_providers.dart';
import '../features/my_routes/application/my_routes_providers.dart';
import '../features/seat_requests/application/seat_request_providers.dart';

/// Server truth another member — or this member, on another device — can
/// change while this app is in the background.
///
/// The member's own name, the place catalogue and the reviews they have
/// received are not here: nothing a returning member was waiting on moves
/// them.
final List<ProviderOrFamily> kForegroundRereads = <ProviderOrFamily>[
  mySeatRequestsProvider,
  incomingSeatRequestsProvider,
  myJourneysProvider,
  journeyProvider,
  myRoutesProvider,
];

class ForegroundRefresh extends ConsumerStatefulWidget {
  const ForegroundRefresh({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ForegroundRefresh> createState() => _ForegroundRefreshState();
}

class _ForegroundRefreshState extends ConsumerState<ForegroundRefresh> {
  late final AppLifecycleListener _lifecycle;

  /// Whether the app has been hidden since the last re-read.
  bool _wasHidden = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: () => _wasHidden = true,
      onResume: _resumed,
    );
  }

  void _resumed() {
    if (!_wasHidden) return;
    _wasHidden = false;

    for (final ProviderOrFamily read in kForegroundRereads) {
      ref.invalidate(read);
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
