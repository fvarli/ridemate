// ─────────────────────────────────────────────────────────────
// RideMate — Edit display name
//
// The whole of "editing a profile", because a display name is the whole of a
// profile. When there is more to change this screen grows; inventing fields
// for it now would be building a form around data that does not exist.
//
// NEVER OPTIMISTIC
//
// The name on the Profile screen changes when the server says it changed, and
// not a moment earlier. An optimistic rename would show a member their new
// name and then, on a failure, either revert it — which looks like the app
// undoing their work — or leave it there, which would be a lie that survives
// until the next read.
//
// The save goes through MyProfileController, so a success replaces the state
// with the profile the SERVER returned: trimming and initials are its
// decisions, and adopting its answer is what keeps the two ends agreeing.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/api/rm_error_copy.dart';
import '../../../core/api/rm_failure.dart';
import '../../../core/icons/rm_icons.dart';
import '../../../core/profile/profile.dart';
import '../../../core/theme/tokens/rm_colors.dart';
import '../../../core/theme/tokens/rm_spacing.dart';
import '../../../core/theme/tokens/rm_typography.dart';
import '../../../core/widgets/rm_button.dart';
import '../../../core/widgets/rm_icon_button.dart';
import '../../../core/widgets/rm_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../application/my_profile_providers.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final TextEditingController _name = TextEditingController();

  bool _prefilled = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Prefilled once, from whatever the server last returned.
  ///
  /// Once, because re-seeding on every build would overwrite what the member
  /// is typing the moment anything else rebuilt this screen.
  void _prefill(Profile profile) {
    if (_prefilled) return;

    _prefilled = true;
    _name.text = profile.displayName;
  }

  bool get _submittable => _name.text.trim().isNotEmpty && !_saving;

  Future<void> _submit() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NavigatorState navigator = Navigator.of(context);

    setState(() {
      _saving = true;
      _error = null;
    });

    final RmSaveOutcome outcome = await ref
        .read(myProfileProvider.notifier)
        .save(_name.text);

    if (!mounted) return;

    if (outcome.succeeded) {
      // Back to Profile, which is already showing the server's answer because
      // the state changed before this line ran.
      navigator.pop();

      return;
    }

    setState(() {
      _saving = false;
      _error = outcome.failure is RmFailure
          ? (outcome.failure! as RmFailure).copy(l10n)
          : l10n.errorUnexpected;
    });
  }

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<ProfileState> state = ref.watch(myProfileProvider);

    if (state.value case ProfileReady(:final Profile profile)) {
      _prefill(profile);
    }

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                RmSpacing.screenGutter,
                RmSpacing.md,
                RmSpacing.screenGutter,
                0,
              ),
              child: Row(
                children: <Widget>[
                  RmIconButton(
                    icon: RmIcons.chevronLeft,
                    semanticLabel: l10n.commonBack,
                    onPressed: () => _back(context),
                  ),
                  const SizedBox(width: RmSpacing.md),
                  Expanded(
                    child: Text(
                      l10n.profileEditName,
                      style: RmTypography.label.copyWith(color: c.ink),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: RmSpacing.screenGutter,
                ),
                children: <Widget>[
                  const SizedBox(height: RmSpacing.xl),
                  RmTextField(
                    label: l10n.profileSetupFieldLabel,
                    hint: l10n.profileSetupFieldHint,
                    controller: _name,
                    error: _error,
                    enabled: !_saving,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _submittable ? _submit() : null,
                  ),
                  const SizedBox(height: RmSpacing.xl),
                  RmButton(
                    label: l10n.profileEditSave,
                    loading: _saving,
                    onPressed: _submittable ? _submit : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoutes.profile);
    }
  }
}
