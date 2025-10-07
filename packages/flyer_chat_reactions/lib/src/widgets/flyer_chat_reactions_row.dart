import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';

import 'package:provider/provider.dart';

import '../helpers/chat_theme_extensions.dart';
import '../models/reaction.dart';
import '../utils/typedef.dart';
import 'reaction_tile.dart';

/// A widget that renders a compact summary of message reactions.
///
/// Displays up to two reaction emojis along with the total count of reactions
/// inside a pill-shaped container that hugs the bottom edge of the message
/// bubble.
class FlyerChatReactionsRow extends StatefulWidget {
  /// The reactions to display, mapped by emoji.
  final List<Reaction> reactions;

  /// Callback for when a reaction is tapped.
  final OnReactionTapCallback? onReactionTap;

  /// Callback for when a reaction is long pressed.
  final OnReactionLongPressCallback? onReactionLongPress;

  /// Callback when the surplus  is tapped.
  final VoidCallback? onSurplusReactionTap;

  /// Font size for the emoji in reaction tiles.
  final TextStyle? emojiTextStyle;

  /// Text style for the count text in reaction tiles.
  /// Note that we use a FittedBox so if the text is too long, it will be scaled down.
  final TextStyle? countTextStyle;

  /// Text style for the surplus text in reaction tiles.
  /// Note that we use a FittedBox so if the text is too long, it will be scaled down.
  final TextStyle? surplusTextStyle;

  /// Space between reaction tiles.
  /// Defaults to 2.
  final double spacing;

  /// Padding applied to the reactions container.
  /// Defaults to horizontal padding with automatic vertical padding.
  final EdgeInsets reactionTilePadding;

  /// Color of the border around reaction tiles.
  /// If null, uses the default theme color.
  final Color? borderColor;

  /// Background color for reaction tiles when not reacted by the user.
  /// If null, uses the default theme color.
  final Color? reactionBackgroundColor;

  /// Background color for reaction tiles when reacted by the user.
  /// If null, uses the default theme color.
  final Color? reactionReactedBackgroundColor;

  /// Alignment of the reactions row
  final MainAxisAlignment alignment;

  /// Remove/Add on tap or not.
  /// If true, the reaction will be removed locally when tapped.
  final bool removeOrAddLocallyOnTap;

  /// Creates a widget that displays a row of reaction tiles.
  const FlyerChatReactionsRow({
    super.key,
    required this.reactions,
    this.onReactionTap,
    this.onReactionLongPress,
    this.onSurplusReactionTap,
    this.emojiTextStyle,
    this.countTextStyle,
    this.surplusTextStyle,
    this.spacing = 2,
    this.reactionTilePadding = const EdgeInsets.symmetric(horizontal: 4),
    this.borderColor,
    this.reactionBackgroundColor,
    this.reactionReactedBackgroundColor,
    this.alignment = MainAxisAlignment.start,
    this.removeOrAddLocallyOnTap = false,
  });

  @override
  State<FlyerChatReactionsRow> createState() => _FlyerChatReactionsRowState();
}

class _FlyerChatReactionsRowState extends State<FlyerChatReactionsRow> {
  final Map<String, _ReactionViewState> _localReactionStates = {};

  @override
  void initState() {
    super.initState();
    _syncLocalReactionStates();
  }

