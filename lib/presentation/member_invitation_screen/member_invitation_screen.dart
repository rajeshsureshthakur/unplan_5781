import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/country_code_selector_widget.dart';
import './widgets/group_info_widget.dart';
import './widgets/invitee_chip_widget.dart';
import './widgets/phone_input_widget.dart';
import './widgets/recent_invitations_widget.dart';

class MemberInvitationScreen extends StatefulWidget {
  const MemberInvitationScreen({Key? key}) : super(key: key);

  @override
  State<MemberInvitationScreen> createState() => _MemberInvitationScreenState();
}

class _MemberInvitationScreenState extends State<MemberInvitationScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final List<Map<String, dynamic>> _invitees = [];
  bool _isLoading = false;
  bool _isSending = false;

  // Country code data
  String _selectedCountryCode = '+1';
  String _selectedCountryFlag = '🇺🇸';

  // Mock group data
  final Map<String, dynamic> _groupData = {
    'id': 'group_001',
    'name': 'Weekend Warriors',
    'memberCount': 8,
    'members': [
      {'id': 'user_001', 'name': 'John Doe', 'phone': '+1234567890'},
      {'id': 'user_002', 'name': 'Jane Smith', 'phone': '+1234567891'},
    ],
  };

  // Mock recent invitations
  final List<Map<String, dynamic>> _recentInvitations = [
    {
      'id': 'inv_001',
      'name': 'Mike Johnson',
      'phone': '+1234567892',
      'status': 'delivered',
      'sentAt': DateTime.now().subtract(Duration(hours: 2)),
    },
    {
      'id': 'inv_002',
      'name': 'Sarah Wilson',
      'phone': '+1234567893',
      'status': 'failed',
      'sentAt': DateTime.now().subtract(Duration(hours: 5)),
    },
    {
      'id': 'inv_003',
      'phone': '+1234567894',
      'status': 'joined',
      'sentAt': DateTime.now().subtract(Duration(days: 1)),
    },
  ];

  // Country codes data
  final List<Map<String, String>> _countryCodes = [
    {'code': '+1', 'flag': '🇺🇸', 'name': 'United States'},
    {'code': '+44', 'flag': '🇬🇧', 'name': 'United Kingdom'},
    {'code': '+91', 'flag': '🇮🇳', 'name': 'India'},
    {'code': '+86', 'flag': '🇨🇳', 'name': 'China'},
    {'code': '+81', 'flag': '🇯🇵', 'name': 'Japan'},
    {'code': '+49', 'flag': '🇩🇪', 'name': 'Germany'},
    {'code': '+33', 'flag': '🇫🇷', 'name': 'France'},
    {'code': '+61', 'flag': '🇦🇺', 'name': 'Australia'},
    {'code': '+55', 'flag': '🇧🇷', 'name': 'Brazil'},
    {'code': '+7', 'flag': '🇷🇺', 'name': 'Russia'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _showCountryCodePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => Container(
        height: 50.h,
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 10.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Select Country Code',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Expanded(
              child: ListView.builder(
                itemCount: _countryCodes.length,
                itemBuilder: (context, index) {
                  final country = _countryCodes[index];
                  return ListTile(
                    leading: Text(
                      country['flag']!,
                      style: TextStyle(fontSize: 20.sp),
                    ),
                    title: Text(
                      country['name']!,
                      style: AppTheme.lightTheme.textTheme.bodyMedium,
                    ),
                    trailing: Text(
                      country['code']!,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedCountryCode = country['code']!;
                        _selectedCountryFlag = country['flag']!;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addPhoneNumber() {
    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) return;

    final fullPhoneNumber = '$_selectedCountryCode$phoneNumber';

    // Check for duplicates
    final isDuplicate =
        _invitees.any((invitee) => invitee['phone'] == fullPhoneNumber);
    if (isDuplicate) {
      _showSnackBar('This phone number is already added', isError: true);
      return;
    }

    // Check if already a member
    final existingMembers = _groupData['members'] as List<Map<String, dynamic>>;
    final isExistingMember =
        existingMembers.any((member) => member['phone'] == fullPhoneNumber);
    if (isExistingMember) {
      _showSnackBar('This person is already a group member', isError: true);
      return;
    }

    setState(() {
      _invitees.add({
        'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
        'phone': fullPhoneNumber,
        'status': 'pending',
      });
    });

    _phoneController.clear();
  }

  void _removeInvitee(int index) {
    setState(() {
      _invitees.removeAt(index);
    });
  }

  Future<void> _addFromContacts() async {
    try {
      setState(() => _isLoading = true);

      // Request contacts permission
      final permission = await Permission.contacts.request();
      if (!permission.isGranted) {
        _showSnackBar('Contacts permission is required', isError: true);
        return;
      }

      // Mock contact selection (in real app, would use contacts_service package)
      await Future.delayed(Duration(milliseconds: 800));

      // Simulate selected contacts
      final mockSelectedContacts = [
        {'name': 'Alex Thompson', 'phone': '+1234567895'},
        {'name': 'Emma Davis', 'phone': '+1234567896'},
      ];

      for (final contact in mockSelectedContacts) {
        final isDuplicate =
            _invitees.any((invitee) => invitee['phone'] == contact['phone']);
        if (!isDuplicate) {
          setState(() {
            _invitees.add({
              'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
              'name': contact['name'],
              'phone': contact['phone'],
              'status': 'pending',
            });
          });
        }
      }

      _showSnackBar('${mockSelectedContacts.length} contacts added');
    } catch (e) {
      _showSnackBar('Failed to access contacts', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendInvitations() async {
    if (_invitees.isEmpty) return;

    try {
      setState(() => _isSending = true);

      // Simulate sending invitations via Firebase Cloud Messaging
      await Future.delayed(Duration(seconds: 2));

      // Update invitation statuses
      for (int i = 0; i < _invitees.length; i++) {
        setState(() {
          _invitees[i]['status'] = 'sent';
          _invitees[i]['sentAt'] = DateTime.now();
        });

        // Simulate delivery status updates
        Future.delayed(Duration(seconds: 3 + i), () {
          if (mounted) {
            setState(() {
              _invitees[i]['status'] = 'delivered';
            });
          }
        });
      }

      _showSnackBar('${_invitees.length} invitations sent successfully');

      // Navigate back after a delay
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context, {
            'invitationsSent': _invitees.length,
            'invitees': List.from(_invitees),
          });
        }
      });
    } catch (e) {
      _showSnackBar('Failed to send invitations', isError: true);
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _resendInvitation(Map<String, dynamic> invitation) async {
    try {
      // Simulate resending invitation
      await Future.delayed(Duration(seconds: 1));

      setState(() {
        final index = _recentInvitations
            .indexWhere((inv) => inv['id'] == invitation['id']);
        if (index != -1) {
          _recentInvitations[index]['status'] = 'sent';
          _recentInvitations[index]['sentAt'] = DateTime.now();
        }
      });

      _showSnackBar('Invitation resent successfully');
    } catch (e) {
      _showSnackBar('Failed to resend invitation', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? AppTheme.lightTheme.colorScheme.error
            : AppTheme.lightTheme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName: 'close',
            color: AppTheme.lightTheme.appBarTheme.foregroundColor!,
            size: 24,
          ),
        ),
        title: Text(
          'Invite Members',
          style: AppTheme.lightTheme.appBarTheme.titleTextStyle,
        ),
        actions: [
          TextButton(
            onPressed:
                _invitees.isEmpty || _isSending ? null : _sendInvitations,
            child: _isSending
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.lightTheme.colorScheme.primary,
                      ),
                    ),
                  )
                : Text(
                    'Send Invites',
                    style: TextStyle(
                      color: _invitees.isEmpty
                          ? AppTheme.lightTheme.colorScheme.onSurfaceVariant
                          : AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group Info
              GroupInfoWidget(groupData: _groupData),

              SizedBox(height: 3.h),

              // Phone Input Section
              Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add by Phone Number',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        CountryCodeSelectorWidget(
                          selectedCountryCode: _selectedCountryCode,
                          selectedCountryFlag: _selectedCountryFlag,
                          onTap: _showCountryCodePicker,
                        ),
                        SizedBox(width: 3.w),
                        PhoneInputWidget(
                          controller: _phoneController,
                          hintText: 'Enter phone number',
                          onChanged: (value) {},
                          onSubmitted: _addPhoneNumber,
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addPhoneNumber,
                        icon: CustomIconWidget(
                          iconName: 'add',
                          color: AppTheme.lightTheme.elevatedButtonTheme.style!
                              .foregroundColor!
                              .resolve({})!,
                          size: 20,
                        ),
                        label: Text('Add Phone Number'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 3.h),

              // Add from Contacts
              Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _addFromContacts,
                    icon: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.lightTheme.colorScheme.primary,
                              ),
                            ),
                          )
                        : CustomIconWidget(
                            iconName: 'contacts',
                            color: AppTheme.lightTheme.outlinedButtonTheme
                                .style!.foregroundColor!
                                .resolve({})!,
                            size: 20,
                          ),
                    label: Text(_isLoading
                        ? 'Loading Contacts...'
                        : 'Add from Contacts'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 4.h),

              // Added Invitees
              if (_invitees.isNotEmpty) ...[
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invitees (${_invitees.length})',
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: AppTheme.lightTheme.colorScheme.outline
                                .withValues(alpha: 0.3),
                            width: 1.0,
                          ),
                        ),
                        child: Wrap(
                          children: _invitees.asMap().entries.map((entry) {
                            final index = entry.key;
                            final invitee = entry.value;
                            return InviteeChipWidget(
                              invitee: invitee,
                              onRemove: () => _removeInvitee(index),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4.h),
              ],

              // Recent Invitations
              RecentInvitationsWidget(
                recentInvitations: _recentInvitations,
                onResend: _resendInvitation,
              ),

              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
    );
  }
}
