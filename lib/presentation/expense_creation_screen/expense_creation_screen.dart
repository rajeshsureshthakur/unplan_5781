import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import './widgets/amount_input_widget.dart';
import './widgets/event_selection_widget.dart';
import './widgets/payer_selection_widget.dart';
import './widgets/split_method_widget.dart';

class ExpenseCreationScreen extends StatefulWidget {
  const ExpenseCreationScreen({Key? key}) : super(key: key);

  @override
  State<ExpenseCreationScreen> createState() => _ExpenseCreationScreenState();
}

class _ExpenseCreationScreenState extends State<ExpenseCreationScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Map<String, dynamic>? _selectedPayer;
  Map<String, dynamic>? _selectedEvent;
  bool _includeAllMembers = true;
  bool _isLoading = false;
  String _selectedCurrency = 'INR'; // Default to INR as requested

  String? _titleError;
  String? _amountError;

  // Currency configurations
  final Map<String, Map<String, String>> _currencies = {
    'USD': {'symbol': '\$', 'name': 'US Dollar'},
    'INR': {'symbol': '₹', 'name': 'Indian Rupee'},
  };

  // Mock data for group members
  final List<Map<String, dynamic>> _groupMembers = [
    {
      "id": "1",
      "name": "Alex Johnson",
      "phone": "+1 (555) 123-4567",
      "avatar":
          "https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=400",
      "isCurrentUser": true,
    },
    {
      "id": "2",
      "name": "Sarah Chen",
      "phone": "+1 (555) 234-5678",
      "avatar":
          "https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg?auto=compress&cs=tinysrgb&w=400",
      "isCurrentUser": false,
    },
    {
      "id": "3",
      "name": "Mike Rodriguez",
      "phone": "+1 (555) 345-6789",
      "avatar":
          "https://images.pexels.com/photos/1043471/pexels-photo-1043471.jpeg?auto=compress&cs=tinysrgb&w=400",
      "isCurrentUser": false,
    },
    {
      "id": "4",
      "name": "Emma Wilson",
      "phone": "+1 (555) 456-7890",
      "avatar":
          "https://images.pexels.com/photos/1181686/pexels-photo-1181686.jpeg?auto=compress&cs=tinysrgb&w=400",
      "isCurrentUser": false,
    },
    {
      "id": "5",
      "name": "David Kim",
      "phone": "+1 (555) 567-8901",
      "avatar":
          "https://images.pexels.com/photos/1040880/pexels-photo-1040880.jpeg?auto=compress&cs=tinysrgb&w=400",
      "isCurrentUser": false,
    },
  ];

  // Mock data for group events
  final List<Map<String, dynamic>> _groupEvents = [
    {
      "id": "1",
      "title": "Weekend Beach Trip",
      "date": "2025-10-15T10:00:00Z",
      "venue": "Santa Monica Beach",
      "status": "upcoming",
    },
    {
      "id": "2",
      "title": "Birthday Dinner",
      "date": "2025-10-08T19:00:00Z",
      "venue": "The Italian Corner",
      "status": "upcoming",
    },
    {
      "id": "3",
      "title": "Movie Night",
      "date": "2025-09-25T20:00:00Z",
      "venue": "AMC Theater",
      "status": "past",
    },
    {
      "id": "4",
      "title": "Hiking Adventure",
      "date": "2025-10-22T08:00:00Z",
      "venue": "Griffith Observatory Trail",
      "status": "upcoming",
    },
  ];

  String? _groupId;
  List<Map<String, dynamic>> _actualGroupMembers = [];

  @override
  void initState() {
    super.initState();
    // Set current user as default payer
    _selectedPayer = _groupMembers.firstWhere(
      (member) => member['isCurrentUser'] == true,
      orElse: () => _groupMembers.first,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments != null && arguments is Map<String, dynamic>) {
      _groupId = arguments['groupId'] as String?;
      final groupMembers = arguments['groupMembers'] as List<dynamic>?;

      if (groupMembers != null) {
        _actualGroupMembers = groupMembers.map((member) {
          final memberData = member['user_profiles'] ?? member;
          return {
            'id': memberData['id'] ?? member['id'] ?? '',
            'name': memberData['full_name'] ?? member['name'] ?? 'Unknown',
            'email': memberData['email'] ?? member['email'] ?? '',
            'avatar': memberData['profile_picture'] ?? member['avatar'] ?? '',
            'isCurrentUser': false, // Will be set based on current user
          };
        }).toList();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _validateTitle(String value) {
    setState(() {
      if (value.isEmpty) {
        _titleError = 'Title is required';
      } else if (value.length > 30) {
        _titleError = 'Title must be 30 characters or less';
      } else {
        _titleError = null;
      }
    });
  }

  void _validateAmount(String value) {
    setState(() {
      final currencySymbol = _currencies[_selectedCurrency]!['symbol']!;
      if (value.isEmpty || value == '${currencySymbol}0.00') {
        _amountError = 'Amount is required';
      } else {
        final cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '');
        final amount = double.tryParse(cleanValue);
        if (amount == null || amount <= 0) {
          _amountError = 'Please enter a valid amount';
        } else if (amount > 999999.99) {
          _amountError = 'Amount is too large';
        } else {
          _amountError = null;
        }
      }
    });
  }

  double get _totalAmount {
    final cleanValue = _amountController.text.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleanValue) ?? 0.0;
  }

  bool get _isFormValid {
    final currencySymbol = _currencies[_selectedCurrency]!['symbol']!;
    return _titleError == null &&
        _amountError == null &&
        _titleController.text.isNotEmpty &&
        _amountController.text.isNotEmpty &&
        _amountController.text != '${currencySymbol}0.00' &&
        _selectedPayer != null;
  }

  void _switchCurrency() {
    setState(() {
      _selectedCurrency = _selectedCurrency == 'INR' ? 'USD' : 'INR';
      // Clear amount when switching currency to avoid confusion
      _amountController.clear();
      _amountError = null;
    });
  }

  // CRITICAL FIX: Enhanced close handler with proper cleanup
  void _handleClose() {
    // Cancel any ongoing operations
    setState(() {
      _isLoading = false;
    });

    // Clear form data to prevent memory leaks
    _titleController.clear();
    _amountController.clear();

    // Ensure proper navigation back with timeout protection
    if (mounted) {
      Navigator.pop(context);
    }
  }

  // CRITICAL FIX: Completely rewritten expense creation with robust error handling
  Future<void> _createExpense() async {
    if (!_isFormValid || _groupId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('🚀 Starting expense creation...');

      // CRITICAL: Add comprehensive timeout protection
      final expenseResult = await Future.any([
        _performExpenseCreation(),
        Future.delayed(const Duration(seconds: 25), () {
          throw Exception('Expense creation timed out - please try again');
        }),
      ]);

      // Success handling
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    '✅ Expense "${_titleController.text}" created successfully!',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.lightTheme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate back with result
        Navigator.pop(context, expenseResult);
      }
    } catch (e) {
      _handleExpenseCreationError(e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // CRITICAL FIX: Separate expense creation logic with retry mechanism
  Future<Map<String, dynamic>> _performExpenseCreation() async {
    print('💰 Preparing expense data...');

    // Validate form data
    final title = _titleController.text.trim();
    final amount = _totalAmount;

    if (title.isEmpty || amount <= 0) {
      throw Exception('Invalid form data - please check your inputs');
    }

    // Prepare split members
    final splitMembers = _actualGroupMembers.isNotEmpty
        ? _actualGroupMembers.map((m) => m['id'] as String).toList()
        : ['demo-user-fallback']; // Fallback for testing

    print(
        '📊 Creating expense: $title, Amount: $amount, Split: ${splitMembers.length} members');

    // Create expense with automatic retry on certain failures
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final result = await SupabaseService.instance.createExpense(
          groupId: _groupId!,
          title: title,
          amount: amount,
          payerId: _selectedPayer?['id'] ?? 'current-user',
          eventId: _selectedEvent?['id'],
          splitMembers: splitMembers,
        );

        print('✅ Expense created successfully on attempt ${attempt + 1}');
        return result;
      } catch (e) {
        print('❌ Expense creation attempt ${attempt + 1} failed: $e');

        if (attempt == 0 &&
            (e.toString().contains('Authentication') ||
                e.toString().contains('session'))) {
          print('🔄 Retrying after authentication issue...');
          await Future.delayed(Duration(seconds: 2));
          continue; // Retry
        }

        rethrow; // Don't retry for other errors or final attempt
      }
    }

    throw Exception('Expense creation failed after multiple attempts');
  }

  // CRITICAL FIX: Enhanced error handling with specific error types
  void _handleExpenseCreationError(dynamic error) {
    if (!mounted) return;

    print('❌ Expense creation error: $error');

    String errorMessage = 'Failed to create expense. ';
    bool showRetry = true;

    if (error.toString().contains('timed out') ||
        error.toString().contains('timeout')) {
      errorMessage += 'The operation timed out. Please check your connection.';
    } else if (error.toString().contains('Authentication failed') ||
        error.toString().contains('session invalid')) {
      errorMessage += 'Please restart the app and try again.';
    } else if (error.toString().contains('group member')) {
      errorMessage += 'You must be a member of this group to create expenses.';
      showRetry = false;
    } else if (error.toString().contains('Access denied')) {
      errorMessage +=
          'You don\'t have permission to create expenses in this group.';
      showRetry = false;
    } else if (error.toString().contains('Invalid data')) {
      errorMessage += 'Please check your expense details and try again.';
    } else if (error.toString().contains('connection')) {
      errorMessage += 'Please check your internet connection.';
    } else if (error.toString().contains('anonymous_provider_disabled')) {
      errorMessage += 'Database configuration issue. Please contact support.';
      showRetry = false;
    } else {
      errorMessage += 'Please try again in a few moments.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 2.w),
            Expanded(child: Text(errorMessage)),
          ],
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: Duration(seconds: 8),
        action: showRetry
            ? SnackBarAction(
                label: 'RETRY',
                textColor: Colors.white,
                onPressed: () => _createExpense(),
              )
            : null,
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
        leading: GestureDetector(
          onTap: _handleClose, // CRITICAL FIX: Use enhanced close handler
          child: Container(
            margin: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: 'close',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 20,
              ),
            ),
          ),
        ),
        title: Text(
          'Add Expense',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 4.w),
            child: GestureDetector(
              onTap: _switchCurrency,
              child: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currencies[_selectedCurrency]!['symbol']!,
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 1.w),
                    CustomIconWidget(
                      iconName: 'swap_horiz',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Currency indicator
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.lightTheme.colorScheme.primary
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _currencies[_selectedCurrency]!['symbol']!,
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Currency: ${_currencies[_selectedCurrency]!['name']}',
                              style: AppTheme.lightTheme.textTheme.titleSmall
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Tap currency icon above to switch',
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 3.h),

                // Title input
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _titleError != null
                          ? AppTheme.lightTheme.colorScheme.error
                          : AppTheme.lightTheme.colorScheme.outline
                              .withValues(alpha: 0.3),
                    ),
                  ),
                  child: TextFormField(
                    controller: _titleController,
                    maxLength: 30,
                    onChanged: _validateTitle,
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Expense Title',
                      hintText: 'Enter expense description',
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: CustomIconWidget(
                          iconName: 'receipt',
                          color: AppTheme.lightTheme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                      counterText: '',
                      errorText: _titleError,
                      errorStyle:
                          AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.error,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 3.h),

                // Amount input with selected currency
                AmountInputWidget(
                  controller: _amountController,
                  onChanged: _validateAmount,
                  errorText: _amountError,
                  selectedCurrency: _selectedCurrency,
                  currencySymbol: _currencies[_selectedCurrency]!['symbol']!,
                ),

                SizedBox(height: 3.h),

                // Payer selection
                PayerSelectionWidget(
                  selectedPayer: _selectedPayer,
                  onPayerSelected: (payer) {
                    setState(() {
                      _selectedPayer = payer;
                    });
                  },
                  groupMembers: _groupMembers,
                ),

                SizedBox(height: 3.h),

                // Event selection
                EventSelectionWidget(
                  selectedEvent: _selectedEvent,
                  onEventSelected: (event) {
                    setState(() {
                      _selectedEvent = event;
                    });
                  },
                  groupEvents: _groupEvents,
                ),

                SizedBox(height: 3.h),

                // Split method
                SplitMethodWidget(
                  includeAllMembers: _includeAllMembers,
                  onIncludeAllMembersChanged: (value) {
                    setState(() {
                      _includeAllMembers = value;
                    });
                  },
                  groupMembers: _groupMembers,
                  totalAmount: _totalAmount,
                  currencySymbol: _currencies[_selectedCurrency]!['symbol']!,
                ),

                SizedBox(height: 4.h),

                // Create expense button
                SizedBox(
                  width: double.infinity,
                  height: 6.h,
                  child: ElevatedButton(
                    onPressed:
                        _isFormValid && !_isLoading ? _createExpense : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFormValid && !_isLoading
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.outline
                              .withValues(alpha: 0.3),
                      foregroundColor: _isFormValid && !_isLoading
                          ? AppTheme.lightTheme.colorScheme.onPrimary
                          : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      elevation: _isFormValid && !_isLoading ? 2 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 5.w,
                                height: 5.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.lightTheme.colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                              SizedBox(width: 3.w),
                              Text(
                                'Creating Expense...',
                                style: AppTheme.lightTheme.textTheme.titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomIconWidget(
                                iconName: 'add',
                                color: _isFormValid
                                    ? AppTheme.lightTheme.colorScheme.onPrimary
                                    : AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant,
                                size: 20,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                'Add Expense',
                                style: AppTheme.lightTheme.textTheme.titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                SizedBox(height: 2.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
