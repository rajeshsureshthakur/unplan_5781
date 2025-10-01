import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../notes_and_polls_screen/widgets/create_note_modal_widget.dart';
import '../notes_and_polls_screen/widgets/create_poll_modal_widget.dart';
import './widgets/balance_summary_widget.dart';
import './widgets/edit_group_info_modal_widget.dart';
import './widgets/event_card_widget.dart';
import './widgets/expense_card_widget.dart';
import './widgets/expense_reports_modal_widget.dart';
import './widgets/member_avatar_widget.dart';
import './widgets/note_card_widget.dart';
import './widgets/notification_card_widget.dart';

class GroupDashboardScreen extends StatefulWidget {
  const GroupDashboardScreen({Key? key}) : super(key: key);

  @override
  State<GroupDashboardScreen> createState() => _GroupDashboardScreenState();
}

class _GroupDashboardScreenState extends State<GroupDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _groupId = '';
  Map<String, dynamic>? _groupData;
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _polls = [];
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;

  final _supabaseService = SupabaseService.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        // CRITICAL FIX: Extract the correct key 'id' instead of 'groupId'
        _groupId = args['id'] ?? '';

        // REVERT FIX: If group data is already provided, use it directly to avoid database calls
        if (args.containsKey('name') && args.containsKey('members')) {
          _groupData = {
            'id': args['id'],
            'name': args['name'],
            'description': args['description'],
            'profile_picture': args['profile_picture'],
            'group_members': args['group_members'] ?? [],
            'memberCount': args['memberCount'] ?? 1,
          };

          // Extract members from group_members data if available
          if (args['group_members'] != null) {
            _members = List<Map<String, dynamic>>.from(
                (args['group_members'] as List).map((member) => {
                      'id': member['user_profiles']?['id'],
                      'full_name':
                          member['user_profiles']?['full_name'] ?? 'Unknown',
                      'email': member['user_profiles']?['email'] ?? '',
                      'profile_picture': member['user_profiles']
                          ?['profile_picture'],
                      'role': member['role'],
                    }));
          } else if (args['members'] != null) {
            _members = List<Map<String, dynamic>>.from(args['members']);
          }

          _isLoading = false;
          setState(() {});
        } else {
          _loadGroupData();
        }

        print('🔍 Group Dashboard initialized with ID: $_groupId');
        print('🔍 Group name: ${_groupData?['name']}');
        print('🔍 Members count: ${_members.length}');
      } else {
        print('❌ No arguments provided to group dashboard');
        _showErrorAndGoBack('No group data provided');
      }
    });
  }

  void _showErrorAndGoBack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  Future<void> _loadGroupData() async {
    try {
      setState(() => _isLoading = true);

      print('🔍 Loading complete group data for: $_groupId');

      // Load group details if not already provided
      if (_groupData == null) {
        final groupData = await _supabaseService.getGroupById(_groupId);
        if (groupData == null) {
          _showErrorAndGoBack('Group not found');
          return;
        }
        _groupData = groupData;

        // Extract members from database response
        if (groupData['group_members'] != null) {
          _members = List<Map<String, dynamic>>.from(
              (groupData['group_members'] as List).map((member) => {
                    'id': member['user_profiles']?['id'],
                    'full_name':
                        member['user_profiles']?['full_name'] ?? 'Unknown',
                    'email': member['user_profiles']?['email'] ?? '',
                    'profile_picture': member['user_profiles']
                        ?['profile_picture'],
                    'role': member['role'],
                  }));
        }
      }

      // Load all related data in parallel for better performance
      final results = await Future.wait([
        _supabaseService.getGroupEvents(_groupId),
        _supabaseService.getGroupExpenses(_groupId),
        _supabaseService.getGroupNotes(_groupId),
        _supabaseService.getGroupPolls(_groupId),
        // Load members if not already loaded
        _members.isEmpty
            ? _supabaseService.getGroupMembers(_groupId)
            : Future.value(_members),
      ]);

      setState(() {
        _events = results[0];
        _expenses = results[1];
        _notes = results[2];
        _polls = results[3];
        if (_members.isEmpty) {
          _members = results[4];
        }
        _isLoading = false;
      });

      print('✅ Group data loaded successfully');
      print(
          '📊 Events: ${_events.length}, Expenses: ${_expenses.length}, Notes: ${_notes.length}, Polls: ${_polls.length}, Members: ${_members.length}');
    } catch (e) {
      print('❌ Error loading group data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading group data: $e')),
        );
      }
    }
  }

  Widget _buildHeader() {
    if (_groupData == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
            AppTheme.lightTheme.colorScheme.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          // Group profile image
          Container(
            width: 16.w,
            height: 16.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.lightTheme.colorScheme.primary,
                  AppTheme.lightTheme.colorScheme.secondary,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: _groupData!['profile_picture'] != null
                  ? CustomImageWidget(
                      imageUrl: _groupData!['profile_picture'],
                      height: 16.w,
                      width: 16.w,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.lightTheme.colorScheme.primary,
                            AppTheme.lightTheme.colorScheme.secondary,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _groupData!['name']?.substring(0, 1).toUpperCase() ??
                              'G',
                          style: AppTheme.lightTheme.textTheme.headlineMedium
                              ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          SizedBox(width: 4.w),

          // Group info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _groupData!['name'] ?? 'Group',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 16,
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      '${_members.length} member${_members.length == 1 ? '' : 's'}',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (_groupData!['description'] != null &&
                    _groupData!['description'].toString().isNotEmpty) ...[
                  SizedBox(height: 1.h),
                  Text(
                    _groupData!['description'],
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Member avatars stack
          if (_members.isNotEmpty)
            Container(
              width: 30.w,
              height: 10.w,
              child: Stack(
                children: [
                  for (int i = 0;
                      i < (_members.length > 4 ? 4 : _members.length);
                      i++)
                    Positioned(
                      left: i * 5.w,
                      child: Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: ClipOval(
                          child: MemberAvatarWidget(
                            member: _members[i],
                            size: 8.w,
                          ),
                        ),
                      ),
                    ),
                  if (_members.length > 4)
                    Positioned(
                      left: 20.w,
                      child: Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.lightTheme.colorScheme.primary
                              .withValues(alpha: 0.8),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '+${_members.length - 4}',
                            style: AppTheme.lightTheme.textTheme.labelSmall
                                ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventsTab() {
    if (_events.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event,
        title: 'No events yet',
        subtitle: 'Create your first group event',
      );
    }

    // Separate upcoming and past events
    final now = DateTime.now();
    final upcomingEvents = _events.where((event) {
      final eventDate = DateTime.tryParse(event['event_date'] ?? '');
      return eventDate != null && eventDate.isAfter(now);
    }).toList();

    final pastEvents = _events.where((event) {
      final eventDate = DateTime.tryParse(event['event_date'] ?? '');
      return eventDate != null && eventDate.isBefore(now);
    }).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (upcomingEvents.isNotEmpty) ...[
            Text(
              'Upcoming Events',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 3.h),
            ...upcomingEvents.map((event) => Padding(
                  padding: EdgeInsets.only(bottom: 3.h),
                  child: EventCardWidget(
                    event: event,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.eventDetails,
                        arguments: {'eventId': event['id']},
                      );
                    },
                  ),
                )),
            SizedBox(height: 4.h),
          ],
          if (pastEvents.isNotEmpty) ...[
            Text(
              'Past Events',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 3.h),
            ...pastEvents.map((event) => Padding(
                  padding: EdgeInsets.only(bottom: 3.h),
                  child: EventCardWidget(
                    event: event,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.eventDetails,
                        arguments: {'eventId': event['id']},
                      );
                    },
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildExpensesTab() {
    return Column(
      children: [
        // Balance summary
        if (_expenses.isNotEmpty)
          Padding(
            padding: EdgeInsets.all(4.w),
            child: BalanceSummaryWidget(
              balances: [],
              currentUserId: '',
              onMarkPaid: (String balanceId) {},
              onApprovePayment: (String balanceId) {},
            ),
          ),

        // Expenses list
        Expanded(
          child: _expenses.isEmpty
              ? _buildEmptyState(
                  icon: Icons.receipt,
                  title: 'No expenses yet',
                  subtitle: 'Track your group expenses',
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  itemCount: _expenses.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 3.h),
                      child: ExpenseCardWidget(
                        expense: _expenses[index],
                        onTap: () {
                          // Navigate to expense details
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNotesTab() {
    if (_notes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.note,
        title: 'No notes yet',
        subtitle: 'Share notes with your group',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: 3.h),
          child: NoteCardWidget(
            note: _notes[index],
            onTap: () {
              // Handle note tap
            },
          ),
        );
      },
    );
  }

  Widget _buildPollsTab() {
    if (_polls.isEmpty) {
      return _buildEmptyState(
        icon: Icons.poll,
        title: 'No polls yet',
        subtitle: 'Create polls for group decisions',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _polls.length,
      itemBuilder: (context, index) {
        final poll = _polls[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 4.h),
          child: Container(
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
                  poll['question'] ?? '',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'By ${poll['author']?['full_name'] ?? 'Unknown'}',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 3.h),

                // Poll options
                if (poll['poll_options'] != null)
                  ...List.generate((poll['poll_options'] as List).length,
                      (optionIndex) {
                    final option = (poll['poll_options'] as List)[optionIndex];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 2.h),
                      child: InkWell(
                        onTap: () {
                          // Handle vote
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppTheme.lightTheme.colorScheme.outline
                                  .withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  option['option_text'] ?? '',
                                  style:
                                      AppTheme.lightTheme.textTheme.bodyMedium,
                                ),
                              ),
                              Text(
                                '0 votes',
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationsTab() {
    if (_notifications.isEmpty) {
      return _buildEmptyState(
        icon: Icons.notifications,
        title: 'No notifications',
        subtitle: 'Group notifications will appear here',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: 3.h),
          child: NotificationCardWidget(
            notification: _notifications[index],
            onTap: () {
              // Handle notification tap
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16.w,
            color: AppTheme.lightTheme.colorScheme.outline,
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            subtitle,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateNoteModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateNoteModalWidget(
        onCreateNote: (note) async {
          try {
            final newNote = await _supabaseService.createNote(
              groupId: _groupId,
              content: note,
            );
            setState(() {
              _notes.insert(0, newNote);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Note created successfully'),
                backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Failed to create note'),
                backgroundColor: AppTheme.lightTheme.colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _showCreatePollModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreatePollModalWidget(
        onCreatePoll: (question, options) async {
          try {
            final newPoll = await _supabaseService.createPoll(
              groupId: _groupId,
              question: question,
              options: options,
            );
            setState(() {
              _polls.insert(0, newPoll);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Poll created successfully'),
                backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Failed to create poll'),
                backgroundColor: AppTheme.lightTheme.colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditGroupModal() {
    if (_groupData == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditGroupInfoModalWidget(
        groupData: _groupData!,
        onUpdateGroup: (updatedGroup) async {
          setState(() {
            _groupData = updatedGroup;
          });

          // Return updated data to previous screen
          Navigator.pop(context, {
            'refreshRequired': true,
            'updated': true,
            'updatedGroup': updatedGroup,
          });
        },
      ),
    );
  }

  void _showExpenseReports() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExpenseReportsModalWidget(
        expenses: _expenses,
        members: _members,
        currency: 'USD',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Loading...'),
          backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
              SizedBox(height: 4.h),
              Text(
                'Loading group data...',
                style: AppTheme.lightTheme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    if (_groupData == null) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Group Not Found'),
          backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 16.w,
                color: AppTheme.lightTheme.colorScheme.error,
              ),
              SizedBox(height: 4.h),
              Text(
                'Group not found',
                style: AppTheme.lightTheme.textTheme.titleLarge,
              ),
              SizedBox(height: 2.h),
              Text(
                'The group you\'re looking for doesn\'t exist or has been removed.',
                textAlign: TextAlign.center,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 4.h),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Go Back',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _groupData!['name'] ?? 'Group',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
            onSelected: (value) {
              HapticFeedback.selectionClick();
              switch (value) {
                case 'edit':
                  _showEditGroupModal();
                  break;
                case 'reports':
                  _showExpenseReports();
                  break;
                case 'members':
                  Navigator.pushNamed(
                    context,
                    AppRoutes.memberInvitation,
                    arguments: {'groupId': _groupId},
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit,
                        size: 20,
                        color: AppTheme.lightTheme.colorScheme.primary),
                    SizedBox(width: 3.w),
                    Text('Edit Group'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'members',
                child: Row(
                  children: [
                    Icon(Icons.people,
                        size: 20,
                        color: AppTheme.lightTheme.colorScheme.secondary),
                    SizedBox(width: 3.w),
                    Text('Manage Members'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'reports',
                child: Row(
                  children: [
                    Icon(Icons.analytics,
                        size: 20,
                        color: AppTheme.lightTheme.colorScheme.tertiary),
                    SizedBox(width: 3.w),
                    Text('Expense Reports'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),

          // Tab bar
          Container(
            color: AppTheme.lightTheme.colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppTheme.lightTheme.colorScheme.primary,
              unselectedLabelColor:
                  AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              indicatorColor: AppTheme.lightTheme.colorScheme.primary,
              indicatorWeight: 3,
              labelStyle: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle:
                  AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              onTap: (index) => HapticFeedback.selectionClick(),
              tabs: const [
                Tab(text: 'Events'),
                Tab(text: 'Expenses'),
                Tab(text: 'Notes'),
                Tab(text: 'Polls'),
                Tab(text: 'Notifications'),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEventsTab(),
                _buildExpensesTab(),
                _buildNotesTab(),
                _buildPollsTab(),
                _buildNotificationsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          switch (_tabController.index) {
            case 0: // Events
              Navigator.pushNamed(
                context,
                AppRoutes.eventCreation,
                arguments: {'groupId': _groupId},
              );
              break;
            case 1: // Expenses
              Navigator.pushNamed(
                context,
                AppRoutes.expenseCreation,
                arguments: {'groupId': _groupId},
              );
              break;
            case 2: // Notes
              _showCreateNoteModal();
              break;
            case 3: // Polls
              _showCreatePollModal();
              break;
          }
        },
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
