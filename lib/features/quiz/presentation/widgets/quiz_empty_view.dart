import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';

class QuizEmptyView extends StatelessWidget {
  final bool isNotFound;

  const QuizEmptyView({super.key, this.isNotFound = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNotFound ? Icons.error_outline_rounded : Icons.quiz_outlined,
              size: 64,
              color: isNotFound
                  ? AppColors.error.withValues(alpha: 0.8)
                  : AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              isNotFound
                  ? 'Quiz not found'
                  : AppLocalizations.of(context)!.noQuestionsYet,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(AppLocalizations.of(context)!.goBack),
            ),
          ],
        ),
      ),
    );
  }
}
