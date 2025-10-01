import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class AmountInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final String? errorText;
  final String selectedCurrency;
  final String currencySymbol;

  const AmountInputWidget({
    Key? key,
    required this.controller,
    required this.onChanged,
    this.errorText,
    required this.selectedCurrency,
    required this.currencySymbol,
  }) : super(key: key);

  @override
  State<AmountInputWidget> createState() => _AmountInputWidgetState();
}

class _AmountInputWidgetState extends State<AmountInputWidget> {
  late List<double> _quickAmounts;
  late FocusNode _focusNode;
  bool _isManuallyEditing = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _updateQuickAmounts();

    // Add listener to detect when user is manually editing
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _isManuallyEditing = true;
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AmountInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCurrency != widget.selectedCurrency) {
      _updateQuickAmounts();
      // Clear the field when currency changes to prevent symbol conflicts
      if (widget.controller.text.isNotEmpty) {
        widget.controller.clear();
        _isManuallyEditing = false;
      }
    }
  }

  void _updateQuickAmounts() {
    // Different quick amounts for different currencies
    if (widget.selectedCurrency == 'INR') {
      _quickAmounts = [100.0, 500.0, 1000.0, 2000.0];
    } else {
      _quickAmounts = [10.0, 25.0, 50.0, 100.0];
    }
  }

  void _selectQuickAmount(double amount) {
    _isManuallyEditing = false;
    final formattedAmount = amount.toStringAsFixed(2);
    widget.controller.text = formattedAmount;
    widget.onChanged(formattedAmount);
    // Remove focus to prevent immediate editing mode
    _focusNode.unfocus();
  }

  String _cleanInput(String input) {
    // Remove all currency symbols and non-numeric characters except decimal point
    return input.replaceAll(RegExp(r'[^\d.]'), '');
  }

  String _formatDisplayValue(String value) {
    if (value.isEmpty) return '';

    final cleanValue = _cleanInput(value);
    if (cleanValue.isEmpty) return '';

    final double? amount = double.tryParse(cleanValue);
    if (amount == null) return '';

    return '${widget.currencySymbol}${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick amount buttons
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Amount',
                style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 1.h),
              Row(
                children: _quickAmounts.map((amount) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: 2.w),
                      child: GestureDetector(
                        onTap: () => _selectQuickAmount(amount),
                        child: Container(
                          height: 5.h,
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.lightTheme.colorScheme.primary
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${widget.currencySymbol}${amount.toInt()}',
                              style: AppTheme.lightTheme.textTheme.labelLarge
                                  ?.copyWith(
                                color: AppTheme.lightTheme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),

        // Amount input field
        Container(
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.errorText != null
                  ? AppTheme.lightTheme.colorScheme.error
                  : AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.3),
            ),
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              // Custom formatter that preserves cursor position during manual editing
              TextInputFormatter.withFunction((oldValue, newValue) {
                // Allow empty input
                if (newValue.text.isEmpty) {
                  _isManuallyEditing = false;
                  return newValue;
                }

                // Clean the input to get only numbers and decimal point
                final cleanText = _cleanInput(newValue.text);

                // If user is manually editing, don't format until they're done
                if (_isManuallyEditing && _focusNode.hasFocus) {
                  // Just return the clean input without currency formatting
                  return TextEditingValue(
                    text: cleanText,
                    selection: TextSelection.collapsed(
                      offset: cleanText.length.clamp(0, cleanText.length),
                    ),
                  );
                }

                // Format with currency symbol when not actively editing
                final formatted = _formatDisplayValue(cleanText);
                return TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }),
            ],
            onChanged: (value) {
              // Pass the clean numeric value to the parent
              final cleanValue = _cleanInput(value);
              widget.onChanged(cleanValue.isNotEmpty ? cleanValue : '0');
            },
            onEditingComplete: () {
              // Format the value when user finishes editing
              _isManuallyEditing = false;
              final currentText = widget.controller.text;
              final formatted = _formatDisplayValue(currentText);
              if (formatted != currentText && formatted.isNotEmpty) {
                widget.controller.text = formatted;
              }
            },
            onTapOutside: (event) {
              // Format the value when user taps outside
              _isManuallyEditing = false;
              final currentText = widget.controller.text;
              final formatted = _formatDisplayValue(currentText);
              if (formatted != currentText && formatted.isNotEmpty) {
                widget.controller.text = formatted;
              }
              _focusNode.unfocus();
            },
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: 'Amount',
              hintText: '${widget.currencySymbol}0.00',
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: Text(
                  widget.currencySymbol,
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              errorText: widget.errorText,
              errorStyle: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.error,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
