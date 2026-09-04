import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/ads/widgets/native_ad_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/providers/local_settings_provider.dart';
import '../../../practice/data/typing_practice_settings.dart';
import 'diagnostics_tile.dart';
import 'downloads_management_card.dart';
import 'learning_settings_tiles.dart';
import 'notifications_settings_card.dart';
import 'settings_dialogs.dart';
import 'settings_widgets.dart';
import 'target_language_tile.dart';

/// Bento layout of the settings screen for desktop and tablet.
class SettingsBentoDesktop extends ConsumerWidget {
  const SettingsBentoDesktop({
    super.key,
    required this.themeMode,
    required this.scriptMode,
    required this.appLanguage,
    required this.soundEnabled,
    required this.reduceVisualEffects,
    required this.isDark,
  });

  final String themeMode;
  final String scriptMode;
  final String appLanguage;
  final bool soundEnabled;
  final bool reduceVisualEffects;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  color: AppColors.accentOchre,
                  index: 0,
                  children: [
                    SettingTile(
                      icon: Icons.dark_mode_rounded,
                      title: AppLocalizations.of(context)!.darkMode,
                      subtitle: _getThemeLabel(context, themeMode),
                      isDark: isDark,
                      onTap: () => showThemeDialog(context, ref, themeMode),
                    ),
                    const SizedBox(height: 10),
                    SettingTile(
                      icon: Icons.language_rounded,
                      title: AppLocalizations.of(context)!.appLanguage,
                      subtitle: _getLanguageLabel(context, appLanguage),
                      isDark: isDark,
                      onTap: () =>
                          showLanguageDialog(context, ref, appLanguage),
                    ),
                    const SizedBox(height: 10),
                    const TeachingLanguageTile(),
                    const SizedBox(height: 10),
                    const LessonAudioModeTile(),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SettingsCard(
                  title: AppLocalizations.of(context)!.scriptDisplay,
                  icon: Icons.translate_rounded,
                  color: AppColors.brandBlue,
                  index: 1,
                  children: [
                    SettingTile(
                      icon: Icons.translate_rounded,
                      title: AppLocalizations.of(context)!.scriptMode,
                      subtitle: _getScriptLabel(context, scriptMode),
                      isDark: isDark,
                      onTap: () => showScriptDialog(context, ref, scriptMode),
                    ),
                    const SizedBox(height: 10),
                    const TargetLanguageTile(),
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
                    const SizedBox(height: 10),
                    ToggleTile(
                      icon: Icons.blur_off_rounded,
                      title: 'Reduce Visual Effects',
                      subtitle:
                          'Simplify animations, visualizers, and particle effects for maximum battery life',
                      value: reduceVisualEffects,
                      isDark: isDark,
                      onChanged: (value) => toggleReduceVisualEffects(ref),
                    ),
                    const SizedBox(height: 10),
                    Semantics(
                      label:
                          "Toggle typing practice for vocabulary and sentences. When enabled, you'll type Ol Chiki characters to complete words and earn 5 stars.",
                      child: ToggleTile(
                        icon: Icons.keyboard_rounded,
                        title: 'Vocabulary & Sentence Practice',
                        subtitle:
                            'Enable active recall typing practice for vocabulary words and sentences',
                        value: ref
                            .watch(typingPracticeSettingsProvider)
                            .enabled,
                        isDark: isDark,
                        onChanged: (value) => ref
                            .read(typingPracticeSettingsProvider.notifier)
                            .setEnabled(value),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SettingsCard(
                  title: AppLocalizations.of(context)!.dangerZone,
                  icon: Icons.warning_rounded,
                  color: AppColors.accentTerracotta,
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
                      onTap: () => showResetDialog(context, ref),
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
                      onTap: () => showDeleteAccountDialog(context, ref),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: NotificationsSettingsCard(isDark: isDark),
        ),
        SizedBox(
          width: double.infinity,
          child: _buildLegalCard(context, isDark, 4),
        ),
        // Phase 6: offline audio downloads & cache management. Renders
        // nothing when the feature flag is off or on web (spec §27).
        const SizedBox(
          width: double.infinity,
          child: DownloadsManagementCard(index: 5),
        ),
      ],
    );
  }
}

/// Bento layout of the settings screen for mobile.
class SettingsBentoMobile extends ConsumerWidget {
  const SettingsBentoMobile({
    super.key,
    required this.themeMode,
    required this.scriptMode,
    required this.appLanguage,
    required this.soundEnabled,
    required this.reduceVisualEffects,
    required this.isDark,
  });

  final String themeMode;
  final String scriptMode;
  final String appLanguage;
  final bool soundEnabled;
  final bool reduceVisualEffects;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SettingsCard(
          title: AppLocalizations.of(context)!.appearance,
          icon: Icons.palette_rounded,
          color: AppColors.accentOchre,
          index: 0,
          children: [
            SettingTile(
              icon: Icons.dark_mode_rounded,
              title: AppLocalizations.of(context)!.darkMode,
              subtitle: _getThemeLabel(context, themeMode),
              isDark: isDark,
              onTap: () => showThemeDialog(context, ref, themeMode),
            ),
            const SizedBox(height: 10),
            SettingTile(
              icon: Icons.language_rounded,
              title: AppLocalizations.of(context)!.appLanguage,
              subtitle: _getLanguageLabel(context, appLanguage),
              isDark: isDark,
              onTap: () => showLanguageDialog(context, ref, appLanguage),
            ),
            const SizedBox(height: 10),
            const TeachingLanguageTile(),
            const SizedBox(height: 10),
            const LessonAudioModeTile(),
          ],
        ),
        const SizedBox(height: 16),
        SettingsCard(
          title: AppLocalizations.of(context)!.scriptDisplay,
          icon: Icons.translate_rounded,
          color: AppColors.brandBlue,
          index: 1,
          children: [
            SettingTile(
              icon: Icons.translate_rounded,
              title: AppLocalizations.of(context)!.scriptMode,
              subtitle: _getScriptLabel(context, scriptMode),
              isDark: isDark,
              onTap: () => showScriptDialog(context, ref, scriptMode),
            ),
            const SizedBox(height: 10),
            const TargetLanguageTile(),
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
            const SizedBox(height: 10),
            ToggleTile(
              icon: Icons.blur_off_rounded,
              title: 'Reduce Visual Effects',
              subtitle:
                  'Simplify animations, visualizers, and particle effects for maximum battery life',
              value: reduceVisualEffects,
              isDark: isDark,
              onChanged: (value) => toggleReduceVisualEffects(ref),
            ),
            const SizedBox(height: 10),
            Semantics(
              label:
                  "Toggle typing practice for vocabulary and sentences. When enabled, you'll type Ol Chiki characters to complete words and earn 5 stars.",
              child: ToggleTile(
                icon: Icons.keyboard_rounded,
                title: 'Vocabulary & Sentence Practice',
                subtitle:
                    'Enable active recall typing practice for vocabulary words and sentences',
                value: ref.watch(typingPracticeSettingsProvider).enabled,
                isDark: isDark,
                onChanged: (value) => ref
                    .read(typingPracticeSettingsProvider.notifier)
                    .setEnabled(value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        NotificationsSettingsCard(isDark: isDark),
        const SizedBox(height: 16),
        _buildLegalCard(context, isDark, 4),
        const SizedBox(height: 16),
        // Phase 6: offline audio downloads & cache management. Renders
        // nothing when the feature flag is off or on web (spec §27).
        const DownloadsManagementCard(index: 5),
        const SizedBox(height: 16),
        const RepaintBoundary(
          child: NativeAdWidget(placement: 'settings_native'),
        ),
        const SizedBox(height: 16),
        SettingsCard(
          title: AppLocalizations.of(context)!.dangerZone,
          icon: Icons.warning_rounded,
          color: AppColors.accentTerracotta,
          index: 3,
          children: [
            SettingTile(
              icon: Icons.restart_alt_rounded,
              title: AppLocalizations.of(context)!.resetProgress,
              subtitle: AppLocalizations.of(context)!.clearAllLearningData,
              isDark: isDark,
              isDestructive: true,
              onTap: () => showResetDialog(context, ref),
            ),
            const SizedBox(height: 10),
            SettingTile(
              icon: Icons.delete_forever_rounded,
              title: AppLocalizations.of(context)!.deleteAccount,
              subtitle: AppLocalizations.of(context)!.deleteAccountSubtitle,
              isDark: isDark,
              isDestructive: true,
              onTap: () => showDeleteAccountDialog(context, ref),
            ),
          ],
        ),
      ],
    );
  }
}

Widget _buildLegalCard(BuildContext context, bool isDark, int index) {
  final l10n = AppLocalizations.of(context)!;
  return SettingsCard(
    title: l10n.legal,
    icon: Icons.verified_user_rounded,
    color: AppColors.accentForest,
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
      const SizedBox(height: 10),
      SettingTile(
        icon: Icons.admin_panel_settings_rounded,
        title: 'Admin Portal',
        subtitle: 'Manage lesson contents and authored quizzes',
        isDark: isDark,
        onTap: () => context.go('/admin'),
      ),
      const SizedBox(height: 10),
      const DiagnosticsTile(),
    ],
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
    case 'hi':
      return l10n.hindi;
    case 'bn':
      return l10n.bengali;
    case 'or':
      return l10n.odia;
    case 'en':
    default:
      return l10n.english;
  }
}
