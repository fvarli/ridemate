// ─────────────────────────────────────────────────────────────
// RideMate — Chat domain
//
// The shape of the conversation, and the fields it deliberately does not have.
// ─────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/widgets/rm_avatar.dart';
import 'package:ridemate/features/chat/domain/chat_entry.dart';
import 'package:ridemate/features/chat/domain/chat_fixtures.dart';
import 'package:ridemate/l10n/app_localizations.dart';
import 'package:ridemate/l10n/app_localizations_en.dart';
import 'package:ridemate/l10n/app_localizations_tr.dart';

/// The code in [file], with comments removed.
///
/// Every banned name below is also *written down* in a header explaining why it
/// is banned, so a raw text scan would match the prohibition itself.
String codeOf(File file) => file
    .readAsLinesSync()
    .map((String line) {
      final int slash = line.indexOf('//');
      return slash == -1 ? line : line.substring(0, slash);
    })
    .join('\n');

void main() {
  final AppLocalizations tr = AppLocalizationsTr();
  final AppLocalizations en = AppLocalizationsEn();

  group('The conversation reproduces the design', () {
    test('has the entries the design draws, in order', () {
      final List<ChatEntry> entries = mockConversation(tr);

      expect(entries, hasLength(5));
      expect(entries[0], isA<ChatDayDivider>());
      expect(entries[1], isA<ChatTextMessage>());
      expect(entries[2], isA<ChatTextMessage>());
      expect(entries[3], isA<ChatLocationMessage>());
      expect(entries[4], isA<ChatTextMessage>());
    });

    test('alternates the two speakers as drawn', () {
      final List<ChatEntry> entries = mockConversation(tr);
      ChatAuthor authorOf(int i) => switch (entries[i]) {
        final ChatTextMessage m => m.author,
        final ChatLocationMessage m => m.author,
        ChatDayDivider() => fail('the divider has no author'),
      };

      expect(authorOf(1), ChatAuthor.participant);
      expect(authorOf(2), ChatAuthor.member);
      expect(authorOf(3), ChatAuthor.participant);
      expect(authorOf(4), ChatAuthor.member);
    });

    test('is localized, not baked into Dart', () {
      // Turkish sentences hard-coded in the model would be shown to an English
      // member. The thread is a function of the localizations for that reason.
      final ChatTextMessage turkish =
          mockConversation(tr)[1] as ChatTextMessage;
      final ChatTextMessage english =
          mockConversation(en)[1] as ChatTextMessage;

      expect(turkish.text, isNot(english.text));
      expect(turkish.text, contains('Kadıköy'));
      expect(english.text, contains('Kadıköy'));
    });
  });

  group('Presence and verification stay separate', () {
    test('the participant carries both, as distinct types', () {
      // The design's header shows a presence dot on the avatar AND a verified
      // check beside the name. They are different claims about different
      // things, so they are different types and neither can stand in for the
      // other.
      expect(MockChatParticipant.presence, RmPresence.online);
      expect(MockChatParticipant.verification, RmVerification.verified);
      expect(MockChatParticipant.presence, isA<RmPresence>());
      expect(MockChatParticipant.verification, isA<RmVerification>());
    });

    test('each has an independent "absent" value', () {
      // Presence can exist without verification and vice versa: neither enum
      // has a member that implies anything about the other.
      expect(RmPresence.values, <RmPresence>[
        RmPresence.none,
        RmPresence.online,
      ]);
      expect(RmVerification.values, <RmVerification>[
        RmVerification.none,
        RmVerification.verified,
      ]);
    });
  });

  group('No messaging domain is invented', () {
    test('ChatEntry carries only what the design draws', () {
      // A field added "for the backend" is how a delivery model sneaks in.
      final String source = codeOf(
        File('lib/features/chat/domain/chat_entry.dart'),
      );

      for (final String banned in <String>[
        'serverId',
        'deliveryStatus',
        'deliveredAt',
        'readAt',
        'isRead',
        'retryCount',
        'remoteUserId',
        'socketSequence',
        'syncState',
        'MessageStatus',
        'timestamp',
        'sentAt',
      ]) {
        expect(
          source.contains(banned),
          isFalse,
          reason: 'chat_entry.dart must not declare $banned',
        );
      }
    });

    test('no messaging or realtime infrastructure exists anywhere', () {
      final List<String> offenders = <String>[];
      for (final FileSystemEntity e in Directory(
        'lib',
      ).listSync(recursive: true)) {
        if (e is! File || !e.path.endsWith('.dart')) continue;
        if (e.path.contains('app_localizations')) continue;
        final String source = codeOf(e);
        for (final String banned in <String>[
          'ChatRepository',
          'MessagingService',
          'TripService',
          'TrackingService',
          'LocationService',
          'RealtimeService',
          'PresenceService',
          'MapService',
          'MapProvider',
          'EtaCalculator',
          'RouteProgressCalculator',
          'calculateEta',
          'calculateProgress',
          'calculateRemainingDistance',
          'updateVehiclePosition',
          'derivePresence',
          'trackingTimer',
          'acceptedTrip',
          'tripStarted',
          'activeBooking',
          'currentRide',
          'sosTriggered',
          'emergencyActive',
          'StreamProvider',
        ]) {
          if (source.contains(banned)) offenders.add('${e.path}: $banned');
        }
      }
      expect(offenders, isEmpty);
    });
  });
}
