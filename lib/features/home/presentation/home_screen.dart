// ─────────────────────────────────────────────────────────────
// RideMate — Home
//
// WHAT THIS REPLACED, AND WHY
//
// Until Phase 17 R2 this screen was the design's "HOME · MAP": a map
// illustration with driver pins, a greeting to somebody called Elif, saved
// addresses for Home/Work/University, and a card offering a 94% match with
// Selin K. — rated 4.9, verified, ₺18 a head. Every one of those was a
// fixture, and together they were the first thing a real member saw after
// signing in. Nothing in this product knows a rating, a verification state, a
// compatibility figure, a cost or anybody's location; the landing screen was
// asserting six capabilities that do not exist, about a person who does not.
//
// WHAT IT SHOWS INSTEAD
//
// Only what the member's own account already answers for:
//
//   the greeting     `GET /me/profile`      their own name
//   your driving     `GET /me/journeys`     the journeys the server returns
//   your requests    `GET /me/seat-requests` the askings they have made
//
// Nothing else. No `/me/routes` read — My Routes is a link, not a third data
// section — because a landing screen that opens four requests to summarise
// itself has become an admin console.
//
// HOME SUMMARISES NOTHING
//
// No "next trip", no "2 rides today", no counts, no totals, no re-ranking, no
// "upcoming". Each of those would be a fact this client derived, and the whole
// point of Phase 16b was that dates, order and inclusion belong to the server.
// The previews show the first few rows of each feed, in the order they
// arrived, and say what the feed says.
//
// THE THREE SECTIONS FAIL SEPARATELY
//
// They are three resources. A journeys outage must not blank out the askings
// that loaded, and neither may take the greeting with it — so each section
// owns its loading, empty and error state and its own retry.
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
import '../../../core/journeys/journey.dart';
import '../../../core/routes/departure.dart';
import '../../../core/seat_requests/seat_request.dart';
import '../../../core/theme/tokens/rm_colors.dart';
import '../../../core/theme/tokens/rm_radius.dart';
import '../../../core/theme/tokens/rm_spacing.dart';
import '../../../core/theme/tokens/rm_typography.dart';
import '../../../core/trips/trip_state_copy.dart';
import '../../../core/widgets/rm_button.dart';
import '../../../core/widgets/rm_card.dart';
import '../../../core/widgets/rm_icon.dart';
import '../../../core/widgets/rm_list_row.dart';
import '../../../l10n/app_localizations.dart';
import '../../journeys/application/journeys_providers.dart';
import '../../journeys/domain/my_journeys_page.dart';
import '../../profile/application/my_profile_providers.dart';
import '../../seat_requests/application/seat_request_providers.dart';
import '../../seat_requests/domain/seat_request_page.dart';

/// How many rows a preview shows.
///
/// The first few of the server's own page, never a selection: nothing here
/// decides which journeys matter, and taking a prefix of an ordered list is the
/// only reduction that cannot reorder it. The full lists are one tap away.
const int kHomePreviewRows = 3;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmColors c = context.rmColors;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            RmSpacing.screenGutter,
            RmSpacing.lg,
            RmSpacing.screenGutter,
            RmSpacing.xxl,
          ),
          children: <Widget>[
            const _Greeting(),
            const SizedBox(height: RmSpacing.lg),
            _SearchCta(l10n: l10n),
            const SizedBox(height: RmSpacing.xl),
            const _DrivingSection(),
            const SizedBox(height: RmSpacing.xl),
            const _RequestsSection(),
            const SizedBox(height: RmSpacing.xl),
            _Manage(l10n: l10n),
          ],
        ),
      ),
    );
  }
}

/// The member's own name, from the server.
///
/// Their own, and only their own. The greeting is the one place a name appears
/// on this screen — no avatar, no initials, no verification mark, none of which
/// this product publishes about anybody.
///
/// While it loads, and if it fails, the greeting stands alone without a name
/// rather than guessing one. A landing screen greeting the wrong person is the
/// defect this section replaced.
class _Greeting extends ConsumerWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmColors c = context.rmColors;
    final AsyncValue<ProfileState> state = ref.watch(myProfileProvider);

    final String? name = switch (state) {
      AsyncValue<ProfileState>(value: final ProfileReady ready) =>
        ready.profile.displayName,
      _ => null,
    };

    return Semantics(
      header: true,
      child: Text(
        name == null ? l10n.homeGreeting : l10n.homeGreetingNamed(name),
        style: RmTypography.titleMd.copyWith(color: c.ink),
      ),
    );
  }
}

