// ─────────────────────────────────────────────────────────────
// RideMate — Create route
//
// Source: docs/claude-designs/RideMate App.dc.html, "CREATE ROUTE" (immutable).
//
// Title → endpoints → weekday recurrence → seats and cost share → ride rules,
// with the primary action docked at the bottom.
//
// A driver here is sharing a journey they are ALREADY making. Nothing on this
// screen implies commercial passenger transport, customer acquisition, driver
// earnings, fare setting or dynamic pricing, and no trip is taken because a
// passenger asked for it.
//
// PHASE 4 SCOPE. `Rotayı yayınla` does NOT publish anything: there is no
// backend, no route entity and no publication lifecycle. It shows a message
// that says so plainly and creates no success or pending state. Telling a
// driver their route was published when nothing left the device is the wrong
// thing to encode in a trust product.
//
// The approved screen has no date or time control at all, so a one-off
// journey cannot state when it departs. That gap is recorded rather than
// designed around — see docs/design-system.md §8.
//
// DEVIATION D-create-1: the header gains a back control the comp does not
// draw. The screen is pushed above the shell with no tab bar, so without it
// the only way out is a system gesture. The chevron tile is the vocabulary
// Match Results and Route Details already use.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/icons/rm_icons.dart';
import '../../../core/places/mock_places.dart';
import '../../../core/places/place.dart';
import '../../../core/theme/tokens/rm_colors.dart';
import '../../../core/theme/tokens/rm_spacing.dart';
import '../../../core/theme/tokens/rm_typography.dart';
import '../../../core/widgets/rm_button.dart';
import '../../../core/widgets/rm_cta_dock.dart';
import '../../../core/widgets/rm_icon_button.dart';
import '../../../core/widgets/rm_list_row.dart';
import '../../../core/widgets/rm_place_picker_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../application/create_route_providers.dart';
import '../domain/create_route_draft.dart';
import 'widgets/recurrence_card.dart';
import 'widgets/ride_rule_chips.dart';
import 'widgets/route_endpoints_card.dart';
import 'widgets/seats_and_cost_row.dart';

/// The driver's route composer.
class CreateRouteScreen extends ConsumerWidget {
  const CreateRouteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final CreateRouteDraft draft = ref.watch(createRouteDraftProvider);
    final CreateRouteDraftController controller = ref.read(
      createRouteDraftProvider.notifier,
    );

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: RmSpacing.xxl),
                children: <Widget>[
                  const _Header(),
                  const SizedBox(height: RmSpacing.xl),
                  _Gutter(
                    child: RouteEndpointsCard(
                      origin: draft.origin,
                      destination: draft.destination,
                      onEditOrigin: () => _pickOrigin(context, ref, draft),
                      onEditDestination: () =>
                          _pickDestination(context, ref, draft),
                    ),
                  ),
                  const SizedBox(height: RmSpacing.md),
                  _Gutter(
                    child: RecurrenceCard(
                      repeats: draft.repeatsOnWeekdays,
                      onChanged: controller.setRepeatsOnWeekdays,
                    ),
                  ),
                  const SizedBox(height: RmSpacing.md),
                  _Gutter(
                    child: SeatsAndCostRow(
                      seats: draft.seats,
                      canDecrement: draft.canDecrementSeats,
                      onIncrement: controller.incrementSeats,
                      onDecrement: controller.decrementSeats,
                    ),
                  ),
                  const SizedBox(height: RmSpacing.xxl),
                  _Gutter(child: RmSectionLabel(l10n.createRouteRulesTitle)),
                  const SizedBox(height: RmSpacing.lg),
                  _Gutter(
                    child: RideRuleChips(
                      selected: draft.rules,
                      onToggle: controller.toggleRule,
                    ),
                  ),
                ],
              ),
            ),
            RmCtaDock(
              children: <Widget>[
                Expanded(
                  child: RmButton(
                    label: l10n.createRoutePublish,
                    onPressed: () => _onPublishRequested(context, l10n),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Temporary Phase 4 behaviour for publishing a route.
  ///
  /// Shows an informational message only. It deliberately does NOT create a
  /// route, mark anything published, mutate or clear the draft, navigate away,
  /// or start a publication lifecycle. Nothing left the device, and the copy
  /// says so. When a backend exists the flow becomes publish → server
  /// acknowledgement → visible to other members, and only then may the UI
  /// claim anything was published.
  void _onPublishRequested(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.createRoutePublishUnavailable)),
      );
  }

  Future<void> _pickOrigin(
    BuildContext context,
    WidgetRef ref,
    CreateRouteDraft draft,
  ) async {
    final Place? place = await showPlacePicker(
      context,
      title: AppLocalizations.of(context).createRouteOriginPickerTitle,
      places: MockPlaces.all,
      selected: draft.origin,
    );
    if (place != null) {
      ref.read(createRouteDraftProvider.notifier).setOrigin(place);
    }
  }

  Future<void> _pickDestination(
    BuildContext context,
    WidgetRef ref,
    CreateRouteDraft draft,
  ) async {
    final Place? place = await showPlacePicker(
      context,
      title: AppLocalizations.of(context).createRouteDestinationPickerTitle,
      places: MockPlaces.all,
      selected: draft.destination,
    );
    if (place != null) {
      ref.read(createRouteDraftProvider.notifier).setDestination(place);
    }
  }
}

/// Back control, title and subtitle.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        RmSpacing.screenGutter,
        RmSpacing.lg,
        RmSpacing.screenGutter,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          RmIconButton(
            icon: RmIcons.chevronLeft,
            semanticLabel: l10n.commonBack,
            // The route is deep-linkable, so a cold launch can arrive here
            // with nothing to pop back to.
            onPressed: () => context.canPop()
                ? context.pop()
                : context.goNamed(AppRoutes.home),
          ),
          const SizedBox(width: RmSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Semantics(
                  header: true,
                  child: Text(
                    l10n.createRouteTitle,
                    style: RmTypography.titleMd.copyWith(color: c.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: RmSpacing.xxs),
                Text(
                  l10n.createRouteSubtitle,
                  style: RmTypography.caption.copyWith(color: c.muted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The screen's standard horizontal inset.
class _Gutter extends StatelessWidget {
  const _Gutter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: RmSpacing.screenGutter),
    child: child,
  );
}
