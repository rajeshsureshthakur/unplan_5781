import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class OtpInputWidget extends StatefulWidget {
  final Function(String) onCompleted;
  final Function(String) onChanged;
  final bool hasError;
  final VoidCallback onClearError;

  const OtpInputWidget({
    Key? key,
    required this.onCompleted,
    required this.onChanged,
    this.hasError = false,
    required this.onClearError,
  }) : super(key: key);

  @override
  State<OtpInputWidget> createState() => _OtpInputWidgetState();
}

class _OtpInputWidgetState extends State<OtpInputWidget>
    with SingleTickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    // Auto-focus on widget creation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    // Listen for clipboard changes to auto-paste OTP
    _setupClipboardListener();
  }

  void _setupClipboardListener() {
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _checkClipboardForOtp();
      }
    });
  }

  Future<void> _checkClipboardForOtp() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null) {
        final text = clipboardData!.text!.replaceAll(RegExp(r'[^0-9]'), '');
        if (text.length == 6) {
          _pinController.text = text;
          widget.onCompleted(text);
          _provideFeedback();
        }
      }
    } catch (e) {
      // Ignore clipboard errors
    }
  }

  void _provideFeedback() {
    HapticFeedback.lightImpact();
  }

  void _triggerShakeAnimation() {
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
  }

  @override
  void didUpdateWidget(OtpInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError && !oldWidget.hasError) {
      _triggerShakeAnimation();
      _pinController.clear();
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 12.w,
      height: 12.w,
      textStyle: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: AppTheme.lightTheme.colorScheme.onSurface,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: widget.hasError
              ? AppTheme.lightTheme.colorScheme.error
              : AppTheme.lightTheme.colorScheme.outline,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
        color: AppTheme.lightTheme.colorScheme.surface,
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(
          color: widget.hasError
              ? AppTheme.lightTheme.colorScheme.error
              : AppTheme.lightTheme.colorScheme.primary,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.hasError
                ? AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.2)
                : AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(
          color: widget.hasError
              ? AppTheme.lightTheme.colorScheme.error
              : AppTheme.lightTheme.colorScheme.primary,
          width: 1.5,
        ),
        color: widget.hasError
            ? AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.1)
            : AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
      ),
    );

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: Column(
            children: [
              Pinput(
                controller: _pinController,
                focusNode: _focusNode,
                length: 6,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                submittedPinTheme: submittedPinTheme,
                showCursor: true,
                cursor: Container(
                  width: 2,
                  height: 20,
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                hapticFeedbackType: HapticFeedbackType.lightImpact,
                onChanged: (value) {
                  if (widget.hasError) {
                    widget.onClearError();
                  }
                  widget.onChanged(value);
                },
                onCompleted: (value) {
                  _provideFeedback();
                  widget.onCompleted(value);
                },
                errorBuilder: (errorText, pin) {
                  return Padding(
                    padding: EdgeInsets.only(top: 1.h),
                    child: Text(
                      errorText ?? '',
                      style: TextStyle(
                        color: AppTheme.lightTheme.colorScheme.error,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  );
                },
              ),
              if (widget.hasError)
                Padding(
                  padding: EdgeInsets.only(top: 1.h),
                  child: Text(
                    'Invalid code. Please try again.',
                    style: TextStyle(
                      color: AppTheme.lightTheme.colorScheme.error,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
