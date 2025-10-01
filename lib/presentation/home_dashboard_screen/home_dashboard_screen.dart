import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';
import './widgets/dashboard_header_widget.dart';
import './widgets/my_actions_tab_widget.dart';
import './widgets/my_groups_tab_widget.dart';
import './widgets/user_profile_stats_widget.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({Key? key}) : super(key: key);

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  bool _isLoading = false;

  // REVERT: Simple working user state
  Map<String, dynamic> _currentUser = {
    "id": "25b09808-c76d-4d60-81d0-7ddf5739c220",
    "name": "Demo User", // Will be updated with real data
    "avatar": null,
    "totalGroups": 0,
    "activeGroups": 0,
    "closedGroups": 0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // REVERT: Simple loading approach
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });

    _setLoginStatus(true);
  }

  Future<void> _setLoginStatus(bool isLoggedIn) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_logged_in', isLoggedIn);
    } catch (e) {
      debugPrint('Error setting login status: $e');
    }
  }

  // FIXED: Enhanced user data loading with multiple sources
  Future<void> _loadUserData() async {
    try {
      print('🔍 Loading user profile data...');

      // Show loading state
      if (mounted) {
        setState(() {
          _currentUser = {
            ..._currentUser,
            "name": "Loading profile...",
          };
        });
      }

      // STEP 1: Try to get profile from SharedPreferences first
      Map<String, dynamic>? localProfile = await _getLocalProfile();

      // STEP 2: Try to get profile from database
      Map<String, dynamic>? databaseProfile = await _getDatabaseProfile();

      // STEP 3: Determine which profile to use (local overrides database if available)
      Map<String, dynamic>? profileData;

      if (localProfile != null &&
          localProfile['name'] != null &&
          localProfile['name'].isNotEmpty) {
        profileData = localProfile;
        print('✅ Using local profile data: ${profileData['name']}');
      } else if (databaseProfile != null &&
          databaseProfile['full_name'] != null) {
        profileData = {
          'name': databaseProfile['full_name'],
          'avatar': databaseProfile['profile_picture'],
          'email': databaseProfile['email'],
        };
        print('✅ Using database profile data: ${profileData['name']}');
      }

      // Get dashboard stats
      final userGroups = await SupabaseService.instance.client
          .from('group_members')
          .select('groups!inner(*)')
          .eq('user_id', '25b09808-c76d-4d60-81d0-7ddf5739c220')
          .timeout(Duration(seconds: 8));

      final totalGroups = userGroups.length;

      if (mounted) {
        setState(() {
          _currentUser = {
            "id": "25b09808-c76d-4d60-81d0-7ddf5739c220",
            "name": profileData?['name'] ?? 'Demo User',
            "avatar": profileData?['avatar'],
            "email": profileData?['email'] ?? 'demo@unplan.app',
            "totalGroups": totalGroups,
            "activeGroups": totalGroups,
            "closedGroups": 0,
            "lastUpdated": DateTime.now().millisecondsSinceEpoch,
          };
        });

        print('✅ Successfully loaded user: ${_currentUser["name"]}');
      }
    } catch (e) {
      print('❌ Error loading user data: $e');

      // Fallback to demo user data
      if (mounted) {
        setState(() {
          _currentUser = {
            ..._currentUser,
            "name": "Demo User",
            "lastUpdated": DateTime.now().millisecondsSinceEpoch,
          };
        });
      }
    }
  }

  // FIXED: Helper method to get local profile data
  Future<Map<String, dynamic>?> _getLocalProfile() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Try multiple sources for local profile data
      String? profileName = prefs.getString('user_profile_name');
      String? profilePicture = prefs.getString('user_profile_picture');

      // Also check 'current_user' for backward compatibility
      String? currentUserString = prefs.getString('current_user');
      Map<String, dynamic>? currentUserData;

      if (currentUserString != null) {
        try {
          currentUserData =
              Map<String, dynamic>.from(json.decode(currentUserString));
        } catch (e) {
          print('⚠️ Failed to parse current_user data: $e');
        }
      }

      // Use specific profile keys first, then fallback to current_user data
      String? finalName = profileName ?? currentUserData?['name'];
      String? finalAvatar = profilePicture ?? currentUserData?['avatar'];

      if (finalName != null && finalName.isNotEmpty) {
        return {
          'name': finalName,
          'avatar': finalAvatar,
        };
      }

      return null;
    } catch (e) {
      print('❌ Error loading local profile: $e');
      return null;
    }
  }

  // CRITICAL FIX: Simplified and more reliable profile image loading
  Future<Map<String, dynamic>?> _getDatabaseProfile() async {
    try {
      final userProfile = await SupabaseService.instance.client
          .from('user_profiles')
          .select('*')
          .eq('id', '25b09808-c76d-4d60-81d0-7ddf5739c220')
          .single()
          .timeout(Duration(seconds: 8));

      print('📊 Database profile loaded: ${userProfile['full_name']}');
      print('📷 Database profile picture: ${userProfile['profile_picture']}');

      // CRITICAL FIX: Ensure profile picture URL is properly formatted and persistent
      if (userProfile['profile_picture'] != null) {
        String profilePicUrl = userProfile['profile_picture'].toString();

        // ENHANCED: Better URL handling for different sources
        if (profilePicUrl.isNotEmpty) {
          if (profilePicUrl.startsWith('http')) {
            // Already a complete URL - use as is
            userProfile['profile_picture'] = profilePicUrl;
          } else if (profilePicUrl.contains('/')) {
            // Storage path - convert to public URL
            try {
              profilePicUrl = SupabaseService.instance.client.storage
                  .from('profile-images')
                  .getPublicUrl(profilePicUrl);
              userProfile['profile_picture'] = profilePicUrl;

              // CRITICAL: Save the complete URL back to local storage for persistence
              final SharedPreferences prefs =
                  await SharedPreferences.getInstance();
              await prefs.setString('user_profile_picture', profilePicUrl);

              print(
                  '🔗 Converted and saved profile picture URL: $profilePicUrl');
            } catch (e) {
              print('⚠️ Failed to convert profile picture URL: $e');
            }
          }
        }
      }

      return userProfile;
    } catch (e) {
      print('⚠️ Could not load database profile: $e');
      return null;
    }
  }

  Future<void> _loadDashboardData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    await _loadUserData();

    // Small delay for better UX
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshDashboard() async {
    HapticFeedback.lightImpact();
    await _loadDashboardData();

    // Force refresh the tab widgets
    setState(() {
      _currentUser = {
        ..._currentUser,
        "lastUpdated": DateTime.now().millisecondsSinceEpoch,
      };
    });
  }

  // ENHANCED: Force refresh when returning from profile screen
  void _navigateToProfile() async {
    HapticFeedback.selectionClick();
    final result = await Navigator.pushNamed(context, '/profile-setup-screen');

    // CRITICAL FIX: Force complete refresh when returning from profile
    if (mounted) {
      print('🔄 Returned from profile screen, force refreshing data...');

      // Clear local cache to force fresh load
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_profile_picture');

      // Force complete data reload
      await _loadDashboardData();
    }
  }

  Future<void> _handleLogout() async {
    try {
      // Clear login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_logged_in', false);
      await prefs.setBool('profile_complete', false);

      // Navigate to authentication screen
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/phone-authentication-screen',
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error during logout: $e');
      // Still navigate to auth screen even if clearing preferences fails
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/phone-authentication-screen',
          (route) => false,
        );
      }
    }
  }

  // REVERT: Simplified group creation navigation that actually works
  void _navigateToCreateGroup() async {
    HapticFeedback.selectionClick();
    print('🆕 Navigating to group creation...');

    try {
      final result =
          await Navigator.pushNamed(context, '/group-creation-screen');

      print('🔄 Returned from group creation with result: $result');

      // Always refresh the dashboard data after group creation attempt
      await _loadDashboardData();

      // Show success message if group was created
      if (result != null && result is Map<String, dynamic>) {
        final newGroupData = result['newGroup'] as Map<String, dynamic>?;
        if (newGroupData != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✅ Group "${newGroupData['name']}" created successfully!'),
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Navigation error: $e');
      // Still refresh the dashboard
      await _loadDashboardData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _refreshDashboard,
          color: AppTheme.lightTheme.colorScheme.primary,
          child: Column(
            children: [
              // Dashboard Header
              DashboardHeaderWidget(
                key: ValueKey(
                    'header_${_currentUser["lastUpdated"] ?? "default"}'),
                currentUser: _currentUser,
                onProfileTap: _navigateToProfile,
                onLogout: _handleLogout,
              ),

              // User Profile Statistics
              UserProfileStatsWidget(
                key: ValueKey(
                    'stats_${_currentUser["lastUpdated"] ?? "default"}'),
                user: _currentUser,
                onProfileTap: _navigateToProfile,
              ),

              SizedBox(height: 2.h),

              // Tab Bar
              Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.lightTheme.colorScheme.shadow
                          .withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.lightTheme.colorScheme.primary,
                  unselectedLabelColor:
                      AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  labelStyle:
                      AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle:
                      AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  indicatorColor: AppTheme.lightTheme.colorScheme.primary,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  onTap: (index) => HapticFeedback.selectionClick(),
                  tabs: const [
                    Tab(
                      text: 'My Groups',
                      icon: Icon(Icons.groups),
                    ),
                    Tab(
                      text: 'My Actions',
                      icon: Icon(Icons.pending_actions),
                    ),
                  ],
                ),
              ),

              // Tab Bar View
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: AppTheme.lightTheme.colorScheme.primary,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Loading dashboard...',
                              style: AppTheme.lightTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          // My Groups Tab - FIXED: Pass the working navigation callback
                          MyGroupsTabWidget(
                            key: ValueKey(
                                'groups_${_currentUser["lastUpdated"] ?? DateTime.now().millisecondsSinceEpoch}'),
                            onCreateGroup: _navigateToCreateGroup,
                            onGroupUpdated: () {
                              // Refresh dashboard stats when groups are updated
                              _loadDashboardData();
                            },
                          ),
                          MyActionsTabWidget(
                            key: ValueKey(
                                'actions_${_currentUser["lastUpdated"] ?? DateTime.now().millisecondsSinceEpoch}'),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
