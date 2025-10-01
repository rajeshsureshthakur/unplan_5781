import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ApprovalVotingWidget extends StatefulWidget {
  final Map<String, dynamic> eventData;
  final String currentUserId;
  final Function(bool vote) onVote;

  const ApprovalVotingWidget({
    Key? key,
    required this.eventData,
    required this.currentUserId,
    required this.onVote,
  }) : super(key: key);

  @override
  State<ApprovalVotingWidget> createState() => _ApprovalVotingWidgetState();
}

class _ApprovalVotingWidgetState extends State<ApprovalVotingWidget>
    with TickerProviderStateMixin {
  late AnimationController _thumbsUpController;
  late AnimationController _thumbsDownController;
  late Animation<double> _thumbsUpScale;
  late Animation<double> _thumbsDownScale;

  @override
  void initState() {
    super.initState();
    _thumbsUpController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _thumbsDownController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _thumbsUpScale = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _thumbsUpController, curve: Curves.elasticOut),
    );
    _thumbsDownScale = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _thumbsDownController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _thumbsUpController.dispose();
    _thumbsDownController.dispose();
    super.dispose();
  }

  void _handleVote(bool isApproval) {
    // Haptic feedback
    HapticFeedback.lightImpact();

    // Animate the pressed button
    if (isApproval) {
      _thumbsUpController.forward().then((_) {
        _thumbsUpController.reverse();
      });
    } else {
      _thumbsDownController.forward().then((_) {
        _thumbsDownController.reverse();
      });
    }

    // Call the callback
    widget.onVote(isApproval);
  }

  @override
  Widget build(BuildContext context) {
    final approvalData =
        widget.eventData["approval"] as Map<String, dynamic>? ?? {};
    final approvedCount = approvalData["approvedCount"] as int? ?? 0;
    final declinedCount = approvalData["declinedCount"] as int? ?? 0;
    final totalVotes = approvedCount + declinedCount;
    final userVote =
        approvalData["userVote"] as String?; // "approved", "declined", or null
    final memberVotes = approvalData["memberVotes"] as List<dynamic>? ?? [];

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.secondary
                  .withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'how_to_vote',
                  color: AppTheme.lightTheme.colorScheme.secondary,
                  size: 24,
                ),
                SizedBox(width: 3.w),
                Text(
                  "Event Approval",
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              children: [
                // Voting buttons
                Row(
                  children: [
                    // Thumbs up button
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _thumbsUpScale,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _thumbsUpScale.value,
                            child: GestureDetector(
                              onTap: () => _handleVote(true),
                              child: Container(
                                height: 12.h,
                                decoration: BoxDecoration(
                                  color: userVote == "approved"
                                      ? AppTheme
                                          .lightTheme.colorScheme.secondary
                                      : AppTheme
                                          .lightTheme.colorScheme.secondary
                                          .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppTheme
                                        .lightTheme.colorScheme.secondary,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CustomIconWidget(
                                      iconName: 'thumb_up',
                                      color: userVote == "approved"
                                          ? AppTheme.lightTheme.colorScheme
                                              .onSecondary
                                          : AppTheme
                                              .lightTheme.colorScheme.secondary,
                                      size: 32,
                                    ),
                                    SizedBox(height: 1.h),
                                    Text(
                                      approvedCount.toString(),
                                      style: AppTheme
                                          .lightTheme.textTheme.headlineSmall
                                          ?.copyWith(
                                        color: userVote == "approved"
                                            ? AppTheme.lightTheme.colorScheme
                                                .onSecondary
                                            : AppTheme.lightTheme.colorScheme
                                                .secondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      "Approve",
                                      style: AppTheme
                                          .lightTheme.textTheme.labelMedium
                                          ?.copyWith(
                                        color: userVote == "approved"
                                            ? AppTheme.lightTheme.colorScheme
                                                .onSecondary
                                            : AppTheme.lightTheme.colorScheme
                                                .secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(width: 4.w),

                    // Thumbs down button
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _thumbsDownScale,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _thumbsDownScale.value,
                            child: GestureDetector(
                              onTap: () => _handleVote(false),
                              child: Container(
                                height: 12.h,
                                decoration: BoxDecoration(
                                  color: userVote == "declined"
                                      ? AppTheme.lightTheme.colorScheme.error
                                      : AppTheme.lightTheme.colorScheme.error
                                          .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        AppTheme.lightTheme.colorScheme.error,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CustomIconWidget(
                                      iconName: 'thumb_down',
                                      color: userVote == "declined"
                                          ? AppTheme
                                              .lightTheme.colorScheme.onError
                                          : AppTheme
                                              .lightTheme.colorScheme.error,
                                      size: 32,
                                    ),
                                    SizedBox(height: 1.h),
                                    Text(
                                      declinedCount.toString(),
                                      style: AppTheme
                                          .lightTheme.textTheme.headlineSmall
                                          ?.copyWith(
                                        color: userVote == "declined"
                                            ? AppTheme
                                                .lightTheme.colorScheme.onError
                                            : AppTheme
                                                .lightTheme.colorScheme.error,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      "Decline",
                                      style: AppTheme
                                          .lightTheme.textTheme.labelMedium
                                          ?.copyWith(
                                        color: userVote == "declined"
                                            ? AppTheme
                                                .lightTheme.colorScheme.onError
                                            : AppTheme
                                                .lightTheme.colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 3.h),

                // Member voting status
                if (memberVotes.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Member Responses",
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),

                  // Member list
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: memberVotes.length,
                    separatorBuilder: (context, index) => SizedBox(height: 1.h),
                    itemBuilder: (context, index) {
                      final member = memberVotes[index] as Map<String, dynamic>;
                      return _buildMemberVoteItem(member);
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberVoteItem(Map<String, dynamic> member) {
    final name = member["name"] as String? ?? "Unknown";
    final avatar = member["avatar"] as String? ?? "";
    final vote = member["vote"] as String?; // "approved", "declined", or null

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (vote) {
      case "approved":
        statusColor = AppTheme.lightTheme.colorScheme.secondary;
        statusIcon = Icons.check_circle;
        statusText = "Approved";
        break;
      case "declined":
        statusColor = AppTheme.lightTheme.colorScheme.error;
        statusIcon = Icons.cancel;
        statusText = "Declined";
        break;
      default:
        statusColor = AppTheme.lightTheme.colorScheme.onSurfaceVariant;
        statusIcon = Icons.schedule;
        statusText = "Pending";
    }

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.1),
            ),
            child: avatar.isNotEmpty
                ? ClipOval(
                    child: CustomImageWidget(
                      imageUrl: avatar,
                      width: 10.w,
                      height: 10.w,
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : "?",
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),

          SizedBox(width: 3.w),

          // Name
          Expanded(
            child: Text(
              name,
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Status
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                statusIcon,
                color: statusColor,
                size: 20,
              ),
              SizedBox(width: 1.w),
              Text(
                statusText,
                style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
