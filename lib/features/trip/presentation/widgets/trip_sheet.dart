// ─────────────────────────────────────────────────────────────
// RideMate — Active trip sheet
//
// Source: docs/claude-designs/RideMate App.dc.html, "ACTIVE TRIP" (immutable).
//
// ETA → driver bar → actions → the live-location footer.
//
// Every figure comes from the snapshot and is displayed unchanged. The ETA does
// not count down and the distance does not shrink; see active_trip_snapshot.
//
// The footer's "Canlı konumun … paylaşılıyor" is PRESENTATION COPY AND NOTHING
// MORE. No location is shared, no trusted contact is contacted, no background
// location exists and no emergency state exists. It is the main reason this
// screen is reachable only in debug builds, and the string must never be reused
// on a release-reachable surface until the behaviour behind it exists.
//
// The driver's avatar carries PRESENCE, not verification — the comp draws a
// plain green dot with no check. The two are different claims and stay
// different types; because this row has no visible "Çevrimiçi" text, the dot is
// load-bearing and its meaning is folded into the row's merged label.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/format/rm_formatters.dart';
import '../../../../core/icons/rm_icons.dart';
import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_radius.dart';
import '../../../../core/theme/tokens/rm_shadows.dart';
import '../../../../core/theme/tokens/rm_sizing.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_avatar.dart';
import '../../../../core/widgets/rm_button.dart';
import '../../../../core/widgets/rm_chip.dart';
import '../../../../core/widgets/rm_icon_button.dart';
import '../../../../core/widgets/rm_pulse_dot.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/active_trip_snapshot.dart';
import 'sos_button.dart';

/// The floating sheet over the map.
class TripSheet extends StatelessWidget {
  const TripSheet({
    required this.trip,
    required this.onCall,
    required this.onMessage,
    required this.onShare,
    required this.onSos,
    super.key,
  });

  final ActiveTripSnapshot trip;
  final VoidCallback onCall;
  final VoidCallback onMessage;
  final VoidCallback onShare;
  final VoidCallback onSos;

  /// The most of the screen the sheet may take, so the map keeps a visible
  /// band even at the maximum text scale.
  static const double maxHeightFraction = 0.72;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: constraints.maxHeight * maxHeightFraction,
          ),
          decoration: BoxDecoration(
            color: c.sheet,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(RmRadius.xxl),
            ),
            boxShadow: context.rmShadows.sheetUp,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                RmSpacing.screenGutter,
                RmSpacing.xl,
                RmSpacing.screenGutter,
                RmSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _EtaRow(trip: trip),
                  const SizedBox(height: RmSpacing.lg),
                  _DriverBar(trip: trip, onCall: onCall, onMessage: onMessage),
                  const SizedBox(height: RmSpacing.md),
                  _Actions(onShare: onShare, onSos: onSos),
                  const SizedBox(height: RmSpacing.md),
                  _LocationFooter(count: trip.emergencyContactCount),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EtaRow extends StatelessWidget {
  const _EtaRow({required this.trip});

  final ActiveTripSnapshot trip;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmFormatters f = RmFormatters.of(context);

    final String duration = f.durationMinutes(trip.etaMinutes);
    final String distance = f.distanceKm(trip.remainingKm);
    final String status = switch (trip.punctuality) {
      TripPunctuality.onTime => l10n.activeTripOnTime,
    };

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: l10n.activeTripEtaSemanticLabel(
        l10n.activeTripEtaLabel,
        duration,
        distance,
        status,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  l10n.activeTripEtaLabel,
                  style: RmTypography.caption.copyWith(color: c.muted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: RmSpacing.xxs),
                // The design sets the duration in Manrope and the distance in
                // mono, on one line.
                Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: duration,
                        style: RmTypography.titleLg.copyWith(color: c.ink),
                      ),
                      TextSpan(
                        text: '  ${RmFormatters.separator.trim()} $distance',
                        style: RmTypography.numericXs.copyWith(color: c.muted),
                      ),
                    ],
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: RmSpacing.md),
          RmBadge(label: status),
        ],
      ),
    );
  }
}

class _DriverBar extends StatelessWidget {
  const _DriverBar({
    required this.trip,
    required this.onCall,
    required this.onMessage,
  });

