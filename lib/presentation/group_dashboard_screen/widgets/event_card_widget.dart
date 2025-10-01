import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class EventCardWidget extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback? onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const EventCardWidget({
    Key? key,
    required this.event,
    this.onTap,
    this.onApprove,
    this.onReject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isUpcoming = (event['date'] as DateTime).isAfter(DateTime.now());
    final String approvalStatus = event['approvalStatus'] ?? 'pending';
    final int approvalCount = event['approvalCount'] ?? 0;
    final int totalMembers = event['totalMembers'] ?? 1;
    final int denialCount = totalMembers - approvalCount;

    // Calculate dynamic background color based on approvals/denials
    Color backgroundColor = AppTheme.lightTheme.colorScheme.surface;

    if (isUpcoming && approvalStatus != 'rejected') {
      final double approvalRatio = approvalCount / totalMembers;
      final double denialRatio = denialCount / totalMembers;

      if (approvalRatio >= 0.7) {
        // High approval rate - green background
        backgroundColor = Colors.green.withValues(alpha: 0.1);
      } else if (denialRatio >= 0.5) {
        // High denial rate - amber background
        backgroundColor = Colors.amber.withValues(alpha: 0.1);
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(
              approvalCount, totalMembers, isUpcoming, approvalStatus),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event['title'] ?? 'Untitled Event',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'calendar_today',
                              size: 16,
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              _formatDate(event['date'] as DateTime),
                              style: AppTheme.lightTheme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        if (event['venue'] != null) ...[
                          SizedBox(height: 0.5.h),
                          Row(
                            children: [
                              CustomIconWidget(
                                iconName: 'location_on',
                                size: 16,
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                              ),
                              SizedBox(width: 2.w),
                              Expanded(
                                child: Text(
                                  event['venue'],
                                  style:
                                      AppTheme.lightTheme.textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 3.w),
                  _buildStatusIndicator(approvalStatus, isUpcoming),
                ],
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'people',
                          size: 16,
                          color: AppTheme.lightTheme.colorScheme.primary,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          '$approvalCount/$totalMembers approved',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isUpcoming && approvalStatus == 'pending') ...[
                    GestureDetector(
                      onTap: onReject,
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.error
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CustomIconWidget(
                          iconName: 'thumb_down',
                          size: 20,
                          color: AppTheme.lightTheme.colorScheme.error,
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    GestureDetector(
                      onTap: onApprove,
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.primary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CustomIconWidget(
                          iconName: 'thumb_up',
                          size: 20,
                          color: AppTheme.lightTheme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBorderColor(int approvalCount, int totalMembers, bool isUpcoming,
      String approvalStatus) {
    if (!isUpcoming || approvalStatus == 'rejected') {
      return AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2);
    }

    final double approvalRatio = approvalCount / totalMembers;
    final int denialCount = totalMembers - approvalCount;
    final double denialRatio = denialCount / totalMembers;

    if (approvalRatio >= 0.7) {
      return Colors.green.withValues(alpha: 0.3);
    } else if (denialRatio >= 0.5) {
      return Colors.amber.withValues(alpha: 0.3);
    }

    return AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2);
  }

  Widget _buildStatusIndicator(String status, bool isUpcoming) {
    Color color;
    String text;
    IconData icon;

    if (!isUpcoming) {
      color = AppTheme.lightTheme.colorScheme.onSurfaceVariant;
      text = 'Past';
      icon = Icons.history;
    } else {
      switch (status) {
        case 'approved':
          color = AppTheme.lightTheme.colorScheme.primary;
          text = 'Approved';
          icon = Icons.check_circle;
          break;
        case 'rejected':
          color = AppTheme.lightTheme.colorScheme.error;
          text = 'Rejected';
          icon = Icons.cancel;
          break;
        default:
          color = AppTheme.lightTheme.colorScheme.tertiary;
          text = 'Pending';
          icon = Icons.schedule;
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 1.w),
          Text(
            text,
            style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference == 1) {
      return 'Tomorrow ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference > 1 && difference <= 7) {
      return '${_getDayName(date.weekday)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
