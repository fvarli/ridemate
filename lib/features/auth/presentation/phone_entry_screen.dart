// ─────────────────────────────────────────────────────────────
// RideMate — Phone entry
//
// The design source draws no sign-in screen; docs/design-system.md lists login
// and OTP entry among the screens it implies and never shows. So this is built
// from the existing component vocabulary — RmTextField, RmButton, the spacing
// and typography tokens — rather than a separate visual language invented for
// authentication.
//
// EVERY CONTROL IS REAL. The button submits to the backend, the loading state
// covers an actual request, and the error text is what the server said,
// translated. Nothing here is a placeholder waiting to be wired up.
// ─────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/session_provider.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/api/rm_error_copy.dart';
import '../../../core/api/rm_failure.dart';
import '../../../core/session/rm_session.dart';
import '../../../core/theme/tokens/rm_colors.dart';
import '../../../core/theme/tokens/rm_radius.dart';
import '../../../core/theme/tokens/rm_spacing.dart';
import '../../../core/theme/tokens/rm_typography.dart';
import '../../../core/widgets/rm_button.dart';
import '../../../core/widgets/rm_text_field.dart';
import '../../../l10n/app_localizations.dart';

class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final TextEditingController _phone = TextEditingController();

  bool _sending = false;
  String? _error;

  /// Why the member is back here, if there is a reason worth telling them.
  ///
  /// Read once, in initState, and cleared from the session as it is read. The
  /// router re-evaluates its redirect on every navigation, so a reason left in
  /// place would put the same notice back on screen each time they moved
  /// between the two auth screens.
  ///
  /// Never shown for an ordinary arrival: a first launch, a deliberate sign
  /// out, or a reinstall all leave it null, because none of those is something
  /// that happened TO the member.
  RmSignedOutReason? _signedOutReason;

  @override
  void initState() {
    super.initState();
    _signedOutReason = ref.read(rmSessionProvider).consumeSignedOutReason();
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  /// Only obviously-empty input is refused here.
  ///
  /// The real rule is per-country metadata the server owns, and duplicating a
  /// guess at it on the client would mean two definitions of "a phone number"
  /// that disagree. A number this accepts and the server rejects comes back as
  /// a validation failure, which is the honest answer.
  bool get _submittable => _phone.text.trim().length >= 4 && !_sending;

  Future<void> _submit() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String phone = _phone.text.trim();

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await ref.read(rmSessionProvider).requestPasscode(phone);

      if (!mounted) {
        return;
      }

      // Completes only when the passcode screen pops, which is not
      // something this method waits for.
      unawaited(context.pushNamed(AppRoutes.authPasscode, extra: phone));
    } on RmFailure catch (failure) {
      if (!mounted) {
        return;
      }
      // The failure's own copy, never the backend's message — RmFailure does
      // not carry one.
      setState(() => _error = failure.copy(l10n));
    } finally {
      if (mounted) {
        setState(() => _sending = false);
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
                l10n.authPhoneTitle,
                style: RmTypography.titleLg.copyWith(color: c.ink),
              ),
              const SizedBox(height: RmSpacing.sm),
              Text(
                l10n.authPhoneBody,
                style: RmTypography.bodyRegular.copyWith(color: c.sub),
              ),
              if (_signedOutReason != null) ...<Widget>[
                const SizedBox(height: RmSpacing.lg),
                _SignedOutNotice(reason: _signedOutReason!),
              ],
              const SizedBox(height: RmSpacing.xxl),
              RmTextField(
                label: l10n.authPhoneFieldLabel,
                hint: l10n.authPhoneFieldHint,
                controller: _phone,
                error: _error,
                enabled: !_sending,
                autofocus: true,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                autofillHints: const <String>[AutofillHints.telephoneNumber],
                inputFormatters: <TextInputFormatter>[
                  // Digits and the characters a member actually types around
                  // them. Normalisation is the server's job.
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+()\s-]')),
                ],
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submittable ? _submit() : null,
              ),
              const SizedBox(height: RmSpacing.xl),
              RmButton(
                label: l10n.authPhoneSubmit,
                loading: _sending,
                // Null disables it. Not a dead control: it becomes tappable
                // as soon as there is something to send.
                onPressed: _submittable ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Explains an involuntary sign-out, once.
///
/// Suspension is kept apart from an expired session on purpose: "sign in
/// again" is exactly the advice that will not work for a suspended account,
/// and repeating it would send the member round a loop the app already knows
/// is closed.
class _SignedOutNotice extends StatelessWidget {
  const _SignedOutNotice({required this.reason});

  final RmSignedOutReason reason;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);

    final bool suspended = reason == RmSignedOutReason.accountSuspended;

    return Container(
      padding: const EdgeInsets.all(RmSpacing.lg),
      decoration: BoxDecoration(
        color: suspended ? c.dangerSoft : c.surfaceMuted,
        borderRadius: RmRadius.brLg,
      ),
      child: Text(
        suspended ? l10n.errorForbidden : l10n.errorUnauthenticated,
        style: RmTypography.bodySm.copyWith(
          color: suspended ? c.danger : c.sub,
        ),
      ),
    );
  }
}
