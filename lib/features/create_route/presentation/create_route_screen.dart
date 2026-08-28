// ─────────────────────────────────────────────────────────────
// RideMate — Create route
//
// Source: docs/claude-designs/RideMate App.dc.html, "CREATE ROUTE" (immutable).
//
// Title → endpoints → recurrence → departure → seats → ride rules, with the
// primary action docked at the bottom.
//
// A driver here is sharing a journey they are ALREADY making. Nothing on this
// screen implies commercial passenger transport, customer acquisition, driver
// earnings, fare setting or dynamic pricing, and no trip is taken because a
// passenger asked for it.
//
// `Rotayı yayınla` NOW PUBLISHES. The journey goes to the server and the
// screen says it worked only once the server has said so — never optimistically
// and never before. A failure is stated as a failure, and the draft survives it
// intact, so nothing the driver typed is lost to a dropped connection.
//
// The approved screen has no date, time or place control at all, and no
// loading, empty or failure state anywhere. Those are recorded deviations, not
// improvisation — see docs/design-system.md §8.
//
// DEVIATION D-create-1: the header gains a back control the comp does not
// draw. The screen is pushed above the shell with no tab bar, so without it
// the only way out is a system gesture. The chevron tile is the vocabulary
// Match Results and Route Details already use.
// ─────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/clock_provider.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/api/rm_error_copy.dart';
import '../../../core/api/rm_failure.dart';
import '../../../core/icons/rm_icons.dart';
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
import '../application/place_catalogue_providers.dart';
import '../application/publication_providers.dart';
import '../domain/create_route_draft.dart';
import '../domain/departure.dart';
import 'widgets/departure_card.dart';
import 'widgets/recurrence_card.dart';
import 'widgets/ride_rule_chips.dart';
import 'widgets/route_endpoints_card.dart';
import 'widgets/seats_row.dart';

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
    final AsyncValue<List<Place>> catalogue = ref.watch(placeCatalogueProvider);
    final PublicationState publication = ref.watch(publicationProvider);

    // The outcome is announced once, when it arrives, rather than rebuilt into
    // the tree — a driver must not have to wonder whether the journey landed.
    ref.listen<PublicationState>(
      publicationProvider,
      (PublicationState? previous, PublicationState next) =>
          _announce(context, l10n, next),
    );

    // A refreshed catalogue may no longer contain something already chosen.
    // Matched on id: a place that has gone is gone, whatever it was called,
    // and keeping a reference the server would reject helps nobody.
    ref.listen<AsyncValue<List<Place>>>(placeCatalogueProvider, (
      AsyncValue<List<Place>>? previous,
      AsyncValue<List<Place>> next,
    ) {
      final List<Place>? places = next.value;
      if (places != null) controller.reconcileWith(places);
    });

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
                      // Tappable only once there is something to choose from.
                      // A picker over a spinner or a failure would offer an
                      // empty list and look broken instead of honest.
                      onEditOrigin: () => _withCatalogue(
                        catalogue,
                        (List<Place> places) =>
                            _pickOrigin(context, ref, draft, places),
                      ),
                      onEditDestination: () => _withCatalogue(
                        catalogue,
                        (List<Place> places) =>
                            _pickDestination(context, ref, draft, places),
                      ),
                    ),
                  ),
                  _CatalogueStatus(catalogue: catalogue),
                  const SizedBox(height: RmSpacing.md),
                  _Gutter(
                    child: RecurrenceCard(
                      repeats: draft.recurrence == Recurrence.weekdays,
                      onChanged: (bool repeats) => controller.setRecurrence(
                        repeats ? Recurrence.weekdays : Recurrence.once,
                      ),
                    ),
                  ),
                  const SizedBox(height: RmSpacing.md),
                  _Gutter(
                    child: DepartureCard(
                      recurrence: draft.recurrence,
                      date: draft.departureDate,
                      time: draft.departureTime,
                      onPickDate: () => _pickDate(context, ref, draft),
                      onPickTime: () => _pickTime(context, ref, draft),
                    ),
                  ),
                  const SizedBox(height: RmSpacing.md),
                  _Gutter(
                    child: SeatsRow(
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
                    // The same treatment the auth screens use while a request
                    // is out. A second tap while this is true is ignored by
                    // the controller, so two taps cannot become two journeys.
                    loading: publication is PublicationInFlight,
                    onPressed: () =>
                        _onPublishRequested(context, ref, l10n, draft),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Publishes, or says what is still missing.
  ///
  /// Local completeness only. Whether the departure is still in the future,
  /// whether the places exist and whether the id is well formed are the
  /// server's questions, and asking them twice would produce two answers that
  /// could disagree.
  void _onPublishRequested(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    CreateRouteDraft draft,
  ) {
    // Named rather than disabled. The design system has no disabled button
    // anywhere, and inventing one here would be a second deviation on top of
    // the departure controls — so the CTA stays live and says what is missing.
    final String? missing = switch (draft) {
      CreateRouteDraft(origin: null) => l10n.createRouteOriginEmpty,
      CreateRouteDraft(destination: null) => l10n.createRouteDestinationEmpty,
      CreateRouteDraft(hasDistinctEndpoints: false) =>
        l10n.createRouteEndpointsSame,
      CreateRouteDraft(departureTime: null) =>
        l10n.createRouteDepartureTimeMissing,
      CreateRouteDraft(needsDepartureDate: true, departureDate: null) =>
        l10n.createRouteDepartureDateMissing,
      _ => null,
    };

    if (missing != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(missing)));

      return;
    }

    unawaited(ref.read(publicationProvider.notifier).publish());
  }

  /// Says what happened, once.
  ///
  /// Success is stated only after the server has confirmed it. A failure is
  /// stated as a failure: nothing optimistic is shown, no route is invented,
  /// and the draft is left exactly as the driver wrote it so nothing they
  /// typed is lost to a dropped connection.
  void _announce(
    BuildContext context,
    AppLocalizations l10n,
    PublicationState state,
  ) {
    final String? message = switch (state) {
      PublicationConfirmed() => l10n.createRoutePublished,
      // The detail comes from the shared error vocabulary rather than a second
      // one invented here.
      PublicationRetryable(:final RmFailure failure) ||
      PublicationRefused(:final RmFailure failure) => failure.copy(l10n),
      PublicationIdle() || PublicationInFlight() => null,
    };

    if (message == null) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Asks for the day a one-off journey happens.
  ///
  /// The window opens today, because a driver cannot publish a journey that has
  /// already left, and closes a year out — far enough for any commute anybody
  /// is planning and near enough that the picker is not an archive. "Today" is
  /// injected so a widget test does not depend on the day it runs.
  Future<void> _pickDate(
    BuildContext context,
    WidgetRef ref,
    CreateRouteDraft draft,
  ) async {
    final DateTime now = ref.read(clockProvider)();
    final DateTime today = DateTime(now.year, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: draft.departureDate?.toPickerValue() ?? today,
      firstDate: today,
      lastDate: DateTime(today.year + 1, today.month, today.day),
    );

    if (picked == null) return;

    ref
        .read(createRouteDraftProvider.notifier)
        .setDepartureDate(DepartureDate.from(picked));
  }

  /// Asks for the wall clock the journey leaves at.
  ///
  /// No initial value is invented when none has been chosen: the picker opens
  /// at the current hour, which is a starting position rather than an answer,
  /// and nothing is written to the draft unless the driver confirms.
  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    CreateRouteDraft draft,
  ) async {
    final DepartureTime? current = draft.departureTime;
    final DateTime now = ref.read(clockProvider)();

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: current == null
          ? TimeOfDay(hour: now.hour, minute: now.minute)
          : TimeOfDay(hour: current.hour, minute: current.minute),
    );

    if (picked == null) return;

    ref
        .read(createRouteDraftProvider.notifier)
        .setDepartureTime(
          DepartureTime(hour: picked.hour, minute: picked.minute),
        );
  }

  /// Runs [open] only when the catalogue has actually arrived.
  void _withCatalogue(
    AsyncValue<List<Place>> catalogue,
    void Function(List<Place>) open,
  ) {
    final List<Place>? places = catalogue.value;
    if (places != null && places.isNotEmpty) open(places);
  }

  /// Opens the picker over the catalogue the server returned.
  ///
  /// `places` is passed in rather than read here, so this method cannot be
  /// called with anything but a loaded catalogue — there is no path from a
  /// failure or a spinner to an open picker.
  Future<void> _pickOrigin(
    BuildContext context,
    WidgetRef ref,
    CreateRouteDraft draft,
    List<Place> places,
  ) async {
    final Place? place = await showPlacePicker(
      context,
      title: AppLocalizations.of(context).createRouteOriginPickerTitle,
      places: places,
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
    List<Place> places,
  ) async {
    final Place? place = await showPlacePicker(
      context,
      title: AppLocalizations.of(context).createRouteDestinationPickerTitle,
      places: places,
      selected: draft.destination,
    );
    if (place != null) {
      ref.read(createRouteDraftProvider.notifier).setDestination(place);
    }
  }
}

