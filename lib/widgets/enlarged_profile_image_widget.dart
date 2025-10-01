import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';

class EnlargedProfileImageWidget extends StatelessWidget {
  final String? imageUrl;
  final String? userName;

  const EnlargedProfileImageWidget({
    Key? key,
    required this.imageUrl,
    this.userName,
  }) : super(key: key);

  static void show(BuildContext context, String? imageUrl, String? userName) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder:
          (BuildContext context) => EnlargedProfileImageWidget(
            imageUrl: imageUrl,
            userName: userName,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(4.w),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background tap to close
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
            ),
          ),

          // Image container
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    margin: EdgeInsets.only(bottom: 2.h),
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: Colors.white, size: 6.w),
                  ),
                ),
              ),

              // Large circular image
              Container(
                width: 70.w,
                height: 70.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipOval(
                  child:
                      imageUrl != null && imageUrl!.isNotEmpty
                          ? CustomImageWidget(
                            imageUrl: imageUrl!,
                            height: 70.w,
                            width: 70.w,
                            fit: BoxFit.cover,
                            errorWidget: Container(
                              color: AppTheme.lightTheme.colorScheme.primary
                                  .withValues(alpha: 0.2),
                              child: Center(
                                child: Text(
                                  (userName?.isNotEmpty == true)
                                      ? userName![0].toUpperCase()
                                      : '?',
                                  style: AppTheme
                                      .lightTheme
                                      .textTheme
                                      .headlineLarge
                                      ?.copyWith(
                                        color:
                                            AppTheme
                                                .lightTheme
                                                .colorScheme
                                                .primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 32.sp,
                                      ),
                                ),
                              ),
                            ),
                          )
                          : Container(
                            color: AppTheme.lightTheme.colorScheme.primary
                                .withValues(alpha: 0.2),
                            child: Center(
                              child: Text(
                                (userName?.isNotEmpty == true)
                                    ? userName![0].toUpperCase()
                                    : '?',
                                style: AppTheme
                                    .lightTheme
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(
                                      color:
                                          AppTheme
                                              .lightTheme
                                              .colorScheme
                                              .primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 32.sp,
                                    ),
                              ),
                            ),
                          ),
                ),
              ),

              // Name below image
              if (userName?.isNotEmpty == true) ...[
                SizedBox(height: 3.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    userName!,
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
