// ─────────────────────────────────────────────────────────────
// RideMate — Chat bubbles
//
// Source: docs/claude-designs/RideMate App.dc.html, "CHAT" (immutable).
//
// Incoming bubbles sit at the start with a tight top-start corner; outgoing sit
// at the end with a tight top-end corner. Both use BorderRadiusDirectional so
// the tight corner follows the reading direction rather than staying pinned to
// the left in RTL.
//
// Authorship is otherwise invisible — it is carried by alignment and colour
// alone, which tells a screen-reader user nothing and a low-vision user very
// little. Each bubble therefore announces "{speaker}: {text}".
//
// EMOJI: the message copy contains 👍 and 🙌, which are in neither bundled
// font. They are approved content and stay, but they are rendered in their own
// span with the platform emoji families as a fallback, rather than smuggled
// through Manrope and left to whatever the engine happens to pick. The
// sentences read correctly without them — they are tone, never meaning.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_radius.dart';
import '../../../../core/theme/tokens/rm_sizing.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/chat_entry.dart';

/// Font families to fall back to for glyphs the product fonts do not carry.
///
/// Only emoji runs get these. Naming them explicitly is the difference between
/// "this text may use the platform emoji font" and "we forgot this glyph is
/// missing" — the second is what put tofu on screen in an earlier phase.
const List<String> kEmojiFallback = <String>[
  'Noto Color Emoji',
  'Apple Color Emoji',
  'Segoe UI Emoji',
];

/// Splits [text] into runs so emoji can be styled separately from prose.
///
/// Public so tests can assert the split rather than the rasterised pixels.
List<(String text, bool isEmoji)> splitEmojiRuns(String text) {
  final List<(String, bool)> runs = <(String, bool)>[];
  final StringBuffer buffer = StringBuffer();
  bool? mode;

  void flush() {
    if (buffer.isEmpty) return;
    runs.add((buffer.toString(), mode!));
    buffer.clear();
  }

  for (final int rune in text.runes) {
    final bool emoji = _isEmoji(rune);
    if (mode != null && emoji != mode) flush();
    mode = emoji;
    buffer.writeCharCode(rune);
  }
  flush();
  return runs;
}

/// Whether [rune] belongs to a block the product fonts do not cover.
bool _isEmoji(int rune) =>
    (rune >= 0x1F300 && rune <= 0x1FAFF) ||
    (rune >= 0x2600 && rune <= 0x27BF) ||
    rune == 0xFE0F ||
    (rune >= 0x1F1E6 && rune <= 0x1F1FF);

/// One text message.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    required this.author,
    required this.text,
    required this.speaker,
    super.key,
  });

  final ChatAuthor author;
  final String text;

  /// How the speaker is named to assistive technology.
  final String speaker;

  bool get _outgoing => author == ChatAuthor.member;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);

    final TextStyle base = RmTypography.bodyRegular.copyWith(
      color: _outgoing ? c.onPrimary : c.ink,
    );

    return Align(
      alignment: _outgoing
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Semantics(
        container: true,
        label: l10n.chatBubbleSemanticLabel(speaker, text),
        excludeSemantics: true,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * _maxWidthFraction,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: RmSpacing.lg,
              vertical: RmSpacing.md,
            ),
            decoration: BoxDecoration(
              color: _outgoing ? c.primary : c.surface,
              border: _outgoing
                  ? null
                  : Border.all(color: c.hairline, width: RmSizing.borderWidth),
              // Directional, so the tight corner follows the reading axis.
              borderRadius: BorderRadiusDirectional.only(
                topStart: Radius.circular(
                  _outgoing ? RmRadius.md : RmRadius.xs,
                ),
                topEnd: Radius.circular(_outgoing ? RmRadius.xs : RmRadius.md),
                bottomStart: const Radius.circular(RmRadius.md),
                bottomEnd: const Radius.circular(RmRadius.md),
              ),
            ),
            child: Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  for (final (String run, bool isEmoji) in splitEmojiRuns(text))
                    TextSpan(
                      text: run,
                      style: isEmoji
                          ? base.copyWith(fontFamilyFallback: kEmojiFallback)
                          : base,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The design caps a bubble at 78% of the screen.
  static const double _maxWidthFraction = 0.78;
}
