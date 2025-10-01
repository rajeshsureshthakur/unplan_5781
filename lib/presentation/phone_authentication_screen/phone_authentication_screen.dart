import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import './widgets/country_code_selector_widget.dart';
import './widgets/country_selection_bottom_sheet_widget.dart';
import './widgets/phone_input_widget.dart';

class PhoneAuthenticationScreen extends StatefulWidget {
  const PhoneAuthenticationScreen({Key? key}) : super(key: key);

  @override
  State<PhoneAuthenticationScreen> createState() =>
      _PhoneAuthenticationScreenState();
}

class _PhoneAuthenticationScreenState extends State<PhoneAuthenticationScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();

  String _selectedCountryCode = '+1';
  String _selectedCountryFlag = '🇺🇸';
  String _selectedCountryName = 'United States';

  bool _isPhoneValid = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_phoneFocusNode.hasFocus && _errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  void _onCountrySelected(Map<String, String> country) {
    setState(() {
      _selectedCountryCode = country['code']!;
      _selectedCountryFlag = country['flag']!;
      _selectedCountryName = country['name']!;
      _phoneController.clear();
      _isPhoneValid = false;
      _errorMessage = null;
    });
  }

  void _onPhoneValidationChanged(bool isValid) {
    setState(() {
      _isPhoneValid = isValid;
    });
  }

  void _showCountrySelector() {
    // Dismiss keyboard first
    FocusScope.of(context).unfocus();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CountrySelectionBottomSheetWidget(
        onCountrySelected: _onCountrySelected,
      ),
    );
  }

  Future<void> _sendCode() async {
    if (!_isPhoneValid) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    try {
      // Simulate Firebase Auth phone verification
      await Future.delayed(const Duration(seconds: 2));

      // Mock validation - simulate different scenarios
      final phoneNumber =
          _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');

      // Allow test number 1234567890 to pass through successfully
      if (phoneNumber == '0000000000') {
        // Simulate invalid number error
        setState(() {
          _errorMessage = 'Invalid phone number format.';
        });
        return;
      }

      // Success - provide haptic feedback
      HapticFeedback.lightImpact();

      // Navigate to OTP verification screen
      Navigator.pushNamed(
        context,
        '/otp-verification-screen',
        arguments: {
          'phoneNumber': '$_selectedCountryCode ${_phoneController.text}',
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error. Please check your connection.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image - Fixed to use Image.asset directly
          Positioned.fill(
            child: Image.asset(
              'assets/images/image-1759246657145.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback in case asset loading fails
                return Container(
                  color: const Color(0xFF4A90E2),
                );
              },
            ),
          ),

          // Dark overlay for better text readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withAlpha(77),
            ),
          ),

          // Main content
          SafeArea(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 8.h),

                      // App Logo with blue gradient
                      Container(
                        width: 20.w,
                        height: 20.w,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF4A90E2),
                              Color(0xFF357ABD),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(51),
                              blurRadius: 8.0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'U',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 6.h),

                      // Welcome text in white
                      Text(
                        'Welcome to Unplan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 2.h),

                      Text(
                        'Enter your phone number to get started',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 8.h),

                      // White rounded card container
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(26),
                              blurRadius: 10.0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Phone Number',
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            SizedBox(height: 3.h),

                            // Country code and phone input row
                            Row(
                              children: [
                                CountryCodeSelectorWidget(
                                  selectedCountryCode: _selectedCountryCode,
                                  selectedCountryFlag: _selectedCountryFlag,
                                  selectedCountryName: _selectedCountryName,
                                  onTap: _showCountrySelector,
                                ),
                                SizedBox(width: 3.w),
                                Expanded(
                                  child: PhoneInputWidget(
                                    controller: _phoneController,
                                    countryCode: _selectedCountryCode,
                                    onValidationChanged:
                                        _onPhoneValidationChanged,
                                    errorText: _errorMessage,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 4.h),

                            // Send code button - styled to match design
                            SizedBox(
                              width: double.infinity,
                              height: 6.h,
                              child: ElevatedButton(
                                onPressed: _isPhoneValid && !_isLoading
                                    ? _sendCode
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isPhoneValid
                                      ? Colors.grey[600]
                                      : Colors.grey[300],
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        width: 20.0,
                                        height: 20.0,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.0,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        'Send Code',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 6.h),

                      // Terms and privacy links in white
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.sp,
                            ),
                            children: [
                              const TextSpan(
                                text: 'By continuing, you agree to our ',
                              ),
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                  color: Colors.white,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: Colors.white,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 4.h),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.removeListener(_onFocusChange);
    _phoneFocusNode.dispose();
    super.dispose();
  }
}