/// The one thing this screen asks a member to do.
class _SearchCta extends StatelessWidget {
  const _SearchCta({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => RmButton(
    label: l10n.homeFindRide,
    semanticLabel: l10n.homeFindRideSemanticLabel,
    fullWidth: true,
    // The Search tab, not Match Results: a search needs two places, and
    // jumping past the screen that collects them would land on an empty
    // result nobody asked for.
    onPressed: () => context.goNamed(AppRoutes.search),
  );
}

/// The journeys this member is driving, as the server returns them.
class _DrivingSection extends ConsumerWidget {
  const _DrivingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<MyJourneysPage> feed = ref.watch(myJourneysProvider);

    return _Section(
      // NOT "today" and NOT "next". `/me/journeys` decides what is in it —
      // today's journeys AND anything still under way, whatever its date — so
      // a heading naming a day would be this client describing a rule it does
      // not own, and would be wrong about the journey started yesterday.
      title: l10n.homeDrivingTitle,
      child: switch (feed) {
        AsyncValue<MyJourneysPage>(hasError: true, :final Object? error) =>
          _Failed(
            message: error is RmFailure
                ? error.copy(l10n)
                : l10n.journeysFailed,
            onRetry: () => ref.read(myJourneysProvider.notifier).refresh(),
          ),
        AsyncValue<MyJourneysPage>(isLoading: true) => const _Loading(),
        AsyncValue<MyJourneysPage>(:final MyJourneysPage? value)
            when value != null =>
          value.journeys.isEmpty
              ? _Empty(message: l10n.journeysEmpty)
              : _JourneyPreview(journeys: value.journeys),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _JourneyPreview extends StatelessWidget {
  const _JourneyPreview({required this.journeys});

  final List<Journey> journeys;

  @override
  Widget build(BuildContext context) {
    // The first few of the server's page, in its order. Nothing sorts, filters
    // or hides: a journey under way on a day already past, and one whose plan
    // has since been cancelled, are both kept deliberately reachable by the
    // feed, and a client that dropped either would strand its driver.
    final List<Journey> shown = journeys.take(kHomePreviewRows).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < shown.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: RmSpacing.sm),
          _JourneyRow(journey: shown[i]),
        ],
      ],
    );
  }
}

class _JourneyRow extends StatelessWidget {
  const _JourneyRow({required this.journey});

  final Journey journey;

