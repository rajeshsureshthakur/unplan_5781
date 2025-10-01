import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/enlarged_profile_image_widget.dart';

class UserProfileStatsWidget extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onProfileTap;

  const UserProfileStatsWidget({
    Key? key,
    required this.user,
    required this.onProfileTap,
  }) : super(key: key);

  // CRITICAL FIX: Enhanced avatar display with better cache handling and increased size
  Widget _buildUserAvatar() {
    final String userName = user['name']?.toString() ?? 'User';
    final String? avatarUrl = user['avatar']?.toString();

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      // CRITICAL FIX: Direct CustomImageWidget usage like in DashboardHeaderWidget
      return CustomImageWidget(
        imageUrl: avatarUrl,
        width: 22.w,
        height: 22.w,
        fit: BoxFit.cover,
        errorWidget: _buildFallbackAvatar(userName),
      );
    } else {
      return _buildFallbackAvatar(userName);
    }
  }

  // CRITICAL FIX: Better fallback avatar with user initials and increased size
  Widget _buildFallbackAvatar(String userName) {
    final String initials = _getInitials(userName);
    final Color backgroundColor = _getAvatarColor(userName);

    return Container(
      width: 22
          .w, // CRITICAL FIX: Increased from 20.w to 22.w for better visibility
      height: 22
          .w, // CRITICAL FIX: Increased from 20.w to 22.w for better visibility
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize:
                20.sp, // CRITICAL FIX: Increased font size for larger avatar
          ),
        ),
      ),
    );
  }

  // CRITICAL FIX: Extract meaningful initials from name
  String _getInitials(String name) {
    if (name.isEmpty) return 'U';

    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    } else {
      return parts
          .take(2)
          .map((part) => part.isNotEmpty ? part[0].toUpperCase() : '')
          .where((initial) => initial.isNotEmpty)
          .join();
    }
  }

  // CRITICAL FIX: Generate consistent colors based on name
  Color _getAvatarColor(String name) {
    final colors = [
      AppTheme.lightTheme.colorScheme.primary,
      AppTheme.lightTheme.colorScheme.secondary,
      AppTheme.lightTheme.colorScheme.tertiary,
      Colors.indigo,
      Colors.teal,
      Colors.orange,
      Colors.purple,
      Colors.pink,
    ];

    final hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    // CRITICAL FIX: Add cache-busting key based on user data
    final cacheKey =
        '${user['name']}_${user['avatar']}_${user['lastUpdated'] ?? DateTime.now().millisecondsSinceEpoch}';

    return Container(
      key: ValueKey(cacheKey), // Force rebuild when user data changes
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // CRITICAL FIX: Enhanced user avatar section with proper data binding
          Column(
            children: [
              // Profile image - tap to enlarge
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  // Show enlarged image
                  EnlargedProfileImageWidget.show(
                    context,
                    user['avatar']?.toString(),
                    user['name']?.toString(),
                  );
                },
                child: Container(
                  key: ValueKey('user_avatar_$cacheKey'),
                  width: 22.w,
                  height: 22.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(child: _buildUserAvatar()),
                ),
              ),
              SizedBox(height: 1.5.h),
              // CRITICAL FIX: Enhanced user name display with proper data binding
              Container(
                key: ValueKey('user_name_$cacheKey'),
                constraints: BoxConstraints(maxWidth: 25.w),
                child: Text(
                  user['name']?.toString() ?? 'User',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ],
          ),

          SizedBox(width: 6.w),

          // CRITICAL FIX: Enhanced stats section with forced updates
          Expanded(
            child: Container(
              key: ValueKey('user_stats_$cacheKey'),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    'Total Groups',
                    user['totalGroups']?.toString() ?? '0',
                    Icons.groups,
                  ),
                  _buildDivider(),
                  _buildStatItem(
                    'Active',
                    user['activeGroups']?.toString() ?? '0',
                    Icons.check_circle,
                  ),
                  _buildDivider(),
                  _buildStatItem(
                    'Closed',
                    user['closedGroups']?.toString() ?? '0',
                    Icons.archive,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: AppTheme.lightTheme.colorScheme.primary,
          size: 24, // CRITICAL FIX: Increased icon size from 20 to 24
        ),
        SizedBox(height: 0.8.h),
        // CRITICAL FIX: Significantly increased font size for stat values
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppTheme.lightTheme.colorScheme.primary,
            fontSize: 22
                .sp, // CRITICAL FIX: Increased from headlineSmall to much larger
          ),
        ),
        SizedBox(height: 0.3.h),
        // CRITICAL FIX: Increased font size for stat labels
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize:
                11.sp, // CRITICAL FIX: Increased from bodySmall to bodyMedium
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 7.h, // CRITICAL FIX: Increased height to match larger content
      width: 1,
      color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
    );
  }
}
