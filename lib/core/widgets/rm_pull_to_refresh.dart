// ─────────────────────────────────────────────────────────────
// RideMate — Pull to refresh
//
// The one gesture by which a member asks the server again. See
// core/api/rm_refresh.dart for what a screen shows while it does.
//
// EVERY STATE IS PULLABLE
//
// Not only a populated list. An empty list is exactly where the next answer
// arrives — a driver with no requests yet is waiting for one — and a failed
// read is where the member most wants to try again. [RmPullable] gives a state
// that does not scroll the scroll view the indicator needs, without changing
// how it looks.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../theme/tokens/rm_colors.dart';

class RmPullToRefresh extends StatelessWidget {
  const RmPullToRefresh({
    required this.onRefresh,
    required this.child,
    super.key,
  });

  /// Completes when the re-read has settled, not when it was sent.
  final Future<void> Function() onRefresh;

  /// A scroll view with [AlwaysScrollableScrollPhysics], or an [RmPullable].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: c.primary,
      backgroundColor: c.surface,
      child: child,
    );
  }
}

/// A state that does not scroll, made pullable without moving it.
///
/// It fills the space it is given exactly as before, so a centred message
/// stays centred.
class RmPullable extends StatelessWidget {
  const RmPullable({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) =>
        SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        ),
  );
}
