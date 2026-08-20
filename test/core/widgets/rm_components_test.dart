import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/a11y/rm_a11y.dart';
import 'package:ridemate/core/icons/rm_icons.dart';
import 'package:ridemate/core/theme/tokens/rm_colors.dart';
import 'package:ridemate/core/theme/tokens/rm_sizing.dart';
import 'package:ridemate/core/widgets/rm_avatar.dart';
import 'package:ridemate/core/widgets/rm_button.dart';
import 'package:ridemate/core/widgets/rm_card.dart';
import 'package:ridemate/core/widgets/rm_chip.dart';
import 'package:ridemate/core/widgets/rm_icon.dart';
import 'package:ridemate/core/widgets/rm_icon_button.dart';
import 'package:ridemate/core/widgets/rm_list_row.dart';
import 'package:ridemate/core/widgets/rm_meters.dart';

import '../../support/pump.dart';

void main() {
  group('RmButton', () {
    testBothThemes('renders and fires in both themes', (
      WidgetTester tester,
      Brightness brightness,
    ) async {
      int taps = 0;
      await tester.pumpRm(
        RmButton(label: 'Rotayı yayınla', onPressed: () => taps++),
        brightness: brightness,
      );

      expect(find.text('Rotayı yayınla'), findsOneWidget);
      await tester.tap(find.byType(RmButton));
      expect(taps, 1);
    });

    testWidgets('a null callback disables it', (WidgetTester tester) async {
      await tester.pumpRm(const RmButton(label: 'Devam'));

      await tester.tap(find.byType(RmButton));
      await tester.pump();
      expect(tester.takeException(), isNull);

      final Semantics s = tester.widget(
        find
            .descendant(
              of: find.byType(RmButton),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(s.properties.enabled, isFalse);
    });

    testWidgets('loading blocks taps and keeps the height stable', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpRm(RmButton(label: 'Gönder', onPressed: () => taps++));
      final double idleHeight = tester.getSize(find.byType(RmButton)).height;

      await tester.pumpRm(
        RmButton(label: 'Gönder', loading: true, onPressed: () => taps++),
      );
      await tester.pump();

      await tester.tap(find.byType(RmButton));
      expect(taps, 0, reason: 'a loading button must not fire again');
      expect(
        tester.getSize(find.byType(RmButton)).height,
        idleHeight,
        reason: 'the layout must not jump under the user finger',
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('every size meets the touch floor', (
      WidgetTester tester,
    ) async {
      for (final RmButtonSize size in RmButtonSize.values) {
        await tester.pumpRm(
          RmButton(label: 'A', size: size, fullWidth: false, onPressed: () {}),
        );
        expect(
          tester.getSize(find.byType(RmButton)).height,
          greaterThanOrEqualTo(RmA11y.minTouchTarget),
          reason: '$size is not tappable enough',
        );
      }
    });

    testWidgets('exposes a button semantic with its label', (
      WidgetTester tester,
    ) async {
      await tester.pumpRm(RmButton(label: 'İstek gönder', onPressed: () {}));
      expect(find.bySemanticsLabel('İstek gönder'), findsOneWidget);
    });
  });

  group('RmIconButton', () {
    testWidgets('requires and exposes a label, since it has no text', (
      WidgetTester tester,
    ) async {
      await tester.pumpRm(
        RmIconButton(
          icon: RmIcons.phone,
          semanticLabel: '112’yi ara',
          onPressed: () {},
        ),
      );
      expect(find.bySemanticsLabel('112’yi ara'), findsOneWidget);
    });

    testWidgets('meets the touch floor at every size', (
      WidgetTester tester,
    ) async {
      for (final RmIconButtonSize size in RmIconButtonSize.values) {
        await tester.pumpRm(
          RmIconButton(
            icon: RmIcons.clock,
            semanticLabel: 'x',
            size: size,
            onPressed: () {},
          ),
        );
        final Size box = tester.getSize(find.byType(RmIconButton));
        expect(box.width, greaterThanOrEqualTo(RmA11y.minTouchTarget));
        expect(box.height, greaterThanOrEqualTo(RmA11y.minTouchTarget));
      }
    });
  });

  group('RmFab', () {
    testWidgets('is the clamped 60dp size', (WidgetTester tester) async {
      await tester.pumpRm(
        RmFab(
          icon: RmIcons.plus,
          semanticLabel: 'Rota oluştur',
          onPressed: () {},
        ),
      );
      expect(
        tester.getSize(find.byType(RmFab)),
        const Size(RmSizing.fab, RmSizing.fab),
      );
    });
  });

  group('RmChip', () {
    testWidgets('keeps its size when toggled (deviation R4)', (
      WidgetTester tester,
    ) async {
      // The source drops the border on a selected chip, which would resize it
      // on every tap. Both states must measure the same here.
      await tester.pumpRm(const RmChip(label: 'Sadece doğrulanmış'));
      final Size unselected = tester.getSize(find.byType(RmChip));

      await tester.pumpRm(
        const RmChip(label: 'Sadece doğrulanmış', selected: true),
      );
      expect(tester.getSize(find.byType(RmChip)), unselected);
    });

    testWidgets('preserves the two distinct selected fills', (
      WidgetTester tester,
    ) async {
      // Attribute chips select brand blue; sort chips select ink navy.
      await tester.pumpRm(const RmChip(label: 'A', selected: true));
      final Container attribute = tester.widget(
        find
            .descendant(
              of: find.byType(RmChip),
              matching: find.byType(Container),
            )
            .first,
      );

      await tester.pumpRm(
        const RmChip(label: 'A', selected: true, tone: RmChipTone.ink),
      );
      final Container sort = tester.widget(
        find
            .descendant(
              of: find.byType(RmChip),
              matching: find.byType(Container),
            )
            .first,
      );

      final Color attributeFill =
          (attribute.decoration! as BoxDecoration).color!;
      final Color sortFill = (sort.decoration! as BoxDecoration).color!;
      expect(attributeFill, RmColors.light.primary);
      expect(sortFill, RmColors.light.ink);
      expect(attributeFill, isNot(sortFill));
    });

    testWidgets('reports selection to assistive technology', (
      WidgetTester tester,
    ) async {
      await tester.pumpRm(
        RmChip(label: 'Kadın sürücü', selected: true, onTap: () {}),
      );
      final Semantics s = tester.widget(
        find
            .descendant(
              of: find.byType(RmChip),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(s.properties.selected, isTrue);
    });
  });

  group('RmAvatar — trust signals stay separable', () {
    testWidgets('shows a verified badge only when verified', (
      WidgetTester tester,
    ) async {
      await tester.pumpRm(const RmAvatar(initials: 'SK'));
      expect(find.byType(RmVerifiedBadge), findsNothing);

      await tester.pumpRm(
        const RmAvatar(initials: 'SK', verification: RmVerification.verified),
      );
      expect(find.byType(RmVerifiedBadge), findsOneWidget);
    });

    testWidgets('presence alone never renders a verification badge', (
      WidgetTester tester,
    ) async {
      // The hazard this guards: a presence dot must never be mistakable in
      // code for a verification claim.
      await tester.pumpRm(
        const RmAvatar(initials: 'SK', presence: RmPresence.online),
      );
      expect(find.byType(RmVerifiedBadge), findsNothing);
    });

    testWidgets('verification outranks presence when both are set', (
      WidgetTester tester,
    ) async {
      await tester.pumpRm(
        const RmAvatar(
          initials: 'SK',
          verification: RmVerification.verified,
          presence: RmPresence.online,
        ),
      );
      expect(find.byType(RmVerifiedBadge), findsOneWidget);
    });

    testWidgets('geometry follows the measured design ratios', (
      WidgetTester tester,
    ) async {
      await tester.pumpRm(
        const RmAvatar(initials: 'SK', size: RmAvatarSize.xxl),
      );
      expect(
        tester.getSize(find.byType(RmAvatar)).width,
        greaterThanOrEqualTo(RmAvatarSize.xxl),
      );
    });
  });

  group('RmTrustRing', () {
    testWidgets('clamps out-of-range progress rather than overdrawing', (
      WidgetTester tester,
    ) async {
      for (final double p in <double>[-1, 0, 0.6, 0.92, 1, 5]) {
        await tester.pumpRm(RmTrustRing(progress: p, semanticLabel: 'Güven'));
        expect(tester.takeException(), isNull, reason: 'progress $p');
      }
    });

    testWidgets('reports its value to assistive technology', (
      WidgetTester tester,
    ) async {
      await tester.pumpRm(
        const RmTrustRing(progress: 0.92, semanticLabel: 'Güven Puanı'),
      );
      expect(find.bySemanticsLabel('Güven Puanı'), findsOneWidget);
    });
  });

  group('RmLinearMeter', () {
    testWidgets('a zero value renders a bare track', (
      WidgetTester tester,
    ) async {
      // Matches the source's empty histogram row, which has no fill child.
      await tester.pumpRm(const RmLinearMeter(progress: 0));
      expect(find.byType(FractionallySizedBox), findsNothing);

      await tester.pumpRm(const RmLinearMeter(progress: 0.94));
      expect(find.byType(FractionallySizedBox), findsOneWidget);
    });
  });

  group('RmCard', () {
    testBothThemes('renders every variant', (
      WidgetTester tester,
      Brightness brightness,
    ) async {
      for (final RmCardVariant v in RmCardVariant.values) {
        await tester.pumpRm(
          RmCard(variant: v, child: const Text('x')),
          brightness: brightness,
        );
        expect(tester.takeException(), isNull, reason: '$v in $brightness');
      }
    });

    testWidgets('becomes a button and grows to the touch floor when tappable', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpRm(
        RmCard(
          onTap: () => taps++,
          padding: EdgeInsets.zero,
          // Deliberately shorter than the touch floor: the card must grow.
          child: const SizedBox(width: 200, height: 8),
        ),
      );

      expect(
        tester.getSize(find.byType(RmCard)).height,
        greaterThanOrEqualTo(RmA11y.minTouchTarget),
      );
      await tester.tap(find.byType(RmCard));
      expect(taps, 1);
    });

    testWidgets('a label replaces its children whether or not it is tappable', (
      WidgetTester tester,
    ) async {
      // The untapped branch used to label the node without excluding its
      // children, so the two merged and every labelled non-tappable card
      // announced its own contents a second time.
      for (final VoidCallback? onTap in <VoidCallback?>[null, () {}]) {
        await tester.pumpRm(
          RmCard(
            onTap: onTap,
            semanticLabel: 'Tek cümle',
            child: const Text('Görsel metin'),
          ),
        );

        final SemanticsNode node = tester.getSemantics(find.byType(RmCard));
        expect(
          node.label,
          'Tek cümle',
          reason: 'onTap == null ? ${onTap == null}',
        );
      }
    });
  });

  group('RmListRow', () {
    testWidgets('shows a chevron only when it navigates', (
      WidgetTester tester,
    ) async {
      await tester.pumpRm(
        const RmListRow(title: 'Güvenilir kişiler', icon: RmIcons.person),
      );
      expect(find.byType(RmIcon), findsOneWidget, reason: 'leading only');

      await tester.pumpRm(
        RmListRow(
          title: 'Güvenilir kişiler',
          icon: RmIcons.person,
          onTap: () {},
        ),
      );
      expect(
        find.byType(RmIcon),
        findsNWidgets(2),
        reason: 'leading + chevron',
      );
    });

    testWidgets('combines title and subtitle for screen readers', (
      WidgetTester tester,
    ) async {
      await tester.pumpRm(
        RmListRow(
          title: 'Güvenilir kişiler',
          subtitle: '2 kişi eklendi',
          onTap: () {},
        ),
      );
      expect(
        find.bySemanticsLabel('Güvenilir kişiler. 2 kişi eklendi'),
        findsOneWidget,
      );
    });

    testWidgets('drops a trailing badge from the default announcement', (
      WidgetTester tester,
    ) async {
      // Guards the reason semanticLabel exists. RmBadge emits no semantics, so
      // a row that carries meaning in its trailing widget announces nothing
      // about it unless the caller says so.
      await tester.pumpRm(
        const RmListRow(
          title: 'Doğrulama rozetleri',
          trailing: RmBadge(label: '4 / 5', tone: RmBadgeTone.success),
        ),
      );

      expect(find.text('4 / 5'), findsOneWidget, reason: 'drawn');
      expect(
        find.bySemanticsLabel(RegExp('4')),
        findsNothing,
        reason: 'but not announced',
      );
    });

    testWidgets('announces the override instead when one is given', (
      WidgetTester tester,
    ) async {
      await tester.pumpRm(
        const RmListRow(
          title: 'Doğrulama rozetleri',
          trailing: RmBadge(label: '4 / 5', tone: RmBadgeTone.success),
          semanticLabel: 'Doğrulama rozetleri: 5 adımdan 4 tanesi tamamlandı',
        ),
      );

      expect(
        find.bySemanticsLabel(
          'Doğrulama rozetleri: 5 adımdan 4 tanesi tamamlandı',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Doğrulama rozetleri'),
        findsNothing,
        reason:
            'the override replaces the composed label, it does not add to it',
      );
    });
  });

  group('RTL safety', () {
    testWidgets('the component set lays out under RTL without overflow', (
      WidgetTester tester,
    ) async {
      await tester.pumpRm(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            RmButton(label: 'Gönder', icon: RmIcons.send, onPressed: () {}),
            const RmChip(label: 'Sadece doğrulanmış', selected: true),
            const RmAvatar(
              initials: 'SK',
              verification: RmVerification.verified,
            ),
            RmListRow(title: 'Profil', icon: RmIcons.person, onTap: () {}),
            const RmInlineMessage(message: 'Ödemeyi uygulama içinden yapın.'),
          ],
        ),
        textDirection: TextDirection.rtl,
        surfaceSize: const Size(393, 900),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
