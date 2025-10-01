import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class EmptyStateWidget extends StatelessWidget {
  final VoidCallback onCreateGroup;

  const EmptyStateWidget({
    Key? key,
    required this.onCreateGroup,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // CRITICAL FIX: Add illustration instead of just icon
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.1),
              ),
              child: Center(
                child: Icon(
                  Icons.groups_outlined,
                  size: 20.w,
                  color: AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.7),
                ),
              ),
            ),

            SizedBox(height: 4.h),

            Text(
              'No Groups Yet',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),

            SizedBox(height: 2.h),

            Text(
              'Create your first group to start planning events and managing expenses with friends.',
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 4.h),

            // CRITICAL FIX: Add prominent create group button
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                onCreateGroup();
              },
              icon: Icon(Icons.add),
              label: Text('Create Your First Group'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),

            SizedBox(height: 2.h),

            // CRITICAL FIX: Add secondary helpful text
            Text(
              'Groups help you organize events, split expenses, and stay connected with your friends.',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
