import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class EmojiReactionsWidget extends StatelessWidget {
  final Map<String, dynamic> reactions;
  final Function(String emoji) onEmojiTap;
  final bool showOnlyCounts;

  const EmojiReactionsWidget({
    Key? key,
    required this.reactions,
    required this.onEmojiTap,
    this.showOnlyCounts = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> availableEmojis = [
      '👍',
      '👎',
      '❤️',
      '😂',
      '😮',
      '🙏',
      '👏',
    ];
    final List<String> activeEmojis =
        availableEmojis
            .where((emoji) => reactions[emoji]?['count'] > 0)
            .toList();

    // If showOnlyCounts is true, only show reaction counts (WhatsApp style)
    if (showOnlyCounts) {
      if (activeEmojis.isEmpty) {
        return SizedBox.shrink();
      }

      return Wrap(
        spacing: 2.w,
        runSpacing: 1.h,
        children:
            activeEmojis.map((emoji) {
              final reactionData = reactions[emoji] as Map<String, dynamic>;
              final int count = reactionData['count'] as int;
              final bool userReacted = reactionData['userReacted'] as bool;

              return GestureDetector(
                onTap: () => onEmojiTap(emoji),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.5.w,
                    vertical: 0.8.h,
                  ),
                  decoration: BoxDecoration(
                    color:
                        userReacted
                            ? AppTheme.lightTheme.colorScheme.primary
                                .withValues(alpha: 0.1)
                            : AppTheme.lightTheme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                    border: Border.all(
                      color:
                          userReacted
                              ? AppTheme.lightTheme.colorScheme.primary
                                  .withValues(alpha: 0.5)
                              : AppTheme.lightTheme.colorScheme.outline
                                  .withValues(alpha: 0.3),
                      width: userReacted ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: TextStyle(fontSize: 3.5.w)),
                      SizedBox(width: 1.w),
                      Text(
                        count.toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight:
                              userReacted ? FontWeight.w600 : FontWeight.w500,
                          color:
                              userReacted
                                  ? AppTheme.lightTheme.colorScheme.primary
                                  : AppTheme
                                      .lightTheme
                                      .colorScheme
                                      .onSurfaceVariant,
                          fontSize: 3.w,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
      );
    }

    // Original behavior for polls and other components
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Active reactions display
        if (activeEmojis.isNotEmpty) ...[
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children:
                activeEmojis.map((emoji) {
                  final reactionData = reactions[emoji] as Map<String, dynamic>;
                  final int count = reactionData['count'] as int;
                  final bool userReacted = reactionData['userReacted'] as bool;

                  return GestureDetector(
                    onTap: () => onEmojiTap(emoji),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.5.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color:
                            userReacted
                                ? AppTheme.lightTheme.colorScheme.primary
                                    .withValues(alpha: 0.1)
                                : AppTheme.lightTheme.colorScheme.surface,
                        border: Border.all(
                          color:
                              userReacted
                                  ? AppTheme.lightTheme.colorScheme.primary
                                  : AppTheme.lightTheme.colorScheme.outline
                                      .withValues(alpha: 0.5),
                          width: userReacted ? 1.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(emoji, style: TextStyle(fontSize: 4.5.w)),
                          if (count > 0) ...[
                            SizedBox(width: 1.w),
                            Text(
                              count.toString(),
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                fontWeight:
                                    userReacted
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                color:
                                    userReacted
                                        ? AppTheme
                                            .lightTheme
                                            .colorScheme
                                            .primary
                                        : AppTheme
                                            .lightTheme
                                            .colorScheme
                                            .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
          SizedBox(height: 1.5.h),
        ],

        // All emoji options (always visible for easy access)
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.outline.withValues(
                alpha: 0.2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
                availableEmojis.map((emoji) {
                  final reactionData =
                      reactions[emoji] as Map<String, dynamic>?;
                  final bool userReacted =
                      reactionData?['userReacted'] ?? false;

                  return GestureDetector(
                    onTap: () => onEmojiTap(emoji),
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color:
                            userReacted
                                ? AppTheme.lightTheme.colorScheme.primary
                                    .withValues(alpha: 0.1)
                                : Colors.transparent,
                        shape: BoxShape.circle,
                        border:
                            userReacted
                                ? Border.all(
                                  color: AppTheme.lightTheme.colorScheme.primary
                                      .withValues(alpha: 0.3),
                                )
                                : null,
                      ),
                      child: Text(
                        emoji,
                        style: TextStyle(
                          fontSize: 5.w,
                          color:
                              userReacted
                                  ? AppTheme.lightTheme.colorScheme.primary
                                  : null,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}
