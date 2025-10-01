import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class GroupDescriptionInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;

  const GroupDescriptionInputWidget({
    Key? key,
    required this.controller,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description (Optional)',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.outline,
              width: 1.5,
            ),
          ),
          child: TextFormField(
            controller: controller,
            onChanged: onChanged,
            maxLength: 150,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add a description for your group',
              prefixIcon: Padding(
                padding: EdgeInsets.only(
                  left: 3.w,
                  right: 3.w,
                  top: 2.h,
                ),
                child: CustomIconWidget(
                  iconName: 'description',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 20,
                ),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 4.w,
                vertical: 2.h,
              ),
              counterStyle: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            style: AppTheme.lightTheme.textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}
