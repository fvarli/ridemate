// ─────────────────────────────────────────────────────────────
// RideMate — text field
//
// WHY THIS EXISTS NOW AND NOT BEFORE
//
// chat_composer.dart records the condition: "A generic RmTextField is earned
// when a second, genuinely generic input appears." Phone entry and passcode
// entry are that second appearance, and unlike the composer they need a
// persistent label, an error state and a disabled state.
//
// The composer is deliberately NOT refactored onto this. It is a composer —
// one line, no label, no error, an embedded send button — and rewriting a
// working widget to share a superficial resemblance would be churn no
// requirement asked for.
//
// INVENTED STATES. The design source contains no input field at all, so the
// error and disabled treatments are extrapolated from the token language the
// same way RmButton's were: error borrows the danger colour already used for
// destructive affordances, disabled borrows the muted surface and faint ink.
// Nothing new is introduced; both are combinations of tokens that already
// exist.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens/rm_colors.dart';
import '../theme/tokens/rm_radius.dart';
import '../theme/tokens/rm_spacing.dart';
import '../theme/tokens/rm_typography.dart';

class RmTextField extends StatelessWidget {
  const RmTextField({
    required this.label,
    required this.controller,
    super.key,
    this.hint,
    this.error,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.autofillHints,
    this.maxLength,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
  });

  /// Always visible, and the accessible name.
  ///
  /// Not a hint. A hint disappears the moment the field is focused, which
  /// leaves a screen-reader user — and anyone who looked away — with an
  /// unlabelled box.
  final String label;

  final TextEditingController controller;
  final String? hint;

  /// Non-null puts the field in its error state and shows the message.
  final String? error;

  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final int? maxLength;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final RmColors c = Theme.of(context).extension<RmColors>()!;
    final bool hasError = error != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: RmTypography.label.copyWith(color: enabled ? c.sub : c.faint),
        ),
        const SizedBox(height: RmSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: RmSpacing.lg,
            vertical: RmSpacing.md,
          ),
          decoration: BoxDecoration(
            color: enabled ? c.surfaceMuted : c.surface,
            borderRadius: RmRadius.brLg,
            border: Border.all(
              color: hasError ? c.danger : c.border,
              width: hasError ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            autofocus: autofocus,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            maxLength: maxLength,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            style: RmTypography.bodyRegular.copyWith(
              color: enabled ? c.ink : c.faint,
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              // The counter would advertise a limit the member did not ask
              // about; maxLength is a guard, not a target.
              counterText: '',
              hintText: hint,
              hintStyle: RmTypography.bodyRegular.copyWith(color: c.faint),
            ),
          ),
        ),
        if (hasError) ...<Widget>[
          const SizedBox(height: RmSpacing.sm),
          Text(error!, style: RmTypography.caption.copyWith(color: c.danger)),
        ],
      ],
    );
  }
}
