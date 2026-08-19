// ─────────────────────────────────────────────────────────────
// RideMate — Chat
//
// Source: docs/claude-designs/RideMate App.dc.html, "CHAT" (immutable).
//
// Header → safety banner → conversation → quick replies → composer.
//
// NOTHING IS SENT AND NOTHING ARRIVES. There is no backend, socket, push,
// delivery, read state or typing indicator; the conversation is authored
// fixture content and the composer's send button says so when tapped. Opening
// this screen creates no request, match, booking, accepted ride, active trip or
// stored conversation — it must never imply that a journey is under way.
//
// DEVIATION D-chat-3: the approved safety banner tells the member to pay only
// inside the app. RideMate has no payments, and this is the one Phase 5 screen
// a real member can reach, so shipping that sentence would claim a capability
// that does not exist — the same failure as a button claiming a request was
// sent. The banner keeps its safety purpose with wording that is true today;
// the approved copy stays untouched in docs/claude-designs/ and returns when
// payment does.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/theme/tokens/rm_colors.dart';
import '../../../core/theme/tokens/rm_spacing.dart';
import '../../../core/widgets/rm_list_row.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/chat_entry.dart';
import '../domain/chat_fixtures.dart';
import 'widgets/chat_composer.dart';
import 'widgets/chat_header.dart';
import 'widgets/chat_quick_replies.dart';
import 'widgets/chat_thread.dart';

/// A conversation with one other member.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Presentation state, and only that. The typed text survives rebuilds while
  // the screen is alive and is persisted nowhere — no SharedPreferences, no
  // store, no repository. A fresh screen starts empty, and that is the honest
  // outcome rather than an invented draft-message feature.
  final TextEditingController _composer = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _composer.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Temporary Phase 5 behaviour for sending a message.
  ///
  /// Shows one message and nothing else. It deliberately does NOT append a
  /// bubble, create an entry, clear the field or navigate — nothing left the
  /// device, and a conversation that grew a message would say otherwise. When
  /// a backend exists the flow becomes send → server acknowledgement →
  /// delivered, and only then may the UI show the message in the thread.
  void _onSendRequested() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.chatSendUnavailable)));
  }

  /// Places a ready-made reply in the composer. It does not send it.
  void _onQuickReply(String reply) {
    _composer.text = reply;
    _composer.selection = TextSelection.collapsed(offset: reply.length);
    _focus.requestFocus();
  }

  void _onBack() {
    // The route is deep-linkable, so a cold launch can arrive with nothing
    // beneath it to pop back to.
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<ChatEntry> entries = mockConversation(l10n);

    return Scaffold(
      backgroundColor: c.background,
      // The app's first keyboard surface: the thread shrinks rather than
      // hiding the last bubble behind the keyboard.
      resizeToAvoidBottomInset: true,
      body: Column(
        children: <Widget>[
          ChatHeader(onBack: _onBack),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              RmSpacing.screenGutter,
              RmSpacing.md,
              RmSpacing.screenGutter,
              0,
            ),
            child: RmInlineMessage(message: l10n.chatSafetyBanner),
          ),
          Expanded(child: ChatThread(entries: entries)),
          Container(
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(top: BorderSide(color: c.hairline)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  RmSpacing.lg,
                  RmSpacing.md,
                  RmSpacing.lg,
                  RmSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ChatQuickReplies(onSelected: _onQuickReply),
                    const SizedBox(height: RmSpacing.md),
                    ChatComposer(
                      controller: _composer,
                      focusNode: _focus,
                      onSend: _onSendRequested,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