  @override
  Widget build(BuildContext context) {
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
    // The wall clock exactly as published; no zone conversion anywhere.
    final String when =
        '$day${RmFormatters.separator}'
        '${journey.departureTime.hhMm}';
    final String state = tripStateLabel(l10n, journey.trip.state);

    return RmCard(
      child: Semantics(
        button: true,
        label: l10n.journeyCardSemanticLabel(route, day, when, state),
        child: InkWell(
          // The journey's own identity travels: the route AND the day. There
          // is no journey id, and a route alone names none of a plan's days.
          onTap: () => context.pushNamed(
            AppRoutes.journeyStatus,
            pathParameters: <String, String>{
              'routeId': journey.routeId,
              'serviceDate': journey.serviceDate.iso,
            },
          ),
          borderRadius: BorderRadius.circular(RmRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: RmSpacing.xs),
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(route, style: RmTypography.body.copyWith(color: c.ink)),
                  const SizedBox(height: RmSpacing.xs),
                  Text(
                    when,
                    style: RmTypography.caption.copyWith(color: c.sub),
                  ),
                  const SizedBox(height: RmSpacing.xs),
                  // Text, never colour alone.
                  Text(
                    state,
                    style: RmTypography.caption.copyWith(color: c.ink),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The seats this member has asked for.
class _RequestsSection extends ConsumerWidget {
  const _RequestsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<SeatRequestPage<MySeatRequest>> page = ref.watch(
      mySeatRequestsProvider,
    );

    return _Section(
      title: l10n.homeRequestsTitle,
      onSeeAll: () => context.pushNamed(AppRoutes.myRequests),
      seeAllLabel: l10n.homeSeeAll,
      child: switch (page) {
        AsyncValue<SeatRequestPage<MySeatRequest>>(
          hasError: true,
          :final Object? error,
        ) =>
          _Failed(
            message: error is RmFailure
                ? error.copy(l10n)
                : l10n.errorUnexpected,
            onRetry: () => ref.read(mySeatRequestsProvider.notifier).refresh(),
          ),
        AsyncValue<SeatRequestPage<MySeatRequest>>(isLoading: true) =>
          const _Loading(),
        AsyncValue<SeatRequestPage<MySeatRequest>>(
          :final SeatRequestPage<MySeatRequest>? value,
        )
            when value != null =>
          value.requests.isEmpty
              ? _Empty(message: l10n.myRequestsEmpty)
              : _RequestPreview(requests: value.requests),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _RequestPreview extends StatelessWidget {
  const _RequestPreview({required this.requests});

  final List<MySeatRequest> requests;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmColors c = context.rmColors;
    final RmFormatters f = RmFormatters.of(context);

    // The server's order and the server's rows. Terminal askings are not
    // hidden to tidy the screen: `declined` and `withdrawn` are answers this
    // member is entitled to see, and the API decides what the page contains.
    final List<MySeatRequest> shown = requests.take(kHomePreviewRows).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < shown.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: RmSpacing.sm),
          Builder(
            builder: (BuildContext context) {
              final MySeatRequest request = shown[i];
              final String route = RmTextConventions.route(
                request.route.origin.label,
                request.route.destination.label,
              );
              final DepartureDate day = request.serviceDate;
              final String when = f.weekdayDate(day.year, day.month, day.day);
              // What the SERVER says this asking is. Never "confirmed", never
              // "booked": an accepted asking is a driver's answer, not a seat
              // held, and nothing here upgrades one into the other.
              final String status = switch (request.status) {
                SeatRequestStatus.pending => l10n.seatRequestPending,
                SeatRequestStatus.accepted => l10n.seatRequestAccepted,
                SeatRequestStatus.declined => l10n.seatRequestDeclined,
                SeatRequestStatus.withdrawn => l10n.seatRequestWithdrawn,
              };

              return RmCard(
                child: Semantics(
                  container: true,
                  label: l10n.homeRequestSemanticLabel(route, when, status),
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          route,
                          style: RmTypography.body.copyWith(color: c.ink),
                        ),
                        const SizedBox(height: RmSpacing.xs),
                        Text(
                          when,
                          style: RmTypography.caption.copyWith(color: c.sub),
                        ),
                        const SizedBox(height: RmSpacing.xs),
                        Text(
                          status,
                          style: RmTypography.caption.copyWith(color: c.ink),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

/// Where the full surfaces are.
///
/// Links, not data. My Routes in particular is deliberately NOT a fourth
/// section: it would be a third request on a landing screen to summarise a list
/// that already has a screen of its own.
class _Manage extends StatelessWidget {
  const _Manage({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Semantics(
        header: true,
        child: Text(
          l10n.homeManageTitle,
          style: RmTypography.titleSm.copyWith(color: context.rmColors.ink),
        ),
      ),
      const SizedBox(height: RmSpacing.sm),
      RmListRow(
        title: l10n.myRoutesTitle,
        trailing: const RmIcon(RmIcons.chevronRight),
        onTap: () => context.pushNamed(AppRoutes.myRoutes),
      ),
      RmListRow(
        title: l10n.myRequestsTitle,
        trailing: const RmIcon(RmIcons.chevronRight),
        onTap: () => context.pushNamed(AppRoutes.myRequests),
      ),
    ],
  );
}

/// A titled block, with an optional way to the full list.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.onSeeAll,
    this.seeAllLabel,
  });

  final String title;
  final Widget child;
  final VoidCallback? onSeeAll;
  final String? seeAllLabel;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final String? label = seeAllLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: RmTypography.titleSm.copyWith(color: c.ink),
                ),
              ),
            ),
            // Flexible, not bare: a Row hands a non-flex child unbounded
            // width, and RmButton centres itself inside its touch-target box —
            // which cannot resolve against infinity.
            if (onSeeAll != null && label != null)
              Flexible(
                child: RmButton(
                  label: label,
                  size: RmButtonSize.sm,
                  variant: RmButtonVariant.ghost,
                  onPressed: onSeeAll,
                ),
              ),
          ],
        ),
        const SizedBox(height: RmSpacing.sm),
        child,
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => Text(
    AppLocalizations.of(context).commonLoading,
    style: RmTypography.body.copyWith(color: context.rmColors.sub),
  );
}

/// Nothing to show, said without a reason.
///
/// The feed does not say why it is empty, so neither does this.
class _Empty extends StatelessWidget {
  const _Empty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Text(
    message,
    style: RmTypography.body.copyWith(color: context.rmColors.sub),
  );
}

/// One section could not be read.
///
/// Scoped to that section: the others keep whatever they successfully loaded,
/// and the retry asks again for this resource alone.
class _Failed extends StatelessWidget {
  const _Failed({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      RmInlineMessage(
        message: message,
        icon: RmIcons.alertTriangle,
        tone: RmRowTone.danger,
      ),
      const SizedBox(height: RmSpacing.sm),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: RmButton(
          label: AppLocalizations.of(context).commonRetry,
          size: RmButtonSize.sm,
          variant: RmButtonVariant.outline,
          onPressed: onRetry,
        ),
      ),
    ],
  );
}
