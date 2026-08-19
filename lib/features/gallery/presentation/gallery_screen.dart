// ─────────────────────────────────────────────────────────────
// RideMate — Design system gallery (DEBUG ONLY)
//
// Developer tooling, registered only under kDebugMode and never reachable in
// a release build. It is the visual QA surface for the design system and the
// fixture the golden tests render.
//
// Its own chrome is intentionally NOT localized: it is a developer tool, not
// product UI, and translating it would add churn for no user benefit. Product
// strings shown inside it come from the real localizations.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_preferences_provider.dart';
import '../../../core/format/rm_formatters.dart';
import '../../../core/format/rm_text_conventions.dart';
import '../../../core/icons/rm_icons.dart';
import '../../../core/theme/tokens/rm_colors.dart';
import '../../../core/theme/tokens/rm_radius.dart';
import '../../../core/theme/tokens/rm_sizing.dart';
import '../../../core/theme/tokens/rm_spacing.dart';
import '../../../core/theme/tokens/rm_typography.dart';
import '../../../core/widgets/rm_avatar.dart';
import '../../../core/widgets/rm_button.dart';
import '../../../core/widgets/rm_card.dart';
import '../../../core/widgets/rm_chip.dart';
import '../../../core/widgets/rm_icon.dart';
import '../../../core/widgets/rm_icon_button.dart';
import '../../../core/widgets/rm_list_row.dart';
import '../../../core/widgets/rm_meters.dart';
import '../../../core/widgets/rm_pulse_dot.dart';
import '../../../core/widgets/rm_status_pill.dart';

