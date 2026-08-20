// ─────────────────────────────────────────────────────────────
// RideMate — Safety list rows
//
// Source: "SAFETY · SOS" (immutable). Three rows with chevrons.
//
// ALL THREE CHEVRONS POINT AT SCREENS THE DESIGN NEVER DREW: a trusted-contact
// editor, a QR scanner, and a block/report form. Each needs its own UX,
// validation, permissions, failure states and — for the last two — policy
// decisions nobody has made.
//
// So the rows render as drawn and stay pressable, and each says which
// capability is missing rather than sharing one generic apology. Three
// different gaps deserve three different sentences.
//
// None of them navigates, stores anything or asks for a permission. In
// particular there is NO local blocked state: remembering a block that never
// happened would let a member believe they are protected from someone.
//
// The domain stays exactly as narrow as the design. Whether
// `Kullanıcı engelle / bildir` is one action or two, what blocking does to
// existing matches and conversations, whether a report is anonymous, and what
// `Gizli inceleme` means operationally are all open — see
// docs/design-system.md §8.
//
// The dark comp omits the third row entirely. It ships in both themes: a
// safety affordance that disappears at night is a regression, not intent
// (D-safety-2).
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/widgets/rm_list_row.dart';

/// The three navigation rows.
class SafetyLinks extends StatelessWidget {
  const SafetyLinks({required this.links, super.key});

  final List<SafetyLink> links;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < links.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: RmSpacing.sm),
          RmListRow(
            title: links[i].title,
            subtitle: links[i].subtitle,
            icon: links[i].icon,
            tone: links[i].tone,
            onTap: links[i].onPressed,
          ),
        ],
      ],
    );
  }
}

/// One row, as declared by the screen.
@immutable
class SafetyLink {
  const SafetyLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.onPressed,
  });

  final String icon;
  final String title;
  final String subtitle;
  final RmRowTone tone;

  /// Shows this row's own unavailability message. It navigates nowhere.
  final VoidCallback onPressed;
}
