import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MemberAttendanceWidget extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final Function(Map<String, dynamic> member) onMemberTap;

  const MemberAttendanceWidget({
    Key? key,
    required this.members,
    required this.onMemberTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'people',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 24,
                ),
                SizedBox(width: 3.w),
                Text(
                  "Member Attendance",
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // Members content
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              children: [
                // Attendance summary
                _buildAttendanceSummary(),

                SizedBox(height: 3.h),

                // Members grid
                _buildMembersGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSummary() {
    int approvedCount = 0;
    int declinedCount = 0;
    int pendingCount = 0;

    for (final member in members) {
      final status = member["approvalStatus"] as String?;
      switch (status) {
        case "approved":
          approvedCount++;
          break;
        case "declined":
          declinedCount++;
          break;
        default:
          pendingCount++;
      }
    }

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            "Approved",
            approvedCount.toString(),
            AppTheme.lightTheme.colorScheme.secondary,
            Icons.check_circle,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildSummaryCard(
            "Declined",
            declinedCount.toString(),
            AppTheme.lightTheme.colorScheme.error,
            Icons.cancel,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildSummaryCard(
            "Pending",
            pendingCount.toString(),
            AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            Icons.schedule,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String label, String count, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          SizedBox(height: 1.h),
          Text(
            count,
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 2.h,
        childAspectRatio: 2.5,
      ),
      itemCount: members.length,
      itemBuilder: (context, index) {
        return _buildMemberCard(members[index]);
      },
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final name = member["name"] as String? ?? "Unknown";
    final avatar = member["avatar"] as String? ?? "";
    final status = member["approvalStatus"] as String?;
    final phone = member["phone"] as String? ?? "";

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case "approved":
        statusColor = AppTheme.lightTheme.colorScheme.secondary;
        statusIcon = Icons.check_circle;
        statusText = "Approved";
        break;
      case "declined":
        statusColor = AppTheme.lightTheme.colorScheme.error;
        statusIcon = Icons.cancel;
        statusText = "Declined";
        break;
      default:
        statusColor = AppTheme.lightTheme.colorScheme.onSurfaceVariant;
        statusIcon = Icons.schedule;
        statusText = "Pending";
    }

    return GestureDetector(
      onTap: () => onMemberTap(member),
      onLongPress: () {
        // Show contact options
        _showContactOptions(member);
      },
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            // Avatar with status indicator
            Stack(
              children: [
                Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.1),
                  ),
                  child: avatar.isNotEmpty
                      ? ClipOval(
                          child: CustomImageWidget(
                            imageUrl: avatar,
                            width: 12.w,
                            height: 12.w,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : "?",
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),

                // Status indicator
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 5.w,
                    height: 5.w,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.lightTheme.colorScheme.surface,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      statusIcon,
                      color: AppTheme.lightTheme.colorScheme.surface,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(width: 3.w),

            // Member info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    statusText,
                    style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactOptions(Map<String, dynamic> member) {
    // This would typically show a bottom sheet or dialog with contact options
    // For now, we'll just print the member info
    print("Contact options for: ${member["name"]}");
    print("Phone: ${member["phone"]}");
  }
}
