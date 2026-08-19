// ─────────────────────────────────────────────────────────────
// RideMate — Quick replies
//
// Source: docs/claude-designs/RideMate App.dc.html, "CHAT" (immutable).
//
// Tapping one INSERTS its text into the composer. It does not send, because
// nothing sends. A local text shortcut claims nothing.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/widgets/rm_chip.dart';
import '../../../../l10n/app_localizations.dart';

/// The two ready-made replies the design offers.
class ChatQuickReplies extends StatelessWidget {
  const ChatQuickReplies({required this.onSelected, super.key});

  /// Receives the reply's text, to place in the composer.
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Wrap(
      spacing: RmSpacing.sm,
      runSpacing: RmSpacing.sm,
      children: <Widget>[
        for (final String reply in <String>[
          l10n.chatQuickReplyOnMyWay,
          l10n.chatQuickReplyRunningLate,
        ])
          RmChip(
            label: reply,
            tone: RmChipTone.info,
            compact: true,
            onTap: () => onSelected(reply),
          ),
      ],
    );
  }
}
