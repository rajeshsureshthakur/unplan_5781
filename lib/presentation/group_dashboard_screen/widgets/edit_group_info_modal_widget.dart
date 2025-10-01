import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class EditGroupInfoModalWidget extends StatefulWidget {
  final Map<String, dynamic> groupData;
  final Function(Map<String, dynamic>) onUpdateGroup;

  const EditGroupInfoModalWidget({
    Key? key,
    required this.groupData,
    required this.onUpdateGroup,
  }) : super(key: key);

  @override
  State<EditGroupInfoModalWidget> createState() =>
      _EditGroupInfoModalWidgetState();
}

class _EditGroupInfoModalWidgetState extends State<EditGroupInfoModalWidget> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  String? _selectedImageUrl;
  bool _isLoading = false;

  // Sample group photos for selection
  final List<String> _groupPhotos = [
    'https://images.unsplash.com/photo-1511632765486-a01980e01a18?w=300&h=300&fit=crop',
    'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=300&h=300&fit=crop',
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=300&h=300&fit=crop',
    'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=300&h=300&fit=crop',
    'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=300&h=300&fit=crop',
    'https://images.unsplash.com/photo-1460819739742-50e2f7b14d7a?w=300&h=300&fit=crop',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.groupData['name'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.groupData['description'] ?? '',
    );
    _selectedImageUrl = widget.groupData['profile_picture'] ??
        widget.groupData['profilePicture'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 12.w,
            height: 0.5.h,
            margin: EdgeInsets.only(top: 2.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(6.w),
            child: Row(
              children: [
                Text(
                  'Edit Group Info',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: CustomIconWidget(
                    iconName: 'close',
                    size: 24,
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group Photo Section
                  _buildGroupPhotoSection(),
                  SizedBox(height: 4.h),

                  // Group Name
                  _buildTextField(
                    controller: _nameController,
                    label: 'Group Name',
                    hint: 'Enter group name',
                    icon: 'group',
                  ),
                  SizedBox(height: 3.h),

                  // Description
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Enter group description',
                    icon: 'description',
                    maxLines: 3,
                  ),
                  SizedBox(height: 6.h),
                ],
              ),
            ),
          ),

          // Save Button
          Container(
            padding: EdgeInsets.all(6.w),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                  foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: AppTheme.lightTheme.colorScheme.onPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Save Changes',
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Group Photo',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),

        // Current photo
        Center(
          child: Container(
            width: 30.w,
            height: 30.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline.withValues(
                  alpha: 0.2,
                ),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: _selectedImageUrl != null
                  ? CustomImageWidget(
                      imageUrl: _selectedImageUrl!,
                      width: 30.w,
                      height: 30.w,
                      fit: BoxFit.cover,
                    )
                  : _buildInitialsAvatar(
                      widget.groupData['name'] ?? 'Group',
                      30.w,
                    ),
            ),
          ),
        ),
        SizedBox(height: 3.h),

        // Photo options
        Text(
          'Choose a photo',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 2.h),

        // Photo grid
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 3.w,
            mainAxisSpacing: 2.h,
            childAspectRatio: 1,
          ),
          itemCount: _groupPhotos.length + 1, // +1 for remove photo option
          itemBuilder: (context, index) {
            if (index == 0) {
              // Remove photo option
              return _buildPhotoOption(
                null,
                isSelected: _selectedImageUrl == null,
                isRemoveOption: true,
              );
            }

            final photoUrl = _groupPhotos[index - 1];
            return _buildPhotoOption(
              photoUrl,
              isSelected: _selectedImageUrl == photoUrl,
            );
          },
        ),
      ],
    );
  }

  Widget _buildPhotoOption(
    String? photoUrl, {
    bool isSelected = false,
    bool isRemoveOption = false,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedImageUrl = photoUrl;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.outline.withValues(
                    alpha: 0.2,
                  ),
            width: isSelected ? 3 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: isRemoveOption
              ? Container(
                  color: AppTheme.lightTheme.colorScheme.surfaceContainer,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'close',
                        size: 24,
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Remove',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : CustomImageWidget(
                  imageUrl: photoUrl!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(String name, double size) {
    final words = name.trim().split(' ');
    String initials = '';

    if (words.isNotEmpty) {
      initials += words[0].isNotEmpty ? words[0][0].toUpperCase() : '';
      if (words.length > 1 && words[1].isNotEmpty) {
        initials += words[1][0].toUpperCase();
      }
    }

    if (initials.isEmpty) initials = 'G';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTheme.colorScheme.primary,
            fontSize: size * 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Padding(
              padding: EdgeInsets.all(4.w),
              child: CustomIconWidget(
                iconName: icon,
                size: 24,
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            filled: true,
            fillColor: AppTheme.lightTheme.colorScheme.surfaceContainer,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.lightTheme.colorScheme.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Group name cannot be empty'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // CRITICAL FIX: Prepare data for database format
      final updatedGroupData = Map<String, dynamic>.from(widget.groupData);
      updatedGroupData['name'] = _nameController.text.trim();
      updatedGroupData['description'] = _descriptionController.text.trim();
      updatedGroupData['profile_picture'] = _selectedImageUrl;
      updatedGroupData['updated_at'] = DateTime.now().toIso8601String();

      print('💾 SAVING GROUP CHANGES - Closing modal first...');

      // CRITICAL FIX: Close modal IMMEDIATELY before any database operations
      if (mounted) {
        Navigator.of(context).pop();
      }

      // CRITICAL FIX: Add a small delay to ensure modal is fully closed
      await Future.delayed(Duration(milliseconds: 100));

      print('💾 Modal closed - calling update callback...');

      // CRITICAL FIX: Call the update callback which handles database operations
      widget.onUpdateGroup(updatedGroupData);

      print('💾 Update callback completed');
    } catch (e) {
      print('❌ Error in save changes: $e');

      // Only handle error if we're still mounted (modal wasn't closed)
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to save changes. Please try again.'),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
