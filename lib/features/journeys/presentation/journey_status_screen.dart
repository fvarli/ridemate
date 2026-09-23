// ─────────────────────────────────────────────────────────────
// RideMate — One dated journey's lifecycle, in full
//
// THE DATED FORM OF TripStatusScreen, AND NOT A COPY OF IT
//
// That screen selects a ROUTE out of the My Routes page and reads the plan's
// own trip — which exists only for a one-off route, because a plan has no
// single journey. This one is addressed by `(routeId, serviceDate)` and reads
// that journey directly, so every day of a plan has a page of its own.
//
// IT READS THE JOURNEY RATHER THAN SEARCHING A LIST
//
// `GET /me/journeys` is BOUNDED — today's journeys and anything still under
// way — so selecting out of it would answer "not found" for every other day a
// route runs, which is most of them. The dated read has no such bound: any day
// the route runs on can be read, ahead or behind.
//
// NOTHING HERE DECIDES WHETHER A COMMAND IS ALLOWED
//
// Not whether the departure has been reached, not whether the service date has
// passed, not what today is in the route's timezone, and not whether a cancelled
// plan may still be ended. Every one of those is read in a zone this client
// cannot evaluate, and the server answers each by name. The controls follow the
// lifecycle the server last returned; the server has the last word on the tap.
//
// WHAT THIS SCREEN IS NOT
//
// Not the Active Trip fixture. No map, no location, no SOS, no passenger, no
// movement — none of which RideMate implements. `in_progress` means the driver
// pressed Start and the server accepted it, and the screen says so out loud.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/api/rm_error_copy.dart';
import '../../../core/api/rm_failure.dart';
import '../../../core/api/rm_refresh.dart';
import '../../../core/format/rm_formatters.dart';
import '../../../core/format/rm_text_conventions.dart';
import '../../../core/icons/rm_icons.dart';
import '../../../core/journeys/journey.dart';
import '../../../core/routes/departure.dart';
import '../../../core/routes/route_decoder.dart';
import '../../../core/theme/tokens/rm_colors.dart';
import '../../../core/theme/tokens/rm_spacing.dart';
import '../../../core/theme/tokens/rm_typography.dart';
import '../../../core/trips/trip_lifecycle.dart';
import '../../../core/trips/trip_state_copy.dart';
import '../../../core/widgets/rm_button.dart';
import '../../../core/widgets/rm_card.dart';
import '../../../core/widgets/rm_icon_button.dart';
import '../../../core/widgets/rm_list_row.dart';
import '../../../core/widgets/rm_pull_to_refresh.dart';
import '../../../l10n/app_localizations.dart';
import '../../my_routes/presentation/trip_refusal_copy.dart';
import '../application/journeys_providers.dart';
import '../domain/journey_detail.dart';

class JourneyStatusScreen extends ConsumerWidget {
  const JourneyStatusScreen({
    required this.routeId,
    required this.serviceDate,
    super.key,
  });

  final String routeId;

  /// The day, as it arrived in the path: `YYYY-MM-DD`.
  ///
  /// Text rather than a [DepartureDate] because a route parameter is text, and
  /// what a member can type is not always a day. It is parsed below by the same
  /// strict reader the wire uses, so `2026-02-30` is refused here rather than
  /// becoming a request about a date that does not exist.
  final String serviceDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmColors c = context.rmColors;

    final DepartureDate? day = RouteDecoder.day(serviceDate);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _Header(l10n: l10n, c: c),
            Expanded(
              child: routeId.isEmpty || day == null
                  // Not a journey anybody has. Said plainly rather than asked
                  // about: a request built from this would name a day the
                  // server has no answer for.
                  ? _Missing(l10n: l10n, c: c, target: null)
                  : _Loaded(
                      target: (routeId: routeId, serviceDate: day),
                      l10n: l10n,
                      c: c,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.l10n, required this.c});

  final AppLocalizations l10n;
  final RmColors c;

  @override
  Widget build(BuildContext context) => Padding(
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
  );

  static void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoutes.myRoutes);
    }
  }
}

/// The journey, once its identity is known to be a real one.
///
/// A widget of its own so the provider is watched with a [JourneyRef] that is
/// already parsed — and so this screen holds that subscription for as long as
/// it is on screen, which is what keeps the auto-disposed family member alive
/// across a command that outlives a tap.
class _Loaded extends ConsumerWidget {
  const _Loaded({required this.target, required this.l10n, required this.c});

