// ─────────────────────────────────────────────────────────────
// RideMate — Chat thread
//
// Source: docs/claude-designs/RideMate App.dc.html, "CHAT" (immutable).
//
// The conversation, in visual order. Deliberately NOT `reverse: true`: that is
// the usual chat idiom, but it inverts semantic traversal so a screen reader
// meets the newest message first. With five authored entries there is nothing
// to gain from it and a reading order to lose.
//
// There is no LiveRegion anywhere — nothing arrives.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_radius.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/chat_entry.dart';
import '../../domain/chat_fixtures.dart';
import 'chat_bubble.dart';
import 'chat_location_card.dart';

/// The scrollable conversation.
class ChatThread extends StatelessWidget {
  const ChatThread({required this.entries, super.key});

  final List<ChatEntry> entries;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    /// How assistive technology names the writer of [author].
    String speakerOf(ChatAuthor author) => switch (author) {
      ChatAuthor.member => l10n.chatSpeakerSelf,
      ChatAuthor.participant => MockChatParticipant.name,
    };

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: RmSpacing.screenGutter,
        vertical: RmSpacing.lg,
      ),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: RmSpacing.md),
      itemBuilder: (BuildContext context, int index) =>
          switch (entries[index]) {
            ChatDayDivider() => const _DayDivider(),
            final ChatTextMessage m => ChatBubble(
              author: m.author,
              text: m.text,
              speaker: speakerOf(m.author),
            ),
            final ChatLocationMessage m => ChatLocationCard(
              author: m.author,
              label: m.label,
              speaker: speakerOf(m.author),
            ),
          },
    );
  }
}

/// The single date separator the design draws.
///
/// Its own node, so it neither merges into the message below it nor is skipped.
class _DayDivider extends StatelessWidget {
  const _DayDivider();

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Center(
      child: Semantics(
        container: true,
        header: true,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: RmSpacing.md,
            vertical: RmSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: c.surfaceMuted,
            borderRadius: RmRadius.brXs,
          ),
          child: Text(
            l10n.dateToday,
            style: RmTypography.micro.copyWith(color: c.faint),
          ),
        ),
      ),
    );
  }
}
