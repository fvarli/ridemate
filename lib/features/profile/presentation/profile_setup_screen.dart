// ─────────────────────────────────────────────────────────────
// RideMate — Profile setup
//
// The one screen a signed-in member without a profile can reach. Built from the
// existing component vocabulary — RmTextField, RmButton, the spacing and
// typography tokens — exactly as the sign-in screens were, because the design
// source draws neither.
//
// THIS IS A COMPLETION SURFACE, NOT THE PROFILE SCREEN
//
// One field, one action. Editing a name later belongs to the Profile screen and
// is F3's; putting it here too would mean two places to change when the rule
// about names changes, and the one nobody remembers would be this one.
//
// IT DOES NOT NAVIGATE
//
// There is no `context.go` on success. The save updates the profile state, the
// router's gate sees a profile where there was none, and the redirect takes the
// member out. A screen that navigated itself would be a second opinion about
// where a member belongs, and the two would disagree the first time a save
// succeeded while the state said otherwise.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/rm_error_copy.dart';
import '../../../core/api/rm_failure.dart';
import '../../../core/theme/tokens/rm_colors.dart';
import '../../../core/theme/tokens/rm_spacing.dart';
import '../../../core/theme/tokens/rm_typography.dart';
import '../../../core/widgets/rm_button.dart';
import '../../../core/widgets/rm_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../application/my_profile_providers.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final TextEditingController _name = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Only obviously-unusable input is refused here.
  ///
  /// The rule is the server's — trimmed, one to eighty characters — and
  /// duplicating it would mean two definitions of "a name" that can disagree.
  /// A name this accepts and the server refuses comes back as a validation
  /// failure, which is the honest answer and the one the member can act on.
  bool get _submittable => _name.text.trim().isNotEmpty && !_saving;

  Future<void> _submit() async {
    final AppLocalizations l10n = AppLocalizations.of(context);

    setState(() {
      _saving = true;
      _error = null;
    });

    final RmSaveOutcome outcome = await ref
        .read(myProfileProvider.notifier)
        .save(_name.text);

    if (!mounted) return;

    setState(() {
      _saving = false;
      // Nothing is shown on success: the member is about to leave this screen
      // because the state changed, not because this method decided so.
      _error = outcome.succeeded ? null : _copyFor(outcome.failure!, l10n);
    });
  }

  /// The failure's own copy, never a backend message — RmFailure carries none.
  String _copyFor(Object failure, AppLocalizations l10n) =>
      failure is RmFailure ? failure.copy(l10n) : l10n.errorUnexpected;

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
                l10n.profileSetupTitle,
                style: RmTypography.titleLg.copyWith(color: c.ink),
              ),
              const SizedBox(height: RmSpacing.sm),
              Text(
                l10n.profileSetupBody,
                style: RmTypography.bodyRegular.copyWith(color: c.sub),
              ),
              const SizedBox(height: RmSpacing.xxl),
              RmTextField(
                label: l10n.profileSetupFieldLabel,
                hint: l10n.profileSetupFieldHint,
                controller: _name,
                error: _error,
                enabled: !_saving,
                autofocus: true,
                textInputAction: TextInputAction.done,
                // No input formatter. A name is whatever the member calls
                // themselves, and a filter here would decide which alphabets
                // are allowed — a decision nobody has made and this screen has
                // no business making.
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submittable ? _submit() : null,
              ),
              const SizedBox(height: RmSpacing.xl),
              RmButton(
                label: l10n.profileSetupSubmit,
                loading: _saving,
                onPressed: _submittable ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
