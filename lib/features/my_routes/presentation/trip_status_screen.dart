// ─────────────────────────────────────────────────────────────
// RideMate — One journey's lifecycle, in full
//
// WHAT THIS SCREEN IS NOT
//
// Not the Active Trip fixture. That one draws a map, claims a live location,
// offers an SOS control and shows a passenger who is not there — none of which
// RideMate implements. It stays registered in debug builds and linked from
// nowhere, and nothing here reuses a line of it. A plain screen that is true
// beats a rich one that is not.
//
// `in_progress` MEANS ONE THING
//
// The driver pressed Start and the server accepted it. Not that the car is
// moving, that the driver is at the origin, that anybody boarded, or that any
// location is known. The screen says so out loud rather than leaving a reader
// to assume the rest.
//
// IT READS THE LIST, BECAUSE THERE IS NO SINGLE-ROUTE ENDPOINT
//
// `GET /me/routes` is the owner's only read, so this selects its row out of
// the page My Routes already holds. That is not a shortcut: it is what keeps
// one lifecycle truth. A command run here updates the card behind it and vice
// versa, because both are looking at the same state. A row that is not in the
// loaded pages says so — nothing is invented to fill the screen.
//
// NOTHING IS COMPUTED FROM THE CLOCK
//
// No duration, no elapsed time, no arrival, no estimate. The three timestamps
// are the server's own and are printed, not measured against each other.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/api/rm_error_copy.dart';
import '../../../core/api/rm_failure.dart';
import '../../../core/format/rm_formatters.dart';
import '../../../core/format/rm_text_conventions.dart';
import '../../../core/icons/rm_icons.dart';
import '../../../core/routes/departure.dart';
import '../../../core/routes/my_route.dart';
import '../../../core/theme/tokens/rm_colors.dart';
import '../../../core/theme/tokens/rm_spacing.dart';
import '../../../core/theme/tokens/rm_typography.dart';
import '../../../core/trips/trip_lifecycle.dart';
import '../../../core/widgets/rm_button.dart';
import '../../../core/widgets/rm_card.dart';
import '../../../core/widgets/rm_icon_button.dart';
import '../../../core/widgets/rm_list_row.dart';
import '../../../l10n/app_localizations.dart';
import '../application/my_routes_providers.dart';
import '../domain/my_routes_page.dart';
import 'trip_refusal_copy.dart';

class TripStatusScreen extends ConsumerWidget {
  const TripStatusScreen({required this.routeId, super.key});

  final String routeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmColors c = context.rmColors;
    final AsyncValue<MyRoutesPage> page = ref.watch(myRoutesProvider);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                RmSpacing.screenGutter,
                RmSpacing.md,
                RmSpacing.screenGutter,
                0,
              ),
              child: Row(
                children: <Widget>[
                  RmIconButton(
                    icon: RmIcons.chevronLeft,
                    semanticLabel: l10n.commonBack,
                    onPressed: () => _back(context),
                  ),
                  const SizedBox(width: RmSpacing.md),
                  Expanded(
                    child: Text(
                      l10n.tripStatusTitle,
                      style: RmTypography.label.copyWith(color: c.ink),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              // `hasError` before `isLoading`, for the reason Route Requests
              // gives: a build that threw sits in a loading state carrying its
              // error, so matching loading first would spin for ever.
              child: switch (page) {
                AsyncValue<MyRoutesPage>(
                  hasError: true,
                  :final Object? error,
                ) =>
                  _Centred(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        RmInlineMessage(
                          message: error is RmFailure
                              ? error.copy(l10n)
                              : l10n.errorUnexpected,
                          icon: RmIcons.alertTriangle,
                          tone: RmRowTone.danger,
                        ),
                        const SizedBox(height: RmSpacing.md),
                        _Retry(l10n: l10n),
                      ],
                    ),
                  ),
                AsyncValue<MyRoutesPage>(isLoading: true) => _Centred(
                  child: Text(
                    l10n.commonLoading,
                    style: RmTypography.body.copyWith(color: c.sub),
                  ),
                ),
                AsyncValue<MyRoutesPage>(:final MyRoutesPage? value)
                    when value != null =>
                  _body(context, ref, l10n, c, value),
                _ => const SizedBox.shrink(),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    RmColors c,
    MyRoutesPage page,
  ) {
    MyRoute? found;
    for (final MyRoute candidate in page.routes) {
      if (candidate.id == routeId) found = candidate;
    }

    // Not in the pages loaded so far. Said plainly rather than filled in: a
    // screen that invented a journey here would be inventing exactly the fact
    // it exists to report.
    if (found == null) {
      return _Centred(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              l10n.tripStatusNotFound,
              style: RmTypography.body.copyWith(color: c.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: RmSpacing.xs),
            Text(
              l10n.tripStatusNotFoundBody,
              style: RmTypography.caption.copyWith(color: c.sub),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: RmSpacing.md),
            _Retry(l10n: l10n),
          ],
        ),
      );
    }

    return _Detail(row: found, busy: page.isChangingTrip(routeId));
  }

  static void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoutes.myRoutes);
    }
  }
}

