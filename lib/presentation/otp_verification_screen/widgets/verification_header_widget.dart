import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class VerificationHeaderWidget extends StatelessWidget {
  const VerificationHeaderWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo/Icon
        Container(
          width: 20.w,
          height: 20.w,
          decoration: BoxDecoration(
            color:
                AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: CustomIconWidget(
            iconName: 'security',
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 10.w,
          ),
        ),
        SizedBox(height: 3.h),

        // Title
        Text(
          'Verify Your Phone',
          style: TextStyle(
            color: AppTheme.lightTheme.colorScheme.onSurface,
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 1.h),

        // Subtitle
        Text(
          'Enter the 6-digit code we sent to your phone number',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            fontSize: 16.sp,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
