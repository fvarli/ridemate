// ─────────────────────────────────────────────────────────────
// RideMate — Chat entries
//
// PRESENTATION DATA ONLY. THERE IS NO MESSAGING.
//
// No backend, no socket, no push, no delivery, no read state, no typing
// indicator, no unread count, no retry queue and no offline send. Nothing here
// travels anywhere.
//
// So this model carries ONLY what the approved design draws. Deliberately
// absent, and not to be added because a future backend might want them:
// serverId, deliveryStatus, deliveredAt, readAt, isRead, retryCount,
// remoteUserId, socketSequence, syncState.
//
// The design draws no timestamps on any bubble, so none are manufactured — and
// there is no groupByDay() helper either, which would have to invent the very
// timestamps the design left out. The single "Bugün" divider is authored
// content, exactly like the messages around it.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

/// Who wrote an entry.
enum ChatAuthor {
  /// The member using the app.
  member,

  /// The other person in the conversation.
  participant,
}

/// One item in the conversation, in reading order.
@immutable
sealed class ChatEntry {
  const ChatEntry();
}

/// The date separator the design draws once, above the first message.
@immutable
final class ChatDayDivider extends ChatEntry {
  const ChatDayDivider();
}

/// A text message.
@immutable
final class ChatTextMessage extends ChatEntry {
  const ChatTextMessage({required this.author, required this.text});

  final ChatAuthor author;
  final String text;
}

/// A shared meeting point: a small map picture and a label.
///
/// It is a picture. There are no coordinates behind it, it opens nothing, and
/// it is not a button.
@immutable
final class ChatLocationMessage extends ChatEntry {
  const ChatLocationMessage({required this.author, required this.label});

  final ChatAuthor author;
  final String label;
}
