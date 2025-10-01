import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PhoneInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final String countryCode;
  final Function(bool) onValidationChanged;
  final String? errorText;

  const PhoneInputWidget({
    Key? key,
    required this.controller,
    required this.countryCode,
    required this.onValidationChanged,
    this.errorText,
  }) : super(key: key);

  @override
  State<PhoneInputWidget> createState() => _PhoneInputWidgetState();
}

class _PhoneInputWidgetState extends State<PhoneInputWidget> {
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_validatePhone);
  }

  void _validatePhone() {
    final phoneNumber = widget.controller.text.replaceAll(RegExp(r'[^\d]'), '');
    bool isValid = false;

    if (widget.countryCode == '+1') {
      // US/Canada: 10 digits
      isValid = phoneNumber.length == 10;
    } else {
      // Other countries: 7-15 digits
      isValid = phoneNumber.length >= 7 && phoneNumber.length <= 15;
    }

    if (_isValid != isValid) {
      setState(() {
        _isValid = isValid;
      });
      widget.onValidationChanged(isValid);
    }
  }

  String _formatPhoneNumber(String value) {
    final phoneNumber = value.replaceAll(RegExp(r'[^\d]'), '');

    if (widget.countryCode == '+1') {
      // US format: (123) 456-7890
      if (phoneNumber.length >= 6) {
        return '(${phoneNumber.substring(0, 3)}) ${phoneNumber.substring(3, 6)}-${phoneNumber.substring(6)}';
      } else if (phoneNumber.length >= 3) {
        return '(${phoneNumber.substring(0, 3)}) ${phoneNumber.substring(3)}';
      } else if (phoneNumber.isNotEmpty) {
        return '(${phoneNumber}';
      }
    } else {
      // International format: add spaces every 3-4 digits
      if (phoneNumber.length > 4) {
        return phoneNumber.replaceAllMapped(
          RegExp(r'(\d{3,4})(?=\d)'),
          (match) => '${match.group(0)} ',
        );
      }
    }

    return phoneNumber;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: widget.errorText != null
                  ? AppTheme.lightTheme.colorScheme.error
                  : _isValid
                      ? AppTheme.lightTheme.colorScheme.secondary
                      : AppTheme.lightTheme.colorScheme.outline,
              width: _isValid ? 2.0 : 1.0,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(
                widget.countryCode == '+1' ? 10 : 15,
              ),
              TextInputFormatter.withFunction((oldValue, newValue) {
                final formatted = _formatPhoneNumber(newValue.text);
                return TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }),
            ],
            decoration: InputDecoration(
              hintText: widget.countryCode == '+1'
                  ? '(123) 456-7890'
                  : 'Enter phone number',
              hintStyle: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.6),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 4.w,
                vertical: 2.h,
              ),
              suffixIcon: _isValid
                  ? CustomIconWidget(
                      iconName: 'check_circle',
                      color: AppTheme.lightTheme.colorScheme.secondary,
                      size: 20,
                    )
                  : null,
            ),
            style: AppTheme.lightTheme.textTheme.bodyLarge,
          ),
        ),
        if (widget.errorText != null) ...[
          SizedBox(height: 1.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: Text(
              widget.errorText!,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.error,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_validatePhone);
    super.dispose();
  }
}