class _Retry extends ConsumerWidget {
  const _Retry({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) => RmButton(
    label: l10n.commonRetry,
    size: RmButtonSize.sm,
    variant: RmButtonVariant.outline,
    onPressed: () => ref.read(myRoutesProvider.notifier).refresh(),
  );
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.row, required this.busy});

  final MyRoute row;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmColors c = context.rmColors;
    final RmFormatters f = RmFormatters.of(context);

    final String journey = RmTextConventions.route(
      row.route.origin.label,
      row.route.destination.label,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        RmSpacing.screenGutter,
        RmSpacing.lg,
        RmSpacing.screenGutter,
        RmSpacing.xl,
      ),
      children: <Widget>[
        Text(journey, style: RmTypography.titleMd.copyWith(color: c.ink)),
        const SizedBox(height: RmSpacing.lg),
        RmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Line(label: l10n.tripStatusDeparture, value: _departure(l10n)),
              const SizedBox(height: RmSpacing.md),
              _Line(label: l10n.tripStatusState, value: _state(l10n)),
              // What `in_progress` does not mean, said rather than assumed.
              if (row.trip.state == TripState.inProgress) ...<Widget>[
                const SizedBox(height: RmSpacing.xs),
                Text(
                  l10n.tripStatusStartedNote,
                  style: RmTypography.caption.copyWith(color: c.sub),
                ),
              ],
            ],
          ),
        ),
        // Each row exists only because the server sent that instant. Nothing
        // is measured between them: no duration, no arrival, no estimate.
        ..._instants(l10n, f),
        if (_canStart || _canEnd) ...<Widget>[
          const SizedBox(height: RmSpacing.lg),
          ..._actions(context, ref, l10n, journey),
        ],
      ],
    );
  }

  bool get _canStart => row.trip.state == TripState.notStarted;

  bool get _canEnd => row.trip.state == TripState.inProgress;

  /// The timestamps that exist, and only those.
  List<Widget> _instants(AppLocalizations l10n, RmFormatters f) {
    final List<Widget> rows = <Widget>[];

    for (final (String label, DateTime? instant) in <(String, DateTime?)>[
      (l10n.tripStatusStartedAt, row.trip.startedAt),
      (l10n.tripStatusCompletedAt, row.trip.completedAt),
      (l10n.tripStatusAbortedAt, row.trip.abortedAt),
    ]) {
      if (instant == null) continue;

      rows
        ..add(const SizedBox(height: RmSpacing.sm))
        ..add(RmListRow(title: label, subtitle: f.instant(instant)));
    }

    return rows;
  }

  String _state(AppLocalizations l10n) => switch (row.trip.state) {
    TripState.notStarted => l10n.tripStatusStateNotStarted,
    TripState.inProgress => l10n.tripStatusStateInProgress,
    TripState.completed => l10n.tripStatusStateCompleted,
    TripState.aborted => l10n.tripStatusStateAborted,
  };

  /// The departure the driver published, in the terms they chose.
  String _departure(AppLocalizations l10n) {
    final DepartureDate? date = row.route.departureDate;

    return switch (row.route.recurrence) {
      Recurrence.weekdays =>
        '${l10n.myRoutesRecurrenceWeekdays} · ${row.route.departureTime.hhMm}',
      Recurrence.once when date != null =>
        '${date.iso} · ${row.route.departureTime.hhMm}',
      Recurrence.once => row.route.departureTime.hhMm,
    };
  }

  /// The same rule the card uses, for the same reason: the lifecycle decides,
  /// and nothing here consults a clock, a route status or a passenger.
  List<Widget> _actions(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String journey,
  ) => <Widget>[
    if (_canStart)
      RmButton(
        label: l10n.myRoutesStartTrip,
        semanticLabel: l10n.myRoutesStartTripSemanticLabel(journey),
        fullWidth: true,
        loading: busy,
        onPressed: () => _run(context, ref, journey, _Command.start),
      ),
    if (_canEnd) ...<Widget>[
      RmButton(
        label: l10n.myRoutesCompleteTrip,
        semanticLabel: l10n.myRoutesCompleteTripSemanticLabel(journey),
        fullWidth: true,
        loading: busy,
        onPressed: () => _run(context, ref, journey, _Command.complete),
      ),
      const SizedBox(height: RmSpacing.sm),
      RmButton(
        label: l10n.myRoutesAbortTrip,
        semanticLabel: l10n.myRoutesAbortTripSemanticLabel(journey),
        variant: RmButtonVariant.outline,
        fullWidth: true,
        loading: busy,
        onPressed: () => _run(context, ref, journey, _Command.abort),
      ),
    ],
  ];

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    String journey,
    _Command command,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final MyRoutesController controller = ref.read(myRoutesProvider.notifier);

    final RmFailure? failure = switch (command) {
      _Command.start => await controller.startTrip(row.id),
      _Command.complete => await controller.completeTrip(row.id),
      _Command.abort => await controller.abortTrip(row.id),
    };

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            failure == null
                ? switch (command) {
                    _Command.start => l10n.myRoutesTripStarted(journey),
                    _Command.complete => l10n.myRoutesTripCompleted(journey),
                    _Command.abort => l10n.myRoutesTripAborted(journey),
                  }
                : tripRefusalCopy(l10n, failure),
          ),
        ),
      );
  }
}

enum _Command { start, complete, abort }

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: RmTypography.caption.copyWith(color: c.sub)),
        const SizedBox(height: RmSpacing.xxs),
        Text(value, style: RmTypography.body.copyWith(color: c.ink)),
      ],
    );
  }
}

class _Centred extends StatelessWidget {
  const _Centred({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(RmSpacing.screenGutter),
      child: child,
    ),
  );
}
