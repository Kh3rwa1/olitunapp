import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/motion/motion.dart';
import '../../../onboarding/providers/onboarding_provider.dart';
import '../providers/auth_providers.dart';
import 'widgets/email_request_form.dart';
import 'widgets/otp_verify_form.dart';

class EmailAuthScreen extends ConsumerStatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  ConsumerState<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends ConsumerState<EmailAuthScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _emailFocus = FocusNode();
  final _otpFocus = FocusNode();
  final _emailFieldKey = GlobalKey<FocusGlowFieldState>();
  final _otpFieldKey = GlobalKey<FocusGlowFieldState>();
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
    _emailFocus.dispose();
    _otpFocus.dispose();
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
      _emailFieldKey.currentState?.shake();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final result = await authRepo.sendOtp(email);

      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message;
          });
        },
        (token) {
          _userId = token;
          setState(() {
            _isLoading = false;
            _codeSent = true;
            _successMessage = 'Code sent to $email';
          });
          _startResendTimer();
        },
      );
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
      _otpFieldKey.currentState?.shake();
      return;
    }

    if (_userId == null) {
      setState(
        () => _errorMessage = 'Session expired. Please resend the code.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final result = await authRepo.verifyOtp(userId: _userId!, secret: code);

      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message;
          });
        },
        (_) {
          if (mounted) {
            ref.read(onboardingProvider.notifier).completeOnboarding();
            ref.invalidate(isAuthenticatedProvider);
            context.go('/');
          }
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _handleSkip() {
    HapticFeedback.lightImpact();
    context.go('/');
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
          child: _codeSent
              ? OtpVerifyForm(
                  email: _emailController.text.trim(),
                  otpController: _otpController,
                  otpFocus: _otpFocus,
                  otpFieldKey: _otpFieldKey,
                  isLoading: _isLoading,
                  errorMessage: _errorMessage,
                  successMessage: _successMessage,
                  resendCooldown: _resendCooldown,
                  onVerifyCode: _handleVerifyCode,
                  onResendCode: _handleSendCode,
                )
              : EmailRequestForm(
                  emailController: _emailController,
                  emailFocus: _emailFocus,
                  emailFieldKey: _emailFieldKey,
                  isLoading: _isLoading,
                  errorMessage: _errorMessage,
                  successMessage: _successMessage,
                  onSendCode: _handleSendCode,
                  onSkip: _handleSkip,
                ),
        ),
      ),
    );
  }
}
