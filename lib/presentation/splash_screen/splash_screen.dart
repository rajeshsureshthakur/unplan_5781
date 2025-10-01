import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../services/supabase_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _loadingAnimationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _loadingAnimation;

  bool _isInitializing = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startInitialization();
  }

  void _initializeAnimations() {
    // Logo animation controller
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Loading animation controller
    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();

    // Logo scale animation
    _logoScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));

    // Logo fade animation
    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    // Loading animation
    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingAnimationController,
      curve: Curves.easeInOut,
    ));

    // Start logo animation
    _logoAnimationController.forward();
  }

  Future<void> _startInitialization() async {
    try {
      setState(() {
        _isInitializing = true;
        _hasError = false;
        _errorMessage = '';
      });

      // STEP 1: Initialize Supabase connection
      await SupabaseService.initialize();
      print('✅ Supabase initialized successfully');

      // Small delay for logo animation to complete
      await Future.delayed(const Duration(milliseconds: 1000));

      // STEP 2: Authenticate user (create demo session)
      final isAuthenticated = await SupabaseService.instance.isUserAuthenticated();
      if (!isAuthenticated) {
        throw Exception('Authentication failed');
      }
      print('✅ Authentication successful');

      // STEP 3: Check if user has existing groups
      final bool hasGroups = await _checkUserGroups();

      if (mounted) {
        _navigateToNextScreen(
            true, hasGroups); // Always authenticated after successful init
      }
    } catch (e) {
      print('❌ Initialization failed: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isInitializing = false;

          // CRITICAL FIX: Provide specific error messages based on error type
          if (e.toString().contains('Invalid Supabase ANON KEY') ||
              e.toString().contains('Placeholder') ||
              e.toString().contains('unplan@123')) {
            _errorMessage =
                'Configuration Error: Please update your Supabase credentials in env.json with real values from your Supabase project.';
          } else if (e.toString().contains('Invalid API Key') ||
              e.toString().contains('401')) {
            _errorMessage =
                'Invalid API credentials. Please check your Supabase project settings and update env.json.';
          } else if (e.toString().contains('configuration')) {
            _errorMessage =
                'Supabase configuration incomplete. Please ensure SUPABASE_URL and SUPABASE_ANON_KEY are set in env.json.';
          } else if (e.toString().contains('Network') ||
              e.toString().contains('connection')) {
            _errorMessage =
                'Network connection failed. Please check your internet connection and try again.';
          } else {
            _errorMessage =
                'Failed to connect to database. Please try again or check your configuration.';
          }
        });
      }
    }
  }

  Future<bool> _checkUserGroups() async {
    try {
      final groups = await SupabaseService.instance.getUserGroups();
      return groups.isNotEmpty;
    } catch (e) {
      print('Warning: Could not check user groups: $e');
      return false; // Continue to group creation if groups check fails
    }
  }

  void _navigateToNextScreen(bool isAuthenticated, bool hasGroups) {
    // Add haptic feedback
    HapticFeedback.lightImpact();

    String nextRoute;
    if (isAuthenticated) {
      nextRoute = hasGroups ? '/groups-list-screen' : '/group-creation-screen';
    } else {
      nextRoute = '/phone-authentication-screen';
    }

    // Navigate with fade transition
    Navigator.pushReplacementNamed(context, nextRoute);
  }

  void _retryInitialization() {
    setState(() {
      _hasError = false;
      _isInitializing = true;
      _errorMessage = '';
    });
    _startInitialization();
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _loadingAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.lightTheme.colorScheme.primary,
              AppTheme.lightTheme.colorScheme.secondary,
              AppTheme.lightTheme.colorScheme.tertiary,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: _hasError ? _buildErrorView() : _buildSplashContent(),
        ),
      ),
    );
  }

  Widget _buildSplashContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo section
        Expanded(
          flex: 3,
          child: Center(
            child: AnimatedBuilder(
              animation: _logoAnimationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _logoScaleAnimation.value,
                  child: Opacity(
                    opacity: _logoFadeAnimation.value,
                    child: _buildLogo(),
                  ),
                );
              },
            ),
          ),
        ),

        // Loading section
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isInitializing) ...[
                _buildLoadingIndicator(),
                SizedBox(height: 2.h),
                Text(
                  'Connecting to database...',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Bottom spacing
        SizedBox(height: 4.h),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 35.w,
      height: 35.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'event_note',
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 12.w,
          ),
          SizedBox(height: 1.h),
          Text(
            'Unplan',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.lightTheme.colorScheme.primary,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Plan less, live more',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.7),
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 8.w,
      height: 8.w,
      child: AnimatedBuilder(
        animation: _loadingAnimation,
        builder: (context, child) {
          return CircularProgressIndicator(
            value: null,
            strokeWidth: 3.0,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withValues(alpha: 0.8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.w),
              ),
              child: CustomIconWidget(
                iconName: 'error_outline',
                color: Colors.white,
                size: 10.w,
              ),
            ),

            SizedBox(height: 3.h),

            // Error title
            Text(
              'Database Connection Failed',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 1.h),

            // Detailed error message
            Text(
              _errorMessage,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13.sp,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 2.h),

            // Configuration guidance
            if (_errorMessage.contains('Configuration Error')) ...[
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2.w),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Fix:',
                      style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      '1. Go to supabase.com/dashboard\n'
                      '2. Select your project\n'
                      '3. Settings → API\n'
                      '4. Copy URL and ANON key\n'
                      '5. Update env.json file\n'
                      '6. Restart the app',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11.sp,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
            ],

            // Retry button
            SizedBox(
              width: 60.w,
              height: 6.h,
              child: ElevatedButton(
                onPressed: _retryInitialization,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.lightTheme.colorScheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3.h),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconWidget(
                      iconName: 'refresh',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 5.w,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Retry Connection',
                      style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}