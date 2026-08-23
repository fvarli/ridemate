// ─────────────────────────────────────────────────────────────
// RideMate — Passcode entry
//
// THE RESEND CONTROL HAS NO COUNTDOWN, DELIBERATELY.
//
// The server enforces a sixty-second cooldown and the contract does not
// publish when it expires — deliberately, since a resend-timing field is
// exactly the sort of thing that turns an endpoint into an oracle. A local
// timer would therefore be the client guessing at a server rule and drawing
// the guess as if it were fact: right until a retry, a clock skew or a second
// device makes it wrong.
//
// So resend is always offered and always real. If the cooldown has not
// elapsed the request comes back rate-limited and the member is told so — one
// round trip, and the answer is true.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/session_provider.dart';
import '../../../core/api/rm_error_copy.dart';
import '../../../core/api/rm_failure.dart';
import '../../../core/theme/tokens/rm_colors.dart';
import '../../../core/theme/tokens/rm_spacing.dart';
import '../../../core/theme/tokens/rm_typography.dart';
import '../../../core/widgets/rm_button.dart';
import '../../../core/widgets/rm_text_field.dart';
import '../../../l10n/app_localizations.dart';

/// How many digits the contract says a passcode has.
const int _passcodeLength = 6;

class PasscodeEntryScreen extends ConsumerStatefulWidget {
  const PasscodeEntryScreen({required this.phone, super.key});

  /// Shown back exactly as the member typed it, so they can tell whether they
  /// mistyped. It is not re-formatted here: canonicalising for display would
  /// mean showing something they did not write.
  final String phone;

  @override
  ConsumerState<PasscodeEntryScreen> createState() =>
      _PasscodeEntryScreenState();
}

class _PasscodeEntryScreenState extends ConsumerState<PasscodeEntryScreen> {
  final TextEditingController _code = TextEditingController();

  bool _busy = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  bool get _submittable => _code.text.length == _passcodeLength && !_busy;

  Future<void> _verify() async {
    final AppLocalizations l10n = AppLocalizations.of(context);

    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });

    try {
      await ref
          .read(rmSessionProvider)
          .verifyPasscode(phone: widget.phone, code: _code.text);

      // Nothing navigates here. The session is now signed in, and deciding
      // where that leads is the router's business — which is the next commit.
      // Inventing a destination now would be a navigation policy that has to
      // be unpicked.
    } on RmFailure catch (failure) {
      if (!mounted) {
        return;
      }
      setState(() => _error = _copyFor(failure, l10n));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// A wrong passcode is told plainly; everything else uses the shared copy.
  ///
  /// The generic unauthenticated line — "your session has ended" — is true of
  /// an expired token and nonsense in front of someone who has just mistyped
  /// six digits. Nothing about how many attempts remain is shown: the server
  /// does not say, and guessing would be inventing a rule.
  String _copyFor(RmFailure failure, AppLocalizations l10n) =>
      failure.status == 401 ? l10n.authCodeInvalid : failure.copy(l10n);

  Future<void> _resend() async {
    final AppLocalizations l10n = AppLocalizations.of(context);

    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });

    try {
      await ref.read(rmSessionProvider).requestPasscode(widget.phone);

      if (!mounted) {
        return;
      }
      setState(() => _notice = l10n.authCodeResent);
    } on RmFailure catch (failure) {
      if (!mounted) {
        return;
      }
      // Rate-limited lands here and says so honestly, which is the whole
      // reason there is no local countdown.
      setState(() => _error = failure.copy(l10n));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: RmSpacing.screenGutter,
          ),
          child: ListView(
            children: <Widget>[
              const SizedBox(height: RmSpacing.huge),
              Text(
                l10n.authCodeTitle,
                style: RmTypography.titleLg.copyWith(color: c.ink),
              ),
              const SizedBox(height: RmSpacing.sm),
              Text(
                l10n.authCodeBody(widget.phone),
                style: RmTypography.bodyRegular.copyWith(color: c.sub),
              ),
              const SizedBox(height: RmSpacing.xxl),
              RmTextField(
                label: l10n.authCodeFieldLabel,
                controller: _code,
                error: _error,
                enabled: !_busy,
                autofocus: true,
                maxLength: _passcodeLength,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const <String>[AutofillHints.oneTimeCode],
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submittable ? _verify() : null,
              ),
              if (_notice != null) ...<Widget>[
                const SizedBox(height: RmSpacing.sm),
                Text(
                  _notice!,
                  style: RmTypography.caption.copyWith(color: c.sub),
                ),
              ],
              const SizedBox(height: RmSpacing.xl),
              RmButton(
                label: l10n.authCodeSubmit,
                loading: _busy,
                onPressed: _submittable ? _verify : null,
              ),
              const SizedBox(height: RmSpacing.md),
              RmButton(
                label: l10n.authCodeResend,
                variant: RmButtonVariant.ghost,
                onPressed: _busy ? null : _resend,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
