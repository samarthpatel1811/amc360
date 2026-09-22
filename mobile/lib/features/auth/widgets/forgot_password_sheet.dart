import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

class ForgotPasswordSheet extends StatefulWidget {
  final String initialEmail;
  final void Function(String email, String newPassword)? onPasswordResetSuccess;

  const ForgotPasswordSheet({
    super.key,
    this.initialEmail = '',
    this.onPasswordResetSuccess,
  });

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  int _currentStep = 1; // 1: Email, 2: Code, 3: New Password
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successInfo;
  bool _mailSent = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  int _resendCountdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail.trim();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _countdownTimer?.cancel();
    setState(() => _resendCountdown = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 1) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
        setState(() => _resendCountdown = 0);
      }
    });
  }

  Future<void> _sendVerificationCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successInfo = null;
    });

    try {
      final res = await ApiClient().post('/auth/forgot-password', data: {
        'email': email,
      });

      if (res.data['success'] == true) {
        final data = res.data['data'] as Map<String, dynamic>?;
        final mailSent = data?['mail_sent'] == true;
        setState(() {
          _isLoading = false;
          _currentStep = 2;
          _mailSent = mailSent;
          _codeController.text = ''; // Always clean and blank; user enters code from Gmail!
          _successInfo = mailSent ? (res.data['message'] ?? 'Verification code sent to your email.') : null;
        });
        _startResendTimer();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = res.data['message'] ?? 'Failed to send code. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _verifyCode() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();

    if (code.length != 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successInfo = null;
    });

    try {
      final res = await ApiClient().post('/auth/verify-reset-code', data: {
        'email': email,
        'code': code,
      });

      if (res.data['success'] == true) {
        setState(() {
          _isLoading = false;
          _currentStep = 3;
          _successInfo = 'Code verified. Enter your new password.';
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = res.data['message'] ?? 'Invalid code';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters');
      return;
    }

    if (password != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successInfo = null;
    });

    try {
      final res = await ApiClient().post('/auth/reset-password', data: {
        'email': email,
        'code': code,
        'password': password,
        'password_confirmation': confirmPassword,
      });

      if (res.data['success'] == true) {
        setState(() => _isLoading = false);
        if (mounted) {
          widget.onPasswordResetSuccess?.call(email, password);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset successfully! You can now sign in.'),
              backgroundColor: AppTheme.success,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = res.data['message'] ?? 'Failed to reset password';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grab Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Row with Step indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reset Password',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentStep == 1
                            ? 'Step 1: Enter your registered email'
                            : _currentStep == 2
                                ? 'Step 2: Enter 6-digit verification code'
                                : 'Step 3: Create a new password',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withAlpha(isDark ? 30 : 15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_currentStep / 3',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Error or Success Banner
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withAlpha(isDark ? 30 : 15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEF4444).withAlpha(60)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (_successInfo != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withAlpha(isDark ? 30 : 15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF10B981).withAlpha(60)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successInfo!,
                          style: const TextStyle(color: Color(0xFF10B981), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // STEP 1: Enter Email
              if (_currentStep == 1) ...[
                AppTextField(
                  label: 'Registered Email Address',
                  hint: 'e.g. admin@cooltech.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.mail_outline_rounded),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Send Verification Code',
                  icon: Icons.send_rounded,
                  isLoading: _isLoading,
                  onPressed: _sendVerificationCode,
                ),
              ],

              // STEP 2: Enter 6-digit Code
              if (_currentStep == 2) ...[
                if (_mailSent) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withAlpha(isDark ? 30 : 15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF10B981).withAlpha(60)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.mark_email_read_rounded, color: Color(0xFF10B981), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Verification email sent to ${_emailController.text.trim()}! Please check your Gmail inbox and enter the 6-digit code below.',
                            style: const TextStyle(color: Color(0xFF10B981), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withAlpha(isDark ? 35 : 20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF59E0B).withAlpha(70)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Please check your email (${_emailController.text.trim()}) and enter the 6-digit code below.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                AppTextField(
                  label: '6-Digit Verification Code',
                  hint: '123456',
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.pin_outlined),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _currentStep = 1),
                      child: const Text('Change Email'),
                    ),
                    TextButton(
                      onPressed: _resendCountdown == 0 ? _sendVerificationCode : null,
                      child: Text(
                        _resendCountdown > 0
                            ? 'Resend Code in ${_resendCountdown}s'
                            : 'Resend Code',
                        style: TextStyle(
                          color: _resendCountdown > 0 ? Colors.grey : const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Verify Code',
                  icon: Icons.verified_user_outlined,
                  isLoading: _isLoading,
                  onPressed: _verifyCode,
                ),
              ],

              // STEP 3: Set New Password
              if (_currentStep == 3) ...[
                AppTextField(
                  label: 'New Password',
                  hint: 'At least 8 characters',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Confirm New Password',
                  hint: 'Re-enter your new password',
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Reset & Save Password',
                  icon: Icons.check_circle_rounded,
                  isLoading: _isLoading,
                  onPressed: _resetPassword,
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
