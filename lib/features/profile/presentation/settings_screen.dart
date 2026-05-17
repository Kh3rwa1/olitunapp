import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/hive_service.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../profile/presentation/providers/profile_providers.dart';
import '../../../core/presentation/layout/responsive_layout.dart';
import '../../../shared/providers/local_settings_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'widgets/settings_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final scriptMode = ref.watch(scriptModeProvider);
    final appLanguage = ref.watch(appLanguageProvider);
    final soundEnabled = ref.watch(soundEnabledProvider);
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
          Text(
            l10n.settings,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.customizeExperience,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 32),
        ],

        // Bento grid for settings sections
        if (isTablet || isDesktop)
          _buildDesktopBento(
            context,
            ref,
            themeMode,
            scriptMode,
            appLanguage,
            soundEnabled,
            isDark,
          )
        else
          _buildMobileBento(
            context,
            ref,
            themeMode,
            scriptMode,
            appLanguage,
            soundEnabled,
            isDark,
          ),

        const SizedBox(height: 120),
      ],
    );

    if (isDesktop) {
      return settingsBody;
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => context.go('/'),
        ),
        title: Text(
          l10n.settings,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: settingsBody,
    );
  }

  Widget _buildDesktopBento(
    BuildContext context,
    WidgetRef ref,
    String themeMode,
    String scriptMode,
    String appLanguage,
    bool soundEnabled,
    bool isDark,
  ) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        // Appearance + Script grouped together
        SizedBox(
          width: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SettingsCard(
                  title: AppLocalizations.of(context)!.appearance,
                  icon: Icons.palette_rounded,
                  color: AppColors.duoPurple,
                  index: 0,
                  children: [
                    SettingTile(
                      icon: Icons.dark_mode_rounded,
                      title: AppLocalizations.of(context)!.darkMode,
                      subtitle: _getThemeLabel(context, themeMode),
                      isDark: isDark,
                      onTap: () => _showThemeDialog(context, ref, themeMode),
                    ),
                    const SizedBox(height: 10),
                    SettingTile(
                      icon: Icons.language_rounded,
                      title: AppLocalizations.of(context)!.appLanguage,
                      subtitle: _getLanguageLabel(context, appLanguage),
                      isDark: isDark,
                      onTap: () =>
                          _showLanguageDialog(context, ref, appLanguage),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SettingsCard(
                  title: AppLocalizations.of(context)!.scriptDisplay,
                  icon: Icons.translate_rounded,
                  color: AppColors.duoBlue,
                  index: 1,
                  children: [
                    SettingTile(
                      icon: Icons.translate_rounded,
                      title: AppLocalizations.of(context)!.scriptMode,
                      subtitle: _getScriptLabel(context, scriptMode),
                      isDark: isDark,
                      onTap: () => _showScriptDialog(context, ref, scriptMode),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Sound + Data grouped
        SizedBox(
          width: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SettingsCard(
                  title: AppLocalizations.of(context)!.sound,
                  icon: Icons.music_note_rounded,
                  color: AppColors.primary,
                  index: 2,
                  children: [
                    ToggleTile(
                      icon: Icons.volume_up_rounded,
                      title: AppLocalizations.of(context)!.soundEffects,
                      subtitle: AppLocalizations.of(
                        context,
                      )!.playSoundsForActions,
                      value: soundEnabled,
                      isDark: isDark,
                      onChanged: (value) => toggleSound(ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SettingsCard(
                  title: AppLocalizations.of(context)!.dangerZone,
                  icon: Icons.warning_rounded,
                  color: AppColors.duoRed,
                  index: 3,
                  children: [
                    SettingTile(
                      icon: Icons.restart_alt_rounded,
                      title: AppLocalizations.of(context)!.resetProgress,
                      subtitle: AppLocalizations.of(
                        context,
                      )!.clearAllLearningData,
                      isDark: isDark,
                      isDestructive: true,
                      onTap: () => _showResetDialog(context, ref),
                    ),
                    const SizedBox(height: 10),
                    SettingTile(
                      icon: Icons.delete_forever_rounded,
                      title: AppLocalizations.of(context)!.deleteAccount,
                      subtitle: AppLocalizations.of(
                        context,
                      )!.deleteAccountSubtitle,
                      isDark: isDark,
                      isDestructive: true,
                      onTap: () => _showDeleteAccountDialog(context, ref),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: _buildLegalCard(context, isDark, 4),
        ),
      ],
    );
  }

  Widget _buildMobileBento(
    BuildContext context,
    WidgetRef ref,
    String themeMode,
    String scriptMode,
    String appLanguage,
    bool soundEnabled,
    bool isDark,
  ) {
    return Column(
      children: [
        SettingsCard(
          title: AppLocalizations.of(context)!.appearance,
          icon: Icons.palette_rounded,
          color: AppColors.duoPurple,
          index: 0,
          children: [
            SettingTile(
              icon: Icons.dark_mode_rounded,
              title: AppLocalizations.of(context)!.darkMode,
              subtitle: _getThemeLabel(context, themeMode),
              isDark: isDark,
              onTap: () => _showThemeDialog(context, ref, themeMode),
            ),
            const SizedBox(height: 10),
            SettingTile(
              icon: Icons.language_rounded,
              title: AppLocalizations.of(context)!.appLanguage,
              subtitle: _getLanguageLabel(context, appLanguage),
              isDark: isDark,
              onTap: () => _showLanguageDialog(context, ref, appLanguage),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SettingsCard(
          title: AppLocalizations.of(context)!.scriptDisplay,
          icon: Icons.translate_rounded,
          color: AppColors.duoBlue,
          index: 1,
          children: [
            SettingTile(
              icon: Icons.translate_rounded,
              title: AppLocalizations.of(context)!.scriptMode,
              subtitle: _getScriptLabel(context, scriptMode),
              isDark: isDark,
              onTap: () => _showScriptDialog(context, ref, scriptMode),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SettingsCard(
          title: AppLocalizations.of(context)!.sound,
          icon: Icons.music_note_rounded,
          color: AppColors.primary,
          index: 2,
          children: [
            ToggleTile(
              icon: Icons.volume_up_rounded,
              title: AppLocalizations.of(context)!.soundEffects,
              subtitle: AppLocalizations.of(context)!.playSoundsForActions,
              value: soundEnabled,
              isDark: isDark,
              onChanged: (value) => toggleSound(ref),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildLegalCard(context, isDark, 4),
        const SizedBox(height: 16),
        SettingsCard(
          title: AppLocalizations.of(context)!.dangerZone,
          icon: Icons.warning_rounded,
          color: AppColors.duoRed,
          index: 3,
          children: [
            SettingTile(
              icon: Icons.restart_alt_rounded,
              title: AppLocalizations.of(context)!.resetProgress,
              subtitle: AppLocalizations.of(context)!.clearAllLearningData,
              isDark: isDark,
              isDestructive: true,
              onTap: () => _showResetDialog(context, ref),
            ),
            const SizedBox(height: 10),
            SettingTile(
              icon: Icons.delete_forever_rounded,
              title: AppLocalizations.of(context)!.deleteAccount,
              subtitle: AppLocalizations.of(context)!.deleteAccountSubtitle,
              isDark: isDark,
              isDestructive: true,
              onTap: () => _showDeleteAccountDialog(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegalCard(BuildContext context, bool isDark, int index) {
    final l10n = AppLocalizations.of(context)!;
    return SettingsCard(
      title: l10n.legal,
      icon: Icons.verified_user_rounded,
      color: AppColors.duoGreen,
      index: index,
      children: [
        SettingTile(
          icon: Icons.privacy_tip_rounded,
          title: l10n.privacyPolicy,
          subtitle: l10n.privacyPolicySubtitle,
          isDark: isDark,
          onTap: () => context.go('/privacy'),
        ),
        const SizedBox(height: 10),
        SettingTile(
          icon: Icons.description_rounded,
          title: l10n.termsOfUse,
          subtitle: l10n.termsOfUseSubtitle,
          isDark: isDark,
          onTap: () => context.go('/terms'),
        ),
      ],
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, String current) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.chooseTheme,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            ThemeOption(
              label: AppLocalizations.of(context)!.systemDefault,
              value: 'system',
              current: current,
              ref: ref,
              isDark: isDark,
            ),
            ThemeOption(
              label: AppLocalizations.of(context)!.light,
              value: 'light',
              current: current,
              ref: ref,
              isDark: isDark,
            ),
            ThemeOption(
              label: AppLocalizations.of(context)!.dark,
              value: 'dark',
              current: current,
              ref: ref,
              isDark: isDark,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showScriptDialog(BuildContext context, WidgetRef ref, String current) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.scriptDisplay,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            ScriptOption(
              label: AppLocalizations.of(context)!.bothScripts,
              value: 'both',
              current: current,
              ref: ref,
              isDark: isDark,
            ),
            ScriptOption(
              label: AppLocalizations.of(context)!.olChikiOnly,
              value: 'olchiki',
              current: current,
              ref: ref,
              isDark: isDark,
            ),
            ScriptOption(
              label: AppLocalizations.of(context)!.latinOnly,
              value: 'latin',
              current: current,
              ref: ref,
              isDark: isDark,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.chooseLanguage,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            LanguageOption(
              label: AppLocalizations.of(context)!.english,
              value: 'en',
              current: current,
              ref: ref,
              isDark: isDark,
            ),
            LanguageOption(
              label: AppLocalizations.of(context)!.santali,
              value: 'sat',
              current: current,
              ref: ref,
              isDark: isDark,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _getThemeLabel(BuildContext context, String mode) {
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case 'light':
        return l10n.light;
      case 'dark':
        return l10n.dark;
      default:
        return l10n.systemDefault;
    }
  }

  String _getScriptLabel(BuildContext context, String mode) {
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case 'olchiki':
        return l10n.olChikiOnly;
      case 'latin':
        return l10n.latinOnly;
      default:
        return l10n.bothScripts;
    }
  }

  String _getLanguageLabel(BuildContext context, String languageCode) {
    final l10n = AppLocalizations.of(context)!;
    switch (languageCode) {
      case 'sat':
        return l10n.santali;
      case 'en':
      default:
        return l10n.english;
    }
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_rounded, color: AppColors.error),
            ),
            const SizedBox(width: 14),
            Text(AppLocalizations.of(context)!.resetProgress),
          ],
        ),
        content: Text(AppLocalizations.of(context)!.resetProgressWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              // Reset progress by clearing the stored data
              ref.read(userStatsProvider.notifier).resetProgress();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.reset),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(l10n.deleteAccount)),
          ],
        ),
        content: Text(l10n.deleteAccountWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              HapticFeedback.mediumImpact();
              try {
                // Show loading
                Navigator.pop(context);
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                final authRepo = ref.read(authRepositoryProvider);
                final result = await authRepo.deleteAccount();

                result.fold(
                  (failure) {
                    if (context.mounted) {
                      Navigator.pop(context); // Close loading
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to delete account: ${failure.message}',
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  (_) async {
                    // Clear all local data
                    await ref.read(sharedPreferencesProvider).clear();

                    // Navigate to welcome screen
                    if (context.mounted) {
                      Navigator.pop(context); // Close loading
                      context.go('/welcome');
                    }
                  },
                );
              } catch (e) {
                // Handle error
                if (context.mounted) {
                  Navigator.pop(context); // Close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to delete account: ${e.toString()}',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.deletePermanently),
          ),
        ],
      ),
    );
  }
}
