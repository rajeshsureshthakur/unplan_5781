import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class BalanceSummaryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> balances;
  final String currency;
  final String currentUserId;
  final Function(String) onMarkPaid;
  final Function(String) onApprovePayment;

  const BalanceSummaryWidget({
    Key? key,
    required this.balances,
    required this.currentUserId,
    required this.onMarkPaid,
    required this.onApprovePayment,
    this.currency = 'USD',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String currencySymbol = currency == 'USD' ? '\$' : '₹';

    // Separate balances into "you owe" and "owes you"
    final youOweBalances = balances.where((balance) {
      return balance['fromUserId'] == currentUserId;
    }).toList();

    final owesYouBalances = balances.where((balance) {
      return balance['toUserId'] == currentUserId;
    }).toList();

    if (balances.isEmpty ||
        (youOweBalances.isEmpty && owesYouBalances.isEmpty)) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
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
          children: [
            CustomIconWidget(
              iconName: 'account_balance_wallet',
              size: 48,
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.5),
            ),
            SizedBox(height: 2.h),
            Text(
              'All settled up!',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'No outstanding balances in this group',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
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
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'account_balance_wallet',
                  size: 24,
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
                SizedBox(width: 3.w),
                Text(
                  'Balance Summary',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // You Owe To Section
          if (youOweBalances.isNotEmpty) ...[
            Divider(
              height: 1,
              color: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.2),
            ),
            Container(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'trending_down',
                        size: 20,
                        color: AppTheme.lightTheme.colorScheme.error,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'You owe',
                        style:
                            AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.lightTheme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  ...youOweBalances.map(
                      (balance) => _buildYouOweItem(balance, currencySymbol)),
                ],
              ),
            ),
          ],

          // Person Owes You Section
          if (owesYouBalances.isNotEmpty) ...[
            if (youOweBalances.isNotEmpty)
              Divider(
                height: 1,
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.2),
              ),
            Container(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'trending_up',
                        size: 20,
                        color: AppTheme.lightTheme.colorScheme.secondary,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Owes you',
                        style:
                            AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.lightTheme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  ...owesYouBalances.map(
                      (balance) => _buildOwesYouItem(balance, currencySymbol)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildYouOweItem(Map<String, dynamic> balance, String currencySymbol) {
    final String toUser = balance['toUser'] ?? 'Unknown';
    final double amount = (balance['amount'] as num).toDouble();
    final String status = balance['status'] ?? 'pending';
    final String? paidBy = balance['paidBy'];
    final String balanceId =
        balance['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color:
                  AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: 'person',
                size: 16,
                color: AppTheme.lightTheme.colorScheme.error,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  toUser,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$currencySymbol${amount.toStringAsFixed(2)}',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _buildActionButton(balanceId, status, true),
        ],
      ),
    );
  }

  Widget _buildOwesYouItem(
      Map<String, dynamic> balance, String currencySymbol) {
    final String fromUser = balance['fromUser'] ?? 'Unknown';
    final double amount = (balance['amount'] as num).toDouble();
    final String status = balance['status'] ?? 'pending';
    final String? paidBy = balance['paidBy'];
    final String balanceId =
        balance['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color:
            AppTheme.lightTheme.colorScheme.secondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              AppTheme.lightTheme.colorScheme.secondary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.secondary
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: 'person',
                size: 16,
                color: AppTheme.lightTheme.colorScheme.secondary,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fromUser,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$currencySymbol${amount.toStringAsFixed(2)}',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _buildActionButton(balanceId, status, false),
        ],
      ),
    );
  }

  Widget _buildActionButton(String balanceId, String status, bool isYouOwe) {
    switch (status) {
      case 'pending':
        if (isYouOwe) {
          // Show "Paid" button for amounts you owe
          return ElevatedButton(
            onPressed: () => onMarkPaid(balanceId),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              minimumSize: Size(0, 0),
            ),
            child: Text(
              'Paid',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        } else {
          // Show disabled "Waiting" button for amounts owed to you
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Waiting',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

      case 'paid':
        if (isYouOwe) {
          // Show disabled "Pending Approval" for amounts you paid
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Pending',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        } else {
          // Show "Approve" button for amounts paid to you
          return ElevatedButton(
            onPressed: () => onApprovePayment(balanceId),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
              foregroundColor: AppTheme.lightTheme.colorScheme.onSecondary,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              minimumSize: Size(0, 0),
            ),
            child: Text(
              'Approve',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

      case 'settled':
        // Show disabled "Settled" button for both
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          decoration: BoxDecoration(
            color:
                AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomIconWidget(
                iconName: 'check_circle',
                size: 16,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
              SizedBox(width: 1.w),
              Text(
                'Settled',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );

      default:
        return SizedBox.shrink();
    }
  }
}
