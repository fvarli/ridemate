// ─────────────────────────────────────────────────────────────
// RideMate — Home
//
// Source: docs/claude-designs/RideMate App.dc.html, "HOME · MAP" and
// "HOME · DARK" (immutable).
//
// Four stacked layers, as drawn:
//   1. the map illustration, bleeding to every edge
//   2. a scrim bar fading from the background colour, holding the greeting,
//      the search field and the saved-address shortcuts
//   3. the floating matches card
//   4. the navigation bar, supplied by the shell
//
// PHASE 2 SCOPE. There is no location, no permissions, no live matching and no
// maps vendor. The map is artwork and everything it shows is a fixture.
//
// The search field is not a text input — the design draws it as a tappable
// summary that opens the search flow, and that is what it does here.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/icons/rm_icons.dart';
import '../../../core/theme/tokens/rm_colors.dart';
import '../../../core/theme/tokens/rm_radius.dart';
import '../../../core/theme/tokens/rm_sizing.dart';
import '../../../core/theme/tokens/rm_spacing.dart';
import '../../../core/theme/tokens/rm_typography.dart';
import '../../../core/widgets/rm_card.dart';
import '../../../core/widgets/rm_chip.dart';
import '../../../core/widgets/rm_icon.dart';
import '../../../core/widgets/rm_status_pill.dart';
import '../../../l10n/app_localizations.dart';
import '../application/home_providers.dart';
import '../domain/home_snapshot.dart';
import 'widgets/home_map.dart';
import 'widgets/nearby_match_sheet.dart';

/// Mock presentation label on the map's destination pin.
const String _kMockDestinationLabel = 'Levent';

/// The map screen.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HomeSnapshot snapshot = ref.watch(homeSnapshotProvider);

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const HomeMap(destinationLabel: _kMockDestinationLabel),
        Align(
          alignment: Alignment.topCenter,
          child: _TopBar(
            snapshot: snapshot,
            onSearch: () => _openSearch(context),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              RmSpacing.lg,
              0,
              RmSpacing.lg,
              RmSpacing.lg,
            ),
            child: NearbyMatchSheet(
              snapshot: snapshot,
              onSeeAllMatches: () => _openSearch(context),
              onMatchSelected: (NearbyMatch _) => _openSearch(context),
            ),
          ),
        ),
      ],
    );
  }

  /// Opens the search branch.
  ///
  /// Search itself arrives in Phase 3; until then this is an honest dead end
  /// rather than a fabricated results screen.
  static void _openSearch(BuildContext context) =>
      context.goNamed(AppRoutes.search);
}

/// The scrim bar over the map: greeting, search field and shortcuts.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.snapshot, required this.onSearch});

  final HomeSnapshot snapshot;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        // Opaque at the top, fading out, so the controls stay legible over
        // whatever the map happens to draw underneath.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[c.background, c.background.withValues(alpha: 0)],
          stops: const <double>[0.55, 1],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: RmSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _GreetingRow(snapshot: snapshot),
              const SizedBox(height: RmSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: RmSpacing.screenGutter,
                ),
                child: _SearchField(onTap: onSearch),
              ),
              const SizedBox(height: RmSpacing.md),
              const _ShortcutRow(),
            ],
          ),
        ),
      ),
    );
  }
}

class _GreetingRow extends StatelessWidget {
  const _GreetingRow({required this.snapshot});

  final HomeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: RmSpacing.screenGutter),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Only the morning greeting is approved copy; time-of-day
                // variants need design before they can exist.
                Text(
                  l10n.homeGreeting,
                  style: RmTypography.caption.copyWith(color: c.muted),
                ),
                Text(
                  snapshot.greetingName,
                  style: RmTypography.titleMd.copyWith(color: c.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: RmSpacing.md),
          RmStatusPill(label: snapshot.locationLabel),
        ],
      ),
    );
  }
}

/// A tappable summary that opens search — not a text input.
///
/// The design draws no real input anywhere, and inventing one here would add
/// a keyboard, focus and validation surface that has never been designed.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return RmCard(
      variant: RmCardVariant.elevated,
      radius: RmRadius.xl,
      padding: const EdgeInsets.symmetric(
        horizontal: RmSpacing.xl,
        vertical: RmSpacing.lg,
      ),
      onTap: onTap,
      semanticLabel: l10n.homeSearchSemanticLabel,
      child: Row(
        children: <Widget>[
          RmIcon(RmIcons.search, color: c.primary),
          const SizedBox(width: RmSpacing.md),
          Expanded(
            child: Text(
              l10n.homeSearchPlaceholder,
              style: RmTypography.bodyLg.copyWith(color: c.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: RmSpacing.md,
              vertical: RmSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: c.primary,
              borderRadius: RmRadius.brXs,
            ),
            child: Text(
              l10n.homeSearchAction,
              style: RmTypography.labelSm.copyWith(color: c.onPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Saved-address shortcuts.
///
/// Icons are kept in both themes: the dark comp omits them, but an icon is
/// information, and dark must never show less than light.
class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return SizedBox(
      height: RmSizing.iconButtonSm,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: RmSpacing.screenGutter),
        children: <Widget>[
          // Compact so all three fit one row at phone width, as designed.
          // The row still scrolls, so a longer locale degrades gracefully
          // instead of clipping.
          RmChip(
            label: l10n.homeShortcutHome,
            icon: RmIcons.home,
            compact: true,
            onTap: () {},
          ),
          const SizedBox(width: RmSpacing.sm),
          RmChip(
            label: l10n.homeShortcutWork,
            icon: RmIcons.briefcase,
            compact: true,
            onTap: () {},
          ),
          const SizedBox(width: RmSpacing.sm),
          RmChip(
            label: l10n.homeShortcutUniversity,
            compact: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
