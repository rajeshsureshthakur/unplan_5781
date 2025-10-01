import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/approval_voting_widget.dart';
import './widgets/comments_section_widget.dart';
import './widgets/event_info_card_widget.dart';
import './widgets/expenses_section_widget.dart';
import './widgets/member_attendance_widget.dart';

class EventDetailsScreen extends StatefulWidget {
  const EventDetailsScreen({Key? key}) : super(key: key);

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final ScrollController _scrollController = ScrollController();

  // Mock data for the event
  final Map<String, dynamic> eventData = {
    "id": "event_001",
    "title": "Beach Volleyball Tournament",
    "date": "October 15, 2025",
    "time": "2:00 PM",
    "venue": "Santa Monica Beach, Volleyball Courts",
    "hasLocation": true,
    "notes":
        "Bring sunscreen, water bottles, and comfortable athletic wear. We'll have snacks and drinks available. Tournament format will be announced on the day based on attendance.",
    "createdBy": "user_001",
    "isPastEvent": false,
    "approval": {
      "enabled": true,
      "approvedCount": 8,
      "declinedCount": 2,
      "userVote": null, // "approved", "declined", or null
      "memberVotes": [
        {
          "userId": "user_002",
          "name": "Sarah Johnson",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
          "vote": "approved"
        },
        {
          "userId": "user_003",
          "name": "Mike Chen",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
          "vote": "approved"
        },
        {
          "userId": "user_004",
          "name": "Emily Rodriguez",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
          "vote": "declined"
        },
        {
          "userId": "user_005",
          "name": "David Kim",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
          "vote": "approved"
        },
        {
          "userId": "user_006",
          "name": "Lisa Thompson",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
          "vote": null
        },
        {
          "userId": "user_007",
          "name": "Alex Martinez",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
          "vote": "approved"
        },
        {
          "userId": "user_008",
          "name": "Jessica Wong",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
          "vote": "declined"
        },
        {
          "userId": "user_009",
          "name": "Ryan O'Connor",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
          "vote": "approved"
        },
        {
          "userId": "user_010",
          "name": "Amanda Foster",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
          "vote": "approved"
        },
        {
          "userId": "user_011",
          "name": "Chris Taylor",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
          "vote": "approved"
        }
      ]
    }
  };

  final List<Map<String, dynamic>> eventExpenses = [
    {
      "id": "expense_001",
      "title": "Volleyball Equipment Rental",
      "amount": 120.0,
      "payer": {
        "userId": "user_002",
        "name": "Sarah Johnson",
        "avatar":
            "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png"
      },
      "splitMembers": [
        {
          "userId": "user_002",
          "name": "Sarah Johnson",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png"
        },
        {
          "userId": "user_003",
          "name": "Mike Chen",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png"
        },
        {
          "userId": "user_004",
          "name": "Emily Rodriguez",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png"
        },
        {
          "userId": "user_005",
          "name": "David Kim",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png"
        },
        {
          "userId": "user_006",
          "name": "Lisa Thompson",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png"
        },
        {
          "userId": "user_007",
          "name": "Alex Martinez",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png"
        }
      ],
      "createdAt": DateTime.now().subtract(const Duration(days: 2))
    },
    {
      "id": "expense_002",
      "title": "Snacks and Refreshments",
      "amount": 85.50,
      "payer": {
        "userId": "user_007",
        "name": "Alex Martinez",
        "avatar":
            "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png"
      },
      "splitMembers": [
        {
          "userId": "user_002",
          "name": "Sarah Johnson",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png"
        },
        {
          "userId": "user_003",
          "name": "Mike Chen",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png"
        },
        {
          "userId": "user_005",
          "name": "David Kim",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png"
        },
        {
          "userId": "user_007",
          "name": "Alex Martinez",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png"
        },
        {
          "userId": "user_009",
          "name": "Ryan O'Connor",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png"
        }
      ],
      "createdAt": DateTime.now().subtract(const Duration(days: 1))
    }
  ];

