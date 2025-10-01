import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class RecentInvitationsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> recentInvitations;
  final Function(Map<String, dynamic>) onResend;

  const RecentInvitationsWidget({
    Key? key,
    required this.recentInvitations,
    required this.onResend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (recentInvitations.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Invitations',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: recentInvitations.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.2),
              ),
              itemBuilder: (context, index) {
                final invitation = recentInvitations[index];
                final String displayName =
                    invitation['name'] ?? invitation['phone'] ?? '';
                final String status = invitation['status'] ?? 'pending';
                final DateTime sentAt = invitation['sentAt'] ?? DateTime.now();

                Color statusColor =
                    AppTheme.lightTheme.colorScheme.onSurfaceVariant;
                String statusText = status.toUpperCase();

                switch (status) {
                  case 'sent':
                    statusColor = AppTheme.lightTheme.colorScheme.primary;
                    break;
                  case 'delivered':
                    statusColor = AppTheme.lightTheme.colorScheme.secondary;
                    break;
                  case 'joined':
                    statusColor = AppTheme.lightTheme.colorScheme.secondary;
                    statusText = 'JOINED';
                    break;
                  case 'failed':
                    statusColor = AppTheme.lightTheme.colorScheme.error;
                    statusText = 'FAILED';
                    break;
                }

                return ListTile(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withValues(alpha: 0.1),
                    child: CustomIconWidget(
                      iconName: status == 'joined'
                          ? 'check_circle'
                          : status == 'failed'
                              ? 'error'
                              : 'schedule',
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    displayName,
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${_formatTime(sentAt)} • $statusText',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: status == 'failed'
                      ? TextButton(
                          onPressed: () => onResend(invitation),
                          child: Text(
                            'Resend',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
