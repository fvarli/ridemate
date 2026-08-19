// ─────────────────────────────────────────────────────────────
// RideMate — Chat screen
//
// Both themes, both locales, RTL, 360dp and 393dp, and the maximum text scale.
//
// The assertion that matters most is what send does NOT do: it must not grow
// the conversation, clear the field or claim anything travelled.
//
// PUMP NOTE: nothing on this screen animates indefinitely, but the harness is
// kept consistent with Active Trip's.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/a11y/rm_a11y.dart';
import 'package:ridemate/core/widgets/rm_avatar.dart';
import 'package:ridemate/core/widgets/rm_chip.dart';
import 'package:ridemate/core/widgets/rm_icon_button.dart';
import 'package:ridemate/features/chat/presentation/chat_screen.dart';
import 'package:ridemate/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:ridemate/features/chat/presentation/widgets/chat_location_card.dart';

import '../../support/fonts.dart';
import '../../support/pump.dart';

const Size kNarrowPhone = Size(360, 800);
const Size kStandardPhone = Size(393, 852);

void main() {
  setUpAll(loadRideMateFonts);

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    TextDirection textDirection = TextDirection.ltr,
    Locale locale = kDefaultTestLocale,
    Size size = kStandardPhone,
    double textScale = 1,
  }) async {
    await tester.pumpRmScreen(
      const ChatScreen(),
      brightness: brightness,
      textDirection: textDirection,
      locale: locale,
      surfaceSize: size,
      textScaler: TextScaler.linear(textScale),
    );
    await tester.pump();
  }

  group('ChatScreen', () {
    testBothThemes('renders the approved conversation', (
      WidgetTester tester,
      Brightness brightness,
    ) async {
      await pump(tester, brightness: brightness);

      expect(tester.takeException(), isNull);
      expect(find.text('Selin K.'), findsOneWidget);
      expect(find.text('Çevrimiçi'), findsOneWidget);
      expect(find.text('Bugün'), findsOneWidget);
      expect(find.byType(ChatBubble), findsNWidgets(3));
      expect(find.byType(ChatLocationCard), findsOneWidget);
      expect(find.text('Yoldayım'), findsOneWidget);
      expect(find.text('5 dk geç'), findsOneWidget);
      expect(find.text('Mesaj yaz…'), findsOneWidget);
    });

    testWidgets('shows no delivery, read or typing state', (
      WidgetTester tester,
    ) async {
      // The design draws none of these, so none is invented.
      await pump(tester);

      for (final String absent in <String>[
        'İletildi',
        'Okundu',
        'Gönderiliyor',
        'yazıyor',
      ]) {
        expect(find.textContaining(absent), findsNothing, reason: absent);
      }
      // Bubbles carry no timestamp either — asserted structurally in
      // chat_domain_test.dart, since the message copy itself mentions a time.
    });

    testWidgets('the safety banner does not claim in-app payments exist', (
      WidgetTester tester,
    ) async {
      // The approved copy says to pay inside the app. There is no payment
      // feature, and this screen is release-reachable, so the shipped wording
      // keeps the safety advice without the false capability claim.
      await pump(tester);

      expect(
        find.textContaining('Ödeme özelliği henüz aktif değil'),
        findsOneWidget,
      );
      expect(
        find.textContaining('uygulama içinden yapın'),
        findsNothing,
        reason: 'RideMate has no payments; the banner must not imply it does',
      );
      expect(find.textContaining('paylaşmayın'), findsOneWidget);
    });
  });

  group('Presence and verification are announced separately', () {
    testWidgets('the header names both, once each', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      expect(
        find.bySemanticsLabel('Selin K., kimliği doğrulanmış, çevrimiçi'),
        findsOneWidget,
      );
    });

    testWidgets('the avatar carries presence, never verification', (
      WidgetTester tester,
    ) async {
      // RmAvatar drops presence when verification is also set, so the check has
      // to be a separate badge — which is also how the design draws it.
      await pump(tester);

      final RmAvatar avatar = tester.widget<RmAvatar>(
        find.descendant(
          of: find.byType(ChatScreen),
          matching: find.byType(RmAvatar),
        ),
      );
      expect(avatar.presence, RmPresence.online);
      expect(avatar.verification, RmVerification.none);
      expect(find.byType(RmVerifiedBadge), findsOneWidget);
    });
  });

  group('Bubbles name their speaker', () {
    testWidgets('authorship is in the label, not just the alignment', (
      WidgetTester tester,
    ) async {
      // Alignment and colour are the only visual cues, and neither reaches a
      // screen-reader user.
      await pump(tester);

      expect(
        find.bySemanticsLabel(RegExp(r'^Selin K\.: Merhaba Elif!')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^Sen: Harika, teşekkürler!')),
        findsOneWidget,
      );
    });

    testWidgets('the location card is content, not a button', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      final SemanticsNode node = tester.getSemantics(
        find.bySemanticsLabel(RegExp('Selin K. konum paylaştı')),
      );
      expect(node.flagsCollection.isButton, isFalse);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
    });

    testWidgets('emoji are split into their own runs, not left to Manrope', (
      WidgetTester tester,
    ) async {
      // Asserting the split rather than the pixels: emoji rasterize differently
      // on every platform, so their glyphs are not a product contract.
      final List<(String, bool)> runs = splitEmojiRuns('Görüşürüz 🙌');
      expect(runs, hasLength(2));
      expect(runs.first, ('Görüşürüz ', false));
      expect(runs.last, ('🙌', true));
      expect(splitEmojiRuns('Sadece metin'), <(String, bool)>[
        ('Sadece metin', false),
      ]);
    });
  });

  group('Sending sends nothing', () {
    testWidgets('says so, keeps the text and grows no conversation', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      final int before = tester.widgetList(find.byType(ChatBubble)).length;

      await tester.enterText(find.byType(TextField), 'Yarın görüşürüz');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Gönder'));
      await tester.pump();

      expect(
        find.text('Mesaj gönderilmedi. Mesajlaşma özelliği henüz eklenmedi.'),
        findsOneWidget,
      );
      // Nothing was appended.
      expect(tester.widgetList(find.byType(ChatBubble)).length, before);
      // And the text is still there — clearing it would look like success.
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Yarın görüşürüz',
      );
      expect(find.byType(ChatScreen), findsOneWidget);
    });

    testWidgets('the send button is never disabled', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      // The design has no disabled button anywhere; gating send would author a
      // validation rule that does not exist.
      final RmIconButton send = tester.widget<RmIconButton>(
        find.ancestor(
          of: find.bySemanticsLabel('Gönder'),
          matching: find.byType(RmIconButton),
        ),
      );
      expect(send.onPressed, isNotNull);

      // Still enabled with the field empty.
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Gönder'));
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('a quick reply lands in the field rather than sending', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      final int before = tester.widgetList(find.byType(ChatBubble)).length;

      await tester.tap(find.text('Yoldayım'));
      await tester.pump();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Yoldayım',
      );
      expect(tester.widgetList(find.byType(ChatBubble)).length, before);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('the quick replies are never selected chips', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      final Iterable<RmChip> chips = tester.widgetList<RmChip>(
        find.byType(RmChip),
      );
      expect(chips, hasLength(2));
      expect(chips.every((RmChip c) => c.tone == RmChipTone.info), isTrue);
    });
  });

  group('Responsiveness', () {
    testWidgets('renders in English, RTL and at the narrow width', (
      WidgetTester tester,
    ) async {
      await pump(tester, textDirection: TextDirection.rtl);
      expect(tester.takeException(), isNull, reason: 'TR RTL');

      await pump(tester, size: kNarrowPhone);
      expect(tester.takeException(), isNull, reason: 'TR at 360dp');

      await pump(tester, locale: const Locale('en'));
      expect(tester.takeException(), isNull, reason: 'EN');
      expect(find.text('Online'), findsOneWidget);
      expect(find.text('Write a message…'), findsOneWidget);
      expect(
        find.textContaining('Payments are not available yet'),
        findsOneWidget,
      );

      await pump(tester, locale: const Locale('en'), size: kNarrowPhone);
      expect(tester.takeException(), isNull, reason: 'EN at 360dp');
    });

    testWidgets('survives the maximum text scale at the narrow width', (
      WidgetTester tester,
    ) async {
      await pump(tester, size: kNarrowPhone, textScale: RmA11y.maxTextScale);

      expect(tester.takeException(), isNull);
      expect(find.byType(ChatBubble), findsWidgets);
    });
  });
}
