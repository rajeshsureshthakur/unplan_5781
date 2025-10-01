import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class GroupCardWidget extends StatelessWidget {
  final Map<String, dynamic> group;
  final VoidCallback onTap;
  final VoidCallback? onUpdateGroupInfo;

  const GroupCardWidget({
    Key? key,
    required this.group,
    required this.onTap,
    this.onUpdateGroupInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final groupName = group['name'] ?? 'Unknown Group';
    final groupDescription = group['description'] ?? '';
    final memberCount = _getMemberCount();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow.withValues(
              alpha: 0.08,
            ),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group header with photo, name, and 3-dot menu
              Row(
                children: [
                  // Group photo
                  Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.lightTheme.colorScheme.outline
                            .withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: ClipOval(
                      child: _buildGroupPhoto(),
                    ),
                  ),

                  SizedBox(width: 3.w),

                  // Group name and member count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          groupName,
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          '$memberCount members',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3-dot menu with Update Group Info option
                  PopupMenuButton<String>(
                    icon: CustomIconWidget(
                      iconName: 'more_vert',
                      size: 20,
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                    onSelected: (value) {
                      if (value == 'update_info' && onUpdateGroupInfo != null) {
                        onUpdateGroupInfo!();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'update_info',
                        child: Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'edit',
                              size: 18,
                              color: AppTheme.lightTheme.colorScheme.primary,
                            ),
                            SizedBox(width: 2.w),
                            Text('Update Group Info'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (groupDescription.isNotEmpty) ...[
                SizedBox(height: 2.h),
                Text(
                  groupDescription,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              SizedBox(height: 2.h),

              // Members preview
              _buildMembersPreview(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupPhoto() {
    final profilePicture = group['profile_picture'] ?? group['profilePicture'];

    if (profilePicture != null && profilePicture.isNotEmpty) {
      return CustomImageWidget(
        imageUrl: profilePicture.toString(),
        width: 12.w,
        height: 12.w,
        fit: BoxFit.cover,
      );
    }

    // Build initials avatar for group
    return _buildInitialsAvatar();
  }

  Widget _buildInitialsAvatar() {
    final groupName = group['name'] ?? 'Group';
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
      width: 12.w,
      height: 12.w,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  int _getMemberCount() {
    if (group['group_members'] != null) {
      return (group['group_members'] as List).length;
    }
    if (group['members'] != null) {
      return (group['members'] as List).length;
    }
    return group['memberCount'] ?? 0;
  }

  Widget _buildMembersPreview() {
    List<dynamic> members = [];

    if (group['group_members'] != null) {
      members = (group['group_members'] as List<dynamic>);
    } else if (group['members'] != null) {
      members = (group['members'] as List<dynamic>);
    }

    if (members.isEmpty) {
      return Row(
        children: [
          CustomIconWidget(
            iconName: 'people',
            size: 16,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: 2.w),
          Text(
            'No members yet',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        SizedBox(
          height: 7.w,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: members.length > 4 ? 4 : members.length,
            itemBuilder: (context, index) {
              if (index == 3 && members.length > 4) {
                return Container(
                  width: 7.w,
                  height: 7.w,
                  margin: EdgeInsets.only(right: 1.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '+${members.length - 3}',
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                );
              }

              final member = members[index];
              final memberData = member['user_profiles'] ?? member;
              final memberAvatar = memberData?['profile_picture'];

              return Container(
                width: 7.w,
                height: 7.w,
                margin: EdgeInsets.only(right: 1.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: memberAvatar != null && memberAvatar.isNotEmpty
                      ? CustomImageWidget(
                          imageUrl: memberAvatar,
                          width: 7.w,
                          height: 7.w,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppTheme.lightTheme.colorScheme.primary
                              .withValues(alpha: 0.2),
                          child: Center(
                            child: Text(
                              (memberData?['full_name'] ?? 'U')[0]
                                  .toUpperCase(),
                              style: AppTheme.lightTheme.textTheme.labelSmall
                                  ?.copyWith(
                                color: AppTheme.lightTheme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                ),
              );
            },
          ),
        ),
        Spacer(),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'View Details',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