  @override
  void didUpdateWidget(covariant FlyerChatReactionsRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_shouldResyncStates(oldWidget)) {
      _syncLocalReactionStates();
    }
  }

  bool _shouldResyncStates(FlyerChatReactionsRow oldWidget) {
    if (oldWidget.removeOrAddLocallyOnTap != widget.removeOrAddLocallyOnTap) {
      return true;
    }

    if (!widget.removeOrAddLocallyOnTap) {
      // When the consumer disables optimistic updates we always rely on the
      // upstream data.
      return true;
    }

    if (oldWidget.reactions.length != widget.reactions.length) {
      return true;
    }

    for (final reaction in widget.reactions) {
      final previous =
          oldWidget.reactions.firstWhere((old) => old.emoji == reaction.emoji,
              orElse: () =>
                  Reaction(
                    emoji: reaction.emoji,
                    count: -1,
                    isReactedByUser: reaction.isReactedByUser,
                    userIds: reaction.userIds,
                  ));
      if (previous.count != reaction.count ||
          previous.isReactedByUser != reaction.isReactedByUser) {
        return true;
      }
    }

    return false;
  }

  void _syncLocalReactionStates() {
    _localReactionStates
      ..clear()
      ..addEntries(
        widget.reactions.map(
          (reaction) => MapEntry(
            reaction.emoji,
            _ReactionViewState(
              count: reaction.count,
              isReactedByUser: reaction.isReactedByUser,
            ),
          ),
        ),
      );
  }

  List<_ReactionDisplayData> _buildEffectiveReactions() {
    return widget.reactions
        .map((reaction) {
          final localState = widget.removeOrAddLocallyOnTap
              ? _localReactionStates[reaction.emoji]
              : null;

          final count = localState?.count ?? reaction.count;
          if (count <= 0) {
            return null;
          }

          return _ReactionDisplayData(
            emoji: reaction.emoji,
            count: count,
            isReactedByUser:
                localState?.isReactedByUser ?? reaction.isReactedByUser,
          );
        })
        .whereType<_ReactionDisplayData>()
        .toList();
  }

  void _handleReactionTap(_ReactionDisplayData reaction) {
    if (widget.removeOrAddLocallyOnTap) {
      setState(() {
        final state = _localReactionStates[reaction.emoji];
        if (state != null) {
          if (state.isReactedByUser) {
            state.count = math.max(state.count - 1, 0);
          } else {
            state.count += 1;
          }
          state.isReactedByUser = !state.isReactedByUser;
        }
      });
    }
    widget.onReactionTap?.call(reaction.emoji);
  }

  void _handleReactionLongPress(_ReactionDisplayData reaction) {
    widget.onReactionLongPress?.call(reaction.emoji);
  }

  Alignment _resolveAlignment() {
    switch (widget.alignment) {
      case MainAxisAlignment.end:
        return Alignment.bottomRight;
      case MainAxisAlignment.center:
        return Alignment.bottomCenter;
      default:
        return Alignment.bottomLeft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveReactions = _buildEffectiveReactions();
    if (effectiveReactions.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = context.read<ChatTheme>();
    final emojiTextStyle = ReactionTileStyleResolver.resolveEmojiTextStyle(
      provided: widget.emojiTextStyle,
      theme: theme,
    );
    final countTextStyle = ReactionTileStyleResolver.resolveCountTextStyle(
      provided: widget.countTextStyle ?? widget.surplusTextStyle,
      theme: theme,
    );
    final reactedBackgroundColor =
        widget.reactionReactedBackgroundColor ??
        theme.reactionReactedBackgroundColor;
    final backgroundColor =
        widget.reactionBackgroundColor ?? theme.reactionBackgroundColor;
    final borderColor = widget.borderColor ?? theme.reactionBorderColor;

    final totalCount = effectiveReactions.fold<int>(
      0,
      (sum, reaction) => sum + reaction.count,
    );
    final showTotalCount = totalCount > 1;

    final displayedReactions = effectiveReactions.take(2).toList();
    final hasHiddenReactions =
        effectiveReactions.length > displayedReactions.length;
    final hasUserReaction =
        effectiveReactions.any((reaction) => reaction.isReactedByUser);
    final containerColor = hasUserReaction ? reactedBackgroundColor : backgroundColor;
    final containerPadding = widget.reactionTilePadding.add(
      const EdgeInsets.symmetric(vertical: 4),
    );

    return Align(
      alignment: _resolveAlignment(),
      child: Container(
        padding: containerPadding,
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < displayedReactions.length; i++) ...[
              _ReactionEmojiButton(
                reaction: displayedReactions[i],
                emojiTextStyle: emojiTextStyle,
                onTap: () => _handleReactionTap(displayedReactions[i]),
                onLongPress: () =>
                    _handleReactionLongPress(displayedReactions[i]),
              ),
              if (i < displayedReactions.length - 1)
                SizedBox(width: widget.spacing),
            ],
            if (showTotalCount) ...[
              if (displayedReactions.isNotEmpty)
                SizedBox(width: widget.spacing),
              _TotalReactionCount(
                count: totalCount,
                textStyle: countTextStyle,
                onTap:
                    hasHiddenReactions ? widget.onSurplusReactionTap : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReactionViewState {
  _ReactionViewState({
    required this.count,
    required this.isReactedByUser,
  });

  int count;
  bool isReactedByUser;
}

class _ReactionDisplayData {
  const _ReactionDisplayData({
    required this.emoji,
    required this.count,
    required this.isReactedByUser,
  });

  final String emoji;
  final int count;
  final bool isReactedByUser;
}

class _ReactionEmojiButton extends StatelessWidget {
  const _ReactionEmojiButton({
    required this.reaction,
    required this.emojiTextStyle,
    this.onTap,
    this.onLongPress,
  });

  final _ReactionDisplayData reaction;
  final TextStyle emojiTextStyle;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final style = reaction.isReactedByUser
        ? emojiTextStyle.copyWith(fontWeight: FontWeight.bold)
        : emojiTextStyle;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(reaction.emoji, style: style),
      ),
    );
  }
}

class _TotalReactionCount extends StatelessWidget {
  const _TotalReactionCount({
    required this.count,
    required this.textStyle,
    this.onTap,
  });

  final int count;
  final TextStyle textStyle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text('$count', style: textStyle),
    );

    if (onTap == null) {
      return child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: child,
    );
  }
}
