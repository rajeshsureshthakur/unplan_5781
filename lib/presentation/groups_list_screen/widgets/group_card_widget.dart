import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class GroupCardWidget extends StatelessWidget {
  final Map<String, dynamic> group;
  final VoidCallback onTap;
  final VoidCallback onMute;
  final VoidCallback onLeave;
  final VoidCallback? onUpdateGroupInfo;

  const GroupCardWidget({
    Key? key,
    required this.group,
    required this.onTap,
    required this.onMute,
    required this.onLeave,
    this.onUpdateGroupInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<dynamic> members = group['members'] as List<dynamic>? ?? [];
    final int memberCount = members.length;
    final String lastActivity =
        group['lastActivity'] as String? ?? 'No recent activity';
    final bool hasUnread = group['hasUnread'] as bool? ?? false;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                // Group Avatar or Initials
                _buildGroupAvatar(),
                SizedBox(width: 4.w),

                // Group Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              group['name'] as String? ?? 'Unnamed Group',
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasUnread)
                            Container(
                              width: 2.w,
                              height: 2.w,
                              decoration: BoxDecoration(
                                color: AppTheme.lightTheme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        '$memberCount ${memberCount == 1 ? 'member' : 'members'}',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        lastActivity,
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // More Options
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'mute') {
                      onMute();
                    } else if (value == 'leave') {
                      onLeave();
                    } else if (value == 'update_info') {
                      if (onUpdateGroupInfo != null) {
                        onUpdateGroupInfo!();
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'update_info',
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'edit',
                            size: 20,
                            color: AppTheme.lightTheme.colorScheme.primary,
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            'Update Group Info',
                            style: TextStyle(
                              color: AppTheme.lightTheme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'mute',
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'notifications_off',
                            size: 20,
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(width: 3.w),
                          Text('Mute Notifications'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'leave',
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'exit_to_app',
                            size: 20,
                            color: AppTheme.lightTheme.colorScheme.error,
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            'Leave Group',
                            style: TextStyle(
                              color: AppTheme.lightTheme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: Padding(
                    padding: EdgeInsets.all(2.w),
                    child: CustomIconWidget(
                      iconName: 'more_vert',
                      size: 20,
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupAvatar() {
    final String groupName = group['name'] as String? ?? 'Unnamed Group';
    final String? groupPhoto = group['profile_picture'] as String? ??
        group['profilePicture'] as String?;

    return Container(
      width: 15.w,
      height: 15.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: groupPhoto != null && groupPhoto.isNotEmpty
            ? CustomImageWidget(
                imageUrl: groupPhoto,
                width: 15.w,
                height: 15.w,
                fit: BoxFit.cover,
              )
            : _buildGroupInitials(groupName),
      ),
    );
  }

  Widget _buildGroupInitials(String groupName) {
    final words = groupName.trim().split(' ');
    String initials = '';

    if (words.isNotEmpty) {
      initials += words[0].isNotEmpty ? words[0][0].toUpperCase() : '';
      if (words.length > 1 && words[1].isNotEmpty) {
        initials += words[1][0].toUpperCase();
      }
    }

    if (initials.isEmpty) initials = 'G';

    return Container(
      width: 15.w,
      height: 15.w,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTheme.colorScheme.primary,
            fontSize: 6.w,
          ),
        ),
      ),
    );
  }
}
