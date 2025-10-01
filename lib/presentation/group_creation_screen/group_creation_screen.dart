import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import './widgets/create_group_button_widget.dart';
import './widgets/group_description_input_widget.dart';
import './widgets/group_name_input_widget.dart';

class GroupCreationScreen extends StatefulWidget {
  const GroupCreationScreen({Key? key}) : super(key: key);

  @override
  State<GroupCreationScreen> createState() => _GroupCreationScreenState();
}

class _GroupCreationScreenState extends State<GroupCreationScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _groupNameFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();

  String? _groupNameError;
  bool _isLoading = false;
  List<Map<String, dynamic>> _invitedMembers = [];

  // Mock contacts data
  final List<Map<String, dynamic>> _mockContacts = [
    {
      "id": 1,
      "name": "Sarah Johnson",
      "phone": "+1 (555) 123-4567",
      "status": "Pending"
    },
    {
      "id": 2,
      "name": "Mike Chen",
      "phone": "+1 (555) 234-5678",
      "status": "Pending"
    },
    {
      "id": 3,
      "name": "Emma Rodriguez",
      "phone": "+1 (555) 345-6789",
      "status": "Pending"
    },
    {
      "id": 4,
      "name": "David Kim",
      "phone": "+1 (555) 456-7890",
      "status": "Pending"
    },
    {
      "id": 5,
      "name": "Lisa Thompson",
      "phone": "+1 (555) 567-8901",
      "status": "Pending"
    },
    {
      "id": 6,
      "name": "Alex Martinez",
      "phone": "+1 (555) 678-9012",
      "status": "Pending"
    }
  ];

  @override
  void initState() {
    super.initState();
    _groupNameController.addListener(_validateGroupName);
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _descriptionController.dispose();
    _groupNameFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  void _validateGroupName() {
    setState(() {
      final name = _groupNameController.text.trim();
      if (name.isEmpty) {
        _groupNameError = null;
      } else if (name.length < 3) {
        _groupNameError = 'Group name must be at least 3 characters';
      } else if (name.length > 50) {
        _groupNameError = 'Group name must be less than 50 characters';
      } else {
        _groupNameError = null;
      }
    });
  }

  bool get _isFormValid {
    final name = _groupNameController.text.trim();
    return name.length >= 3 && name.length <= 50 && _groupNameError == null;
  }

  void _showContactPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildContactPickerModal(),
    );
  }

  Widget _buildContactPickerModal() {
    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Contacts',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: CustomIconWidget(
                    iconName: 'close',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(4.w),
              itemCount: _mockContacts.length,
              itemBuilder: (context, index) {
                final contact = _mockContacts[index];
                final isSelected = _invitedMembers.any(
                  (member) => (member['id'] as int) == (contact['id'] as int),
                );

                return Container(
                  margin: EdgeInsets.only(bottom: 2.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.primary
                            .withValues(alpha: 0.1)
                        : AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.outline
                              .withValues(alpha: 0.3),
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.primary
                            .withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (contact['name'] as String)[0].toUpperCase(),
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      contact['name'] as String,
                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      contact['phone'] as String,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: isSelected
                        ? CustomIconWidget(
                            iconName: 'check_circle',
                            color: AppTheme.lightTheme.colorScheme.primary,
                            size: 24,
                          )
                        : CustomIconWidget(
                            iconName: 'radio_button_unchecked',
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                    onTap: () => _toggleContactSelection(contact),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _toggleContactSelection(Map<String, dynamic> contact) {
    setState(() {
      final existingIndex = _invitedMembers.indexWhere(
        (member) => (member['id'] as int) == (contact['id'] as int),
      );

      if (existingIndex >= 0) {
        _invitedMembers.removeAt(existingIndex);
      } else {
        _invitedMembers.add({
          ...contact,
          'status': 'Pending',
        });
      }
    });
  }

  void _removeMember(int index) {
    setState(() {
      _invitedMembers.removeAt(index);
    });
  }

  Future<void> _createGroup() async {
    if (!_isFormValid) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('🆕 Starting group creation with Supabase...');

      // CRITICAL FIX: Use actual Supabase service to create group in database
      final newGroup = await SupabaseService.instance.createGroup(
        name: _groupNameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        profilePicture: null, // Could be added later with image picker
      );

      print('✅ Group created successfully: ${newGroup['name']}');

      // Show success message with haptic feedback
      HapticFeedback.heavyImpact();

      if (mounted) {
        Fluttertoast.showToast(
          msg: "Group '${newGroup['name']}' created successfully!",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          textColor: Colors.white,
        );

        // Navigate back with the new group data
        await Future.delayed(Duration(milliseconds: 500));
        Navigator.pop(context, {
          'newGroup': newGroup,
          'refreshRequired': true,
        });
      }
    } catch (e) {
      print('❌ Group creation failed: $e');

      HapticFeedback.heavyImpact();

      if (mounted) {
        String errorMessage = 'Failed to create group. Please try again.';

        // Provide more specific error messages
        String errorString = e.toString().toLowerCase();
        if (errorString.contains('connection') ||
            errorString.contains('timeout')) {
          errorMessage =
              'Connection failed. Please check your internet and try again.';
        } else if (errorString.contains('permission') ||
            errorString.contains('denied')) {
          errorMessage = 'Permission denied. Please check your account status.';
        } else if (errorString.contains('invalid') ||
            errorString.contains('format')) {
          errorMessage = 'Invalid group information. Please check your input.';
        }

        Fluttertoast.showToast(
          msg: errorMessage,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          textColor: Colors.white,
        );

        // Show more detailed error in SnackBar for debugging
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _createGroup(),
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
          'Create Group',
          style: AppTheme.lightTheme.appBarTheme.titleTextStyle,
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
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
                        color: AppTheme.lightTheme.colorScheme.primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 16.w,
                            height: 16.w,
                            decoration: BoxDecoration(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: CustomIconWidget(
                                iconName: 'group_add',
                                color:
                                    AppTheme.lightTheme.colorScheme.onPrimary,
                                size: 32,
                              ),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Create Your Group',
                            style: AppTheme.lightTheme.textTheme.headlineSmall
                                ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.lightTheme.colorScheme.primary,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'Start planning together with friends and family',
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

                    SizedBox(height: 3.h),

                    // Group details card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.lightTheme.colorScheme.shadow
                                .withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Group Details',
                            style: AppTheme.lightTheme.textTheme.titleLarge
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2.h),

                          // Group name input
                          GroupNameInputWidget(
                            controller: _groupNameController,
                            onChanged: (value) => _validateGroupName(),
                            errorText: _groupNameError,
                          ),

                          SizedBox(height: 3.h),

                          // Description input
                          GroupDescriptionInputWidget(
                            controller: _descriptionController,
                            onChanged: (value) => setState(() {}),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 3.h),

                    // CRITICAL FIX: For now, focus on core group creation. Member invitations can be added later
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.lightTheme.colorScheme.shadow
                                .withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Group Settings',
                            style: AppTheme.lightTheme.textTheme.titleLarge
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(3.w),
                            decoration: BoxDecoration(
                              color: AppTheme.lightTheme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                  size: 20,
                                ),
                                SizedBox(width: 2.w),
                                Expanded(
                                  child: Text(
                                    'You can invite members and configure group settings after creation.',
                                    style: AppTheme
                                        .lightTheme.textTheme.bodySmall
                                        ?.copyWith(
                                      color: AppTheme
                                          .lightTheme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 4.h),
                  ],
                ),
              ),
            ),

            // Bottom action section
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: CreateGroupButtonWidget(
                isEnabled: _isFormValid,
                isLoading: _isLoading,
                onPressed: _createGroup,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
