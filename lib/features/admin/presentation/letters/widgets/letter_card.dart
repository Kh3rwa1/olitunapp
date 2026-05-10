import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/models/content_models.dart';

/// Single letter card in the admin grid.
///
/// Extracted from the private `_LetterCard` in the original monolithic screen.
class LetterCard extends StatelessWidget {
  final LetterModel letter;
  final bool isDark;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const LetterCard({
    super.key,
    required this.letter,
    required this.isDark,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          onTap: onEdit,
          onLongPress: onDelete,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.premiumMint,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentMint.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  letter.charOlChiki,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'OlChiki',
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    letter.transliterationLatin,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (index * 50).ms, duration: 300.ms)
        .scale(begin: const Offset(0.9, 0.9));
  }
}
