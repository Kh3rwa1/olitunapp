import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';

class AdminLoginHeader extends StatelessWidget {
  const AdminLoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
}
