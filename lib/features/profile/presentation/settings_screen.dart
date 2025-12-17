import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/bubble_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/animated_buttons.dart';
import '../../../shared/providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final scriptMode = ref.watch(scriptModeProvider);
    final soundEnabled = ref.watch(soundEnabledProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BubbleBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: CircleIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () => context.pop(),
          ),
          title: const Text('Settings'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Appearance Section
                _buildSectionTitle(context, 'Appearance'),
                const SizedBox(height: AppConstants.spacingM),
                _buildThemeSelector(context, ref, themeMode),
                const SizedBox(height: AppConstants.spacingL),

                // Script Mode Section
                _buildSectionTitle(context, 'Script Display'),
                const SizedBox(height: AppConstants.spacingM),
                _buildScriptModeSelector(context, ref, scriptMode),
                const SizedBox(height: AppConstants.spacingL),

                // Sound Section
                _buildSectionTitle(context, 'Audio'),
                const SizedBox(height: AppConstants.spacingM),
                SoftCard(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  child: Row(
                    children: [
                      Icon(
                        soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                        color: AppColors.primaryCyan,
                      ),
                      const SizedBox(width: AppConstants.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sound Effects',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              'Play sounds for interactions',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: soundEnabled,
                        onChanged: (value) {
                          ref.read(soundEnabledProvider.notifier).state = value;
                          ref.read(userRepositoryProvider).setLocalSoundEnabled(value);
                        },
                        activeTrackColor: AppColors.primaryCyan,
                        thumbColor: WidgetStatePropertyAll(
                          soundEnabled ? Colors.white : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.spacingL),

                // About Section
                _buildSectionTitle(context, 'About'),
                const SizedBox(height: AppConstants.spacingM),
                SoftCard(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  child: Column(
                    children: [
                      _buildAboutRow(context, 'Version', '1.0.0'),
                      const Divider(height: AppConstants.spacingL),
                      _buildAboutRow(context, 'Developer', 'Olitun Team'),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXL),

                // Logout button
                SecondaryButton(
                  text: 'Sign Out',
                  icon: Icons.logout_rounded,
                  onPressed: () => _showLogoutDialog(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }

  Widget _buildThemeSelector(BuildContext context, WidgetRef ref, String currentMode) {
    return SoftCard(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        children: [
          _ThemeOption(
            icon: Icons.brightness_auto_rounded,
            title: 'System',
            subtitle: 'Follow system theme',
            isSelected: currentMode == AppConstants.themeSystem,
            onTap: () => _setTheme(ref, AppConstants.themeSystem),
          ),
          const Divider(height: AppConstants.spacingL),
          _ThemeOption(
            icon: Icons.light_mode_rounded,
            title: 'Light',
            subtitle: 'Always use light theme',
            isSelected: currentMode == AppConstants.themeLight,
            onTap: () => _setTheme(ref, AppConstants.themeLight),
          ),
          const Divider(height: AppConstants.spacingL),
          _ThemeOption(
            icon: Icons.dark_mode_rounded,
            title: 'Dark',
            subtitle: 'Always use dark theme',
            isSelected: currentMode == AppConstants.themeDark,
            onTap: () => _setTheme(ref, AppConstants.themeDark),
          ),
        ],
      ),
    );
  }

  Widget _buildScriptModeSelector(BuildContext context, WidgetRef ref, String currentMode) {
    return SoftCard(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        children: [
          _ScriptOption(
            title: 'Ol Chiki Only',
            subtitle: 'ᱚᱞ ᱪᱤᱠᱤ',
            isSelected: currentMode == AppConstants.scriptOlChiki,
            onTap: () => _setScriptMode(ref, AppConstants.scriptOlChiki),
          ),
          const Divider(height: AppConstants.spacingL),
          _ScriptOption(
            title: 'Latin Only',
            subtitle: 'Ol Chiki (Romanized)',
            isSelected: currentMode == AppConstants.scriptLatin,
            onTap: () => _setScriptMode(ref, AppConstants.scriptLatin),
          ),
          const Divider(height: AppConstants.spacingL),
          _ScriptOption(
            title: 'Both Scripts',
            subtitle: 'ᱚᱞ ᱪᱤᱠᱤ / Ol Chiki',
            isSelected: currentMode == AppConstants.scriptBoth,
            onTap: () => _setScriptMode(ref, AppConstants.scriptBoth),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  void _setTheme(WidgetRef ref, String mode) {
    ref.read(themeModeProvider.notifier).state = mode;
    ref.read(userRepositoryProvider).setLocalThemeMode(mode);
  }

  void _setScriptMode(WidgetRef ref, String mode) {
    ref.read(scriptModeProvider.notifier).state = mode;
    ref.read(userRepositoryProvider).setLocalScriptMode(mode);
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        ),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authRepositoryProvider).signOut();
              await ref.read(userRepositoryProvider).clearLocalPreferences();
              if (context.mounted) {
                context.go('/welcome');
              }
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primaryCyan : null,
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.primaryCyan : null,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.primaryCyan,
            ),
        ],
      ),
    );
  }
}

class _ScriptOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ScriptOption({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.primaryCyan : null,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.primaryCyan,
            ),
        ],
      ),
    );
  }
}
