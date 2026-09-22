import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/typing_practice_controller.dart';

/// Celebratory card displayed when a user successfully completes a typing practice session.
class TypingPracticeDoneCard extends StatelessWidget {
  final TypingPracticeArgs args;
  final bool isDark;
  final VoidCallback onTryAgain;

  const TypingPracticeDoneCard({
    super.key,
    required this.args,
    required this.isDark,
    required this.onTryAgain,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark
        ? AppColors.charcoal.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.8);
    final cardBorder = isDark
        ? Colors.white10
        : Colors.black.withValues(alpha: 0.05);

    final isDesktopWeb =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black26
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Celebratory check icon and title
            const Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Practiced Successfully',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Ol Chiki resolved word
            Text(
              args.target,
              style: const TextStyle(
                fontFamily: 'OlChiki',
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            // Latin
            Text(
              args.latin,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            // Meaning
            Text(
              args.meaning,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 20),
            Divider(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
            ),
            const SizedBox(height: 12),
            // Try again link
            TextButton(
              onPressed: onTryAgain,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Try Again',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      fontSize: 14,
                    ),
                  ),
                  if (isDesktopWeb) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Enter ↵',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
