// ─────────────────────────────────────────────────────────────
// RideMate — Minimum tap target wrapper
//
// Adapted from the same helper in the sibling Quietly project, with the
// RideMate naming and an added RTL note.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/widgets.dart';

import 'rm_a11y.dart';

/// Guarantees [child] is tappable across at least [size] in both axes,
/// without changing how large it *looks*.
///
/// Use this wherever the design specifies a control smaller than
/// [RmA11y.minTouchTarget] — the stepper buttons and the small inline
/// buttons. The visual box stays on-design; only the hit area grows.
class RmTapTarget extends StatelessWidget {
  const RmTapTarget({
    required this.child,
    super.key,
    this.onTap,
    this.semanticLabel,
    this.size = RmA11y.minTouchTarget,
  });

  final Widget child;

  /// When null the target is inert and exposes no button semantics.
  final VoidCallback? onTap;

  /// Screen-reader label. Omit only for genuinely decorative content.
  final String? semanticLabel;

  /// Minimum side length. Defaults to [RmA11y.minTouchTarget].
  final double size;

  @override
  Widget build(BuildContext context) {
    // Center with unit factors so the box hugs the child and only expands to
    // the minimum, rather than filling its parent.
    Widget content = ConstrainedBox(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      child: Center(widthFactor: 1, heightFactor: 1, child: child),
    );

    if (onTap != null) {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: content,
      );
    }

    if (semanticLabel != null) {
      content = Semantics(
        label: semanticLabel,
        button: onTap != null,
        enabled: onTap != null,
        excludeSemantics: true,
        child: content,
      );
    }

    return content;
  }
}
