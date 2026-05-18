import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../providers/admin_auth_provider.dart';
import 'widgets/admin_login_background.dart';
import 'widgets/admin_login_header.dart';
import 'widgets/admin_login_form.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _emailGlowKey = GlobalKey<FocusGlowFieldState>();
  final _passwordGlowKey = GlobalKey<FocusGlowFieldState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    final emailInvalid = !email.contains('@');
    final passwordInvalid = password.length < 8;
    if (emailInvalid || passwordInvalid) {
      if (emailInvalid) _emailGlowKey.currentState?.shake();
      if (passwordInvalid) _passwordGlowKey.currentState?.shake();
      HapticFeedback.heavyImpact();
      _formKey.currentState?.validate();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final svc = ref.read(adminAuthServiceProvider);
    final ok = await svc.signInAsAdmin(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (ok) {
      ref.invalidate(adminAuthProvider);
      context.go('/admin');
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Sign-in failed, or this account is not in the admin team.';
      });
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AdminTokens.base(isDark),
      body: Stack(
        children: [
          const AdminLoginBackground(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AdminLoginHeader(),
                    const SizedBox(height: 28),
                    AdminLoginForm(
                      emailController: _emailController,
                      passwordController: _passwordController,
                      formKey: _formKey,
                      emailFocus: _emailFocus,
                      passwordFocus: _passwordFocus,
                      emailGlowKey: _emailGlowKey,
                      passwordGlowKey: _passwordGlowKey,
                      isLoading: _isLoading,
                      errorMessage: _errorMessage,
                      onSignIn: _handleLogin,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'PROTECTED BY APPWRITE TEAMS',
                      style: AdminTokens.eyebrow(isDark).copyWith(
                        letterSpacing: 3,
                        fontSize: 10,
                        color: AdminTokens.textMuted(isDark),
                      ),
                    ).animate().fadeIn(delay: 600.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
