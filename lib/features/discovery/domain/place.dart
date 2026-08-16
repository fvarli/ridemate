// ─────────────────────────────────────────────────────────────
// RideMate — Place
//
// A journey endpoint as the UI shows it: an id and a human label.
//
// PRESENTATION DATA ONLY. There are no coordinates, no geocoding, no place
// provider and no address model. Phase 3 selects endpoints from a fixed local
// list; when real location search arrives, only the SOURCE of that list
// changes, and this type gains whatever the provider actually returns.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

/// A selectable journey endpoint.
@immutable
final class Place {
  const Place({required this.id, required this.label});

  final String id;

  /// Display label, e.g. `Kadıköy, İskele Meydanı`.
  final String label;

  @override
  bool operator ==(Object other) => other is Place && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Place($id)';
}