/// Browsable catalogue of every design-system primitive.
class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key, this.forceTextDirection});

  /// Forces a text direction. Used by the RTL golden; null follows the locale.
  final TextDirection? forceTextDirection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RmColors c = context.rmColors;

    final Widget body = Scaffold(
      appBar: AppBar(
        title: const Text('Design System'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Cycle theme',
            onPressed: () => ref.read(themeModeProvider.notifier).cycle(),
            icon: const Icon(Icons.brightness_6_outlined),
          ),
          IconButton(
            tooltip: 'Toggle locale',
            onPressed: () {
              final Locale? current = ref.read(localeProvider);
              ref
                  .read(localeProvider.notifier)
                  .set(
                    current?.languageCode == 'en'
                        ? const Locale('tr')
                        : const Locale('en'),
                  );
            },
            icon: const Icon(Icons.translate_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(RmSpacing.screenGutter),
        children: <Widget>[
          const _Section('Typography', child: _TypographySpecimen()),
          _Section('Colours', child: _ColourSpecimen(colors: c)),
          const _Section('Buttons', child: _ButtonSpecimen()),
          const _Section('Icon buttons', child: _IconButtonSpecimen()),
          const _Section('Chips', child: _ChipSpecimen()),
          const _Section('Badges', child: _BadgeSpecimen()),
          const _Section('Cards', child: _CardSpecimen()),
          const _Section('Avatars & trust', child: _AvatarSpecimen()),
          const _Section('Meters', child: _MeterSpecimen()),
          const _Section('List rows', child: _ListRowSpecimen()),
          const _Section('States', child: _StateSpecimen()),
          const _Section('Live status', child: _LiveStatusSpecimen()),
          const _Section('Formatting', child: _FormatSpecimen()),
          const _Section('Icons', child: _IconSheet()),
          const SizedBox(height: RmSpacing.huge),
        ],
      ),
    );

    return forceTextDirection == null
        ? body
        : Directionality(textDirection: forceTextDirection!, child: body);
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, {required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: RmSpacing.xxxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          RmSectionLabel(title),
          const SizedBox(height: RmSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _TypographySpecimen extends StatelessWidget {
  const _TypographySpecimen();

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final MapEntry<String, TextStyle> e in RmTypography.all.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: RmSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${e.key} · ${e.value.fontSize!.toStringAsFixed(0)}',
                  style: RmTypography.micro.copyWith(color: c.muted),
                ),
                Text(
                  e.key.startsWith('numeric')
                      ? '12.480 · %94 · ₺18'
                      : 'Güvenilir yolculuk',
                  style: e.value.copyWith(color: c.ink),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ColourSpecimen extends StatelessWidget {
  const _ColourSpecimen({required this.colors});

  final RmColors colors;

  @override
  Widget build(BuildContext context) {
    final Map<String, Color> swatches = <String, Color>{
      'primary': colors.primary,
      'primaryPressed': colors.primaryPressed,
      'primarySoft': colors.primarySoft,
      'success': colors.success,
      'successSoft': colors.successSoft,
      'danger': colors.danger,
      'dangerSoft': colors.dangerSoft,
      'warning': colors.warning,
      'warningSoft': colors.warningSoft,
      'background': colors.background,
      'surface': colors.surface,
      'surfaceMuted': colors.surfaceMuted,
      'border': colors.border,
      'ink': colors.ink,
      'sub': colors.sub,
      'muted': colors.muted,
      'faint': colors.faint,
      'disabled': colors.disabled,
    };

    return Wrap(
      spacing: RmSpacing.md,
      runSpacing: RmSpacing.md,
      children: <Widget>[
        for (final MapEntry<String, Color> e in swatches.entries)
          SizedBox(
            width: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: e.value,
                    borderRadius: RmRadius.brSm,
                    border: Border.all(color: colors.border),
                  ),
                ),
                const SizedBox(height: RmSpacing.xs),
                Text(
                  e.key,
                  style: RmTypography.micro.copyWith(color: colors.sub),
                ),
                Text(
                  '#${e.value.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                  style: RmTypography.numericMicro.copyWith(
                    color: colors.muted,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ButtonSpecimen extends StatelessWidget {
  const _ButtonSpecimen();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (final RmButtonVariant v in RmButtonVariant.values) ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: RmSpacing.md),
            child: Column(
              children: <Widget>[
                RmButton(
                  label: v.name,
                  variant: v,
                  size: RmButtonSize.md,
                  onPressed: () {},
                ),
                const SizedBox(height: RmSpacing.sm),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: RmButton(
                        label: 'disabled',
                        variant: v,
                        size: RmButtonSize.md,
                      ),
                    ),
                    const SizedBox(width: RmSpacing.md),
                    Expanded(
                      child: RmButton(
                        label: 'loading',
                        variant: v,
                        size: RmButtonSize.md,
                        loading: true,
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        for (final RmButtonSize s in RmButtonSize.values)
          Padding(
            padding: const EdgeInsets.only(bottom: RmSpacing.md),
            child: RmButton(
              label: 'size ${s.name}',
              size: s,
              icon: RmIcons.shareTrip,
              onPressed: () {},
            ),
          ),
      ],
    );
  }
}

class _IconButtonSpecimen extends StatelessWidget {
  const _IconButtonSpecimen();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: RmSpacing.md,
      runSpacing: RmSpacing.md,
      children: <Widget>[
        for (final RmIconButtonVariant v in RmIconButtonVariant.values)
          RmIconButton(
            icon: RmIcons.phone,
            semanticLabel: v.name,
            variant: v,
            onPressed: () {},
          ),
        const RmIconButton(icon: RmIcons.clock, semanticLabel: 'disabled'),
        RmFab(
          icon: RmIcons.plus,
          semanticLabel: 'Rota oluştur',
          onPressed: () {},
        ),
      ],
    );
  }
}

class _ChipSpecimen extends StatelessWidget {
  const _ChipSpecimen();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: RmSpacing.sm,
      runSpacing: RmSpacing.sm,
      children: <Widget>[
        RmChip(
          label: 'Sadece doğrulanmış',
          icon: RmIcons.check,
          selected: true,
          onTap: () {},
        ),
        RmChip(label: '4.5+ puan', onTap: () {}),
        RmChip(label: 'Kadın sürücü', onTap: () {}),
        RmChip(
          label: 'En uyumlu',
          tone: RmChipTone.ink,
          selected: true,
          compact: true,
          onTap: () {},
        ),
        RmChip(
          label: 'En yakın',
          tone: RmChipTone.ink,
          compact: true,
          onTap: () {},
        ),
        const RmChip(label: 'Dakik · 41', tone: RmChipTone.info),
      ],
    );
  }
}

class _BadgeSpecimen extends StatelessWidget {
  const _BadgeSpecimen();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: RmSpacing.sm,
      runSpacing: RmSpacing.sm,
      children: <Widget>[
        for (final RmBadgeTone t in RmBadgeTone.values)
          RmBadge(label: t.name, tone: t),
        const RmBadge(label: '4,9', icon: RmIcons.starFilled, numeric: true),
        const RmBadge(label: '%94 uyum', numeric: true),
      ],
    );
  }
}

class _CardSpecimen extends StatelessWidget {
  const _CardSpecimen();

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    return Column(
      children: <Widget>[
        for (final RmCardVariant v in RmCardVariant.values)
          Padding(
            padding: const EdgeInsets.only(bottom: RmSpacing.md),
            child: RmCard(
              variant: v,
              child: Text(
                v.name,
                style: RmTypography.titleSm.copyWith(
                  color: v == RmCardVariant.gradient ? c.onPrimary : c.ink,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AvatarSpecimen extends StatelessWidget {
  const _AvatarSpecimen();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: RmSpacing.lg,
          runSpacing: RmSpacing.lg,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            for (final double s in <double>[
              RmAvatarSize.xs,
              RmAvatarSize.sm,
              RmAvatarSize.md,
              RmAvatarSize.lg,
              RmAvatarSize.xl,
              RmAvatarSize.xxl,
              RmAvatarSize.hero,
            ])
              RmAvatar(initials: 'SK', size: s),
          ],
        ),
        const SizedBox(height: RmSpacing.xl),
        const Wrap(
          spacing: RmSpacing.lg,
          runSpacing: RmSpacing.lg,
          children: <Widget>[
            RmAvatar(initials: 'SK', identity: RmIdentity.amber),
            RmAvatar(initials: 'MA', identity: RmIdentity.green),
            RmAvatar(initials: 'EY', identity: RmIdentity.purple),
            RmAvatar(
              initials: 'SK',
              shape: RmAvatarShape.circle,
              identity: RmIdentity.green,
            ),
          ],
        ),
        const SizedBox(height: RmSpacing.xl),
        // Verification and presence are separate concepts — see RmAvatar.
        const Wrap(
          spacing: RmSpacing.lg,
          runSpacing: RmSpacing.lg,
          children: <Widget>[
            RmAvatar(initials: 'SK', size: RmAvatarSize.xl),
            RmAvatar(
              initials: 'SK',
              size: RmAvatarSize.xl,
              verification: RmVerification.verified,
            ),
            RmAvatar(
              initials: 'SK',
              size: RmAvatarSize.xl,
              presence: RmPresence.online,
            ),
          ],
        ),
      ],
    );
  }
}

class _MeterSpecimen extends StatelessWidget {
  const _MeterSpecimen();

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            RmTrustRing(
              progress: 0.92,
              child: Text(
                '92',
                style: RmTypography.numericLg.copyWith(color: c.ink),
              ),
            ),
            const SizedBox(width: RmSpacing.xl),
            RmTrustRing(
              progress: 0.6,
              color: c.primary,
              child: Text(
                '60',
                style: RmTypography.numericLg.copyWith(color: c.ink),
              ),
            ),
          ],
        ),
        const SizedBox(height: RmSpacing.xl),
        for (final double p in <double>[0, 0.42, 0.82, 0.94, 1])
          Padding(
            padding: const EdgeInsets.only(bottom: RmSpacing.md),
            child: RmLinearMeter(
              progress: p,
              gradient: p > 0.9 ? c.meterPrimary : null,
              color: p < 0.9 ? c.warning : null,
            ),
          ),
      ],
    );
  }
}