  final JourneyRef target;
  final AppLocalizations l10n;
  final RmColors c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<JourneyDetail> detail = ref.watch(journeyProvider(target));

    // The lifecycle can move on another device, so the driver can ask the
    // server again from any state.
    return RmPullToRefresh(
      onRefresh: () => rmReread(ref, <Refreshable<Future<Object?>>>[
        journeyProvider(target).future,
      ]),
      // `hasError` before `isLoading`, for the reason My Routes gives: a build
      // that threw sits in a loading state carrying its error, so matching
      // loading first would spin for ever.
      //
      // A held answer comes before both. A failed re-read of a journey this
      // screen has already shown is not evidence that the journey is missing,
      // and saying "not found" over it would be false.
      child: switch (detail) {
        AsyncValue<JourneyDetail>(:final JourneyDetail? held)
            when held != null =>
          _Detail(
            target: target,
            detail: held,
            refreshFailed: detail.refreshFailed,
          ),
        AsyncValue<JourneyDetail>(hasError: true, :final Object? error) =>
          RmPullable(
            child: _Missing(
              l10n: l10n,
              c: c,
              target: target,
              failure: error is RmFailure ? error : null,
            ),
          ),
        AsyncValue<JourneyDetail>(isLoading: true) => RmPullable(
          child: _Centred(
            child: Text(
              l10n.commonLoading,
              style: RmTypography.body.copyWith(color: c.sub),
            ),
          ),
        ),
        AsyncValue<JourneyDetail>(:final JourneyDetail? value)
            when value != null =>
          _Detail(target: target, detail: value),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _Missing extends ConsumerWidget {
  const _Missing({
    required this.l10n,
    required this.c,
    required this.target,
    this.failure,
  });

  final AppLocalizations l10n;
  final RmColors c;

  /// Null when the path itself did not name a journey, in which case there is
  /// nothing to retry.
  final JourneyRef? target;
  final RmFailure? failure;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final JourneyRef? target = this.target;

    return _Centred(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            l10n.journeyNotFound,
            style: RmTypography.body.copyWith(color: c.ink),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: RmSpacing.xs),
          Text(
            // The server's own reason when it gave one. A 404 here is
            // deliberately indistinguishable between "not your route" and
            // "this route does not run that day", and nothing invents which.
            failure?.copy(l10n) ?? l10n.journeyNotFoundBody,
            style: RmTypography.caption.copyWith(color: c.sub),
            textAlign: TextAlign.center,
          ),
          if (target != null) ...<Widget>[
            const SizedBox(height: RmSpacing.md),
            RmButton(
              label: l10n.commonRetry,
              size: RmButtonSize.sm,
              variant: RmButtonVariant.outline,
              onPressed: () =>
                  ref.read(journeyProvider(target).notifier).refresh(),
            ),
          ],
        ],
      ),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({
    required this.target,
    required this.detail,
    this.refreshFailed = false,
  });

  final JourneyRef target;
  final JourneyDetail detail;

  /// This lifecycle is the last answer, and asking again did not replace it.
  final bool refreshFailed;

  Journey get journey => detail.journey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmColors c = context.rmColors;
    final RmFormatters f = RmFormatters.of(context);

    final String route = RmTextConventions.route(
      journey.origin.label,
      journey.destination.label,
    );
    final String day = f.weekdayDate(
      journey.serviceDate.year,
      journey.serviceDate.month,
      journey.serviceDate.day,
    );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        RmSpacing.screenGutter,
        RmSpacing.lg,
        RmSpacing.screenGutter,
        RmSpacing.xl,
      ),
      children: <Widget>[
        if (refreshFailed) ...<Widget>[
          RmInlineMessage(
            message: l10n.commonRefreshFailed,
            icon: RmIcons.alertTriangle,
            tone: RmRowTone.danger,
          ),
          const SizedBox(height: RmSpacing.md),
        ],
        Text(route, style: RmTypography.titleMd.copyWith(color: c.ink)),
        const SizedBox(height: RmSpacing.lg),
        RmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // WHICH DAY, first. It is half the identity, and a driver
              // looking at a plan's Tuesday must never be left inferring that
              // from the rest of the page.
              _Line(label: l10n.tripStatusServiceDate, value: day),
              const SizedBox(height: RmSpacing.md),
              // The wall clock as published — no zone conversion.
              _Line(
                label: l10n.tripStatusDeparture,
                value: journey.departureTime.hhMm,
              ),
              const SizedBox(height: RmSpacing.md),
              // Always present on this surface: a journey is a concrete day, so
              // the question always has an answer, and no stored trip means
              // `notStarted`. Unlike MyRoute.trip, which is null for a plan and
              // means the question does not apply at all.
              _Line(
                label: l10n.tripStatusState,
                value: tripStateLabel(l10n, journey.trip.state),
              ),
              if (journey.trip.state == TripState.inProgress) ...<Widget>[
                const SizedBox(height: RmSpacing.xs),
                Text(
                  l10n.tripStatusStartedNote,
                  style: RmTypography.caption.copyWith(color: c.sub),
                ),
              ],
            ],
          ),
        ),
        // Each row exists only because the server sent that instant. Nothing is
        // measured between them: no duration, no arrival, no estimate.
        ..._instants(l10n, f),
        if (_canStart || _canEnd) ...<Widget>[
          const SizedBox(height: RmSpacing.lg),
          ..._actions(context, ref, l10n, route),
        ],
      ],
    );
  }

  /// The lifecycle decides which controls exist, and nothing else does.
  ///
  /// NOT the service date, NOT the route's status and NOT a clock. A journey
  /// that is under way stays endable after its own day has gone and after its
  /// plan has been cancelled — the backend keeps both reachable on purpose, and
  /// a screen that hid the controls would strand a driver mid-journey with a
  /// trip they cannot close.
  bool get _canStart => journey.trip.state == TripState.notStarted;

  bool get _canEnd => journey.trip.state == TripState.inProgress;

  List<Widget> _instants(AppLocalizations l10n, RmFormatters f) {
    final List<Widget> rows = <Widget>[];

    for (final (String label, DateTime? instant) in <(String, DateTime?)>[
      (l10n.tripStatusStartedAt, journey.trip.startedAt),
      (l10n.tripStatusCompletedAt, journey.trip.completedAt),
      (l10n.tripStatusAbortedAt, journey.trip.abortedAt),
    ]) {
      if (instant == null) continue;

      rows
        ..add(const SizedBox(height: RmSpacing.sm))
        ..add(RmListRow(title: label, subtitle: f.instant(instant)));
    }

    return rows;
  }

  List<Widget> _actions(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String route,
  ) => <Widget>[
    if (_canStart)
      RmButton(
        label: l10n.myRoutesStartTrip,
        semanticLabel: l10n.myRoutesStartTripSemanticLabel(route),
        fullWidth: true,
        loading: detail.isChangingTrip,
        onPressed: () => _run(context, ref, route, _Command.start),
      ),
    if (_canEnd) ...<Widget>[
      RmButton(
        label: l10n.myRoutesCompleteTrip,
        semanticLabel: l10n.myRoutesCompleteTripSemanticLabel(route),
        fullWidth: true,
        loading: detail.isChangingTrip,
        onPressed: () => _run(context, ref, route, _Command.complete),
      ),
      const SizedBox(height: RmSpacing.sm),
      RmButton(
        label: l10n.myRoutesAbortTrip,
        semanticLabel: l10n.myRoutesAbortTripSemanticLabel(route),
        variant: RmButtonVariant.outline,
        fullWidth: true,
        loading: detail.isChangingTrip,
        onPressed: () => _run(context, ref, route, _Command.abort),
      ),
    ],
  ];

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    String route,
    _Command command,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    // Read before the await, and held: this screen is watching the same family
    // member, so the controller stays alive for the whole command.
    final JourneyController controller = ref.read(
      journeyProvider(target).notifier,
    );

    final RmFailure? failure = switch (command) {
      _Command.start => await controller.start(),
      _Command.complete => await controller.complete(),
      _Command.abort => await controller.abort(),
    };

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            failure == null
                ? switch (command) {
                    _Command.start => l10n.myRoutesTripStarted(route),
                    _Command.complete => l10n.myRoutesTripCompleted(route),
                    _Command.abort => l10n.myRoutesTripAborted(route),
                  }
                // The refusal the server named, in the shared Trip vocabulary.
                // Never inferred from `message`, which is developer-facing
                // English no client displays.
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
