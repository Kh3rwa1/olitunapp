import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../settings/controllers/admin_settings_controller.dart';

class TranslationEngineCard extends ConsumerWidget {
  const TranslationEngineCard({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(adminSettingsControllerProvider);
    final isSaving = settingsState.isSaving('translation_engine');
    final isIndicTrans = settingsState.isIndicTrans2Engine;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminTokens.raised(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
        border: Border.all(color: AdminTokens.border(isDark)),
        boxShadow: AdminTokens.raisedShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentPurpleDark, AppColors.indigoVivid],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.indigoVivid.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 22,
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
                          'AI Translation Engine',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AdminTokens.textPrimary(isDark),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (isIndicTrans
                                        ? AppColors.indigoVivid
                                        : AppColors.primary)
                                    .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  (isIndicTrans
                                          ? AppColors.indigoVivid
                                          : AppColors.primary)
                                      .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isIndicTrans
                                      ? AppColors.indigoVivid
                                      : AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isIndicTrans
                                    ? 'IndicTrans2 (Cloudflare)'
                                    : 'Google Translate',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isIndicTrans
                                      ? AppColors.indigoVivid
                                      : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose the primary neural model powering Instant Translate and Ol Chiki translation.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AdminTokens.textSecondary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSaving)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Options Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              final children = [
                _EngineChoiceTile(
                  isDark: isDark,
                  isSelected: isIndicTrans,
                  isDisabled: isSaving,
                  badge: 'Recommended for Indic',
                  badgeColor: AppColors.indigoVivid,
                  icon: Icons.hub_rounded,
                  title: 'IndicTrans2 (AI4Bharat)',
                  subtitle:
                      'Cloudflare Workers AI · 1B Multilingual Model. Specialized for Indian languages with native Ol Chiki (sat_Olck) output. Automatic Google Translate fallback for reverse queries.',
                  onTap: () {
                    if (!isIndicTrans && !isSaving) {
                      ref
                          .read(adminSettingsControllerProvider.notifier)
                          .saveSetting('translation_engine', 'cloudflare');
                    }
                  },
                ),
                SizedBox(width: isNarrow ? 0 : 16, height: isNarrow ? 12 : 0),
                _EngineChoiceTile(
                  isDark: isDark,
                  isSelected: !isIndicTrans,
                  isDisabled: isSaving,
                  badge: 'Standard NMT',
                  badgeColor: AppColors.primary,
                  icon: Icons.g_translate_rounded,
                  title: 'Google Translate',
                  subtitle:
                      'Google Neural Machine Translation · Full bidirectional translation across global languages including Santali and English.',
                  onTap: () {
                    if (isIndicTrans && !isSaving) {
                      ref
                          .read(adminSettingsControllerProvider.notifier)
                          .saveSetting('translation_engine', 'google');
                    }
                  },
                ),
              ];

              return isNarrow
                  ? Column(children: children)
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: children[0]),
                        children[1],
                        Expanded(child: children[2]),
                      ],
                    );
            },
          ),

          const SizedBox(height: 12),

          // Footer info
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: AdminTokens.textSecondary(isDark),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Switching engines applies immediately to the Appwrite translation pipeline. Cache entries are isolated per engine.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AdminTokens.textSecondary(isDark),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EngineChoiceTile extends StatelessWidget {
  final bool isDark;
  final bool isSelected;
  final bool isDisabled;
  final String badge;
  final Color badgeColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _EngineChoiceTile({
    required this.isDark,
    required this.isSelected,
    required this.isDisabled,
    required this.badge,
    required this.badgeColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? badgeColor : AdminTokens.border(isDark);

    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? badgeColor.withValues(alpha: isDark ? 0.12 : 0.06)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.02)
                    : Colors.black.withValues(alpha: 0.02)),
          borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? badgeColor
                      : AdminTokens.textSecondary(isDark),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AdminTokens.textPrimary(isDark),
                    ),
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? badgeColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? badgeColor
                          : AdminTokens.border(isDark),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                height: 1.4,
                color: AdminTokens.textSecondary(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