class _ListRowSpecimen extends StatelessWidget {
  const _ListRowSpecimen();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (final RmRowTone t in RmRowTone.values)
          Padding(
            padding: const EdgeInsets.only(bottom: RmSpacing.md),
            child: RmListRow(
              title: 'Row tone ${t.name}',
              subtitle: 'İkincil açıklama satırı',
              icon: RmIcons.shield,
              tone: t,
              onTap: () {},
            ),
          ),
        RmListRow(
          title: 'Doğrulama rozetleri',
          subtitle: 'Kimlik doğrulama',
          icon: RmIcons.shieldCheck,
          tone: RmRowTone.success,
          trailing: const RmBadge(label: '4 / 5', numeric: true),
          onTap: () {},
        ),
      ],
    );
  }
}

/// The live-status family.
///
/// Both of these were built in Phase 1 for the Active Trip screen and had no
/// consumer until Phase 5, so this specimen is the first place a reviewer can
/// see them. The dots animate indefinitely and still themselves under reduced
/// motion.
class _LiveStatusSpecimen extends StatelessWidget {
  const _LiveStatusSpecimen();

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Wrap(
          spacing: RmSpacing.sm,
          runSpacing: RmSpacing.sm,
          children: <Widget>[
            RmStatusPill(label: 'Kadıköy'),
            RmStatusPill(
              label: 'CANLI YOLCULUK',
              tone: RmStatusPillTone.ink,
              pulsing: true,
            ),
          ],
        ),
        const SizedBox(height: RmSpacing.xl),
        Row(
          children: <Widget>[
            RmPulseDot(color: c.success, pulsing: true),
            const SizedBox(width: RmSpacing.sm),
            RmPulseDot(color: c.primary, pulsing: true),
            const SizedBox(width: RmSpacing.sm),
            RmPulseDot(color: c.muted),
          ],
        ),
      ],
    );
  }
}

