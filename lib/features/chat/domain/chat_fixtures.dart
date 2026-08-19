// ─────────────────────────────────────────────────────────────
// RideMate — Chat fixtures
//
// PRESENTATION FIXTURES. NOT A CONVERSATION.
//
// The exchange the design draws, reproduced so the screen can be seen and
// reviewed. Nobody sent these messages and nobody received them.
//
// This is a FUNCTION of the localizations rather than a const list, because
// the content is prose: baking Turkish sentences into Dart would render them
// to an English-locale member. Place fragments may live in Dart; sentences
// live in the ARB. That is the same rule the rest of the app follows.
// ─────────────────────────────────────────────────────────────

import '../../../core/widgets/rm_avatar.dart';
import '../../../l10n/app_localizations.dart';
import 'chat_entry.dart';

/// The other person in the conversation, as the design's header draws them.
///
/// Presence and verification are BOTH shown, in different places — the dot sits
/// on the avatar, the check beside the name — and they stay separate types
/// because they are separate claims. `RmAvatar` drops presence when
/// verification is also passed to it, which is exactly why the check is
/// rendered as its own badge rather than through the avatar.
abstract final class MockChatParticipant {
  const MockChatParticipant._();

  static const String name = 'Selin K.';
  static const String initials = 'SK';
  static const RmIdentity identity = RmIdentity.amber;
  static const RmVerification verification = RmVerification.verified;
  static const RmPresence presence = RmPresence.online;
}

/// The conversation the design draws, in reading order.
List<ChatEntry> mockConversation(AppLocalizations l10n) => <ChatEntry>[
  const ChatDayDivider(),
  ChatTextMessage(
    author: ChatAuthor.participant,
    text: l10n.chatMessageIncoming,
  ),
  ChatTextMessage(author: ChatAuthor.member, text: l10n.chatMessageOutgoing),
  ChatLocationMessage(
    author: ChatAuthor.participant,
    label: l10n.chatLocationLabel,
  ),
  ChatTextMessage(
    author: ChatAuthor.member,
    text: l10n.chatMessageOutgoingClosing,
  ),
];
