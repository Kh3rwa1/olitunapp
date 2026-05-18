import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import 'email_auth_messages.dart';
import 'email_auth_primary_button.dart';
import 'email_auth_text_field.dart';

class EmailRequestForm extends StatelessWidget {
  final TextEditingController emailController;
  final FocusNode emailFocus;
  final GlobalKey<FocusGlowFieldState> emailFieldKey;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final VoidCallback onSendCode;
  final VoidCallback onSkip;

  const EmailRequestForm({
    super.key,
    required this.emailController,
    required this.emailFocus,
    required this.emailFieldKey,
    required this.isLoading,
    required this.errorMessage,
    required this.successMessage,
    required this.onSendCode,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

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
              child: const Icon(
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
              l10n.signInWithEmail,
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
          l10n.magicCodeDescription,
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white54 : Colors.black45,
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

        const SizedBox(height: 40),

        // Email field
        EmailAuthTextField(
          controller: emailController,
          focusNode: emailFocus,
          glowKey: emailFieldKey,
          label: l10n.emailAddress,
          hint: l10n.emailHint,
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.1),

        EmailAuthMessages(
          errorMessage: errorMessage,
          successMessage: successMessage,
        ),

        const SizedBox(height: 36),

        // Send Code button
        EmailAuthPrimaryButton(
              label: l10n.sendCode,
              onTap: onSendCode,
              isLoading: isLoading,
            )
            .animate()
            .fadeIn(delay: 400.ms, duration: 500.ms)
            .scale(begin: const Offset(0.96, 0.96)),

        const SizedBox(height: 28),

        // Skip link
        Center(
          child: GestureDetector(
            onTap: onSkip,
            child: Text(
              l10n.continueWithoutAccount,
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
}
