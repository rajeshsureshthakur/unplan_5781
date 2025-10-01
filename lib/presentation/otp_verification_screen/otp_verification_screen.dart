import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/otp_input_widget.dart';
import './widgets/phone_display_widget.dart';
import './widgets/resend_timer_widget.dart';
import './widgets/verification_header_widget.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({Key? key}) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with TickerProviderStateMixin {
  String _otpCode = '';
  bool _isVerifying = false;
  bool _hasError = false;
  bool _isResending = false;
  late AnimationController _successController;
  late Animation<double> _successAnimation;

  String _phoneNumber = '+1 (555) 123-4567'; // Default fallback

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    // Get phone number from route arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['phoneNumber'] != null) {
        setState(() {
          _phoneNumber = args['phoneNumber'] as String;
        });
      }
    });
  }

  void _setupAnimations() {
    _successController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _successAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    ));
  }

  void _onOtpChanged(String value) {
    setState(() {
      _otpCode = value;
      if (_hasError) {
        _hasError = false;
      }
    });
  }

  void _onOtpCompleted(String value) {
    setState(() {
      _otpCode = value;
    });
    _verifyOtp();
  }

  void _clearError() {
    setState(() {
      _hasError = false;
    });
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) return;

    setState(() {
      _isVerifying = true;
      _hasError = false;
    });

    try {
      // Simulate Firebase OTP verification
      await Future.delayed(const Duration(seconds: 2));

      // Mock verification logic - accept any 6-digit code for test purposes
      // In real app, use Firebase Auth verification
      if (_otpCode.length == 6) {
        // Success case - accept any valid 6-digit OTP
        await _showSuccessAnimation();
        _navigateToNextScreen();
      } else {
        // Error case
        setState(() {
          _hasError = true;
          _isVerifying = false;
        });
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isVerifying = false;
      });
      _showErrorSnackBar('Verification failed. Please try again.');
    }
  }

  Future<void> _showSuccessAnimation() async {
    HapticFeedback.heavyImpact();
    await _successController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _navigateToNextScreen() {
    // Navigate to home dashboard instead of profile setup
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home-dashboard-screen',
      (route) => false,
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(4.w),
      ),
    );
  }

  Future<void> _resendCode() async {
    setState(() {
      _isResending = true;
    });

    try {
      // Simulate resending OTP
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isResending = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Verification code sent successfully'),
          backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(4.w),
        ),
      );
    } catch (e) {
      setState(() {
        _isResending = false;
      });
      _showErrorSnackBar('Failed to resend code. Please try again.');
    }
  }

  void _editPhoneNumber() {
    Navigator.pushReplacementNamed(context, '/phone-authentication-screen');
  }

  @override
  void dispose() {
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Column(
                children: [
                  SizedBox(height: 2.h),

                  // Back button
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: CustomIconWidget(
                          iconName: 'arrow_back',
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                          size: 24,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              AppTheme.lightTheme.colorScheme.surface,
                          padding: EdgeInsets.all(3.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4.h),

                  // Header
                  const VerificationHeaderWidget(),

                  SizedBox(height: 4.h),

                  // Phone display
                  PhoneDisplayWidget(
                    phoneNumber: _phoneNumber,
                    onEditPhone: _editPhoneNumber,
                  ),

                  SizedBox(height: 4.h),

                  // OTP Input
                  OtpInputWidget(
                    onCompleted: _onOtpCompleted,
                    onChanged: _onOtpChanged,
                    hasError: _hasError,
                    onClearError: _clearError,
                  ),

                  SizedBox(height: 4.h),

                  // Resend timer
                  ResendTimerWidget(
                    onResend: _resendCode,
                    isLoading: _isResending,
                  ),

                  SizedBox(height: 4.h),

                  // Verify button
                  SizedBox(
                    width: double.infinity,
                    height: 7.h,
                    child: ElevatedButton(
                      onPressed: (_otpCode.length == 6 && !_isVerifying)
                          ? _verifyOtp
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppTheme.lightTheme.colorScheme.primary,
                        foregroundColor:
                            AppTheme.lightTheme.colorScheme.onPrimary,
                        disabledBackgroundColor: AppTheme
                            .lightTheme.colorScheme.outline
                            .withValues(alpha: 0.3),
                        elevation: _otpCode.length == 6 ? 2 : 0,
                        shadowColor: AppTheme.lightTheme.colorScheme.primary
                            .withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isVerifying
                          ? SizedBox(
                              width: 6.w,
                              height: 6.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.lightTheme.colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : Text(
                              'Verify',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Wrong number link
                  TextButton(
                    onPressed: _editPhoneNumber,
                    style: TextButton.styleFrom(
                      foregroundColor:
                          AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      padding: EdgeInsets.symmetric(
                          horizontal: 4.w, vertical: 1.5.h),
                    ),
                    child: Text(
                      'Wrong number?',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),

                  SizedBox(height: 2.h),
                ],
              ),
            ),

            // Success animation overlay
            if (_successController.isAnimating)
              AnimatedBuilder(
                animation: _successAnimation,
                builder: (context, child) {
                  return Container(
                    color: AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: _successAnimation.value * 0.9),
                    child: Center(
                      child: Transform.scale(
                        scale: _successAnimation.value,
                        child: Container(
                          width: 20.w,
                          height: 20.w,
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: CustomIconWidget(
                            iconName: 'check_circle',
                            color: AppTheme.lightTheme.colorScheme.secondary,
                            size: 12.w,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
