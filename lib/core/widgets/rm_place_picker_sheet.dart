// ─────────────────────────────────────────────────────────────
// RideMate — Place picker
//
// A modal sheet listing the places a member can choose from.
//
// Shared because Search and Create Route use it with an identical interaction
// contract: the same sheet, the same rows, the same `Future<Place?>`. If either
// side ever needs a different treatment, it comes back out rather than growing
// flags.
//
// DELIBERATELY NOT A SEARCH FIELD. The approved design contains no text input,
// no autocomplete and no suggestion list, so none is invented here. This is a
// deterministic local list.
//
// When real location search arrives it replaces the LIST SOURCE only — the
// sheet, the draft and every widget that reads it stay exactly as they are.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../places/place.dart';
import '../theme/tokens/rm_colors.dart';
import '../theme/tokens/rm_spacing.dart';
import '../theme/tokens/rm_typography.dart';
import 'rm_journey_marker.dart';
import 'rm_list_row.dart';

/// Shows the picker and resolves to the chosen place, or null if dismissed.
Future<Place?> showPlacePicker(
  BuildContext context, {
  required String title,
  required List<Place> places,
  required Place? selected,
}) {
  return showModalBottomSheet<Place>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) =>
        _PlacePickerSheet(title: title, places: places, selected: selected),
  );
}

class _PlacePickerSheet extends StatelessWidget {
  const _PlacePickerSheet({
    required this.title,
    required this.places,
    required this.selected,
  });

  final String title;
  final List<Place> places;

  /// The place already chosen, if any.
  ///
  /// Null before a driver has chosen one — which is the normal state of a
  /// Create Route endpoint until the server catalogue has been read and
  /// something picked from it. No row is marked, and nothing is preselected.
  final Place? selected;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          RmSpacing.screenGutter,
          0,
          RmSpacing.screenGutter,
          RmSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                title,
                style: RmTypography.titleSm.copyWith(color: c.ink),
              ),
            ),
            const SizedBox(height: RmSpacing.lg),
            for (final Place place in places)
              Padding(
                padding: const EdgeInsets.only(bottom: RmSpacing.sm),
                child: RmListRow(
                  title: place.label,
                  tone: place == selected
                      ? RmRowTone.primary
                      : RmRowTone.neutral,
                  trailing: place == selected
                      ? const RmJourneyMarker(RmJourneyPoint.origin)
                      : null,
                  onTap: () => Navigator.of(context).pop(place),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
