import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';

class EmailAuthScreen extends ConsumerStatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  ConsumerState<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends ConsumerState<EmailAuthScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _codeSent = false;
  String? _errorMessage;
  String? _successMessage;
  String? _userId; // Appwrite userId from createEmailToken

  // Resend timer
  int _resendCooldown = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendCooldown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) timer.cancel();
      });
    });
  }

  Future<void> _handleSendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final token = await authRepo.sendOtp(email);
      _userId = token.userId;

      setState(() {
        _isLoading = false;
        _codeSent = true;
        _successMessage = 'Code sent to $email';
      });
      _startResendTimer();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _handleVerifyCode() async {
    final code = _otpController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter the verification code');
      return;
    }

    if (_userId == null) {
      setState(() => _errorMessage = 'Session expired. Please resend the code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.verifyOtp(userId: _userId!, secret: code);

      // Invalidate cached auth state so AuthGate widgets update
      ref.invalidate(isAuthenticatedProvider);

      // Try to fetch user profile and sync name
      try {
        final user = await authRepo.getMe();
        if (user.name.isNotEmpty) {
          await updateUserName(ref, user.name);
        }
      } catch (_) {}

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _handleSkip() {
    HapticFeedback.lightImpact();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () {
            if (_codeSent) {
              setState(() {
                _codeSent = false;
                _errorMessage = null;
                _successMessage = null;
                _otpController.clear();
              });
            } else {
              context.go('/welcome');
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: _handleSkip,
            child: Text(
              'Skip',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black45,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: _codeSent ? _buildOtpStep(isDark) : _buildEmailStep(isDark),
        ),
      ),
    );
  }

  // ─── Step 1: Email Input ───
  Widget _buildEmailStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // Icon
        Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.email_outlined,
                color: AppColors.primary,
                size: 36,
              ),
            )
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),

        const SizedBox(height: 28),

        Text(
              'Sign In with Email',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -0.5,
              ),
            )
            .animate()
            .fadeIn(delay: 100.ms, duration: 500.ms)
            .slideX(begin: -0.05),

        const SizedBox(height: 8),

        Text(
          'We\'ll send you a magic code to verify your identity. No password needed!',
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white54 : Colors.black45,
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

        const SizedBox(height: 40),

        // Email field
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'learner@example.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          isDark: isDark,
        ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.1),

        _buildMessages(),

        const SizedBox(height: 36),

        // Send Code button
        _buildPrimaryButton(
              label: 'Send Code',
              onTap: _handleSendCode,
              isDark: isDark,
            )
            .animate()
            .fadeIn(delay: 400.ms, duration: 500.ms)
            .scale(begin: const Offset(0.96, 0.96)),

        const SizedBox(height: 28),

        // Skip link
        Center(
          child: GestureDetector(
            onTap: _handleSkip,
            child: Text(
              'Continue without an account',
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ).animate().fadeIn(delay: 600.ms, duration: 500.ms),

        const SizedBox(height: 40),
      ],
    );
  }

  // ─── Step 2: OTP Verification ───
  Widget _buildOtpStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // Icon
        Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.verified_rounded,
                color: AppColors.primary,
                size: 36,
              ),
            )
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),

        const SizedBox(height: 28),

        Text(
              'Enter Verification Code',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -0.5,
              ),
            )
            .animate()
            .fadeIn(delay: 100.ms, duration: 500.ms)
            .slideX(begin: -0.05),

        const SizedBox(height: 8),

        RichText(
          text: TextSpan(
            text: 'We sent a code to ',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white54 : Colors.black45,
              height: 1.5,
            ),
            children: [
              TextSpan(
                text: _emailController.text.trim(),
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

        const SizedBox(height: 40),

        // OTP field
        _buildTextField(
          controller: _otpController,
          label: 'Verification Code',
          hint: 'Enter code from email',
          icon: Icons.pin_rounded,
          keyboardType: TextInputType.text,
          isDark: isDark,
        ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.1),

        _buildMessages(),

        const SizedBox(height: 36),

        // Verify button
        _buildPrimaryButton(
              label: 'Verify & Continue',
              onTap: _handleVerifyCode,
              isDark: isDark,
            )
            .animate()
            .fadeIn(delay: 400.ms, duration: 500.ms)
            .scale(begin: const Offset(0.96, 0.96)),

        const SizedBox(height: 24),

        // Resend
        Center(
          child: GestureDetector(
            onTap: _resendCooldown > 0 ? null : _handleSendCode,
            child: Text(
              _resendCooldown > 0
                  ? 'Resend code in ${_resendCooldown}s'
                  : 'Resend code',
              style: TextStyle(
                color: _resendCooldown > 0
                    ? (isDark ? Colors.white24 : Colors.black26)
                    : AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ).animate().fadeIn(delay: 600.ms, duration: 500.ms),

        const SizedBox(height: 40),
      ],
    );
  }

  // ─── Shared Widgets ───

  Widget _buildMessages() {
    return Column(
      children: [
        if (_errorMessage != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _errorMessage!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Icon(
                    Icons.copy_rounded,
                    color: Colors.red.withValues(alpha: 0.5),
                    size: 16,
                  ),
                ),
              ],
            ),
          ).animate().shake(),
        ],
        if (_successMessage != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _successMessage!,
                    style: const TextStyle(color: Colors.green, fontSize: 13),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),
        ],
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : Colors.black87,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 16,
              letterSpacing: keyboardType == TextInputType.number ? 8 : 0,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark ? Colors.white24 : Colors.black26,
                fontSize: 15,
                letterSpacing: 0,
              ),
              prefixIcon: Icon(
                icon,
                color: isDark ? Colors.white38 : Colors.black38,
                size: 22,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
      ],
    );
  }
}
