import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/storage_service.dart';
import '../../../shared/providers/providers.dart';
import '../../../core/presentation/layout/responsive_layout.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final scriptMode = ref.watch(scriptModeProvider);
    final soundEnabled = ref.watch(soundEnabledProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    final settingsBody = ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 20,
        vertical: isDesktop ? 32 : 20,
      ),
      children: [
        if (isDesktop) ...[
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Customize your learning experience',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(height: 32),
        ],

        // Appearance Section
        _SectionHeader('Appearance', isDark),
        const SizedBox(height: 16),
        _SettingTile(
          icon: Icons.dark_mode_rounded,
          title: 'Dark Mode',
          subtitle: _getThemeLabel(themeMode),
          isDark: isDark,
          onTap: () => _showThemeDialog(context, ref, themeMode),
        ),

        const SizedBox(height: 28),

        // Script Section
        _SectionHeader('Script Display', isDark),
        const SizedBox(height: 16),
        _SettingTile(
          icon: Icons.translate_rounded,
          title: 'Script Mode',
          subtitle: _getScriptLabel(scriptMode),
          isDark: isDark,
          onTap: () => _showScriptDialog(context, ref, scriptMode),
        ),

        const SizedBox(height: 28),

        // Sound Section
        _SectionHeader('Sound', isDark),
        const SizedBox(height: 16),
        _ToggleTile(
          icon: Icons.volume_up_rounded,
          title: 'Sound Effects',
          subtitle: 'Play sounds for actions',
          value: soundEnabled,
          isDark: isDark,
          onChanged: (value) => toggleSound(ref),
        ),

        const SizedBox(height: 28),

        // Data Section
        _SectionHeader('Data', isDark),
        const SizedBox(height: 16),
        _SettingTile(
          icon: Icons.restart_alt_rounded,
          title: 'Reset Progress',
          subtitle: 'Clear all learning data',
          isDark: isDark,
          isDestructive: true,
          onTap: () => _showResetDialog(context, ref),
        ),
      ],
    );

    // On desktop, render inline (no Scaffold/AppBar) since it's inside MainShellScreen
    if (isDesktop) {
      return settingsBody;
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: settingsBody,
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
              prefs.remove('user_progress_data');
              // Force a reload by invalidating the provider
              ref.invalidate(progressProvider);
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
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader(this.title, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: isDark ? Colors.white38 : Colors.black38,
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