  final ActiveTripSnapshot trip;
  final VoidCallback onCall;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RmFormatters f = RmFormatters.of(context);

    final String rating = f.rating(trip.driverRating);

    return Container(
      padding: const EdgeInsets.all(RmSpacing.md),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: RmRadius.brLg,
      ),
      child: Row(
        children: <Widget>[
          // One merged node: the presence dot has no visible text beside it on
          // this screen, so the label has to say "çevrimiçi" itself.
          Expanded(
            child: Semantics(
              container: true,
              excludeSemantics: true,
              label: l10n.activeTripDriverSemanticLabel(
                trip.driverName,
                rating,
                trip.vehicleName,
                trip.plate,
              ),
              child: Row(
                children: <Widget>[
                  RmAvatar(
                    initials: trip.driverInitials,
                    size: RmAvatarSize.md,
                    identity: trip.driverIdentity,
                    // Presence, never verification. The comp draws no check.
                    presence: trip.driverPresence,
                    surfaceColor: c.surfaceMuted,
                  ),
                  const SizedBox(width: RmSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          l10n.activeTripDriverName(trip.driverName, rating),
                          style: RmTypography.body.copyWith(color: c.ink),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: RmSpacing.xxs),
                        // Two lines, never truncated: the plate is an identity
                        // and safety datum, not decoration. Its own spaces are
                        // non-breaking so a wrap falls at the separator rather
                        // than splitting "34 ABC 128" across lines.
                        Text(
                          l10n.activeTripDriverMeta(
                            trip.vehicleName,
                            trip.plate.replaceAll(' ', '\u00A0'),
                          ),
                          style: RmTypography.captionSm.copyWith(
                            color: c.muted,
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: RmSpacing.sm),
          RmIconButton(
            icon: RmIcons.phone,
            semanticLabel: l10n.activeTripCall,
            variant: RmIconButtonVariant.success,
            onPressed: onCall,
          ),
          const SizedBox(width: RmSpacing.sm),
          RmIconButton(
            icon: RmIcons.chatBubble,
            semanticLabel: l10n.activeTripMessage,
            variant: RmIconButtonVariant.filled,
            onPressed: onMessage,
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.onShare, required this.onSos});

  final VoidCallback onShare;
  final VoidCallback onSos;

  /// The width at which the designed side-by-side row actually fits.
  ///
  /// DEVIATION D-trip-3: on a phone it does not. "Yolculuğu paylaş" needs 138dp
  /// of label at the scaled type size, plus its icon and padding, beside a
  /// fixed 148dp SOS — about 214dp against the 185dp a 393dp screen leaves. The
  /// comp is marginal at its own artboard for the same reason the Search
  /// endpoints were (D-search-2), and neither label may be truncated: one is a
  /// safety control and the other would read as "Yolculuğu ...". So the two
  /// stack on phones and only regain the designed row on a wider surface.
  static const double _sideBySideMin = 420;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    final Widget share = RmButton(
      label: l10n.activeTripShare,
      icon: RmIcons.shareTrip,
      variant: RmButtonVariant.outline,
      size: RmButtonSize.md,
      onPressed: onShare,
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Stack rather than shrink. SOS never narrows and never ellipsises.
        if (constraints.maxWidth < _sideBySideMin) {
          return Column(
            children: <Widget>[
              share,
              const SizedBox(height: RmSpacing.md),
              SosButton(onPressed: onSos, expanded: true),
            ],
          );
        }
        return Row(
          children: <Widget>[
            Expanded(child: share),
            const SizedBox(width: RmSpacing.md),
            SosButton(onPressed: onSos),
          ],
        );
      },
    );
  }
}

/// The live-location line. Presentation copy — nothing is shared. See header.
class _LocationFooter extends StatelessWidget {
  const _LocationFooter({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // Decorative: the sentence beside it carries the meaning.
        ExcludeSemantics(child: RmPulseDot(color: c.primary, pulsing: true)),
        const SizedBox(width: RmSpacing.sm),
        Flexible(
          child: Text(
            l10n.activeTripLocationSharing(count),
            style: RmTypography.captionSm.copyWith(color: c.sub),
            textAlign: TextAlign.center,
            maxLines: 3,
          ),
        ),
      ],
    );
  }
}