/// What the endpoints card can offer, and why, when it cannot offer anything.
///
/// Renders nothing at all when the catalogue is present and non-empty — the
/// card speaks for itself then. Every other case says something true: still
/// loading, nothing supported yet, or could not be read, with a way to ask
/// again.
///
/// THERE IS NO FALLBACK LIST. A failure here leaves a driver unable to choose
/// an endpoint, which is correct: the alternative is offering places the server
/// has never heard of, letting them build a journey on one, and failing at
/// publication with an error about an unknown id.
class _CatalogueStatus extends ConsumerWidget {
  const _CatalogueStatus({required this.catalogue});

  final AsyncValue<List<Place>> catalogue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    final (String message, bool retryable)? state = switch (catalogue) {
      AsyncValue<List<Place>>(hasError: true) => (
        l10n.createRoutePlacesUnavailable,
        true,
      ),
      AsyncValue<List<Place>>(isLoading: true) => (
        l10n.createRoutePlacesLoading,
        false,
      ),
      AsyncValue<List<Place>>(:final List<Place> value) when value.isEmpty => (
        l10n.createRoutePlacesEmpty,
        true,
      ),
      _ => null,
    };

    if (state == null) return const SizedBox.shrink();

    final (String message, bool retryable) = state;

    return Padding(
      padding: const EdgeInsets.only(top: RmSpacing.md),
      child: _Gutter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            RmInlineMessage(message: message),
            if (retryable) ...<Widget>[
              const SizedBox(height: RmSpacing.md),
              RmButton(
                label: l10n.commonRetry,
                size: RmButtonSize.sm,
                variant: RmButtonVariant.outline,
                fullWidth: false,
                // A fresh request, not a cached answer — there is no cache.
                onPressed: () =>
                    ref.read(placeCatalogueProvider.notifier).refresh(),
              ),
            ],
          ],
        ),
      ),
    );
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