  final List<Map<String, dynamic>> groupMembers = [
    {
      "userId": "user_002",
      "name": "Sarah Johnson",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "phone": "+1 (555) 123-4567",
      "approvalStatus": "approved"
    },
    {
      "userId": "user_003",
      "name": "Mike Chen",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "phone": "+1 (555) 234-5678",
      "approvalStatus": "approved"
    },
    {
      "userId": "user_004",
      "name": "Emily Rodriguez",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "phone": "+1 (555) 345-6789",
      "approvalStatus": "declined"
    },
    {
      "userId": "user_005",
      "name": "David Kim",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "phone": "+1 (555) 456-7890",
      "approvalStatus": "approved"
    },
    {
      "userId": "user_006",
      "name": "Lisa Thompson",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "phone": "+1 (555) 567-8901",
      "approvalStatus": "pending"
    },
    {
      "userId": "user_007",
      "name": "Alex Martinez",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "phone": "+1 (555) 678-9012",
      "approvalStatus": "approved"
    },
    {
      "userId": "user_008",
      "name": "Jessica Wong",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "phone": "+1 (555) 789-0123",
      "approvalStatus": "declined"
    },
    {
      "userId": "user_009",
      "name": "Ryan O'Connor",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "phone": "+1 (555) 890-1234",
      "approvalStatus": "approved"
    },
    {
      "userId": "user_010",
      "name": "Amanda Foster",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "phone": "+1 (555) 901-2345",
      "approvalStatus": "approved"
    },
    {
      "userId": "user_011",
      "name": "Chris Taylor",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "phone": "+1 (555) 012-3456",
      "approvalStatus": "approved"
    }
  ];

  final List<Map<String, dynamic>> eventComments = [
    {
      "id": "comment_001",
      "author": {
        "userId": "user_003",
        "name": "Mike Chen",
        "avatar":
            "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png"
      },
      "content":
          "Excited for this! I've been practicing my serves. Should we bring our own water bottles or will there be a water station?",
      "timestamp": DateTime.now().subtract(const Duration(hours: 3)),
      "isCurrentUser": false
    },
    {
      "id": "comment_002",
      "author": {
        "userId": "user_002",
        "name": "Sarah Johnson",
        "avatar":
            "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png"
      },
      "content":
          "Great question Mike! I'll bring a cooler with water and sports drinks for everyone. Looking forward to seeing everyone's skills!",
      "timestamp": DateTime.now().subtract(const Duration(hours: 2)),
      "isCurrentUser": false
    },
    {
      "id": "comment_003",
      "author": {
        "userId": "user_001",
        "name": "You",
        "avatar":
            "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png"
      },
      "content":
          "Thanks Sarah! I'll also bring some first aid supplies just in case. The weather forecast looks perfect for beach volleyball.",
      "timestamp": DateTime.now().subtract(const Duration(minutes: 45)),
      "isCurrentUser": true
    }
  ];

  final String currentUserId = "user_001";
  bool get isEventCreator => eventData["createdBy"] == currentUserId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleVote(bool isApproval) {
    setState(() {
      final approvalData = eventData["approval"] as Map<String, dynamic>;
      final currentVote = approvalData["userVote"] as String?;

      // Update vote counts
      if (currentVote == "approved") {
        approvalData["approvedCount"] =
            (approvalData["approvedCount"] as int) - 1;
      } else if (currentVote == "declined") {
        approvalData["declinedCount"] =
            (approvalData["declinedCount"] as int) - 1;
      }

      // Set new vote
      if (isApproval) {
        approvalData["userVote"] = "approved";
        approvalData["approvedCount"] =
            (approvalData["approvedCount"] as int) + 1;
      } else {
        approvalData["userVote"] = "declined";
        approvalData["declinedCount"] =
            (approvalData["declinedCount"] as int) + 1;
      }

      // Update member votes list
      final memberVotes = approvalData["memberVotes"] as List<dynamic>;
      final existingVoteIndex = memberVotes.indexWhere(
          (vote) => (vote as Map<String, dynamic>)["userId"] == currentUserId);

      if (existingVoteIndex != -1) {
        memberVotes[existingVoteIndex]["vote"] =
            isApproval ? "approved" : "declined";
      }
    });

    // Show feedback
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isApproval
            ? "You approved this event!"
            : "You declined this event."),
        backgroundColor: isApproval
            ? AppTheme.lightTheme.colorScheme.secondary
            : AppTheme.lightTheme.colorScheme.error,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleAddExpense() {
    Navigator.pushNamed(context, '/expense-creation-screen');
  }

