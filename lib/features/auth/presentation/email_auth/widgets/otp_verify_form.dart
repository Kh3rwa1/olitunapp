import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import 'email_auth_messages.dart';
import 'email_auth_primary_button.dart';
import 'email_auth_text_field.dart';

class OtpVerifyForm extends StatelessWidget {
  final String email;
  final TextEditingController otpController;
  final FocusNode otpFocus;
  final GlobalKey<FocusGlowFieldState> otpFieldKey;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final int resendCooldown;
  final VoidCallback onVerifyCode;
  final VoidCallback onResendCode;

  const OtpVerifyForm({
    super.key,
    required this.email,
    required this.otpController,
    required this.otpFocus,
    required this.otpFieldKey,
    required this.isLoading,
    required this.errorMessage,
    required this.successMessage,
    required this.resendCooldown,
    required this.onVerifyCode,
    required this.onResendCode,
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
              l10n.enterVerificationCode,
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
                text: email,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

        const SizedBox(height: 40),

        // OTP field
        EmailAuthTextField(
          controller: otpController,
          focusNode: otpFocus,
          glowKey: otpFieldKey,
          label: l10n.verificationCode,
          hint: l10n.enterCodeFromEmail,
          icon: Icons.pin_rounded,
        ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.1),

        EmailAuthMessages(
          errorMessage: errorMessage,
          successMessage: successMessage,
        ),

        const SizedBox(height: 36),

        // Verify button
        EmailAuthPrimaryButton(
              label: l10n.verifyAndContinue,
              onTap: onVerifyCode,
              isLoading: isLoading,
            )
            .animate()
            .fadeIn(delay: 400.ms, duration: 500.ms)
            .scale(begin: const Offset(0.96, 0.96)),

        const SizedBox(height: 24),

        // Resend
        Center(
          child: GestureDetector(
            onTap: resendCooldown > 0 ? null : onResendCode,
            child: Text(
              resendCooldown > 0
                  ? l10n.resendCodeIn(resendCooldown)
                  : l10n.resendCode,
              style: TextStyle(
                color: resendCooldown > 0
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
}
