import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CountryCodeSelectorWidget extends StatelessWidget {
  final String selectedCountryCode;
  final String selectedCountryFlag;
  final String selectedCountryName;
  final VoidCallback onTap;

  const CountryCodeSelectorWidget({
    Key? key,
    required this.selectedCountryCode,
    required this.selectedCountryFlag,
    required this.selectedCountryName,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.lightTheme.colorScheme.outline,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(12.0),
          color: AppTheme.lightTheme.colorScheme.surface,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedCountryFlag,
              style: TextStyle(fontSize: 16.sp),
            ),
            SizedBox(width: 2.w),
            Text(
              selectedCountryCode,
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 1.w),
            CustomIconWidget(
              iconName: 'keyboard_arrow_down',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
