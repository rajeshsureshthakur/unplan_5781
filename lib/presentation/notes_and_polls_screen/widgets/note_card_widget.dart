import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import './emoji_reactions_widget.dart';

class NoteCardWidget extends StatelessWidget {
  final Map<String, dynamic> note;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final Function(String emoji)? onEmojiReaction;

  const NoteCardWidget({
    Key? key,
    required this.note,
    this.onLongPress,
    this.onTap,
    this.onEmojiReaction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DateTime createdAt = note['createdAt'] as DateTime;
    final String timeAgo = _getTimeAgo(createdAt);
    final String authorName = note['authorName'] as String;
    final String content = note['content'] as String;
    final String? authorAvatar = note['authorAvatar'] as String?;
    final bool isOwnNote = authorName == 'You' || authorName == 'Alex Johnson';
    final Map<String, dynamic> reactions =
        note['reactions'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (authorAvatar != null) ...[
                      CircleAvatar(
                        radius: 4.w,
                        backgroundImage: NetworkImage(authorAvatar),
                      ),
                      SizedBox(width: 3.w),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authorName,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            timeAgo,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        try {
                          if (value == 'edit' && onLongPress != null) {
                            await Future.delayed(Duration(milliseconds: 100));
                            onLongPress!();
                          } else if (value == 'react') {
                            await Future.delayed(Duration(milliseconds: 100));
                            _showReactionsBottomSheet(context);
                          }
                        } catch (e) {
                          print('❌ Menu action error: $e');
                          // Silently handle the error to prevent app hanging
                        }
                      },
                      itemBuilder: (context) {
                        try {
                          return [
                            if (isOwnNote)
                              PopupMenuItem<String>(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    CustomIconWidget(
                                      iconName: 'edit',
                                      size: 4.w,
                                      color: AppTheme
                                          .lightTheme.colorScheme.onSurface,
                                    ),
                                    SizedBox(width: 2.w),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                            PopupMenuItem<String>(
                              value: 'react',
                              child: Row(
                                children: [
                                  Text('😊', style: TextStyle(fontSize: 4.w)),
                                  SizedBox(width: 2.w),
                                  Text('React'),
                                ],
                              ),
                            ),
                          ];
                        } catch (e) {
                          print('❌ Menu builder error: $e');
                          // Return empty list to prevent crash
                          return <PopupMenuEntry<String>>[];
                        }
                      },
                      child: GestureDetector(
                        onTap: () async {
                          try {
                            // Add small delay to prevent rapid taps
                            await Future.delayed(Duration(milliseconds: 200));
                            // Do nothing - let PopupMenuButton handle
                          } catch (e) {
                            print('❌ Three dots tap error: $e');
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(2.w),
                          child: CustomIconWidget(
                            iconName: 'more_vert',
                            size: 5.w,
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  content,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: null,
                  overflow: TextOverflow.visible,
                ),
                SizedBox(height: 2.h),
                if (onEmojiReaction != null)
                  EmojiReactionsWidget(
                    reactions: reactions,
                    onEmojiTap: onEmojiReaction!,
                    showOnlyCounts: true,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReactionsBottomSheet(BuildContext context) {
    try {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (BuildContext sheetContext) {
          return Container(
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 2.h),
                Container(
                  width: 12.w,
                  height: 0.5.h,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 3.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: Column(
                    children: [
                      Text(
                        'React to this message',
                        style: Theme.of(sheetContext)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 3.h),
                      _buildEmojiGrid(sheetContext),
                      SizedBox(height: 4.h),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print('❌ Bottom sheet error: $e');
      // Silently fail to prevent app hanging
    }
  }

  Widget _buildEmojiGrid(BuildContext context) {
    final List<String> availableEmojis = [
      '👍',
      '👎',
      '❤️',
      '😂',
      '😮',
      '🙏',
      '👏',
    ];

    final Map<String, dynamic> reactions =
        note['reactions'] as Map<String, dynamic>? ?? {};

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 4.w,
        mainAxisSpacing: 2.h,
      ),
      itemCount: availableEmojis.length,
      itemBuilder: (context, index) {
        final emoji = availableEmojis[index];
        final reactionData = reactions[emoji] as Map<String, dynamic>?;
        final bool userReacted = reactionData?['userReacted'] ?? false;

        return GestureDetector(
          onTap: () async {
            try {
              Navigator.pop(context);
              await Future.delayed(Duration(milliseconds: 100));
              if (onEmojiReaction != null) {
                onEmojiReaction!(emoji);
              }
            } catch (e) {
              print('❌ Emoji reaction error: $e');
            }
          },
          child: Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: userReacted
                  ? AppTheme.lightTheme.colorScheme.primary.withValues(
                      alpha: 0.1,
                    )
                  : AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: userReacted
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.outline.withValues(
                        alpha: 0.3,
                      ),
                width: userReacted ? 2 : 1,
              ),
            ),
            child: Center(child: Text(emoji, style: TextStyle(fontSize: 8.w))),
          ),
        );
      },
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}
