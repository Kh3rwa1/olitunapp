import 'package:flutter/material.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';

class TranslationStatsCard extends StatelessWidget {
  final String selectedLang;
  final String langName;
  final String langFlag;
  final int totalCount;
  final int translatedCount;
  final bool isDark;

  const TranslationStatsCard({
    super.key,
    required this.selectedLang,
    required this.langName,
    required this.langFlag,
    required this.totalCount,
    required this.translatedCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final pct = totalCount > 0 ? (translatedCount / totalCount * 100).round() : 100;
    final isComplete = pct >= 95;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AdminTokens.raised(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
        border: Border.all(color: AdminTokens.border(isDark)),
        boxShadow: AdminTokens.raisedShadow(isDark),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              langFlag,
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$langName Translation Coverage',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AdminTokens.textPrimary(isDark),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (isComplete ? AppColors.accentForest : AppColors.accentOchre)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$pct% Covered',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isComplete ? AppColors.accentForest : AppColors.accentOchre,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalCount > 0 ? (translatedCount / totalCount).clamp(0.0, 1.0) : 1.0,
                    backgroundColor: AdminTokens.sunken(isDark),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isComplete ? AppColors.primary : AppColors.accentOchre,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$translatedCount of $totalCount items have localized meaning & transliteration in $langName',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AdminTokens.textSecondary(isDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