  void _handleMemberTap(Map<String, dynamic> member) {
    // Show member details or contact options
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildMemberBottomSheet(member),
    );
  }

  void _handleAddComment(String comment) {
    setState(() {
      eventComments.insert(0, {
        "id": "comment_${DateTime.now().millisecondsSinceEpoch}",
        "author": {
          "userId": currentUserId,
          "name": "You",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png"
        },
        "content": comment,
        "timestamp": DateTime.now(),
        "isCurrentUser": true
      });
    });

    // Show feedback
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Comment added!"),
        backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _handleEditEvent() {
    Navigator.pushNamed(context, '/event-creation-screen');
  }

  void _handleDeleteEvent() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Event"),
        content: const Text(
            "Are you sure you want to delete this event? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Event deleted successfully"),
                  backgroundColor: AppTheme.lightTheme.colorScheme.error,
                ),
              );
            },
            child: Text(
              "Delete",
              style: TextStyle(color: AppTheme.lightTheme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _handleShareEvent() {
    final eventTitle = eventData["title"] as String;
    final eventDate = eventData["date"] as String;
    final eventTime = eventData["time"] as String;
    final eventVenue = eventData["venue"] as String;

    final shareText = """
🏐 $eventTitle

📅 $eventDate at $eventTime
📍 $eventVenue

Join us for this exciting event! Download Unplan to RSVP and stay updated.
""";

    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Event details copied to clipboard!"),
        backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          eventData["title"] as String? ?? "Event Details",
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomIconWidget(
              iconName: 'arrow_back',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
          ),
        ),
        actions: [
          // Share button
          GestureDetector(
            onTap: _handleShareEvent,
            child: Container(
              margin: EdgeInsets.only(right: 2.w),
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomIconWidget(
                iconName: 'share',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
            ),
          ),

          // More options
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _handleEditEvent();
                  break;
                case 'delete':
                  _handleDeleteEvent();
                  break;
              }
            },
            itemBuilder: (context) => [
              if (isEventCreator) ...[
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit Event'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Event', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ],
            child: Container(
              margin: EdgeInsets.only(right: 4.w),
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomIconWidget(
                iconName: 'more_vert',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 24,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Event info card
              EventInfoCardWidget(
                eventData: eventData,
                isCreator: isEventCreator,
                onEdit: _handleEditEvent,
                onDelete: _handleDeleteEvent,
              ),

              // Approval voting section
              if ((eventData["approval"] as Map<String, dynamic>?)
                          ?.containsKey("enabled") ==
                      true &&
                  (eventData["approval"] as Map<String, dynamic>)["enabled"] ==
                      true)
                ApprovalVotingWidget(
                  eventData: eventData,
                  currentUserId: currentUserId,
                  onVote: _handleVote,
                ),

              // Expenses section
              ExpensesSectionWidget(
                expenses: eventExpenses,
                onAddExpense: _handleAddExpense,
              ),

              // Member attendance
              MemberAttendanceWidget(
                members: groupMembers,
                onMemberTap: _handleMemberTap,
              ),

              // Comments section
              CommentsSectionWidget(
                comments: eventComments,
                onAddComment: _handleAddComment,
              ),

              // Bottom padding
              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberBottomSheet(Map<String, dynamic> member) {
    final name = member["name"] as String? ?? "Unknown";
    final avatar = member["avatar"] as String? ?? "";
    final phone = member["phone"] as String? ?? "";
    final status = member["approvalStatus"] as String?;

    return Container(
      padding: EdgeInsets.all(6.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          SizedBox(height: 4.h),

          // Member info
          Row(
            children: [
              Container(
                width: 16.w,
                height: 16.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.1),
                ),
                child: avatar.isNotEmpty
                    ? ClipOval(
                        child: CustomImageWidget(
                          imageUrl: avatar,
                          width: 16.w,
                          height: 16.w,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : "?",
                          style: AppTheme.lightTheme.textTheme.headlineSmall
                              ?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      phone,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 4.h),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Handle call action
                  },
                  icon: CustomIconWidget(
                    iconName: 'phone',
                    color: AppTheme.lightTheme.colorScheme.onPrimary,
                    size: 20,
                  ),
                  label: const Text("Call"),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Handle message action
                  },
                  icon: CustomIconWidget(
                    iconName: 'message',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 20,
                  ),
                  label: const Text("Message"),
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),
        ],
      ),
    );
  }
}
