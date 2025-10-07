import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:provider/provider.dart';

/// Represents a single reaction entry with an emoji and reaction count.
class FlyerChatReaction {
  /// Creates a reaction entry with the provided [emoji] and number of [count].
  const FlyerChatReaction({
    required this.emoji,
    required this.count,
  });

  /// The emoji or reaction identifier to display.
  final String emoji;

  /// Number of unique reactions for the [emoji].
  final int count;
}

/// Displays reactions for a chat message using Flyer Chat theming.
class FlyerChatMessageReactions extends StatelessWidget {
  /// Creates a widget that renders message reactions within a styled container.
  const FlyerChatMessageReactions({
    super.key,
    required this.reactions,
    this.isSentByMe = false,
    this.padding = const EdgeInsets.only(top: 6),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  /// Normalized list of reactions to render.
  final List<FlyerChatReaction> reactions;

  /// Indicates whether the message belongs to the current user.
  final bool isSentByMe;

  /// Outer padding for the reactions container.
  final EdgeInsetsGeometry padding;

  /// Border radius of the reactions container.
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = context.select(
      (ChatTheme t) => (
        background: t.colors.surface,
        borderColor: t.colors.surfaceContainerHigh,
        textStyle: t.typography.labelMedium.copyWith(
          color: t.colors.onSurface,
        ),
        emojiStyle: t.typography.bodyLarge,
      ),
    );

    final displayed = reactions.take(2).toList();
    final totalCount = reactions.fold<int>(0, (value, element) => value + element.count);
    final showCount = totalCount > 1;

    final children = <Widget>[
      for (final reaction in displayed)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            reaction.emoji,
            style: theme.emojiStyle,
          ),
        ),
    ];

    if (showCount) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(width: 4));
      }
      children.add(Text(totalCount.toString(), style: theme.textStyle));
    }

    return Padding(
      padding: padding,
      child: Align(
        alignment: isSentByMe
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: borderRadius,
            border: Border.all(color: theme.borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
