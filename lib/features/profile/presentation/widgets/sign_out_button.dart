// ─────────────────────────────────────────────────────────────
// RideMate — Sign out
//
// One control, placed on every face the Profile experience can show a
// signed-in member: the loaded profile, a profile that failed to load, a
// profile that does not exist yet, and setup. Leaving must not depend on the
// profile read succeeding — a member stuck behind a failing request, or on a
// number they did not mean to use, would otherwise have no way out.
//
// IT DOES NOT NAVIGATE
//
// The session becomes signed out and the router's redirect takes the member to
// sign-in, exactly as it does when a session ends any other way. A screen that
// navigated itself would be a second opinion about where a member belongs.
//
// No confirmation. Signing out costs one passcode to undo, and nothing here
// has made a rule that it deserves a dialog.
// ─────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/session_provider.dart';
import '../../../../core/widgets/rm_button.dart';
import '../../../../l10n/app_localizations.dart';

class SignOutButton extends ConsumerWidget {
  const SignOutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => RmButton(
    label: AppLocalizations.of(context).profileSignOut,
    size: RmButtonSize.sm,
    variant: RmButtonVariant.ghost,
    // Not awaited. The device is signed out before the revocation is sent, so
    // this screen is gone by the time the request answers.
    onPressed: () => unawaited(ref.read(rmSessionProvider).signOut()),
  );
}
