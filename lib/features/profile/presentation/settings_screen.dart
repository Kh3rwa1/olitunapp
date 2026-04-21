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
import '../../../shared/widgets/bento_grid.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final scriptMode = ref.watch(scriptModeProvider);
    final soundEnabled = ref.watch(soundEnabledProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isTablet = ResponsiveLayout.isTablet(context);

    final settingsBody = ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 20,
        vertical: isDesktop ? 32 : 20,
      ),
      children: [
        if (isDesktop) ...[
          Text(
            'Settings',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Customize your learning experience',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 32),
        ],

        // Bento grid for settings sections
        if (isTablet || isDesktop)
          _buildDesktopBento(context, ref, themeMode, scriptMode, soundEnabled, isDark)
        else
          _buildMobileBento(context, ref, themeMode, scriptMode, soundEnabled, isDark),

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
          'Settings',
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
                child: _buildSettingsCard(
                  context: context,
                  title: 'Appearance',
                  icon: Icons.palette_rounded,
                  color: AppColors.duoPurple,
                  isDark: isDark,
                  index: 0,
                  children: [
                    _SettingTile(
                      icon: Icons.dark_mode_rounded,
                      title: 'Dark Mode',
                      subtitle: _getThemeLabel(themeMode),
                      isDark: isDark,
                      onTap: () => _showThemeDialog(context, ref, themeMode),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSettingsCard(
                  context: context,
                  title: 'Script Display',
                  icon: Icons.translate_rounded,
                  color: AppColors.duoBlue,
                  isDark: isDark,
                  index: 1,
                  children: [
                    _SettingTile(
                      icon: Icons.translate_rounded,
                      title: 'Script Mode',
                      subtitle: _getScriptLabel(scriptMode),
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
                child: _buildSettingsCard(
                  context: context,
                  title: 'Sound',
                  icon: Icons.music_note_rounded,
                  color: AppColors.primary,
                  isDark: isDark,
                  index: 2,
                  children: [
                    _ToggleTile(
                      icon: Icons.volume_up_rounded,
                      title: 'Sound Effects',
                      subtitle: 'Play sounds for actions',
                      value: soundEnabled,
                      isDark: isDark,
                      onChanged: (value) => toggleSound(ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSettingsCard(
                  context: context,
                  title: 'Danger Zone',
                  icon: Icons.warning_rounded,
                  color: AppColors.duoRed,
                  isDark: isDark,
                  index: 3,
                  children: [
                    _SettingTile(
                      icon: Icons.restart_alt_rounded,
                      title: 'Reset Progress',
                      subtitle: 'Clear all learning data',
                      isDark: isDark,
                      isDestructive: true,
                      onTap: () => _showResetDialog(context, ref),
                    ),
                    const SizedBox(height: 10),
                    _SettingTile(
                      icon: Icons.delete_forever_rounded,
                      title: 'Delete Account',
                      subtitle: 'Permanently delete your account',
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
      ],
    );
  }

  Widget _buildMobileBento(
    BuildContext context,
    WidgetRef ref,
    String themeMode,
    String scriptMode,
    bool soundEnabled,
    bool isDark,
  ) {
    return Column(
      children: [
        _buildSettingsCard(
          context: context,
          title: 'Appearance',
          icon: Icons.palette_rounded,
          color: AppColors.duoPurple,
          isDark: isDark,
          index: 0,
          children: [
            _SettingTile(
              icon: Icons.dark_mode_rounded,
              title: 'Dark Mode',
              subtitle: _getThemeLabel(themeMode),
              isDark: isDark,
              onTap: () => _showThemeDialog(context, ref, themeMode),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          context: context,
          title: 'Script Display',
          icon: Icons.translate_rounded,
          color: AppColors.duoBlue,
          isDark: isDark,
          index: 1,
          children: [
            _SettingTile(
              icon: Icons.translate_rounded,
              title: 'Script Mode',
              subtitle: _getScriptLabel(scriptMode),
              isDark: isDark,
              onTap: () => _showScriptDialog(context, ref, scriptMode),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          context: context,
          title: 'Sound',
          icon: Icons.music_note_rounded,
          color: AppColors.primary,
          isDark: isDark,
          index: 2,
          children: [
            _ToggleTile(
              icon: Icons.volume_up_rounded,
              title: 'Sound Effects',
              subtitle: 'Play sounds for actions',
              value: soundEnabled,
              isDark: isDark,
              onChanged: (value) => toggleSound(ref),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          context: context,
          title: 'Danger Zone',
          icon: Icons.warning_rounded,
          color: AppColors.duoRed,
          isDark: isDark,
          index: 3,
          children: [
            _SettingTile(
              icon: Icons.restart_alt_rounded,
              title: 'Reset Progress',
              subtitle: 'Clear all learning data',
              isDark: isDark,
              isDestructive: true,
              onTap: () => _showResetDialog(context, ref),
            ),
            const SizedBox(height: 10),
            _SettingTile(
              icon: Icons.delete_forever_rounded,
              title: 'Delete Account',
              subtitle: 'Permanently delete your account',
              isDark: isDark,
              isDestructive: true,
              onTap: () => _showDeleteAccountDialog(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
    required int index,
    required List<Widget> children,
  }) {
    return AnimatedBentoChild(
      index: index,
      child: BentoCell(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  String _getThemeLabel(String mode) {
    switch (mode) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      default:
        return 'System default';
    }
  }

  String _getScriptLabel(String mode) {
    switch (mode) {
      case 'olchiki':
        return 'Ol Chiki only';
      case 'latin':
        return 'Latin only';
      default:
        return 'Both scripts';
    }
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
              'Choose Theme',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            _ThemeOption('System default', 'system', current, ref, isDark),
            _ThemeOption('Light', 'light', current, ref, isDark),
            _ThemeOption('Dark', 'dark', current, ref, isDark),
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
              'Script Display',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            _ScriptOption('Both scripts', 'both', current, ref, isDark),
            _ScriptOption('Ol Chiki only', 'olchiki', current, ref, isDark),
            _ScriptOption('Latin only', 'latin', current, ref, isDark),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
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
            const Text('Reset Progress'),
          ],
        ),
        content: const Text(
          'This will clear all your progress, stars, and streaks. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
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
              child: const Icon(
                Icons.delete_forever_rounded,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(child: Text('Delete Account')),
          ],
        ),
        content: const Text(
          'This will permanently delete your account and all associated data. This action cannot be undone.\n\nYour progress, settings, and personal information will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
                          content: Text('Failed to delete account: ${failure.message}'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  (_) async {
                    // Clear all local data
                    await prefs.clear();

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
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }
}


class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (isDestructive ? AppColors.error : AppColors.primary)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDestructive ? AppColors.error : AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDestructive
                          ? AppColors.error
                          : (isDark ? Colors.white : Colors.black),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final WidgetRef ref;
  final bool isDark;

  const _ThemeOption(
    this.label,
    this.value,
    this.current,
    this.ref,
    this.isDark,
  );

  @override
  Widget build(BuildContext context) {
    final isSelected = value == current;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : null,
      onTap: () {
        updateThemeMode(ref, value);
        Navigator.pop(context);
      },
    );
  }
}

class _ScriptOption extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final WidgetRef ref;
  final bool isDark;

  const _ScriptOption(
    this.label,
    this.value,
    this.current,
    this.ref,
    this.isDark,
  );

  @override
  Widget build(BuildContext context) {
    final isSelected = value == current;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : null,
      onTap: () {
        updateScriptMode(ref, value);
        Navigator.pop(context);
      },
    );
  }
}
