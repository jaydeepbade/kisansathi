import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/cache/hive_service.dart';
import '../../../core/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  
  bool _otpSent = false;
  bool _isLoading = false;
  int _resendTimer = 30;

  @override
  void dispose() {
    _phoneController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        }
      });
      return _resendTimer > 0;
    });
  }

  void _sendOtp() {
    if (_phoneController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit phone number (कृपया सही 10-अंकीय नंबर डालें)'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate Supabase Phone OTP dispatch latency
    Future.delayed(const Duration(milliseconds: 1200)).then((_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _otpSent = true;
        _resendTimer = 30;
      });
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent to +91 ${_phoneController.text} successfully! (ओटीपी भेजा गया)'),
          backgroundColor: AppColors.primary,
        ),
      );
    });
  }

  void _verifyOtp() {
    String otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit OTP code.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate OTP server validation
    Future.delayed(const Duration(milliseconds: 1000)).then((_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      // Save user auth details locally in Hive cache
      HiveService.saveBool('is_logged_in', true);
      HiveService.saveString('user_phone', '+91 ${_phoneController.text}');
      
      // Seed default name for greeting
      HiveService.saveString('user_name', 'Rajesh Kumar');
      HiveService.saveString('user_location', 'Pune, Maharashtra');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login Successful! Welcome to FarmSaathi.'),
          backgroundColor: AppColors.success,
        ),
      );
      
      context.go('/dashboard');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () {
            if (_otpSent) {
              setState(() {
                _otpSent = false;
              });
            } else {
              context.go('/onboarding');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // App logo indicator
              Row(
                children: [
                  const Icon(Icons.eco, color: AppColors.primary, size: 36),
                  const SizedBox(width: 8),
                  Text(
                    'FarmSaathi',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              Text(
                _otpSent ? 'Verify OTP Code' : 'Verify Your Phone',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _otpSent
                    ? 'Enter the 6-digit code sent to +91 ${_phoneController.text}'
                    : 'We will send a 6-digit OTP code to verify your profile.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 48),

              if (!_otpSent) ...[
                // Phone input field with custom flag prefix
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: InputDecoration(
                    hintText: 'Enter Mobile Number',
                    prefixIcon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                      ),
                      child: const Text(
                        '🇮🇳 +91',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    counterText: '',
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 36),
                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : ElevatedButton(
                        onPressed: _sendOtp,
                        child: const Text('Send Verification Code'),
                      ),
              ] else ...[
                // 6-digit OTP code input boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 48,
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            if (index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            } else {
                              _focusNodes[index].unfocus();
                            }
                          } else {
                            if (index > 0) {
                              _focusNodes[index - 1].requestFocus();
                            }
                          }
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 36),
                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : ElevatedButton(
                        onPressed: _verifyOtp,
                        child: const Text('Verify & Proceed'),
                      ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the code? ",
                      style: TextStyle(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    GestureDetector(
                      onTap: _resendTimer == 0 ? _sendOtp : null,
                      child: Text(
                        _resendTimer > 0 ? 'Resend in ${_resendTimer}s' : 'Resend Code',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _resendTimer > 0 
                              ? (isDark ? Colors.white38 : Colors.black38) 
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
