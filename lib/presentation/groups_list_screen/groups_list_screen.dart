import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/empty_state_widget.dart';
import './widgets/floating_create_button_widget.dart';
import './widgets/group_card_widget.dart';
import './widgets/search_bar_widget.dart';

class GroupsListScreen extends StatefulWidget {
  const GroupsListScreen({Key? key}) : super(key: key);

  @override
  State<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends State<GroupsListScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  String _searchQuery = '';
  bool _isSearchActive = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _allGroups = [];
  List<Map<String, dynamic>> _filteredGroups = [];

  // Mock data for groups
  final List<Map<String, dynamic>> _mockGroups = [
    {
      "id": "1",
      "name": "Weekend Warriors",
      "members": [
        {
          "id": "1",
          "name": "Alex Johnson",
          "avatar":
              "https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=400"
        },
        {
          "id": "2",
          "name": "Sarah Chen",
          "avatar":
              "https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg?auto=compress&cs=tinysrgb&w=400"
        },
        {
          "id": "3",
          "name": "Mike Rodriguez",
          "avatar":
              "https://images.pexels.com/photos/1222271/pexels-photo-1222271.jpeg?auto=compress&cs=tinysrgb&w=400"
        },
        {
          "id": "4",
          "name": "Emma Wilson",
          "avatar":
              "https://images.pexels.com/photos/1130626/pexels-photo-1130626.jpeg?auto=compress&cs=tinysrgb&w=400"
        },
        {"id": "5", "name": "David Kim", "avatar": null}
      ],
      "lastActivity": "New event: Beach Volleyball - 2 hours ago",
      "hasUnread": true,
      "createdAt": DateTime.now().subtract(const Duration(days: 15)),
    },
    {
      "id": "2",
      "name": "College Reunion Planning",
      "members": [
        {
          "id": "6",
          "name": "Jennifer Martinez",
          "avatar":
              "https://images.pexels.com/photos/1181686/pexels-photo-1181686.jpeg?auto=compress&cs=tinysrgb&w=400"
        },
        {
          "id": "7",
          "name": "Robert Taylor",
          "avatar":
              "https://images.pexels.com/photos/1043471/pexels-photo-1043471.jpeg?auto=compress&cs=tinysrgb&w=400"
        },
        {"id": "8", "name": "Lisa Anderson", "avatar": null}
      ],
      "lastActivity": "Expense added: Venue booking - \$500 - Yesterday",
      "hasUnread": false,
      "createdAt": DateTime.now().subtract(const Duration(days: 30)),
    },
    {
      "id": "3",
      "name": "Hiking Enthusiasts",
      "members": [
        {
          "id": "9",
          "name": "Chris Thompson",
          "avatar":
              "https://images.pexels.com/photos/1040880/pexels-photo-1040880.jpeg?auto=compress&cs=tinysrgb&w=400"
        },
        {
          "id": "10",
          "name": "Amanda Davis",
          "avatar":
              "https://images.pexels.com/photos/1036623/pexels-photo-1036623.jpeg?auto=compress&cs=tinysrgb&w=400"
        }
      ],
      "lastActivity": "Poll created: Next hiking destination - 3 days ago",
      "hasUnread": true,
      "createdAt": DateTime.now().subtract(const Duration(days: 7)),
    },
    {
      "id": "4",
      "name": "Foodie Adventures",
      "members": [
        {
          "id": "11",
          "name": "Kevin Lee",
          "avatar":
              "https://images.pexels.com/photos/1212984/pexels-photo-1212984.jpeg?auto=compress&cs=tinysrgb&w=400"
        },
        {"id": "12", "name": "Rachel Green", "avatar": null},
        {
          "id": "13",
          "name": "Tom Wilson",
          "avatar":
              "https://images.pexels.com/photos/1043474/pexels-photo-1043474.jpeg?auto=compress&cs=tinysrgb&w=400"
        },
        {
          "id": "14",
          "name": "Sophie Brown",
          "avatar":
              "https://images.pexels.com/photos/1181424/pexels-photo-1181424.jpeg?auto=compress&cs=tinysrgb&w=400"
        },
        {"id": "15", "name": "Jake Miller", "avatar": null},
        {
          "id": "16",
          "name": "Olivia Garcia",
          "avatar":
              "https://images.pexels.com/photos/1239288/pexels-photo-1239288.jpeg?auto=compress&cs=tinysrgb&w=400"
        }
      ],
      "lastActivity": "Note added: Restaurant recommendations - 1 week ago",
      "hasUnread": false,
      "createdAt": DateTime.now().subtract(const Duration(days: 45)),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check if a new group was passed as argument
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['newGroup'] != null) {
      final newGroup = args['newGroup'] as Map<String, dynamic>;
      setState(() {
        _allGroups.insert(0, newGroup); // Add to beginning of list
        _filteredGroups = List.from(_allGroups);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _allGroups = List.from(_mockGroups);
      _filteredGroups = List.from(_allGroups);
      _isLoading = false;
    });
  }

  Future<void> _refreshGroups() async {
    HapticFeedback.lightImpact();
    await _loadGroups();
  }

  void _filterGroups(String query) {
    setState(() {
      _searchQuery = query;
      _isSearchActive = query.isNotEmpty;

      if (query.isEmpty) {
        _filteredGroups = List.from(_allGroups);
      } else {
        _filteredGroups = _allGroups.where((group) {
          final groupName = (group['name'] as String).toLowerCase();
          return groupName.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _isSearchActive = false;
      _filteredGroups = List.from(_allGroups);
    });
  }

  void _navigateToGroup(Map<String, dynamic> group) async {
    HapticFeedback.selectionClick();

    // Navigate and wait for result
    final result = await Navigator.pushNamed(
      context,
      '/group-dashboard-screen',
      arguments: group,
    );

    // If user left the group, remove it from the list
    if (result == true) {
      setState(() {
        _allGroups.removeWhere((g) => g['id'] == group['id']);
        _filteredGroups.removeWhere((g) => g['id'] == group['id']);
      });
    }
  }

  void _createGroup() {
    HapticFeedback.selectionClick();
    Navigator.pushNamed(context, '/group-creation-screen').then((result) {
      // Refresh groups list when returning from creation
      _loadGroups();
    });
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
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _allGroups.removeWhere((g) => g['id'] == group['id']);
                _filteredGroups.removeWhere((g) => g['id'] == group['id']);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Left ${group['name']}'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
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

  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(
        text,
        style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return Text(
        text,
        style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(
            text: text.substring(0, index),
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              backgroundColor: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.2),
            ),
          ),
          TextSpan(
            text: text.substring(index + query.length),
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'My Groups',
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/profile-setup-screen');
            },
            icon: Container(
              width: 8.w,
              height: 8.w,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'person',
                  size: 4.w,
                  color: AppTheme.lightTheme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            SearchBarWidget(
              onSearchChanged: _filterGroups,
              onClear: _clearSearch,
              isActive: _isSearchActive,
            ),

            // Groups List
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.lightTheme.colorScheme.primary,
                      ),
                    )
                  : _filteredGroups.isEmpty
                      ? _searchQuery.isNotEmpty
                          ? _buildNoSearchResults()
                          : EmptyStateWidget(onCreateGroup: _createGroup)
                      : RefreshIndicator(
                          key: _refreshIndicatorKey,
                          onRefresh: _refreshGroups,
                          color: AppTheme.lightTheme.colorScheme.primary,
                          child: ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _filteredGroups.length,
                            itemBuilder: (context, index) {
                              final group = _filteredGroups[index];
                              return GroupCardWidget(
                                group: group,
                                onTap: () => _navigateToGroup(group),
                                onMute: () => _muteGroup(group),
                                onLeave: () => _leaveGroup(group),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: _filteredGroups.isNotEmpty
          ? FloatingCreateButtonWidget(onPressed: _createGroup)
          : null,
    );
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'search_off',
              size: 15.w,
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 3.h),
            Text(
              'No groups found',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Try searching with different keywords',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
