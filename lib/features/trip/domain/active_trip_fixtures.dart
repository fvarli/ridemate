// ─────────────────────────────────────────────────────────────
// RideMate — Active trip fixtures
//
// PRESENTATION FIXTURES. NOT LIVE DATA.
//
// Everything here reproduces the approved Active Trip screen so the driver and
// passenger experience can be seen and reviewed on a device. None of it is
// measured, tracked or calculated, and none of it changes over time.
// ─────────────────────────────────────────────────────────────

import '../../../core/widgets/rm_avatar.dart';
import 'active_trip_snapshot.dart';

/// The trip the design draws.
const ActiveTripSnapshot kMockActiveTrip = ActiveTripSnapshot(
  driverName: 'Selin K.',
  driverInitials: 'SK',
  driverIdentity: RmIdentity.amber,
  driverRating: 4.9,
  // The comp draws a plain green dot with no check: presence, not verification.
  driverPresence: RmPresence.online,
  vehicleName: 'VW Passat',
  plate: '34 ABC 128',
  etaMinutes: 18,
  remainingKm: 6.2,
  punctuality: TripPunctuality.onTime,
  emergencyContactCount: 2,
);