class _StateSpecimen extends StatelessWidget {
  const _StateSpecimen();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // The shipped Chat wording, not the comp's. The approved sentence
        // tells the member to pay inside the app, and there is no payment
        // feature — see D-chat-3.
        RmInlineMessage(
          message:
              'Ödeme özelliği henüz aktif değil. '
              'Kişisel veya finansal bilgilerinizi paylaşmayın.',
        ),
        SizedBox(height: RmSpacing.md),
        RmInlineMessage(
          message: 'Bu bir bilgi mesajıdır.',
          icon: RmIcons.shieldCheck,
          tone: RmRowTone.success,
        ),
        SizedBox(height: RmSpacing.xl),
        // Invented, token-derived: the source has no loading state.
        RmSkeleton(width: 220, height: 20),
        SizedBox(height: RmSpacing.sm),
        RmSkeleton(width: 160, height: 16),
      ],
    );
  }
}

class _FormatSpecimen extends StatelessWidget {
  const _FormatSpecimen();

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final RmFormatters f = RmFormatters.of(context);
    final DateTime now = DateTime(2026, 8, 16, 12);

    final Map<String, String> rows = <String, String>{
      'money': f.money(18),
      'percent': f.percentOf100(94),
      'rating': f.rating(4.9),
      'count': f.count(12480),
      'distance': f.distanceKm(6.2),
      'duration': f.durationMinutes(18),
      'time': f.time(DateTime(2026, 1, 1, 8, 25)),
      'relative': f.relativeDate(DateTime(2026, 8, 14), now: now),
      'name': RmTextConventions.abbreviateName('Selin Kaya'),
      'phone': RmTextConventions.maskPhone('+90 555 123 4542'),
      'plate': RmTextConventions.plate('34abc128'),
      'route': RmTextConventions.route('Kadıköy', 'Levent'),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'locale: ${f.localeName}',
          style: RmTypography.micro.copyWith(color: c.muted),
        ),
        const SizedBox(height: RmSpacing.sm),
        for (final MapEntry<String, String> e in rows.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: RmSpacing.xs),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 100,
                  child: Text(
                    e.key,
                    style: RmTypography.micro.copyWith(color: c.muted),
                  ),
                ),
                Expanded(
                  child: Text(
                    e.value,
                    style: RmTypography.numericXs.copyWith(color: c.ink),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _IconSheet extends StatelessWidget {
  const _IconSheet();

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    return Wrap(
      spacing: RmSpacing.lg,
      runSpacing: RmSpacing.lg,
      children: <Widget>[
        for (final MapEntry<String, String> e in RmIcons.all.entries)
          SizedBox(
            width: 84,
            child: Column(
              children: <Widget>[
                RmIcon(e.value, size: RmIconSize.xl, color: c.ink),
                const SizedBox(height: RmSpacing.xs),
                Text(
                  e.key,
                  style: RmTypography.micro.copyWith(color: c.muted),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
