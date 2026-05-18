import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';

class AdminLoginForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;
  final FocusNode emailFocus;
  final FocusNode passwordFocus;
  final GlobalKey<FocusGlowFieldState> emailGlowKey;
  final GlobalKey<FocusGlowFieldState> passwordGlowKey;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onSignIn;

  const AdminLoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.formKey,
    required this.emailFocus,
    required this.passwordFocus,
    required this.emailGlowKey,
    required this.passwordGlowKey,
    required this.isLoading,
    required this.errorMessage,
    required this.onSignIn,
  });

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
      hintStyle: AdminTokens.body(
        isDark,
      ).copyWith(color: AdminTokens.textMuted(isDark)),
      prefixIcon: Icon(icon, size: 18, color: AdminTokens.textTertiary(isDark)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
      decoration: BoxDecoration(
        color: AdminTokens.raised(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusXl),
        border: Border.all(color: AdminTokens.border(isDark)),
        boxShadow: AdminTokens.overlayShadow(isDark),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _fieldLabel('Email address', isDark),
            const SizedBox(height: 8),
            FocusGlowField(
              key: emailGlowKey,
              focusNode: emailFocus,
              glowColor: AppColors.primary,
              child: TextFormField(
                controller: emailController,
                focusNode: emailFocus,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                enabled: !isLoading,
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
              key: passwordGlowKey,
              focusNode: passwordFocus,
              glowColor: AppColors.primary,
              child: TextFormField(
                controller: passwordController,
                focusNode: passwordFocus,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                enabled: !isLoading,
                onFieldSubmitted: (_) => onSignIn(),
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
            if (errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        errorMessage!,
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
                onPressed: isLoading ? null : onSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
                  ),
                ),
                child: isLoading
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
}
