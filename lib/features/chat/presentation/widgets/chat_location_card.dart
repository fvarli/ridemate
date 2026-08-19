// ─────────────────────────────────────────────────────────────
// RideMate — Shared location card
//
// Source: docs/claude-designs/RideMate App.dc.html, "CHAT" (immutable).
//
// A small map picture over a label. It is ARTWORK: no coordinates, no
// location, no provider. It opens nothing, so it is deliberately NOT a button
// and announces as content.
//
// The mini map is a 220x84 artboard, which is why RmMapScene carries its own
// designSize — cover-scaling this to the phone artboard would crop it into a
// meaningless fragment.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/theme/tokens/rm_colors.dart';
import '../../../../core/theme/tokens/rm_radius.dart';
import '../../../../core/theme/tokens/rm_sizing.dart';
import '../../../../core/theme/tokens/rm_spacing.dart';
import '../../../../core/theme/tokens/rm_typography.dart';
import '../../../../core/widgets/rm_map_canvas.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/chat_entry.dart';
import 'chat_bubble.dart';

/// The design's 220x84 mini map: a road grid and a single point.
const RmMapScene kChatLocationScene = RmMapScene(
  designSize: Size(220, 84),
  roads: <RmMapRoad>[
    RmMapRoad(start: Offset(0, 30), end: Offset(220, 30), width: 6),
    RmMapRoad(start: Offset(0, 58), end: Offset(220, 58), width: 6),
    RmMapRoad(start: Offset(70, 0), end: Offset(70, 84), width: 6),
    RmMapRoad(start: Offset(150, 0), end: Offset(150, 84), width: 6),
  ],
  buildings: <RmMapBuilding>[],
  // A single point renders as the marker below rather than a polyline.
  route: <Offset>[],
);

/// A shared meeting point.
class ChatLocationCard extends StatelessWidget {
  const ChatLocationCard({
    required this.author,
    required this.label,
    required this.speaker,
    super.key,
  });

  final ChatAuthor author;
  final String label;

  /// How the sharer is named to assistive technology.
  final String speaker;

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool outgoing = author == ChatAuthor.member;

    return Align(
      alignment: outgoing
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Semantics(
        container: true,
        // Content, not a control: it goes nowhere.
        label: l10n.chatLocationSemanticLabel(speaker, label),
        excludeSemantics: true,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.8,
          ),
          child: ClipRRect(
            borderRadius: RmRadius.brMd,
            child: Container(
              decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(
                  color: c.hairline,
                  width: RmSizing.borderWidth,
                ),
                borderRadius: RmRadius.brMd,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(
                    height: _mapHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        RmMapCanvas(scene: kChatLocationScene),
                        Center(child: _LocationPoint()),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: RmSpacing.md,
                      vertical: RmSpacing.sm,
                    ),
                    child: Text.rich(
                      TextSpan(
                        children: <InlineSpan>[
                          for (final (String run, bool isEmoji)
                              in splitEmojiRuns(label))
                            TextSpan(
                              text: run,
                              style: isEmoji
                                  ? RmTypography.label.copyWith(
                                      color: c.ink,
                                      fontFamilyFallback: kEmojiFallback,
                                    )
                                  : RmTypography.label.copyWith(color: c.ink),
                            ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The design's 84px artboard height, scaled.
  static const double _mapHeight = 120;
}

/// The blue dot the design centres on the mini map.
class _LocationPoint extends StatelessWidget {
  const _LocationPoint();

  @override
  Widget build(BuildContext context) {
    final RmColors c = context.rmColors;

    return Container(
      width: RmSpacing.xxl,
      height: RmSpacing.xxl,
      decoration: BoxDecoration(
        color: c.primary,
        shape: BoxShape.circle,
        border: Border.all(color: c.surface, width: RmSizing.badgeRingWidth),
      ),
    );
  }
}
