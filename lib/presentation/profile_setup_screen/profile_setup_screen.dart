import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import './widgets/action_buttons_widget.dart';
import './widgets/name_input_widget.dart';
import './widgets/profile_avatar_widget.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _profileImageUrl;
  String? _profilePictureUrl;
  String? _nameError;
  bool _isLoading = false;
  bool _isNameValid = false;
  bool _isFirstTimeRegistration = false;
  Map<String, dynamic>? _existingUserData;

  List<CameraDescription>? _cameras;
  CameraController? _cameraController;

  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadExistingProfile();
  }

  void _initializeAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutQuart,
    ));

    // Start animations
    _fadeAnimationController.forward();
    _slideAnimationController.forward();
  }

  // CRITICAL FIX: Load existing profile data with current user name
  Future<void> _loadExistingProfile() async {
    try {
      print('🔍 Loading existing profile data...');

      // First try to get from database
      final currentUser = await SupabaseService.instance.getCurrentUser();

      if (currentUser['full_name'] != null) {
        setState(() {
          _nameController.text = currentUser['full_name'];
          _profilePictureUrl = currentUser['profile_picture'];
          _existingUserData = currentUser;
          _isNameValid = currentUser['full_name'].toString().trim().length >= 2;
        });
        print('✅ Loaded profile: ${currentUser['full_name']}');
        print('📷 Profile picture: ${currentUser['profile_picture']}');
      } else {
        // Fallback to local storage
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final savedName = prefs.getString('user_profile_name') ?? '';
        final savedImage = prefs.getString('user_profile_picture');

        if (savedName.isNotEmpty) {
          setState(() {
            _nameController.text = savedName;
            _profilePictureUrl = savedImage;
            _isNameValid = savedName.trim().length >= 2;
          });
          print('✅ Loaded from local storage: $savedName');
        }
      }
    } catch (e) {
      print('⚠️ Error loading profile: $e');
    }
  }

  void _handleNameChanged(String value) {
    setState(() {
      _isNameValid = value.trim().length >= 2;
      _nameError = value.trim().isEmpty
          ? 'Please enter your name'
          : value.trim().length < 2
              ? 'Name must be at least 2 characters'
              : null;
    });
  }

  // CRITICAL FIX: Enhanced image picker with proper modal
  Future<void> _showImagePickerModal() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                'Update Profile Picture',
                style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 3.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImagePickerOption(
                    icon: 'camera_alt',
                    label: 'Camera',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                  _buildImagePickerOption(
                    icon: 'photo_library',
                    label: 'Gallery',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                  if (_profilePictureUrl != null)
                    _buildImagePickerOption(
                      icon: 'delete',
                      label: 'Remove',
                      onTap: _removeProfileImage,
                      isDestructive: true,
                    ),
                ],
              ),
              SizedBox(height: 3.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImagePickerOption({
    required String icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 15.w,
            height: 15.w,
            decoration: BoxDecoration(
              color: isDestructive
                  ? AppTheme.lightTheme.colorScheme.errorContainer
                  : AppTheme.lightTheme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomIconWidget(
              iconName: icon,
              size: 6.w,
              color: isDestructive
                  ? AppTheme.lightTheme.colorScheme.onErrorContainer
                  : AppTheme.lightTheme.colorScheme.onPrimaryContainer,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: isDestructive
                  ? AppTheme.lightTheme.colorScheme.error
                  : AppTheme.lightTheme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        await _cropAndSetImage(image.path);
      }
    } catch (e) {
      print('⚠️ Image pick error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeProfileImage() {
    setState(() {
      _profileImageUrl = null;
      _profilePictureUrl = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile picture removed'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
      ),
    );
  }

  // CRITICAL FIX: Enhanced image handling to prepare for storage upload
  Future<void> _cropAndSetImage(String imagePath) async {
    print('📷 Processing image: $imagePath');

    if (kIsWeb) {
      setState(() {
        _profileImageUrl = imagePath;
        _profilePictureUrl = imagePath; // For web, use directly
      });
      print('📷 Web image set: $imagePath');
      return;
    }

    try {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Photo',
            toolbarColor: AppTheme.lightTheme.colorScheme.primary,
            toolbarWidgetColor: AppTheme.lightTheme.colorScheme.onPrimary,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
            showCropGrid: true,
          ),
          IOSUiSettings(
            title: 'Crop Profile Photo',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _profileImageUrl = croppedFile.path;
          _profilePictureUrl = croppedFile.path;
        });
        print('📷 Cropped image set: ${croppedFile.path}');
      }
    } catch (e) {
      print('⚠️ Image cropping failed: $e');
      setState(() {
        _profileImageUrl = imagePath;
        _profilePictureUrl = imagePath;
      });
      print('📷 Using original image: $imagePath');
    }
  }

  // Add this method to handle profile save errors
  void _handleProfileSaveError(dynamic error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // CRITICAL FIX: Enhanced profile picture saving with proper persistence
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Add timeout protection
      await Future.any([
        _performProfileSave(),
        Future.delayed(const Duration(seconds: 20), () {
          throw Exception('Profile save timeout - please try again');
        }),
      ]);

      // FIXED: Navigate back to home dashboard instead of groups list
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home-dashboard-screen');
      }
    } catch (e) {
      _handleProfileSaveError(e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // CRITICAL FIX: Enhanced profile save to update demo user in database
  Future<void> _performProfileSave() async {
    final fullName = _nameController.text.trim();

    if (fullName.isEmpty) {
      throw Exception('Name is required');
    }

    print('👤 Saving profile with Supabase Storage: $fullName');

    try {
      // CRITICAL FIX: Use SupabaseService with proper storage integration
      final updatedProfile = await SupabaseService.instance.updateUserProfile(
        fullName: fullName,
        profilePicture: _profileImageUrl, // Pass the local image path
      );

      print('✅ Profile saved successfully with storage integration');
      print('📷 Profile picture URL: ${updatedProfile['profile_picture']}');

      // Update local variables with database response
      setState(() {
        _profilePictureUrl = updatedProfile['profile_picture'];
      });

      // Also save locally as backup
      await _saveProfileLocally(fullName, updatedProfile['profile_picture']);
    } catch (e) {
      print('❌ Database profile save failed: $e');

      // Fallback to local storage only if database update fails
      await _saveProfileLocally(fullName, _profileImageUrl);
      print('✅ Profile saved locally as fallback');
    }
  }

  // CRITICAL FIX: Enhanced local storage to handle proper image URLs
  Future<void> _saveProfileLocally(String fullName, String? imageUrl) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // CRITICAL: Use specific profile keys that home dashboard looks for
      await prefs.setString('user_profile_name', fullName);
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await prefs.setString('user_profile_picture', imageUrl);
      }
      await prefs.setBool('profile_setup_completed', true);

      // ALSO save in current_user for backward compatibility
      final userData = {
        "id": "25b09808-c76d-4d60-81d0-7ddf5739c220",
        "name": fullName,
        "avatar": imageUrl,
        "totalGroups": 0,
        "activeGroups": 0,
        "closedGroups": 0,
      };
      await prefs.setString('current_user', jsonEncode(userData));

      print('✅ Profile saved to local storage: $fullName');
      print('📷 Image URL saved: $imageUrl');
    } catch (e) {
      print('❌ Local profile save failed: $e');
      throw Exception('Failed to save profile data');
    }
  }

  Future<void> _handleLogout() async {
    try {
      await SupabaseService.instance.signOut();
      if (mounted) {
        // Success - navigate to next screen
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/phone-authentication-screen',
          (route) => false,
        );
      }
    } catch (e) {
      print('⚠️ Logout error: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Profile Setup',
          style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Column(
                children: [
                  SizedBox(height: 4.h),

                  // Welcome Text
                  Text(
                    'Complete Your Profile',
                    style:
                        AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Add your name and profile picture to get started',
                    style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 5.h),

                  // Profile Avatar
                  ProfileAvatarWidget(
                    imageUrl: _profilePictureUrl,
                    onTap: _showImagePickerModal,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Tap to add photo',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 5.h),

                  // Name Input
                  NameInputWidget(
                    controller: _nameController,
                    errorText: _nameError,
                    onChanged: _handleNameChanged,
                  ),
                  SizedBox(height: 6.h),

                  // Action Buttons
                  ActionButtonsWidget(
                    isLoading: _isLoading,
                    isNameValid: _isNameValid,
                    isFirstTimeRegistration: _isFirstTimeRegistration,
                    onCompleteSetup: _saveProfile,
                    onLogout: _handleLogout,
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
