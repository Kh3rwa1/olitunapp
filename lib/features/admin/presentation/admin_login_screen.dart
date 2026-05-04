import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/motion/motion.dart';
import '../../../core/theme/admin_tokens.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_auth_provider.dart';

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
          _buildBackground(isDark),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBrand(isDark),
                    const SizedBox(height: 28),
                    _buildLoginCard(isDark),
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

  Widget _buildBackground(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF050810),
                  const Color(0xFF0A1018),
                  const Color(0xFF050810),
                ]
              : [
                  AdminTokens.neutral50,
                  Colors.white,
                  AdminTokens.neutral75,
                ],
        ),
      ),
      child: Stack(
        children: [
          _blob(
            color: AppColors.primary
                .withValues(alpha: isDark ? 0.18 : 0.12),
            top: -80,
            left: -60,
            size: 320,
            duration: 18.seconds,
          ),
          _blob(
            color: AppColors.duoBlue
                .withValues(alpha: isDark ? 0.12 : 0.08),
            bottom: -100,
            right: -50,
            size: 360,
            duration: 22.seconds,
          ),
          // Subtle dot grid for texture.
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: isDark ? 0.05 : 0.04,
                child: CustomPaint(painter: _DotGridPainter(isDark: isDark)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob({
    required Color color,
    double? top,
    double? left,
    double? bottom,
    double? right,
    required Duration duration,
    double size = 300,
  }) {
    return Positioned(
      top: top,
      left: left,
      bottom: bottom,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .move(
            begin: Offset.zero,
            end: const Offset(40, 40),
            duration: duration,
            curve: Curves.easeInOut,
          )
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.18, 1.18),
            duration: duration,
            curve: Curves.easeInOut,
          ),
    );
  }

  Widget _buildBrand(bool isDark) {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: AdminTokens.brandGlow(AppColors.primary),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset(
              'assets/icons/olitun_logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ).animate().scale(
              duration: 500.ms,
              curve: Curves.easeOutBack,
              begin: const Offset(0.7, 0.7),
            ),
        const SizedBox(height: 16),
        Text(
          'Olitun Studio',
          style: AdminTokens.pageTitle(isDark).copyWith(fontSize: 28),
        ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1, end: 0),
        const SizedBox(height: 6),
        Text(
          'Sign in to manage content',
          style: AdminTokens.body(isDark),
        ).animate().fadeIn(delay: 250.ms),
      ],
    );
  }

  Widget _buildLoginCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
      decoration: BoxDecoration(
        color: AdminTokens.raised(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusXl),
        border: Border.all(color: AdminTokens.border(isDark)),
        boxShadow: AdminTokens.overlayShadow(isDark),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _fieldLabel('Email address', isDark),
            const SizedBox(height: 8),
            FocusGlowField(
              key: _emailGlowKey,
              focusNode: _emailFocus,
              glowColor: AppColors.primary,
              child: TextFormField(
                controller: _emailController,
                focusNode: _emailFocus,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                enabled: !_isLoading,
                style: AdminTokens.bodyStrong(isDark),
                decoration: _decoration(
                  hint: 'admin@example.com',
                  icon: Icons.alternate_email_rounded,
                  isDark: isDark,
                ),
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'Enter a valid email'
                    : null,
              ),
            ),
            const SizedBox(height: 18),
            _fieldLabel('Password', isDark),
            const SizedBox(height: 8),
            FocusGlowField(
              key: _passwordGlowKey,
              focusNode: _passwordFocus,
              glowColor: AppColors.primary,
              child: TextFormField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                enabled: !_isLoading,
                onFieldSubmitted: (_) => _handleLogin(),
                style: AdminTokens.bodyStrong(isDark),
                decoration: _decoration(
                  hint: 'Min 8 characters',
                  icon: Icons.lock_outline_rounded,
                  isDark: isDark,
                ),
                validator: (v) =>
                    (v == null || v.length < 8) ? 'Min 8 characters' : null,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 18, color: AppColors.error),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AdminTokens.label(isDark).copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_open_rounded, size: 18),
                          SizedBox(width: 10),
                          Text(
                            'Sign in',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                'Need access? Ask a team owner to add you in Appwrite.',
                textAlign: TextAlign.center,
                style: AdminTokens.label(isDark).copyWith(
                  color: AdminTokens.textTertiary(isDark),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.04, end: 0);
  }

  Widget _fieldLabel(String text, bool isDark) {
    return Text(
      text,
      style: AdminTokens.label(isDark).copyWith(
        color: AdminTokens.textPrimary(isDark),
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    );
  }

  InputDecoration _decoration({
    required String hint,
    required IconData icon,
    required bool isDark,
  }) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AdminTokens.sunken(isDark),
      hintStyle: AdminTokens.body(isDark)
          .copyWith(color: AdminTokens.textMuted(isDark)),
      prefixIcon: Icon(icon,
          size: 18, color: AdminTokens.textTertiary(isDark)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
        borderSide: BorderSide(color: AdminTokens.border(isDark)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
        borderSide: BorderSide(color: AdminTokens.border(isDark)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final bool isDark;
  _DotGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.white : Colors.black
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
