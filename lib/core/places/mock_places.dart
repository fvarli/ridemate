// ─────────────────────────────────────────────────────────────
// RideMate — Place fixtures
//
// PRESENTATION FIXTURE. NOT A DATA SOURCE.
//
// The İstanbul places the approved design names, in the order it lists them.
// Every label appears verbatim in docs/claude-designs/RideMate App.dc.html.
//
// This is a fixed list, not a geocoding result, not a search index and not a
// nearby-places query. It is shared rather than feature-owned because the
// passenger side (Search) and the driver side (Create Route) choose from the
// same list; when real place search arrives it replaces this file and nothing
// else.
// ─────────────────────────────────────────────────────────────

import 'place.dart';

/// Selectable journey endpoints.
abstract final class MockPlaces {
  const MockPlaces._();

  static const Place kadikoy = Place(
    id: 'kadikoy-iskele',
    label: 'Kadıköy, İskele Meydanı',
  );
  static const Place levent = Place(
    id: 'levent-metro',
    label: 'Levent, Metro İstasyonu',
  );
  static const Place maslak = Place(
    id: 'maslak-42',
    label: 'Maslak, 42 Maslak',
  );
  static const Place atasehir = Place(
    id: 'atasehir-palladium',
    label: 'Ataşehir, Palladium',
  );
  static const Place university = Place(id: 'universite', label: 'Üniversite');

  static const List<Place> all = <Place>[
    kadikoy,
    levent,
    maslak,
    atasehir,
    university,
  ];
}
