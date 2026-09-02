import 'package:flutter/material.dart';
import 'package:itun/core/theme/app_typography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/presentation/layout/responsive_layout.dart';
import '../../../shared/providers/local_settings_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'widgets/settings_bento_sections.dart';
import '../../../core/ads/widgets/banner_ad_widget.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final scriptMode = ref.watch(effectiveScriptModeProvider);
    final appLanguage = ref.watch(appLanguageProvider);
    final soundEnabled = ref.watch(soundEnabledProvider);
    final reduceVisualEffects = ref.watch(reduceVisualEffectsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isTablet = ResponsiveLayout.isTablet(context);
    final l10n = AppLocalizations.of(context)!;

    final settingsBody = ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 20,
        vertical: isDesktop ? 32 : 20,
      ),
      children: [
        if (isDesktop) ...[
          Row(
            children: [
              IconButton(
                tooltip: 'Go back',
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white : Colors.black,
                ),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/profile');
                  }
                },
              ),
              const SizedBox(width: 8),
              Text(
                l10n.settings,
                style: AppTypography.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: Text(
              l10n.customizeExperience,
              style: AppTypography.inter(
                fontSize: 14,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],

        // Bento grid for settings sections
        if (isTablet || isDesktop)
          SettingsBentoDesktop(
            themeMode: themeMode,
            scriptMode: scriptMode,
            appLanguage: appLanguage,
            soundEnabled: soundEnabled,
            reduceVisualEffects: reduceVisualEffects,
            isDark: isDark,
          )
        else
          SettingsBentoMobile(
            themeMode: themeMode,
            scriptMode: scriptMode,
            appLanguage: appLanguage,
            soundEnabled: soundEnabled,
            reduceVisualEffects: reduceVisualEffects,
            isDark: isDark,
          ),

        const SizedBox(height: 120),
      ],
    );

    if (isDesktop) {
      return Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        body: settingsBody,
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      bottomNavigationBar: const BannerAdWidget(placement: 'settings_bottom'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Go back',
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        title: Text(
          l10n.settings,
          style: AppTypography.inter(
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: settingsBody,
    );
  }
}
