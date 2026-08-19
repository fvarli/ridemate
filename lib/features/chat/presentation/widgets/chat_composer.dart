// ─────────────────────────────────────────────────────────────
// RideMate — Chat composer
//
// Source: docs/claude-designs/RideMate App.dc.html, "CHAT" (immutable).
//
// SEND DOES NOT SEND. That is the whole contract of this widget.
//
// Tapping send shows one message saying the text was not sent, and then:
// appends no bubble, creates no ChatEntry, clears nothing, navigates nowhere,
// and produces no delivered, read, pending, failed or retrying state. There is
// no message entity, no client-generated id and no lifecycle — inventing any of
// them would build the messaging domain this phase must not build.
//
// DEVIATION D-chat-1: the comp draws a styled pill with a placeholder span, not
// an <input> — there is not one in all fifteen screens. Home's search field has
// the same shape and is deliberately NOT a text input, because tapping it opens
// a picker, so a static summary is the honest rendering there. Here the
// placeholder says "Mesaj yaz…" beside a send button, so a pill that cannot be
// typed into would be the more dishonest of the two options. A real TextField
// it is.
//
// It stays feature-local. One composer with a leading action, no label, no
// helper, no error and an embedded send button is not a generic form field, and
// promoting it would mean inventing five states with no design reference. A
// generic RmTextField is earned when a second, genuinely generic input appears.
//
// DEVIATION D-trip-2 (same class): the leading "+" has no defined behaviour
// anywhere in the design, so it is drawn and left inert rather than given an
// invented purpose — not attachments, not camera, not location sending.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/icons/rm_icons.dart';
import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_radius.dart';
import '../../../../core/theme/tokens/rm_sizing.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_icon.dart';
import '../../../../core/widgets/rm_icon_button.dart';
import '../../../../l10n/app_localizations.dart';

/// The message field and its send button.
class ChatComposer extends StatelessWidget {
  const ChatComposer({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  /// Called on send. It must not append anything — see the file header.
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RmSpacing.md,
        vertical: RmSpacing.md,
      ),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: RmRadius.brLg,
      ),
      child: Row(
        children: <Widget>[
          // Inert by design: see D-trip-2 in the file header.
          ExcludeSemantics(
            child: RmIcon(
              RmIcons.plusThin,
              size: RmIconSize.md,
              color: c.faint,
            ),
          ),
          const SizedBox(width: RmSpacing.md),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: RmTypography.bodyRegular.copyWith(color: c.ink),
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: l10n.chatComposerHint,
                hintStyle: RmTypography.bodyRegular.copyWith(color: c.faint),
                // A hint disappears on focus, so it cannot be the accessible
                // name. This one persists.
                labelText: null,
              ),
            ),
          ),
          const SizedBox(width: RmSpacing.md),
          RmIconButton(
            icon: RmIcons.send,
            semanticLabel: l10n.chatSend,
            variant: RmIconButtonVariant.filled,
            // Never disabled: the design has no disabled button anywhere, and
            // gating send would author a validation rule that does not exist.
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}
