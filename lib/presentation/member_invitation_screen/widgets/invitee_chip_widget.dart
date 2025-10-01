import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class InviteeChipWidget extends StatelessWidget {
  final Map<String, dynamic> invitee;
  final VoidCallback onRemove;

  const InviteeChipWidget({
    Key? key,
    required this.invitee,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String displayName = invitee['name'] ?? invitee['phone'] ?? '';
    final String status = invitee['status'] ?? 'pending';

    Color statusColor = AppTheme.lightTheme.colorScheme.onSurfaceVariant;
    switch (status) {
      case 'sent':
        statusColor = AppTheme.lightTheme.colorScheme.primary;
        break;
      case 'delivered':
        statusColor = AppTheme.lightTheme.colorScheme.secondary;
        break;
      case 'joined':
        statusColor = AppTheme.lightTheme.colorScheme.secondary;
        break;
      case 'failed':
        statusColor = AppTheme.lightTheme.colorScheme.error;
        break;
    }

    return Container(
      margin: EdgeInsets.only(right: 2.w, bottom: 1.h),
      child: Chip(
        avatar: status != 'pending'
            ? CircleAvatar(
                backgroundColor: statusColor.withValues(alpha: 0.2),
                radius: 8,
                child: CustomIconWidget(
                  iconName: status == 'joined'
                      ? 'check'
                      : status == 'failed'
                          ? 'close'
                          : 'schedule',
                  color: statusColor,
                  size: 12,
                ),
              )
            : null,
        label: Text(
          displayName,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        deleteIcon: CustomIconWidget(
          iconName: 'close',
          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          size: 16,
        ),
        onDeleted: onRemove,
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        side: BorderSide(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.5),
          width: 1.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
      ),
    );
  }
}
