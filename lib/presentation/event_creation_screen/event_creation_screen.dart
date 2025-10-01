import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/approval_toggle_widget.dart';
import './widgets/date_time_picker_widget.dart';
import './widgets/form_field_widget.dart';

class EventCreationScreen extends StatefulWidget {
  const EventCreationScreen({Key? key}) : super(key: key);

  @override
  State<EventCreationScreen> createState() => _EventCreationScreenState();
}

class _EventCreationScreenState extends State<EventCreationScreen>
    with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _requiresApproval = false;
  bool _isLoading = false;

  String? _titleError;
  String? _dateError;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();

    _titleController.addListener(_validateTitle);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _venueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _validateTitle() {
    setState(() {
      if (_titleController.text.isEmpty) {
        _titleError = 'Event title is required';
      } else if (_titleController.text.length > 50) {
        _titleError = 'Title must be 50 characters or less';
      } else {
        _titleError = null;
      }
    });
  }

  void _validateDate() {
    setState(() {
      if (_selectedDate == null) {
        _dateError = 'Event date is required';
      } else if (_selectedDate!
          .isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
        _dateError = 'Event date cannot be in the past';
      } else {
        _dateError = null;
      }
    });
  }

  bool get _isFormValid {
    return _titleController.text.isNotEmpty &&
        _titleController.text.length <= 50 &&
        _selectedDate != null &&
        !_selectedDate!
            .isBefore(DateTime.now().subtract(const Duration(days: 1)));
  }

  Future<void> _createEvent() async {
    if (!_isFormValid) {
      _validateTitle();
      _validateDate();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call to create event
      await Future.delayed(const Duration(seconds: 2));

      // Show success feedback
      HapticFeedback.lightImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                CustomIconWidget(
                  iconName: 'check_circle',
                  color: AppTheme.lightTheme.colorScheme.onPrimary,
                  size: 20,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    'Event "${_titleController.text}" created successfully!',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.lightTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate back to group dashboard
        Navigator.pop(context, {
          'title': _titleController.text,
          'date': _selectedDate,
          'time': _selectedTime,
          'venue': _venueController.text,
          'notes': _notesController.text,
          'requiresApproval': _requiresApproval,
          'createdAt': DateTime.now(),
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                CustomIconWidget(
                  iconName: 'error_outline',
                  color: AppTheme.lightTheme.colorScheme.onError,
                  size: 20,
                ),
                SizedBox(width: 3.w),
                const Expanded(
                  child: Text('Failed to create event. Please try again.'),
                ),
              ],
            ),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName: 'close',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 24,
          ),
        ),
        title: Text(
          'Create Event',
          style: AppTheme.lightTheme.appBarTheme.titleTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: _isFormValid && !_isLoading ? _createEvent : null,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.lightTheme.primaryColor,
                      ),
                    ),
                  )
                : Text(
                    'Create',
                    style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                      color: _isFormValid
                          ? AppTheme.lightTheme.primaryColor
                          : AppTheme.lightTheme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.lightTheme.primaryColor
                              .withValues(alpha: 0.1),
                          AppTheme.secondaryLight
                              .withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        CustomIconWidget(
                          iconName: 'event',
                          color: AppTheme.lightTheme.primaryColor,
                          size: 48,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Plan Your Next Adventure',
                          style: AppTheme.lightTheme.textTheme.headlineSmall
                              ?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Create an event and let your group know what\'s coming up',
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4.h),

                  // Event title field
                  FormFieldWidget(
                    label: 'Event Title',
                    hint: 'What are you planning?',
                    iconName: 'title',
                    controller: _titleController,
                    maxLength: 50,
                    isRequired: true,
                    errorText: _titleError,
                    onChanged: (value) => _validateTitle(),
                  ),
                  SizedBox(height: 3.h),

                  // Date and time picker
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Date & Time',
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            ' *',
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      DateTimePickerWidget(
                        selectedDate: _selectedDate,
                        selectedTime: _selectedTime,
                        onDateSelected: (date) {
                          setState(() {
                            _selectedDate = date;
                          });
                          _validateDate();
                        },
                        onTimeSelected: (time) {
                          setState(() {
                            _selectedTime = time;
                          });
                        },
                      ),
                      _dateError != null
                          ? Padding(
                              padding: EdgeInsets.only(top: 1.h),
                              child: Text(
                                _dateError!,
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppTheme.lightTheme.colorScheme.error,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                  SizedBox(height: 3.h),

                  // Venue field
                  FormFieldWidget(
                    label: 'Venue',
                    hint: 'Where will this happen?',
                    iconName: 'location_on',
                    controller: _venueController,
                    maxLength: 100,
                  ),
                  SizedBox(height: 3.h),

                  // Notes field
                  FormFieldWidget(
                    label: 'Notes',
                    hint: 'Any additional details or special instructions...',
                    iconName: 'notes',
                    controller: _notesController,
                    maxLength: 200,
                    maxLines: 3,
                  ),
                  SizedBox(height: 3.h),

                  // Approval toggle
                  ApprovalToggleWidget(
                    requiresApproval: _requiresApproval,
                    onToggleChanged: (value) {
                      setState(() {
                        _requiresApproval = value;
                      });
                    },
                  ),
                  SizedBox(height: 6.h),

                  // Create event button
                  Container(
                    width: double.infinity,
                    height: 7.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _isFormValid && !_isLoading
                          ? [
                              BoxShadow(
                                color: AppTheme.lightTheme.primaryColor
                                    .withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: ElevatedButton(
                      onPressed:
                          _isFormValid && !_isLoading ? _createEvent : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFormValid
                            ? AppTheme.lightTheme.primaryColor
                            : AppTheme.lightTheme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.3),
                        foregroundColor: _isFormValid
                            ? AppTheme.lightTheme.colorScheme.onPrimary
                            : AppTheme.lightTheme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                        elevation: _isFormValid ? 4 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.lightTheme.colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 3.w),
                                Text(
                                  'Creating Event...',
                                  style: AppTheme
                                      .lightTheme.textTheme.titleMedium
                                      ?.copyWith(
                                    color: AppTheme
                                        .lightTheme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomIconWidget(
                                  iconName: 'add_circle',
                                  color: _isFormValid
                                      ? AppTheme
                                          .lightTheme.colorScheme.onPrimary
                                      : AppTheme.lightTheme.colorScheme
                                          .onSurfaceVariant
                                          .withValues(alpha: 0.7),
                                  size: 24,
                                ),
                                SizedBox(width: 3.w),
                                Text(
                                  'Create Event',
                                  style: AppTheme
                                      .lightTheme.textTheme.titleMedium
                                      ?.copyWith(
                                    color: _isFormValid
                                        ? AppTheme
                                            .lightTheme.colorScheme.onPrimary
                                        : AppTheme.lightTheme.colorScheme
                                            .onSurfaceVariant
                                            .withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}