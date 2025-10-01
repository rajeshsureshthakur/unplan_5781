import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import '../../../services/supabase_service.dart';
import '../../groups_list_screen/widgets/empty_state_widget.dart';
import '../../groups_list_screen/widgets/floating_create_button_widget.dart';
import '../../groups_list_screen/widgets/group_card_widget.dart';

class MyGroupsTabWidget extends StatefulWidget {
  final VoidCallback? onCreateGroup;
  final VoidCallback? onGroupUpdated;

  const MyGroupsTabWidget({
    Key? key,
    this.onCreateGroup,
    this.onGroupUpdated,
  }) : super(key: key);

  @override
  State<MyGroupsTabWidget> createState() => _MyGroupsTabWidgetState();
}

class _MyGroupsTabWidgetState extends State<MyGroupsTabWidget> {
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = false;
  String? _lastUpdateKey;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      print('🔍 Loading groups from database...');

      final groupsFromDb = await SupabaseService.instance
          .getUserGroups()
          .timeout(Duration(seconds: 15));

      if (groupsFromDb.isNotEmpty) {
        final convertedGroups = <Map<String, dynamic>>[];

        for (var group in groupsFromDb) {
          try {
            final members = <Map<String, dynamic>>[];

            // Process group members data
            if (group['group_members'] != null) {
              for (var member in (group['group_members'] as List)) {
                if (member['user_profiles'] != null) {
                  members.add({
                    'id': member['user_profiles']['id'],
                    'name': member['user_profiles']['full_name'] ?? 'Unknown',
                    'avatar': member['user_profiles']['profile_picture'] ??
                        'https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=400',
                  });
                }
              }
            }

            convertedGroups.add({
              'id': group['id'],
              'name': group['name'] ?? 'Untitled Group',
              'description': group['description'],
              'profile_picture': group['profile_picture'],
              'members': members,
              'memberCount': group['memberCount'] ?? members.length,
              'lastActivity':
                  'Updated ${_getTimeAgo(group['updated_at'] ?? group['created_at'])}',
              'hasUnread':
                  false, // Could be enhanced with real notification logic
              'createdAt': DateTime.tryParse(group['created_at'] ?? '') ??
                  DateTime.now(),
              // CRITICAL FIX: Keep original data for passing to group dashboard
              'group_members': group['group_members'],
              'created_by': group['created_by'],
              'updated_at': group['updated_at'],
            });
          } catch (e) {
            print('⚠️ Error processing group ${group['id']}: $e');
            // Skip this group and continue processing others
            continue;
          }
        }

        if (mounted) {
          setState(() {
            _groups = convertedGroups;
            _lastUpdateKey = DateTime.now().millisecondsSinceEpoch.toString();
          });
        }

        print(
            '✅ Successfully loaded ${convertedGroups.length} groups from database');
      } else {
        if (mounted) {
          setState(() {
            _groups = [];
            _lastUpdateKey = DateTime.now().millisecondsSinceEpoch.toString();
          });
        }
        print('ℹ️ No groups found in database - showing empty state');
      }
    } catch (e) {
      print('❌ Error loading groups from database: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Unable to load groups. Please check your connection and try again.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _loadGroups(),
            ),
          ),
        );

        setState(() {
          _groups = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getTimeAgo(String? timestamp) {
    if (timestamp == null) return 'recently';

    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'just now';
      }
    } catch (e) {
      return 'recently';
    }
  }

  void _navigateToGroup(Map<String, dynamic> group) async {
    HapticFeedback.selectionClick();

    final result = await Navigator.pushNamed(
      context,
      '/group-dashboard-screen',
      arguments: {
        ...group,
        'id': group['id'],
        'name': group['name'],
        'description': group['description'],
        'profile_picture': group['profile_picture'],
        'group_members': group['group_members'],
        'memberCount': group['memberCount'],
      },
    );

    if (result != null && result is Map<String, dynamic>) {
      print('🔄 Received result from group dashboard: $result');

      if (result['leftGroup'] == true) {
        await _loadGroups();
        widget.onGroupUpdated?.call();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✅ Left "${result['groupName'] ?? 'group'}" successfully'),
              backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (result['refreshRequired'] == true) {
        await _loadGroups();
        widget.onGroupUpdated?.call();

        if (mounted && result['updated'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Group updated successfully'),
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      await _loadGroups();
      widget.onGroupUpdated?.call();
    }
  }

  void _navigateToUpdateGroupInfo(Map<String, dynamic> group) async {
    HapticFeedback.selectionClick();
    print('📝 DIRECT GROUP UPDATE FROM HOME - Group: ${group['name']}');

    try {
      // CRITICAL FIX: Navigate directly to profile setup screen with group edit mode
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: true,
        builder: (context) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 90.w,
              maxHeight: 80.h,
            ),
            padding: EdgeInsets.all(6.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dialog Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Update Group Info',
                      style:
                          AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 3.h),

                // Group Name Input
                TextFormField(
                  initialValue: group['name'],
                  decoration: InputDecoration(
                    labelText: 'Group Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.group),
                  ),
                  onChanged: (value) {
                    group['name'] = value;
                  },
                ),

                SizedBox(height: 2.h),

                // Group Description Input
                TextFormField(
                  initialValue: group['description'] ?? '',
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    group['description'] = value.isEmpty ? null : value;
                  },
                ),

                SizedBox(height: 4.h),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            // Show loading indicator
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => Center(
                                child: Container(
                                  padding: EdgeInsets.all(4.w),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.lightTheme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                        color: AppTheme
                                            .lightTheme.colorScheme.primary,
                                      ),
                                      SizedBox(height: 2.h),
                                      Text('Updating group...'),
                                    ],
                                  ),
                                ),
                              ),
                            );

                            // Update group via Supabase
                            final updatedGroup =
                                await SupabaseService.instance.updateGroup(
                              groupId: group['id'],
                              name: group['name'] ?? 'Untitled Group',
                              description: group['description'],
                              profilePicture: group['profile_picture'],
                            );

                            // Close loading dialog
                            Navigator.of(context).pop();

                            // Close edit dialog and return result
                            Navigator.of(context).pop({
                              'updated': true,
                              'refreshRequired': true,
                              'updatedGroup': updatedGroup,
                            });
                          } catch (e) {
                            // Close loading dialog
                            Navigator.of(context).pop();

                            // Show error
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Failed to update group: ${e.toString()}'),
                                backgroundColor:
                                    AppTheme.lightTheme.colorScheme.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppTheme.lightTheme.colorScheme.primary,
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Update',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      print('📝 Direct group edit dialog result: $result');

      // Handle the result from the direct edit dialog
      if (result != null) {
        if (result['refreshRequired'] == true || result['updated'] == true) {
          print('🔄 Refreshing groups list due to direct update');
          await _loadGroups();
          widget.onGroupUpdated?.call();

          if (mounted && result['updated'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Group updated successfully'),
                backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('❌ Direct group update failed: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to open group editor'),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _createGroup() async {
    HapticFeedback.selectionClick();

    if (widget.onCreateGroup != null) {
      widget.onCreateGroup!();
      return;
    }

    print('🆕 Navigating to group creation...');

    final result = await Navigator.pushNamed(context, '/group-creation-screen');

    print('🔄 Returned from group creation with result: $result');

    if (result != null && result is Map<String, dynamic>) {
      final newGroupData = result['newGroup'] as Map<String, dynamic>?;
      if (newGroupData != null) {
        print('✅ New group created: ${newGroupData['name']}');

        await _loadGroups();
        widget.onGroupUpdated?.call();

        if (mounted) {
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
    } else {
      await _loadGroups();
      widget.onGroupUpdated?.call();
    }
  }

  void _muteGroup(Map<String, dynamic> group) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notifications muted for ${group['name']}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _leaveGroup(Map<String, dynamic> group) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave Group'),
        content: Text('Are you sure you want to leave "${group['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 16),
                        Text('Leaving group...'),
                      ],
                    ),
                    duration: Duration(seconds: 30),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }

              try {
                final success = await SupabaseService.instance
                    .leaveGroup(group['id'] ?? '')
                    .timeout(Duration(seconds: 20));

                if (success) {
                  if (mounted) {
                    setState(() {
                      _groups.removeWhere((g) => g['id'] == group['id']);
                    });

                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Left ${group['name']} successfully'),
                        duration: const Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor:
                            AppTheme.lightTheme.colorScheme.secondary,
                      ),
                    );

                    await _loadGroups();
                    widget.onGroupUpdated?.call();
                  }
                } else {
                  throw Exception('Leave operation failed');
                }
              } catch (e) {
                print('❌ Error leaving group: $e');

                if (mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();

                  String errorMessage =
                      'Failed to leave group. Please try again.';
                  if (e.toString().contains('timeout')) {
                    errorMessage =
                        'Request timed out. Please check your connection.';
                  } else if (e.toString().contains('Permission denied')) {
                    errorMessage =
                        'You don\'t have permission to leave this group.';
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ $errorMessage'),
                      duration: const Duration(seconds: 4),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppTheme.lightTheme.colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Leave',
              style: TextStyle(color: AppTheme.lightTheme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshGroups() async {
    HapticFeedback.lightImpact();
    await _loadGroups();
    widget.onGroupUpdated?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            )
          : _groups.isEmpty
              ? EmptyStateWidget(onCreateGroup: _createGroup)
              : RefreshIndicator(
                  onRefresh: _refreshGroups,
                  color: AppTheme.lightTheme.colorScheme.primary,
                  child: ListView.builder(
                    key: ValueKey(_lastUpdateKey ?? 'groups_list'),
                    padding: EdgeInsets.all(4.w),
                    itemCount: _groups.length,
                    itemBuilder: (context, index) {
                      final group = _groups[index];
                      return GroupCardWidget(
                        key: ValueKey(
                            'group_${group['id']}_${_lastUpdateKey ?? ''}'),
                        group: group,
                        onTap: () => _navigateToGroup(group),
                        onMute: () => _muteGroup(group),
                        onLeave: () => _leaveGroup(group),
                        onUpdateGroupInfo: () =>
                            _navigateToUpdateGroupInfo(group),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingCreateButtonWidget(
        onPressed: _createGroup,
      ),
    );
  }
}
